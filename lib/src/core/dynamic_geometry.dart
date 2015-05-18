/*
 * @author mrdoob / http://mrdoob.com/
 */

part of three.core;

class DynamicGeometry implements IGeometry {
  int id = GeometryIdCount++;

  String uuid = generateUUID();

  String name = '';
  String type = 'DynamicGeometry';

  List<Vector3> vertices = [];
  List<Vector3> colors = [];
  List<Vector3> normals = [];
  List<Vector2> uvs = [];
  List<Face3> faces = [];

  /*
  List morphTargets = [];
  List morphColors = [];
  List morphNormals = [];
  List skinWeights = [];
  List skinIndices = [];
  List lineDistances = [];
  */

  Aabb3 boundingBox;
  Sphere boundingSphere;

  // update flags

  bool verticesNeedUpdate = false;
  bool normalsNeedUpdate = false;
  bool colorsNeedUpdate = false;
  bool uvsNeedUpdate = false;

  /// List of [MorphTarget].
  List<MorphTarget> morphTargets;

  /// List of [MorphColor].
  List<MorphColor> morphColors;

  /// List of [MorphNormal]
  List<MorphNormal> morphNormals;

  /// List of skinning weights, matching number and order of vertices.
  List<Vector4> skinWeights;

  /// List of skinning indices, matching number and order of vertices.
  List<Vector4> skinIndices;

  DynamicGeometry();

  DynamicGeometry.fromGeometry(Geometry geometry) {
    setFromGeometry(geometry);
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
    if (boundingSphere == null) {
      boundingSphere = new Sphere();
    }

    boundingSphere.setFromPoints(vertices);
  }

  void computeFaceNormals() {
    warn('DynamicGeometry: computeFaceNormals() is not a method of this type of geometry.');
  }

  void computeVertexNormals() {
    warn('DynamicGeometry: computeVertexNormals() is not a method of this type of geometry.');
  }

  void setFromGeometry(Geometry geometry) {
    this.vertices = geometry.vertices;
    this.faces = geometry.faces;

    var faces = geometry.faces;
    var faceVertexUvs = geometry.faceVertexUvs[0];

    normals.length = colors.length = uvs.length = geometry._maxFaceIndex;

    for (var i = 0; i < faces.length; i++) {
      var face = faces[i];
      var indices = [face.a, face.b, face.c];

      var vertexNormals = face.vertexNormals;
      var vertexColors = face.vertexColors;
      var vertexUvs;

      for (var j = 0; j < vertexNormals.length; j++) {
        normals[indices[j]] = vertexNormals[j];
      }

      for (var j = 0; j < vertexColors.length; j++) {
        colors[indices[j]] = vertexColors[j];
      }

      if (faceVertexUvs.length > i) {
        vertexUvs = faceVertexUvs[i];
      } else {
        vertexUvs = [new Vector2.zero(), new Vector2.zero(), new Vector2.zero()];
      }

      for (var j = 0; j < vertexUvs.length; j++) {
        uvs[indices[j]] = vertexUvs[j];
      }
    }

    if (colors.any((e) => e == null)) colors.length = 0;
  }

  StreamController _onDisposeController = new StreamController.broadcast();
  Stream get onDispose => _onDisposeController.stream;

  void dispose() {
    _onDisposeController.add(null);
  }

  noSuchMethod(Invocation invocation) {
    print("'${invocation.memberName}' not available in DynamicGeometry");
  }

  Map _data = {};
  operator [](k) => _data[k];
  operator []=(k, v) => _data[k] = v;
}
