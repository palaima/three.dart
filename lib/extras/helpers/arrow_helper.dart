/*
 * @author WestLangley / http://github.com/WestLangley
 * @author zz85 / http://github.com/zz85
 * @author bhouston / http://exocortex.com
 *
 *  based on r64
 */

part of three.extras.helpers;

/// Creates an arrow for visualizing directions
class ArrowHelper extends Object3D {
  Vector3 position;

  Line line;
  Mesh cone;

  ArrowHelper(Vector3 direction, Vector3 origin, [double length = 1.0, int hex = 0xffff00,
              double headLength,  double headWidth]) {
    if (headLength == null) headLength = 0.2 * length;
    if (headWidth == null) headWidth = 0.2 * headLength;

    position = origin;

    var lineGeometry = new Geometry()
      ..vertices.addAll([new Vector3.zero(), new Vector3(0.0, 1.0, 0.0)]);

    line = new Line(lineGeometry, new LineBasicMaterial(color: hex))
        ..matrixAutoUpdate = false;
    add(line);

    var coneGeometry = new CylinderGeometry(0.0, 0.5, 1.0, 5, 1)
        ..applyMatrix(new Matrix4.translation(new Vector3(0.0, -0.5, 0.0)));

    cone = new Mesh(coneGeometry, new MeshBasicMaterial(color: hex))
      ..matrixAutoUpdate = false;
    add(cone);

    setDirection(direction);
    setLength(length, headLength, headWidth );
  }

  void setDirection(Vector3 direction) {
    if (direction.y > 0.99999) {
      quaternion = new Quaternion(0.0, 0.0, 0.0, 1.0);
    } else if (direction.y < -0.99999) {
      quaternion = new Quaternion(1.0, 0.0, 0.0, 0.0);
    } else {
      var axis = new Vector3(direction.z, 0.0, -direction.x).normalize();
      var radians = math.acos(direction.y);
      quaternion.setAxisAngle(axis, radians);
    }
  }

  void setLength(double length, [double headLength, double headWidth]) {
    if (headLength == null) headLength = 0.2 * length;
    if (headWidth == null) headWidth = 0.2 * headLength;

    line.scale.setValues(1.0, length, 1.0);
    line.updateMatrix();

    cone.scale.setValues(headWidth, headLength, headWidth);
    cone.position.y = length;
    cone.updateMatrix();
  }

  void setColor(int hex) {
    line.material.color.setHex(hex);
    cone.material.color.setHex(hex);
  }
}