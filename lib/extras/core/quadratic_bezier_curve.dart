part of three.extras.core;

class QuadraticBezierCurve extends Curve2D {

  Vector2 v0, v1, v2;

  QuadraticBezierCurve(this.v0, this.v1, this.v2);

  getPoint(t) {

    var tx, ty;

    tx = shape_utils.b2(t, v0.x, v1.x, v2.x);
    ty = shape_utils.b2(t, v0.y, v1.y, v2.y);

    return new Vector2(tx, ty);
  }


  getTangent(t) {

    var tx, ty;

    tx = curve_utils.tangentQuadraticBezier(t, v0.x, v1.x, v2.x);
    ty = curve_utils.tangentQuadraticBezier(t, v0.y, v1.y, v2.y);

    // returns unit vector
    return new Vector2(tx, ty).normalize();
  }
}
