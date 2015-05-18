part of three.extras.helpers;

class VertexNormalsHelper extends LineSegments {
  Object3D object;

  double size;

  Matrix3 normalMatrix;

  VertexNormalsHelper(this.object, {this.size: 1.0, hex: 0xff0000, linewidth: 1.0})
      : super(new DynamicGeometry(), new LineBasicMaterial(color: hex, linewidth: linewidth)) {
    var faces = (object as GeometryObject).geometry.faces;

    for (var i = 0; i < faces.length; i++) {
      var face = faces[i];

      for (var j = 0; j < face.vertexNormals.length; j++) {
        geometry.vertices.addAll([new Vector3.zero(), new Vector3.zero()]);
      }
    }

    matrixAutoUpdate = false;
    normalMatrix = new Matrix3.identity();
    update();
  }

  void update() {
    object.updateMatrixWorld(force: true);

    normalMatrix.copyNormalMatrix(this.object.matrixWorld);

    var vertices = geometry.vertices;

    var objectGeo = (object as GeometryObject).geometry;
    var verts = objectGeo.vertices;
    var faces = objectGeo.faces;

    var worldMatrix = object.matrixWorld;

    var idx = 0;

    for (var i = 0; i < faces.length; i++) {
      var face = faces[i];

      for (var j = 0; j < face.vertexNormals.length; j++) {
        var vertexId = face.indices[j];
        var vertex = verts[vertexId];

        var normal = face.vertexNormals[j];

        vertices[idx].setFrom(vertex).applyMatrix4(worldMatrix);

        _v..setFrom(normal)..applyMatrix3(normalMatrix)..normalize()..scale(size);

        _v.add(vertices[idx]);
        idx = idx + 1;

        vertices[idx].setFrom(_v);
        idx = idx + 1;
      }
    }

    (geometry as DynamicGeometry).verticesNeedUpdate = true;
  }


  static final Vector3 _v = new Vector3.zero();
}
