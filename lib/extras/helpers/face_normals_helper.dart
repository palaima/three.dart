/*
 * @author mrdoob / http://mrdoob.com/
 * @author WestLangley / http://github.com/WestLangley
 */

part of three.extras.helpers;

class FaceNormalsHelper extends LineSegments {
  Object3D object;

  double size;

  Matrix3 normalMatrix = new Matrix3.identity();

  FaceNormalsHelper(this.object, {this.size: 1.0, hex: 0xffff00, linewidth: 1.0})
      : super(new Geometry(), new LineBasicMaterial(color: hex, linewidth: linewidth)) {
    var faces = (object as GeometryObject).geometry.faces;

    for (var i = 0; i < faces.length; i++) {
      geometry.vertices.addAll([new Vector3.zero(), new Vector3.zero()]);
    }

    matrixAutoUpdate = false;
    update();
  }

  void update() {
    var vertices = geometry.vertices;

    var objectGeo = (object as GeometryObject).geometry;

    var objectVertices = objectGeo.vertices;
    var objectFaces = objectGeo.faces;
    var objectWorldMatrix = object.matrixWorld;

    object.updateMatrixWorld(force: true);

    normalMatrix.copyNormalMatrix(objectWorldMatrix);

    for (var i = 0, i2 = 0; i < objectFaces.length; i++, i2 += 2) {
      var face = objectFaces[i];

      vertices[i2]
        ..setFrom(objectVertices[face.a])
        ..add(objectVertices[face.b])
        ..add(objectVertices[face.c])
        ..scale(1 / 3)
        ..applyMatrix4(objectWorldMatrix);

      vertices[i2 + 1]
        ..setFrom(face.normal)
        ..applyMatrix3(normalMatrix)
        ..normalize()
        ..scale(size)
        ..add(vertices[i2]);
    }

    geometry.verticesNeedUpdate = true;
  }
}
