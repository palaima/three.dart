/*
 * @author mrdoob / http://mrdoob.com/
 */

part of three;

class DynamicGeometry extends Object with DisposeStream implements IGeometry {
  int id = GeometryIdCount++;

  String uuid = ThreeMath.generateUUID();

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

  DynamicGeometry();

  DynamicGeometry.fromGeometry(Geometry geometry) {
    setFromGeometry(geometry);
  }

  /// Computes bounding box of the geometry, updating Geometry.boundingBox.
  void computeBoundingBox() {
    if (boundingBox == null) {
      boundingBox = new Aabb3.fromPoints(vertices);
    }
  }

  /// Computes bounding sphere of the geometry, updating Geometry.boundingSphere.
  ///
  /// Neither bounding boxes or bounding spheres are computed by default.
  /// They need to be explicitly computed, otherwise they are null.
  void computeBoundingSphere() {
    num radiusSq;

    var maxRadiusSq = vertices.fold(0, (num curMaxRadiusSq, Vector3 vertex) {
      radiusSq = vertex.length2;
      return (radiusSq > curMaxRadiusSq) ? radiusSq : curMaxRadiusSq;
    });

    boundingSphere = new Sphere.centerRadius(new Vector3.zero(), Math.sqrt(maxRadiusSq));
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
      var vertexUvs = faceVertexUvs[i];

      for (var j = 0; j < vertexNormals.length; j++) {
        normals[indices[j]] = vertexNormals[j];
      }

      for (var j = 0; j < vertexColors.length; j++) {
        colors[indices[j]] = vertexColors[j];
      }

      for (var j = 0; j < vertexUvs.length; j++) {
        uvs[indices[j]] = vertexUvs[j];
      }
    }

    if (colors.any((e) => e == null)) colors.length = 0;
  }

  void dispose() {
    _onDisposeController.add(null);
  }
}
