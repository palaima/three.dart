part of three.extras.core;

class ArcCurve extends Curve2D {

  num aX, aY, aRadius, aStartAngle, aEndAngle;
  bool aClockwise;

  ArcCurve(this.aX, this.aY, this.aRadius, this.aStartAngle, this.aEndAngle, this.aClockwise) : super();

  getPoint(t) {

    var deltaAngle = aEndAngle - aStartAngle;

    if (!aClockwise) {
      t = 1 - t;
    }

    var angle = aStartAngle + t * deltaAngle;

    var tx = aX + aRadius * math.cos(angle);
    var ty = aY + aRadius * math.sin(angle);

    return new Vector2(tx, ty);
  }

}
