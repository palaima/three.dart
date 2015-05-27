/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on https://github.com/mrdoob/three.js/blob/9c2a88d21713eaddd73bfc5b9b00847cf8059225/src/core/DirectGeometry.js
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

  DirectGeometry.fromGeometry(Geometry geometry, Material material) {
    setFromGeometry(geometry, material);
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

  void setFromGeometry(Geometry geometry, [Material material]) {
    var faces = geometry.faces;
    var vertices = geometry.vertices;
    var faceVertexUvs = geometry.faceVertexUvs;
    var materialVertexColors =
        material != null ? material.vertexColors : NoColors;

    var hasFaceVertexUv = faceVertexUvs.length > 0 && faceVertexUvs[0].length > 0;
    var hasFaceVertexUv2 = faceVertexUvs.length > 1 && faceVertexUvs[1].length > 0;

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

      this.vertices
          .addAll([vertices[face.a], vertices[face.b], vertices[face.c]]);

      var vertexNormals = face.vertexNormals;

      if (vertexNormals.length == 3) {
        this.normals
            .addAll([vertexNormals[0], vertexNormals[1], vertexNormals[2]]);
      } else {
        var normal = face.normal;

        this.normals.addAll([normal, normal, normal]);
      }

      var vertexColors = face.vertexColors;

      if (materialVertexColors == VertexColors) {
        this.colors.addAll([vertexColors[0], vertexColors[1], vertexColors[2]]);
      } else if (materialVertexColors == FaceColors) {
        var color = face.color;

        this.colors.addAll([color, color, color]);
      }

      if (hasFaceVertexUv) {
        var vertexUvs = faceVertexUvs[0][i];

        if (vertexUvs != null) {
          this.uvs.addAll([vertexUvs[0], vertexUvs[1], vertexUvs[2]]);
        } else {
          warn('BufferGeometry.fromGeometry(): Undefined vertexUv $i');

          this.uvs.addAll(
              [new Vector2.zero(), new Vector2.zero(), new Vector2.zero()]);
        }
      }

      if (hasFaceVertexUv2) {
        var vertexUvs = faceVertexUvs[1][i];

        if (vertexUvs != null) {
          this.uvs2.addAll([vertexUvs[0], vertexUvs[1], vertexUvs[2]]);
        } else {
          warn('BufferGeometry.fromGeometry(): Undefined vertexUv2 $i');

          this.uvs2.addAll(
              [new Vector2.zero(), new Vector2.zero(), new Vector2.zero()]);
        }
      }

      // morphs

      for (var j = 0; j < morphTargetsLength; j++) {
        var morphTarget = morphTargets[j].vertices;

        this.morphTargets[j].addAll(
            [morphTarget[face.a], morphTarget[face.b], morphTarget[face.c]]);
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
        this.skinIndices.addAll(
            [skinIndices[face.a], skinIndices[face.b], skinIndices[face.c]]);
      }

      if (hasSkinWeights) {
        this.skinWeights.addAll([
            skinWeights[face.a], skinWeights[face.b], skinWeights[face.c]]);
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
