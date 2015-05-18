part of three.core;

/*
 * @author mr.doob / http://mrdoob.com/
 * @author kile / http://kile.stravaganza.org/
 * @author alteredq / http://alteredqualia.com/
 * @author mikael emtinger / http://gomo.se/
 * @author zz85 / http://www.lab4games.net/zz85/blog
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * based on r70
 */

abstract class IGeometry {
  int id;
  String uuid;
  String type;
  List<MorphTarget> morphTargets;
  List<MorphColor> morphColors;
  List<MorphNormal> morphNormals;

  Aabb3 boundingBox;
  Sphere boundingSphere;

  List<Vector3> vertices;
  List<Face3> faces;

  var animations, firstAnimation;

  List skinWeights, skinIndices;

  void applyMatrix(Matrix4 matrix);

  void computeBoundingSphere();
  void computeBoundingBox();

  operator [](String key);
  operator []=(String key, value);

  clone();

  void dispose();
}

/// Base class for geometries.
/// A geometry holds all data necessary to describe a 3D model.
class Geometry implements IGeometry {
  /// Unique number of this object instance.
  int id = GeometryIdCount++;

  String uuid = generateUUID();

  /// Name for this geometry. Default is an empty string.
  String name = '';

  String type = 'Geometry';

  /// List of vertices.
  /// The array of vertices holds every position of points in the model.
  /// To signal an update in this array, [verticesNeedUpdate] needs to be set to true.
  List<Vector3> vertices = [];

  /// List of vertex colors, matching number and order of vertices.
  /// Used in [ParticleSystem] and [Line].
  /// Meshes use per-face-use-of-vertex colors embedded directly in faces.
  /// To signal an update in this array, [colorsNeedUpdate] needs to be set to true.
  List<Color> colors = [];

  /// List of triangles.
  /// The array of faces describe how each vertex in the model is connected with each other.
  /// To signal an update in this array, Geometry.elementsNeedUpdate needs to be set to true.
  List<Face3> faces = [];

  /// List of face UV layers.
  /// Each UV layer is an array of UVs matching the order and number of vertices in faces.
  /// To signal an update in this array, Geometry.uvsNeedUpdate needs to be set to true.
  List<List<List<Vector2>>> faceVertexUvs = [[]];

  /// List of [MorphTarget].
  List<MorphTarget> morphTargets = [];

  /// List of [MorphColor].
  List<MorphColor> morphColors = [];

  /// List of [MorphNormal]
  List<MorphNormal> morphNormals = [];

  /// List of skinning weights, matching number and order of vertices.
  List<Vector4> skinWeights = [];

  /// List of skinning indices, matching number and order of vertices.
  List<Vector4> skinIndices = [];

  /// A list containing distances between vertices for Line geometries.
  /// This is required for LinePieces/LineDashedMaterial to render correctly.
  /// Line distances can also be generated with computeLineDistances.
  List<double> lineDistances = [];

  /// Bounding box.
  Aabb3 boundingBox;

  /// Bounding sphere.
  Sphere boundingSphere;

  /// True if geometry has tangents. Set in Geometry.computeTangents.
  bool hasTangents = false;

  // Backwards compatibility
  var materials = [];
  var faceUvs = [];
  var normals = [];

  // Used in JSONLoader
  var bones, animation, animations, firstAnimation;

  /// Bakes matrix transform directly into vertex coordinates.
  void applyMatrix(Matrix4 matrix) {
    var normalMatrix = matrix.getNormalMatrix();

    vertices.forEach((vertex) => vertex.applyMatrix4(matrix));

    faces.forEach((face) {
      face.normal..applyMatrix3(normalMatrix)..normalize();

      if (!face.vertexNormals.any((e) => e == null)) {
        face.vertexNormals.forEach((vertexNormal) =>
            vertexNormal..applyMatrix3(normalMatrix)..normalize());
      }
    });

    if (boundingBox != null) computeBoundingBox();
    if (boundingSphere != null) computeBoundingSphere();
  }

  Geometry fromBufferGeometry(BufferGeometry geometry) {
    var vertices = geometry.aPosition.array;
    var indices = geometry.aIndex != null ? geometry.aIndex.array : null;
    var normals = geometry.aNormal != null ? geometry.aNormal.array : null;
    var colors = geometry.aColor != null ? geometry.aColor.array : null;
    var uvs = geometry.aUV != null ? geometry.aUV.array : null;

    var tempNormals = [];
    var tempUVs = [];

    for (var i = 0, j = 0; i < vertices.length; i += 3, j += 2) {
      this.vertices.add(new Vector3(vertices[i], vertices[i + 1], vertices[i + 2]));

      if (normals != null) {
        tempNormals.add(new Vector3(normals[i], normals[i + 1], normals[i + 2]));
      }

      if (colors != null) {
        this.colors.add(new Color.fromList(colors));
      }

      if (uvs != null) {
        tempUVs.add(new Vector2(uvs[j], uvs[j + 1]));
      }
    }

    var addFace = (a, b, c) {
      var vertexNormals = normals != null ? [tempNormals[a].clone(), tempNormals[b].clone(), tempNormals[c].clone()] : [];
      var vertexColors = colors != null ? [this.colors[a].clone(), this.colors[b].clone(), this.colors[c].clone()] : [];

      this.faces.add(new Face3(a, b, c, normal: vertexNormals, color: vertexColors));

      if (uvs != null) {
        this.faceVertexUvs[0].add([tempUVs[a].clone(), tempUVs[b].clone(), tempUVs[c].clone()]);
      }
    };

    if (indices != null) {
      for (var i = 0; i < indices.length; i += 3) {
        addFace(indices[i], indices[i + 1], indices[i + 2]);
      }
    } else {
      for (var i = 0; i < vertices.length / 3; i += 3) {
        addFace(i, i + 1, i + 2);
      }
    }

    computeFaceNormals();

    if (geometry.boundingBox != null) {
      boundingBox = geometry.boundingBox.clone();
    }

    if (geometry.boundingSphere != null) {
      boundingSphere = geometry.boundingSphere.clone();
    }

    return this;
  }

  Vector3 center() {
    computeBoundingBox();

    var offset = boundingBox.center..negate();

    applyMatrix(new Matrix4.translation(offset));

    return offset;
  }

  /// Computes face normals.
  void computeFaceNormals() {
    var cb = new Vector3.zero(),
        ab = new Vector3.zero();

    for (var f = 0; f < faces.length; f++) {
      var face = faces[f];

      var vA = vertices[face.a];
      var vB = vertices[face.b];
      var vC = vertices[face.c];

      cb.subVectors(vC, vB);
      ab.subVectors(vA, vB);
      cb.crossVectors(cb, ab);

      cb.normalize();

      face.normal.setFrom(cb);
    }
  }

  /// Computes vertex normals by averaging face normals.
  ///
  /// Face normals must be existing / computed beforehand.
  void computeVertexNormals({bool areaWeighted: false}) {
    var vertices = new List.generate(this.vertices.length, (_) => new Vector3.zero());

    if (areaWeighted) {

      // vertex normals weighted by triangle areas
      // http://www.iquilezles.org/www/articles/normals/normals.htm

      var cb = new Vector3.zero(), ab = new Vector3.zero();

      for (var f = 0; f < faces.length; f++) {
        var face = faces[f];

        var vA = this.vertices[face.a];
        var vB = this.vertices[face.b];
        var vC = this.vertices[face.c];

        cb.subVectors(vC, vB);
        ab.subVectors(vA, vB);
        cb.crossVectors(cb, ab);

        vertices[face.a].add(cb);
        vertices[face.b].add(cb);
        vertices[face.c].add(cb);

      }

    } else {
      for (var f = 0; f < faces.length; f++) {
        var face = faces[f];

        vertices[face.a].add(face.normal);
        vertices[face.b].add(face.normal);
        vertices[face.c].add(face.normal);
      }
    }

    for (var v = 0; v < this.vertices.length; v++) {
      vertices[v].normalize();
    }

    for (var f = 0; f < faces.length; f++) {
      var face = faces[f];

      face.vertexNormals.add(vertices[face.a].clone());
      face.vertexNormals.add(vertices[face.b].clone());
      face.vertexNormals.add(vertices[face.c].clone());
    }
  }

  // TODO implement computeMorphNormals
  void computeMorphNormals() {
    throw new UnimplementedError();
  }

  /// Computes vertex tangents.
  ///
  /// Based on http://www.terathon.com/code/tangent.html
  /// Geometry must have vertex UVs (layer 0 will be used).
  void computeTangents() {
    // based on http://www.terathon.com/code/tangent.html
    // tangents go to vertices

    var uv;

    var tan1 = new List(vertices.length);
    var tan2 = new List(vertices.length);

    var sdir = new Vector3.zero(),
        tdir = new Vector3.zero(),
        tmp = new Vector3.zero(),
        tmp2 = new Vector3.zero(),
        n = new Vector3.zero();

    for (var v = 0; v < vertices.length; v++) {
      tan1[v] = new Vector3.zero();
      tan2[v] = new Vector3.zero();
    }

    handleTriangle(a, b, c, ua, ub, uc) {
      var vA = vertices[a];
      var vB = vertices[b];
      var vC = vertices[c];

      var uvA = uv[ua];
      var uvB = uv[ub];
      var uvC = uv[uc];

      var x1 = vB.x - vA.x;
      var x2 = vC.x - vA.x;
      var y1 = vB.y - vA.y;
      var y2 = vC.y - vA.y;
      var z1 = vB.z - vA.z;
      var z2 = vC.z - vA.z;

      var s1 = uvB.x - uvA.x;
      var s2 = uvC.x - uvA.x;
      var t1 = uvB.y - uvA.y;
      var t2 = uvC.y - uvA.y;

      var r = 1.0 / (s1 * t2 - s2 * t1);
      sdir.setValues((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r);
      tdir.setValues((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r);

      tan1[a].add(sdir);
      tan1[b].add(sdir);
      tan1[c].add(sdir);

      tan2[a].add(tdir);
      tan2[b].add(tdir);
      tan2[c].add(tdir);
    }

    for (var f = 0; f < faces.length; f++) {
      var face = faces[f];
      uv = faceVertexUvs[0][f]; // use UV layer 0 for tangents

      handleTriangle(face.a, face.b, face.c, 0, 1, 2);
    }

    for (var f = 0; f < faces.length; f++) {
      var face = faces[f];

      for (var i = 0; i < math.min(face.vertexNormals.length, 3); i++) {
        n.setFrom(face.vertexNormals[i]);

        var vertexIndex = face.indices[i];

        var t = tan1[vertexIndex];

        // Gram-Schmidt orthogonalize

        tmp.setFrom(t);
        tmp.sub(n.scale(n.dot(t))).normalize();

        // Calculate handedness

        tmp2.crossVectors(face.vertexNormals[i], t);
        var test = tmp2.dot(tan2[vertexIndex]);
        var w = (test < 0.0) ? - 1.0 : 1.0;

        face.vertexTangents[i] = new Vector4(tmp.x, tmp.y, tmp.z, w);
      }
    }


    hasTangents = true;
  }

  /// Compute distances between vertices for Line geometries.
  void computeLineDistances() {
    var d = 0.0;

    for (var i = 0; i < vertices.length; i++) {

      if (i > 0) {
        d += vertices[i].distanceTo(vertices[i - 1]);
      }

      lineDistances[i] = d;
    }
  }

  /// Computes bounding box of the geometry, updating Geometry.boundingBox.
  void computeBoundingBox() {
    if (boundingBox == null) {
      boundingBox = new Aabb3();
    }

    boundingBox.setFromPoints(vertices);
  }

  /// Computes bounding sphere of the geometry, updating Geometry.boundingSphere.
  ///
  /// Neither bounding boxes or bounding spheres are computed by default.
  /// They need to be explicitly computed, otherwise they are null.
  void computeBoundingSphere() {
    if (boundingSphere == null ) {
      boundingSphere = new Sphere();
    }

    boundingSphere.setFromPoints(vertices);
  }

  /// Merge two geometries or geometry and geometry from object (using object's transform).
  void merge(Geometry geometry, {Matrix4 matrix, int materialIndexOffset: 0}) {
    var normalMatrix,
        vertexOffset = this.vertices.length,
        vertices1 = this.vertices,
        vertices2 = geometry.vertices,
        faces1 = this.faces,
        faces2 = geometry.faces,
        uvs1 = this.faceVertexUvs[0],
        uvs2 = geometry.faceVertexUvs[0];

    if (matrix != null) {
      normalMatrix = matrix.getNormalMatrix();
    }

    // vertices

    for (var i = 0; i < vertices2.length; i++) {
      var vertex = vertices2[i];

      var vertexCopy = vertex.clone();

      if (matrix != null) vertexCopy.applyProjection(matrix);

      vertices1.add(vertexCopy);
    }

    // faces

    for (var i = 0; i < faces2.length; i ++) {
      var face = faces2[i],
          faceVertexNormals = face.vertexNormals,
          faceVertexColors = face.vertexColors;

      var faceCopy = new Face3(face.a + vertexOffset, face.b + vertexOffset, face.c + vertexOffset)
        ..normal.setFrom(face.normal);

      if (normalMatrix != null) {
        faceCopy.normal..applyMatrix3(normalMatrix)..normalize();
      }

      for (var j = 0; j < faceVertexNormals.length; j++) {
        var normal = faceVertexNormals[j].clone();

        if (normalMatrix != null) {
          normal..applyMatrix3(normalMatrix)..normalize();
        }

        faceCopy.vertexNormals.add(normal);
      }

      faceCopy.color.setFrom(face.color);

      for (var j = 0; j < faceVertexColors.length; j++) {
        var color = faceVertexColors[j];
        faceCopy.vertexColors.add(color.clone());
      }

      faces1.add(faceCopy);
    }

    // uvs

    for (var i = 0; i < uvs2.length; i ++) {
      var uv = uvs2[i], uvCopy = [];

      if (uv == null) continue;

      for (var j = 0; j < uv.length; j++) {
        uvCopy.add(uv[j].clone());
      }

      uvs1.add(uvCopy);
    }
  }

  void mergeMesh(Mesh mesh) {
    if (mesh.matrixAutoUpdate) mesh.updateMatrix();
    merge(mesh.geometry, matrix: mesh.matrix);
  }

  /// Checks for duplicate vertices with hashmap.
  /// Duplicated vertices are removed and faces' vertices are updated.
  int mergeVertices() {
    var verticesMap = {}; // Hashmap for looking up vertice by position coordinates (and making sure they are unique)
    var unique = [], changes = new List(vertices.length);

    var precisionPoints = 4; // number of decimal points, eg. 4 for epsilon of 0.0001
    var precision = math.pow(10, precisionPoints);

    for (var i = 0; i < vertices.length; i++) {
      var v = this.vertices[i];
      var key = '${(v.x * precision).round()}_${(v.y * precision).round()}_${(v.z * precision).round()}';

      if (verticesMap[key] == null) {
        verticesMap[key] = i;
        unique.add(vertices[i]);
        changes[i] = unique.length - 1;
      } else {
        changes[i] = changes[verticesMap[key]];
      }
    };

    // if faces are completely degenerate after merging vertices, we
    // have to remove them from the geometry.
    var faceIndicesToRemove = [];

    for (var i = 0; i < faces.length; i++) {
      var face = faces[i];

      face.a = changes[face.a];
      face.b = changes[face.b];
      face.c = changes[face.c];

      var indices = [face.a, face.b, face.c];

      // if any duplicate vertices are found in a Face3
      // we have to remove the face as nothing can be saved
      for (var n = 0; n < 3; n ++) {
        if (indices[n] == indices[(n + 1) % 3]) {
          faceIndicesToRemove.add(i);
          break;
        }
      }
    }

    for (var i = faceIndicesToRemove.length - 1; i >= 0; i--) {
      var idx = faceIndicesToRemove[i];

      faces.removeAt(idx);
      faceVertexUvs.forEach((uv) => uv.removeAt(idx));
    }

    // Use unique set of vertices

    var diff = vertices.length - unique.length;
    vertices = unique;
    return diff;
  }

  // TODO implement computeMorphNormals
  toJSON() {
    throw new UnimplementedError();
  }

  /// Creates a new clone of the Geometry.
  Geometry clone() {
    var geometry = new Geometry();

    for (var i = 0; i < vertices.length; i ++) {
      geometry.vertices.add(vertices[i].clone());
    }

    for (var i = 0; i < faces.length; i++) {
      geometry.faces.add(faces[i].clone());
    }

    for (var i = 0; i < this.faceVertexUvs.length; i ++) {
      var faceVertexUvs = this.faceVertexUvs[i];

      if (geometry.faceVertexUvs[i] == null) {
        geometry.faceVertexUvs[i] = [];
      }

      for (var j = 0; j < faceVertexUvs.length; j ++) {
        var uvs = faceVertexUvs[j], uvsCopy = [];

        for (var k = 0; k < uvs.length; k ++) {
          var uv = uvs[k];

          uvsCopy.add(uv.clone());
        }

        geometry.faceVertexUvs[i].add(uvsCopy);
      }
    }

    return geometry;
  }

  Map _data = {};
  operator [](k) => _data[k];
  operator []=(k, v) => _data[k] = v;

  // Used in DynamicGeometry
  int get _maxFaceIndex {
    var maxIndex = 0;
    for (var f = 0; f < faces.length; f++) {
      var max = faces[f].indices.reduce(math.max);
      if (max > maxIndex) maxIndex = max;
    }
    return maxIndex + 1;
  }

  @Deprecated('')
  void computeCentroids() {
    faces.forEach((face) {

      face.centroid.setValues(0.0, 0.0, 0.0);

      face.indices.forEach((idx) {
        face.centroid.add(vertices[idx]);
      });

      face.centroid /= face.indices.length.toDouble();

    });
  }

  StreamController _onDisposeController = new StreamController.broadcast();
  Stream get onDispose => _onDisposeController.stream;

  void dispose() {
    _onDisposeController.add(this);
  }
}

class MorphTarget {
  String name;
  List<Vector3> vertices;
  MorphTarget({this.name, this.vertices});
}

class MorphColor {
  String name;
  List<Color> colors;
  MorphColor({this.name, this.colors});
}

class MorphNormal {
  List faceNormals;
  List vertexNormals;
  MorphNormal({this.faceNormals, this.vertexNormals});
}