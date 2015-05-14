part of three.extras.core;

class QuadraticBezierCurve3 extends Curve3D {
  Vector3 v0, v1, v2;
  QuadraticBezierCurve3(this.v0, this.v1, this.v2) : super();

  Vector3 getPoint(t) {

    var tx, ty, tz;

    tx = shape_utils.b2(t, v0.x, v1.x, v2.x);
    ty = shape_utils.b2(t, v0.y, v1.y, v2.y);
    tz = shape_utils.b2(t, v0.z, v1.z, v2.z);

    return new Vector3(tx, ty, tz);

  }
}
