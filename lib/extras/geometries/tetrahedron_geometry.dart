/*
 * @author timothypratley / https://github.com/timothypratley
 *
 * based on r71
 */

part of three.extras.geometries;

class TetrahedronGeometry extends PolyhedronGeometry {
  factory TetrahedronGeometry(double radius, int detail) {
    var vertices = [1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1];

    var faces = [2, 1, 0, 0, 3, 2, 1, 3, 0, 2, 3, 1];

    return new TetrahedronGeometry._internal(vertices, faces, radius, detail);
  }

  TetrahedronGeometry._internal(List<int> vertices, List<int> faces, double radius, int details)
      : super(vertices, faces, radius, details);

}
