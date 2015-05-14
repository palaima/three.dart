/*
 * @author timothypratley / https://github.com/timothypratley
 *
 * based on r71
 */

part of three.extras.geometries;

class OctahedronGeometry extends PolyhedronGeometry {
  factory OctahedronGeometry(double radius, int detail) {
    var vertices = [1, 0, 0, -1, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 1, 0, 0, -1];

    var faces = [0, 2, 4, 0, 4, 3, 0, 3, 5, 0, 5, 2, 1, 2, 5, 1, 5, 3, 1, 3, 4, 1, 4, 2];

    return new OctahedronGeometry._internal(vertices, faces, radius, detail);
  }

  OctahedronGeometry._internal(List<int> vertices, List<int> faces, double radius, int details)
      : super(vertices, faces, radius, details);
}
