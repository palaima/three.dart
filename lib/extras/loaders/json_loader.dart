/*
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author nelson silva / http://www.inevo.pt/
 *
 * based on r71
 */

part of three.extras.loaders;

class JSONLoader extends Loader {
  bool withCredentials = false;

  JSONLoader({bool showStatus: false}) : super(showStatus: showStatus);

  Future load(String url, {texturePath}) {
    texturePath = texturePath != null && (texturePath is String) ? texturePath : _extractUrlBase(url);

    _onLoadStartController.add(null);

    return _loadAjaxJSON(url, texturePath);
  }

  Future _loadAjaxJSON(String url, String texturePath) {
    var completer = new Completer();

    var xhr = new HttpRequest();

    var length = 0;

    xhr.onReadyStateChange.listen((onData) {
      if (xhr.readyState == HttpRequest.DONE) {
        if (xhr.status == 200 || xhr.status == 0) {
          if (xhr.responseText != null) {
            var json = JSON.decode(xhr.responseText);
            var metadata = json['metadata'];

            if (metadata != null) {
              if (metadata['type'] == 'object') {
                error('JSONLoader: $url should be loaded with ObjectLoader instead.');
                return;
              }

              if (metadata['type'] == 'scene') {
                error('JSONLoader: $url seems to be a Scene. Use SceneLoader instead.');
                return;
              }
            }

            var result = _parse(json, texturePath);
            completer.complete(result['geometry']); // , result['materials']);
          } else {
            error('JSONLoader: $url seems to be unreachable or the file is empty.');
          }

          // in context of more complex asset initialization
          // do not block on single failed file
          // maybe should go even one more level up

          //completer.complete(); TODO
        } else {
          error('JSONLoader: Couldn\'t load $url (${xhr.status})');
        }
      } else if (xhr.readyState == HttpRequest.LOADING) {
          if (length == 0) {
            length = xhr.getResponseHeader('Content-Length');
          }

          _onLoadProgressController.add({'total': length, 'loaded': xhr.responseText.length});
      } else if (xhr.readyState == HttpRequest.HEADERS_RECEIVED) {
        length = xhr.getResponseHeader('Content-Length');
      }
    });

    xhr.open('GET', url, async: true);
    xhr.withCredentials = withCredentials;
    xhr.send(null);

    return completer.future;
  }

  Map _parse(Map json, texturePath) {
    var geometry = new Geometry();
    var scale = json['scale'] != null ? 1.0 / json['scale'] : 1.0;

    _parseModel(json, geometry, scale);

    _parseSkin(json, geometry);
    _parseMorphing(json, geometry, scale);

    geometry.computeFaceNormals();
    geometry.computeBoundingSphere();

    if (json['materials'] == null || json['materials'].length == 0) {
      return {'geometry': geometry};
    } else {
      var materials = _initMaterials(json['materials'], texturePath);

      if (_needsTangents(materials)) {
        geometry.computeTangents();
      }

      return {'geometry': geometry, 'materials': materials};
    }
  }

  void _parseModel(Map json, Geometry geometry, double scale) {
    bool isBitSet(value, position) => value & (1 << position) > 0;

    var faces = json['faces'],
        vertices = json['vertices'],
        normals = json['normals'],
        colors = json['colors'],
        nUvLayers = 0;

    if (json['uvs'] != null) {
      // disregard empty arrays

      for (var i = 0; i < json['uvs'].length; i++) {
        if (json['uvs'][i].isNotEmpty) nUvLayers++;
      }

      for (var i = 0; i < nUvLayers; i++) {
        geometry.faceVertexUvs[i] = [];
      }
    }

    var offset = 0;
    var zLength = vertices.length;

    while (offset < zLength) {
      var vertex = new Vector3.zero()
        ..x = vertices[offset++] * scale
        ..y = vertices[offset++] * scale
        ..z = vertices[offset++] * scale;

      geometry.vertices.add(vertex);
    }

    offset = 0;
    zLength = faces.length;

    while (offset < zLength) {
      var type = faces[offset++];

      var isQuad = isBitSet(type, 0);
      var hasMaterial = isBitSet(type, 1);
      var hasFaceVertexUv = isBitSet(type, 3);
      var hasFaceNormal = isBitSet(type, 4);
      var hasFaceVertexNormal = isBitSet(type, 5);
      var hasFaceColor = isBitSet(type, 6);
      var hasFaceVertexColor = isBitSet(type, 7);

      // log("type", type, "bits", isQuad, hasMaterial, hasFaceVertexUv, hasFaceNormal, hasFaceVertexNormal, hasFaceColor, hasFaceVertexColor);

      if (isQuad) {
        var faceA = new Face3(faces[offset], faces[offset + 1], faces[offset + 3]);
        var faceB = new Face3(faces[offset + 1], faces[offset + 2], faces[offset + 3]);

        offset += 4;

        if (hasMaterial) {
          offset++;
        }

        // to get face <=> uv index correspondence

        var fi = geometry.faces.length;
        geometry.faceVertexUvs.length = nUvLayers;

        if (hasFaceVertexUv) {
          for (var i = 0; i < nUvLayers; i++) {
            var uvLayer = json['uvs'][i];

            geometry.faceVertexUvs[i].length = fi + 2;

            geometry.faceVertexUvs[i][fi] = [];
            geometry.faceVertexUvs[i][fi + 1] = [];

            for (var j = 0; j < 4; j++) {
              var uvIndex = faces[offset++];

              var u = uvLayer[uvIndex * 2];
              var v = uvLayer[uvIndex * 2 + 1];

              var uv = new Vector2(u, v);

              if (j != 2) geometry.faceVertexUvs[i][fi].add(uv);
              if (j != 0) geometry.faceVertexUvs[i][fi + 1].add(uv);
            }
          }
        }

        if (hasFaceNormal) {
          var normalIndex = faces[offset++] * 3;

          faceA.normal.setValues(normals[normalIndex++], normals[normalIndex++], normals[normalIndex]);

          faceB.normal.setFrom(faceA.normal);
        }

        if (hasFaceVertexNormal) {
          for (var i = 0; i < 4; i++) {
            var normalIndex = faces[offset++] * 3;

            var normal = new Vector3(normals[normalIndex++], normals[normalIndex++], normals[normalIndex]);

            if (i != 2) faceA.vertexNormals.add(normal);
            if (i != 0) faceB.vertexNormals.add(normal);
          }
        }

        if (hasFaceColor) {
          var colorIndex = faces[offset++];
          var hex = colors[colorIndex];

          faceA.color.setHex(hex);
          faceB.color.setHex(hex);
        }

        if (hasFaceVertexColor) {
          for (var i = 0; i < 4; i++) {
            var colorIndex = faces[offset++];
            var hex = colors[colorIndex];

            if (i != 2) faceA.vertexColors.add(new Color(hex));
            if (i != 0) faceB.vertexColors.add(new Color(hex));
          }
        }

        geometry.faces.add(faceA);
        geometry.faces.add(faceB);
      } else {
        var face = new Face3(faces[offset++], faces[offset++], faces[offset++]);

        if (hasMaterial) {
          offset++;
        }

        // to get face <=> uv index correspondence

        var fi = geometry.faces.length;
        geometry.faceVertexUvs.length = nUvLayers;

        if (hasFaceVertexUv) {
          for (var i = 0; i < nUvLayers; i++) {
            var uvLayer = json['uvs'][i];

            geometry.faceVertexUvs[i].length = fi + 1;
            geometry.faceVertexUvs[i][fi] = [];

            for (var j = 0; j < 3; j++) {
              var uvIndex = faces[offset++];

              var u = uvLayer[uvIndex * 2];
              var v = uvLayer[uvIndex * 2 + 1];

              var uv = new Vector2(u, v);

              geometry.faceVertexUvs[i][fi].add(uv);
            }
          }
        }

        if (hasFaceNormal) {
          var normalIndex = faces[offset++] * 3;

          face.normal.setValues(normals[normalIndex++], normals[normalIndex++], normals[normalIndex]);
        }

        if (hasFaceVertexNormal) {
          for (var i = 0; i < 3; i++) {
            var normalIndex = faces[offset++] * 3;

            var normal = new Vector3(normals[normalIndex++], normals[normalIndex++], normals[normalIndex]);

            face.vertexNormals.add(normal);
          }
        }

        if (hasFaceColor) {
          var colorIndex = faces[offset++];
          face.color.setHex(colors[colorIndex]);
        }

        if (hasFaceVertexColor) {
          for (var i = 0; i < 3; i++) {
            var colorIndex = faces[offset++];
            face.vertexColors.add(new Color(colors[colorIndex]));
          }
        }

        geometry.faces.add(face);
      }
    }
  }

  void _parseSkin(Map json, Geometry geometry) {
    var influencesPerVertex = (json['influencesPerVertex'] != null) ? json['influencesPerVertex'] : 2;

    if (json['skinWeights'] != null) {
      for (var i = 0; i < json['skinWeights'].length; i += influencesPerVertex) {
        var x = json['skinWeights'][i];
        var y = (influencesPerVertex > 1) ? json['skinWeights'][i + 1] : 0;
        var z = (influencesPerVertex > 2) ? json['skinWeights'][i + 2] : 0;
        var w = (influencesPerVertex > 3) ? json['skinWeights'][i + 3] : 0;

        geometry.skinWeights.add(new Vector4(x, y, z, w));
      }
    }

    if (json['skinIndices'] != null) {
      for (var i = 0; i < json['skinIndices'].length; i += influencesPerVertex) {
        var a = json['skinIndices'][i];
        var b = (influencesPerVertex > 1) ? json['skinIndices'][i + 1] : 0;
        var c = (influencesPerVertex > 2) ? json['skinIndices'][i + 2] : 0;
        var d = (influencesPerVertex > 3) ? json['skinIndices'][i + 3] : 0;

        geometry.skinIndices.add(new Vector4(a, b, c, d));
      }
    }

    geometry.bones = json['bones'];

    if (geometry.bones != null &&
        geometry.bones.length > 0 &&
        (geometry.skinWeights.length != geometry.skinIndices.length ||
            geometry.skinIndices.length != geometry.vertices.length)) {
      warn('JSONLoader: When skinning, number of vertices (' +
          geometry.vertices.length.toString() +
          '), skinIndices (' +
          geometry.skinIndices.length.toString() +
          '), and skinWeights (' +
          geometry.skinWeights.length.toString() +
          ') should match.');
    }

    // could change this to json.animations[0] or remove completely

    geometry.animation = json['animation'];
    geometry.animations = json['animations'];
  }

  void _parseMorphing(Map json, Geometry geometry, double scale) {
    if (json['morphTargets'] != null) {
      for (var i = 0, l = json['morphTargets'].length; i < l; i++) {
        geometry.morphTargets.add(new MorphTarget(name: json['morphTargets'][i]['name'], vertices: []));

        var dstVertices = geometry.morphTargets[i].vertices;
        var srcVertices = json['morphTargets'][i]['vertices'];

        for (var v = 0; v < srcVertices.length; v += 3) {
          var vertex = new Vector3.zero();
          vertex.x = srcVertices[v] * scale;
          vertex.y = srcVertices[v + 1] * scale;
          vertex.z = srcVertices[v + 2] * scale;

          dstVertices.add(vertex);
        }
      }
    }

    if (json['morphColors'] != null) {
      for (var i = 0, l = json['morphColors'].length; i < l; i++) {
        geometry.morphColors.add(new MorphColor(name: json['morphColors'][i]['name'], colors: []));

        var dstColors = geometry.morphColors[i].colors;
        var srcColors = json['morphColors'][i]['colors'];

        for (var c = 0; c < srcColors.length; c += 3) {
          var color = new Color(0xffaa00);
          color.setRGB(srcColors[c], srcColors[c + 1], srcColors[c + 2]);
          dstColors.add(color);
        }
      }
    }
  }
}
