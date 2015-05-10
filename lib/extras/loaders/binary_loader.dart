/*
 * @author alteredq / http://alteredqualia.com/
 */

// TODO: Clean up a bit (add type information etc.)

part of three.extras.loaders;

class BinaryLoader extends Loader {
  bool showProgress;

  BinaryLoader({bool showStatus: true}) : super(showStatus: showStatus);

  Future load(String url, {texturePath, binaryPath}) {
    if (texturePath == null) texturePath = _extractUrlBase(url);
    if (binaryPath == null) binaryPath = _extractUrlBase(url);

    if (showProgress == true) onLoadProgress.listen(_updateProgress);

    _onLoadStartController.add(null);

    // #1 load JS part via web worker

    return _loadAjaxJSON(url, texturePath, binaryPath);
  }

  Future _loadAjaxJSON(String url, texturePath, binaryPath) {
    var completer = new Completer();
    var xhr = new HttpRequest();

    texturePath = texturePath is String ? texturePath : _extractUrlBase(url);
    binaryPath = binaryPath is String ? binaryPath : _extractUrlBase(url);

    xhr.onReadyStateChange.listen((event) {
      if (xhr.readyState == 4) {
        if (xhr.status == 200 || xhr.status == 0) {
          var json = JSON.decode(xhr.responseText);
          _loadAjaxBuffers(json, binaryPath, texturePath, completer);
        } else {
          error('BinaryLoader: Couldn\'t load [$url] [${xhr.status}]');
        }
      }
    });

    xhr.open('GET', url, async: true);
    xhr.send(null);

    return completer.future;
  }

  void _loadAjaxBuffers(Map json, String binaryPath, String texturePath, Completer completer) {
    var xhr = new HttpRequest(),
        url = binaryPath + json['buffers'];

    xhr.onLoad.listen((event) {
      ByteBuffer buffer = xhr.response;

//      if (buffer == null) {
//
//        // IEWEBGL needs this
//        buffer = (new Uint8List(xhr.responseBody)).buffer;
//      }

      if (buffer.lengthInBytes == 0) {
        // iOS and other XMLHttpRequest level 1

        var bufView = new Uint8List(xhr.responseText.length);

        for (var i = 0, l = xhr.responseText.length; i < l; i++) {
          bufView[i] = xhr.responseText.codeUnitAt(i) & 0xff;
        }
      }

      _createBinModel(buffer, texturePath, json['materials'], completer);
    });

    xhr.onProgress.listen((event) {
      if (event.lengthComputable) {
        _onLoadProgressController.add(event);
      }
    });

    xhr.onError.listen((event) => error('BinaryLoader: Couldn\'t load [$url] [${xhr.status}]'));

    xhr.open('GET', url, async: true);
    xhr.responseType = 'arraybuffer';
    xhr.overrideMimeType('text/plain; charset=x-user-defined');
    xhr.send(null);
  }

  void _createBinModel(ByteBuffer data, String texturePath, List jsonMaterials, Completer completer) {
    var geometry = new Model(data);
    var materials = _initMaterials(jsonMaterials, texturePath);

    if (_needsTangents(materials)) geometry.computeTangents();

    completer.complete(geometry); //, materials);
  }
}

class Model extends Geometry {
  ByteBuffer data;
  Map md;

  List normals = [];
  List uvs = [];

  Model(this.data) {
    var currentOffset = 0;

    md = _parseMetaData(data, currentOffset);

    currentOffset += md['header_bytes'];

    // buffers sizes

    var tri_size = md['vertex_index_bytes'] * 3 + md['material_index_bytes'];
    var quad_size = md['vertex_index_bytes'] * 4 + md['material_index_bytes'];

    var len_tri_flat = md['ntri_flat'] * (tri_size);
    var len_tri_smooth = md['ntri_smooth'] * (tri_size + md['normal_index_bytes'] * 3);
    var len_tri_flat_uv = md['ntri_flat_uv'] * (tri_size + md['uv_index_bytes'] * 3);
    var len_tri_smooth_uv =
        md['ntri_smooth_uv'] * (tri_size + md['normal_index_bytes'] * 3 + md['uv_index_bytes'] * 3);

    var len_quad_flat = md['nquad_flat'] * (quad_size);
    var len_quad_smooth = md['nquad_smooth'] * (quad_size + md['normal_index_bytes'] * 4);
    var len_quad_flat_uv = md['nquad_flat_uv'] * (quad_size + md['uv_index_bytes'] * 4);

    // read buffers

    currentOffset += _init_vertices(currentOffset);

    currentOffset += _init_normals(currentOffset);
    currentOffset += _handlePadding(md['nnormals'] * 3);

    currentOffset += _init_uvs(currentOffset);

    var start_tri_flat = currentOffset;
    var start_tri_smooth = start_tri_flat + len_tri_flat + _handlePadding(md['ntri_flat'] * 2);
    var start_tri_flat_uv = start_tri_smooth + len_tri_smooth + _handlePadding(md['ntri_smooth'] * 2);
    var start_tri_smooth_uv = start_tri_flat_uv + len_tri_flat_uv + _handlePadding(md['ntri_flat_uv'] * 2);

    var start_quad_flat = start_tri_smooth_uv + len_tri_smooth_uv + _handlePadding(md['ntri_smooth_uv'] * 2);
    var start_quad_smooth = start_quad_flat + len_quad_flat + _handlePadding(md['nquad_flat'] * 2);
    var start_quad_flat_uv = start_quad_smooth + len_quad_smooth + _handlePadding(md['nquad_smooth'] * 2);
    var start_quad_smooth_uv =
        start_quad_flat_uv + len_quad_flat_uv + _handlePadding(md['nquad_flat_uv'] * 2);

    // have to first process faces with uvs
    // so that face and uv indices match

    _init_triangles_flat_uv(start_tri_flat_uv);
    _init_triangles_smooth_uv(start_tri_smooth_uv);

    _init_quads_flat_uv(start_quad_flat_uv);
    _init_quads_smooth_uv(start_quad_smooth_uv);

    // now we can process untextured faces

    _init_triangles_flat(start_tri_flat);
    _init_triangles_smooth(start_tri_smooth);

    _init_quads_flat(start_quad_flat);
    _init_quads_smooth(start_quad_smooth);

    computeFaceNormals();
  }

  _handlePadding(n) => (n % 4) != 0 ? (4 - n % 4) : 0;

  Map _parseMetaData(data, offset) {
    var metaData = {
      'signature': _parseString(data, offset, 12),
      'header_bytes': _parseUChar8(data, offset + 12),
      'vertex_coordinate_bytes': _parseUChar8(data, offset + 13),
      'normal_coordinate_bytes': _parseUChar8(data, offset + 14),
      'uv_coordinate_bytes': _parseUChar8(data, offset + 15),
      'vertex_index_bytes': _parseUChar8(data, offset + 16),
      'normal_index_bytes': _parseUChar8(data, offset + 17),
      'uv_index_bytes': _parseUChar8(data, offset + 18),
      'material_index_bytes': _parseUChar8(data, offset + 19),
      'nvertices': _parseUInt32(data, offset + 20),
      'nnormals': _parseUInt32(data, offset + 20 + 4 * 1),
      'nuvs': _parseUInt32(data, offset + 20 + 4 * 2),
      'ntri_flat': _parseUInt32(data, offset + 20 + 4 * 3),
      'ntri_smooth': _parseUInt32(data, offset + 20 + 4 * 4),
      'ntri_flat_uv': _parseUInt32(data, offset + 20 + 4 * 5),
      'ntri_smooth_uv': _parseUInt32(data, offset + 20 + 4 * 6),
      'nquad_flat': _parseUInt32(data, offset + 20 + 4 * 7),
      'nquad_smooth': _parseUInt32(data, offset + 20 + 4 * 8),
      'nquad_flat_uv': _parseUInt32(data, offset + 20 + 4 * 9),
      'nquad_smooth_uv': _parseUInt32(data, offset + 20 + 4 * 10)
    };

    return metaData;
  }

  _parseString(data, offset, length) {
    var charList = new Uint8List.view(data, offset, length);

    var text = "";

    for (var i = 0; i < length; i++) {
      text += new String.fromCharCode(charList[offset + i]);
    }

    return text;
  }

  _parseUChar8(data, offset) {
    var charList = new Uint8List.view(data, offset, 1);

    return charList[0];
  }

  _parseUInt32(data, offset) {
    var intList = new Uint32List.view(data, offset, 1);

    return intList[0];
  }

  _init_vertices(start) {
    var nElements = md['nvertices'];

    var coordList = new Float32List.view(data, start, nElements * 3);

    var i, x, y, z;

    for (i = 0; i < nElements; i++) {
      x = coordList[i * 3];
      y = coordList[i * 3 + 1];
      z = coordList[i * 3 + 2];

      vertices.add(new Vector3(x, y, z));
    }

    return nElements * 3 * Float32List.BYTES_PER_ELEMENT;
  }

  _init_normals(start) {
    var nElements = md['nnormals'];

    if (nElements != null) {
      var normalList = new Int8List.view(data, start, nElements * 3);

      var i, x, y, z;

      for (i = 0; i < nElements; i++) {
        x = normalList[i * 3];
        y = normalList[i * 3 + 1];
        z = normalList[i * 3 + 2];

        normals.addAll([x / 127, y / 127, z / 127]);
      }
    }

    return nElements * 3 * Int8List.BYTES_PER_ELEMENT;
  }

  _init_uvs(start) {
    var nElements = md['nuvs'];

    if (nElements != null) {
      var uvList = new Float32List.view(data, start, nElements * 2);

      var i, u, v;

      for (i = 0; i < nElements; i++) {
        u = uvList[i * 2];
        v = uvList[i * 2 + 1];

        uvs.addAll([u, v]);
      }
    }

    return nElements * 2 * Float32List.BYTES_PER_ELEMENT;
  }

  _init_uvs3(nElements, offset) {
    var i, uva, uvb, uvc, u1, u2, u3, v1, v2, v3;

    var uvIndexBuffer = new Uint32List.view(data, offset, 3 * nElements);

    for (i = 0; i < nElements; i++) {
      uva = uvIndexBuffer[i * 3];
      uvb = uvIndexBuffer[i * 3 + 1];
      uvc = uvIndexBuffer[i * 3 + 2];

      u1 = uvs[uva * 2];
      v1 = uvs[uva * 2 + 1];

      u2 = uvs[uvb * 2];
      v2 = uvs[uvb * 2 + 1];

      u3 = uvs[uvc * 2];
      v3 = uvs[uvc * 2 + 1];

      faceVertexUvs[0].add([new Vector2(u1, v1), new Vector2(u2, v2), new Vector2(u3, v3)]);
    }
  }

  _init_uvs4(nElements, offset) {
    var i, uva, uvb, uvc, uvd, u1, u2, u3, u4, v1, v2, v3, v4;

    var uvIndexBuffer = new Uint32List.view(data, offset, 4 * nElements);

    for (i = 0; i < nElements; i++) {
      uva = uvIndexBuffer[i * 4];
      uvb = uvIndexBuffer[i * 4 + 1];
      uvc = uvIndexBuffer[i * 4 + 2];
      uvd = uvIndexBuffer[i * 4 + 3];

      u1 = uvs[uva * 2];
      v1 = uvs[uva * 2 + 1];

      u2 = uvs[uvb * 2];
      v2 = uvs[uvb * 2 + 1];

      u3 = uvs[uvc * 2];
      v3 = uvs[uvc * 2 + 1];

      u4 = uvs[uvd * 2];
      v4 = uvs[uvd * 2 + 1];

      faceVertexUvs[0].add([new Vector2(u1, v1), new Vector2(u2, v2), new Vector2(u4, v4)]);

      faceVertexUvs[0].add([new Vector2(u2, v2), new Vector2(u3, v3), new Vector2(u4, v4)]);
    }
  }

  _init_faces3_flat(nElements, offsetVertices, offsetMaterials) {
    var i, a, b, c;

    var vertexIndexBuffer = new Uint32List.view(data, offsetVertices, 3 * nElements);

    for (i = 0; i < nElements; i++) {
      a = vertexIndexBuffer[i * 3];
      b = vertexIndexBuffer[i * 3 + 1];
      c = vertexIndexBuffer[i * 3 + 2];

      faces.add(new Face3(a, b, c));
    }
  }

  _init_faces4_flat(nElements, offsetVertices, offsetMaterials) {
    var i, a, b, c, d;

    var vertexIndexBuffer = new Uint32List.view(data, offsetVertices, 4 * nElements);

    for (i = 0; i < nElements; i++) {
      a = vertexIndexBuffer[i * 4];
      b = vertexIndexBuffer[i * 4 + 1];
      c = vertexIndexBuffer[i * 4 + 2];
      d = vertexIndexBuffer[i * 4 + 3];

      faces.add(new Face3(a, b, d));
      faces.add(new Face3(b, c, d));
    }
  }

  _init_faces3_smooth(nElements, offsetVertices, offsetNormals, offsetMaterials) {
    var i, a, b, c;
    var na, nb, nc;

    var vertexIndexBuffer = new Uint32List.view(data, offsetVertices, 3 * nElements);
    var normalIndexBuffer = new Uint32List.view(data, offsetNormals, 3 * nElements);

    for (i = 0; i < nElements; i++) {
      a = vertexIndexBuffer[i * 3];
      b = vertexIndexBuffer[i * 3 + 1];
      c = vertexIndexBuffer[i * 3 + 2];

      na = normalIndexBuffer[i * 3];
      nb = normalIndexBuffer[i * 3 + 1];
      nc = normalIndexBuffer[i * 3 + 2];

      var nax = normals[na * 3],
          nay = normals[na * 3 + 1],
          naz = normals[na * 3 + 2],
          nbx = normals[nb * 3],
          nby = normals[nb * 3 + 1],
          nbz = normals[nb * 3 + 2],
          ncx = normals[nc * 3],
          ncy = normals[nc * 3 + 1],
          ncz = normals[nc * 3 + 2];

      faces.add(new Face3(a, b, c,
          normal: [new Vector3(nax, nay, naz), new Vector3(nbx, nby, nbz), new Vector3(ncx, ncy, ncz)]));
    }
  }

  _init_faces4_smooth(nElements, offsetVertices, offsetNormals, offsetMaterials) {
    var i, a, b, c, d;
    var na, nb, nc, nd;

    var vertexIndexBuffer = new Uint32List.view(data, offsetVertices, 4 * nElements);
    var normalIndexBuffer = new Uint32List.view(data, offsetNormals, 4 * nElements);

    for (i = 0; i < nElements; i++) {
      a = vertexIndexBuffer[i * 4];
      b = vertexIndexBuffer[i * 4 + 1];
      c = vertexIndexBuffer[i * 4 + 2];
      d = vertexIndexBuffer[i * 4 + 3];

      na = normalIndexBuffer[i * 4];
      nb = normalIndexBuffer[i * 4 + 1];
      nc = normalIndexBuffer[i * 4 + 2];
      nd = normalIndexBuffer[i * 4 + 3];

      var nax = normals[na * 3],
          nay = normals[na * 3 + 1],
          naz = normals[na * 3 + 2],
          nbx = normals[nb * 3],
          nby = normals[nb * 3 + 1],
          nbz = normals[nb * 3 + 2],
          ncx = normals[nc * 3],
          ncy = normals[nc * 3 + 1],
          ncz = normals[nc * 3 + 2],
          ndx = normals[nd * 3],
          ndy = normals[nd * 3 + 1],
          ndz = normals[nd * 3 + 2];

      faces.add(new Face3(a, b, d,
          normal: [new Vector3(nax, nay, naz), new Vector3(nbx, nby, nbz), new Vector3(ndx, ndy, ndz)]));

      faces.add(new Face3(b, c, d,
          normal: [new Vector3(nbx, nby, nbz), new Vector3(ncx, ncy, ncz), new Vector3(ndx, ndy, ndz)]));
    }
  }

  _init_triangles_flat(start) {
    var nElements = md['ntri_flat'];

    if (nElements != null) {
      var offsetMaterials = start + nElements * Uint32List.BYTES_PER_ELEMENT * 3;
      _init_faces3_flat(nElements, start, offsetMaterials);
    }
  }

  _init_triangles_flat_uv(start) {
    var nElements = md['ntri_flat_uv'];

    if (nElements != null) {
      var offsetUvs = start + nElements * Uint32List.BYTES_PER_ELEMENT * 3;
      var offsetMaterials = offsetUvs + nElements * Uint32List.BYTES_PER_ELEMENT * 3;

      _init_faces3_flat(nElements, start, offsetMaterials);
      _init_uvs3(nElements, offsetUvs);
    }
  }

  _init_triangles_smooth(start) {
    var nElements = md['ntri_smooth'];

    if (nElements != null) {
      var offsetNormals = start + nElements * Uint32List.BYTES_PER_ELEMENT * 3;
      var offsetMaterials = offsetNormals + nElements * Uint32List.BYTES_PER_ELEMENT * 3;

      _init_faces3_smooth(nElements, start, offsetNormals, offsetMaterials);
    }
  }

  _init_triangles_smooth_uv(start) {
    var nElements = md['ntri_smooth_uv'];

    if (nElements != null) {
      var offsetNormals = start + nElements * Uint32List.BYTES_PER_ELEMENT * 3;
      var offsetUvs = offsetNormals + nElements * Uint32List.BYTES_PER_ELEMENT * 3;
      var offsetMaterials = offsetUvs + nElements * Uint32List.BYTES_PER_ELEMENT * 3;

      _init_faces3_smooth(nElements, start, offsetNormals, offsetMaterials);
      _init_uvs3(nElements, offsetUvs);
    }
  }

  _init_quads_flat(start) {
    var nElements = md['nquad_flat'];

    if (nElements != null) {
      var offsetMaterials = start + nElements * Uint32List.BYTES_PER_ELEMENT * 4;
      _init_faces4_flat(nElements, start, offsetMaterials);
    }
  }

  _init_quads_flat_uv(start) {
    var nElements = md['nquad_flat_uv'];

    if (nElements != null) {
      var offsetUvs = start + nElements * Uint32List.BYTES_PER_ELEMENT * 4;
      var offsetMaterials = offsetUvs + nElements * Uint32List.BYTES_PER_ELEMENT * 4;

      _init_faces4_flat(nElements, start, offsetMaterials);
      _init_uvs4(nElements, offsetUvs);
    }
  }

  _init_quads_smooth(start) {
    var nElements = md['nquad_smooth'];

    if (nElements != null) {
      var offsetNormals = start + nElements * Uint32List.BYTES_PER_ELEMENT * 4;
      var offsetMaterials = offsetNormals + nElements * Uint32List.BYTES_PER_ELEMENT * 4;

      _init_faces4_smooth(nElements, start, offsetNormals, offsetMaterials);
    }
  }

  _init_quads_smooth_uv(start) {
    var nElements = md['nquad_smooth_uv'];

    if (nElements != null) {
      var offsetNormals = start + nElements * Uint32List.BYTES_PER_ELEMENT * 4;
      var offsetUvs = offsetNormals + nElements * Uint32List.BYTES_PER_ELEMENT * 4;
      var offsetMaterials = offsetUvs + nElements * Uint32List.BYTES_PER_ELEMENT * 4;

      _init_faces4_smooth(nElements, start, offsetNormals, offsetMaterials);
      _init_uvs4(nElements, offsetUvs);
    }
  }
}
