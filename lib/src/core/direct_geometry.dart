/*
 * @author mrdoob / http://mrdoob.com/
 *
 * Based on https://github.com/mrdoob/three.js/tree/da8ef6db17c718e5b15eb86a88ba13338c3d61ee/src/core/DirectGeometry.js
 */

part of three.core;

class DirectGeometry implements IGeometry {
  int id = GeometryIdCount++;

  String uuid = generateUUID();

  String name = '';
  String type = 'DynamicGeometry';

  List indices = [];
  List<Vector3> vertices = [];
  List<Color> colors = [];
  List<Vector3> normals = [];
  List<Vector2> uvs = [];
  List uvs2 = [];

  /// List of [MorphTarget].
  List morphTargets = [];

  /// List of [MorphColor].
  List morphColors = [];

  /// List of [MorphNormal]
  List morphNormals = [];

  /// List of skinning weights, matching number and order of vertices.
  List<Vector4> skinWeights = [];

  /// List of skinning indices, matching number and order of vertices.
  List<Vector4> skinIndices = [];

  Aabb3 boundingBox;
  Sphere boundingSphere;

  // update flags

  bool verticesNeedUpdate = false;
  bool normalsNeedUpdate = false;
  bool colorsNeedUpdate = false;
  bool uvsNeedUpdate = false;

  DirectGeometry();

  DirectGeometry.fromGeometry(Geometry geometry) {
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
    warn(
        'DynamicGeometry: computeFaceNormals() is not a method of this type of geometry.');
  }

  void computeVertexNormals() {
    warn(
        'DynamicGeometry: computeVertexNormals() is not a method of this type of geometry.');
  }

  void setFromGeometry(Geometry geometry) {
    var faces = geometry.faces;
    var vertices = geometry.vertices;
    var faceVertexUvs = geometry.faceVertexUvs;

    var hasFaceVertexUv =
        faceVertexUvs.length > 0 && faceVertexUvs[0].length > 0;
    var hasFaceVertexUv2 =
        faceVertexUvs.length > 1 && faceVertexUvs[1].length > 0;

    // morphs

    var morphTargets = geometry.morphTargets;
    var morphTargetsLength = morphTargets.length;

    for (var i = 0; i < morphTargetsLength; i++) {
      this.morphTargets.add([]);
    }

    var morphNormals = geometry.morphNormals;
    var morphNormalsLength = morphNormals.length;

    for (var i = 0; i < morphNormalsLength; i++) {
      this.morphNormals.add([]);
    }

    var morphColors = geometry.morphColors;
    var morphColorsLength = morphColors.length;

    for (var i = 0; i < morphColorsLength; i++) {
      this.morphColors.add([]);
    }

    // skins

    var skinIndices = geometry.skinIndices;
    var skinWeights = geometry.skinWeights;

    var hasSkinIndices = skinIndices.length == vertices.length;
    var hasSkinWeights = skinWeights.length == vertices.length;

    //

    for (var i = 0; i < faces.length; i++) {
      var face = faces[i];

      this.vertices.add(vertices[face.a]);
      this.vertices.add(vertices[face.b]);
      this.vertices.add(vertices[face.c]);

      var vertexNormals = face.vertexNormals;

      if (vertexNormals.length == 3) {
        this.normals.add(vertexNormals[0]);
        this.normals.add(vertexNormals[1]);
        this.normals.add(vertexNormals[2]);
      } else {
        var normal = face.normal;

        this.normals.add(normal);
        this.normals.add(normal);
        this.normals.add(normal);
      }

      var vertexColors = face.vertexColors;

      if (vertexColors.length == 3) {
        colors.add(vertexColors[0]);
        colors.add(vertexColors[1]);
        colors.add(vertexColors[2]);
      } else {
        var color = face.color;

        colors.add(color);
        colors.add(color);
        colors.add(color);
      }

      if (hasFaceVertexUv) {
        var vertexUvs = faceVertexUvs[0][i];

        if (vertexUvs != null) {
          this.uvs.add(vertexUvs[0]);
          this.uvs.add(vertexUvs[1]);
          this.uvs.add(vertexUvs[2]);
        } else {
          warn('BufferGeometry.fromGeometry(): Undefined vertexUv $i');

          this.uvs.add(new Vector2.zero());
          this.uvs.add(new Vector2.zero());
          this.uvs.add(new Vector2.zero());
        }
      }

      if (hasFaceVertexUv2) {
        var vertexUvs = faceVertexUvs[1][i];

        if (vertexUvs != null) {
          this.uvs2.add(vertexUvs[0]);
          this.uvs2.add(vertexUvs[1]);
          this.uvs2.add(vertexUvs[2]);
        } else {
          warn('BufferGeometry.fromGeometry(): Undefined vertexUv2 $i');

          this.uvs2.add(new Vector2.zero());
          this.uvs2.add(new Vector2.zero());
          this.uvs2.add(new Vector2.zero());
        }
      }

      // morphs

      for (var j = 0; j < morphTargetsLength; j++) {
        var morphTarget = morphTargets[j].vertices;

        this.morphTargets[j].add(morphTarget[face.a]);
        this.morphTargets[j].add(morphTarget[face.b]);
        this.morphTargets[j].add(morphTarget[face.c]);
      }
      /*
      for ( var j = 0; j < morphNormalsLength; j ++ ) {

        var morphNormal = morphNormals[ j ].vertexNormals[ i ];

        this.morphNormals[ j ].push( morphNormal.a, morphNormal.b, morphNormal.c );

      }

      for ( var j = 0; j < morphColorsLength; j ++ ) {

        var morphColor = morphColors[ j ].colors;

        this.morphColors[ j ].push( morphColor[ face.a ], morphColor[ face.b ], morphColor[ face.c ] );

      }
      */

      // skins

      if (hasSkinIndices) {
        this.skinIndices.add(skinIndices[face.a]);
        this.skinIndices.add(skinIndices[face.b]);
        this.skinIndices.add(skinIndices[face.c]);
      }

      if (hasSkinWeights) {
        this.skinWeights.add(skinWeights[face.a]);
        this.skinWeights.add(skinWeights[face.b]);
        this.skinWeights.add(skinWeights[face.c]);
      }
    }

    this.verticesNeedUpdate = geometry.verticesNeedUpdate;
    this.normalsNeedUpdate = geometry.normalsNeedUpdate;
    this.colorsNeedUpdate = geometry.colorsNeedUpdate;
    this.uvsNeedUpdate = geometry.uvsNeedUpdate;
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
