library three.extras.curve_extras;

import 'dart:math' as math;
import 'package:three/three.dart' show Curve3D, Vector3;

class GrannyKnot extends Curve3D {
  Vector3 getPoint(double t) {
    t = 2 * math.PI * t;

    var x = -0.22 * math.cos(t) - 1.28 * math.sin(t) - 0.44 * math.cos(3 * t) - 0.78 * math.sin(3 * t);
    var y = -0.1 * math.cos(2 * t) - 0.27 * math.sin(2 * t) + 0.38 * math.cos(4 * t) + 0.46 * math.sin(4 * t);
    var z = 0.7 * math.cos(3 * t) - 0.4 * math.sin(3 * t);

    return new Vector3(x, y, z)..scale(20.0);
  }
}

class HeartCurve extends Curve3D {
  double scale;

  HeartCurve([this.scale = 5.0]);

  Vector3 getPoint(double t) {
    t *= 2 * math.PI;

    var tx = 16 * math.pow(math.sin(t), 3);
    var ty = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t);

    return new Vector3(tx, ty, 0.0)..scale(scale);
  }
}

class VivianiCurve extends Curve3D {
  double radius;

  VivianiCurve(this.radius);

  Vector3 getPoint(double t) {
    t = t * 4 * math.PI; // Normalized to 0..1
    var a = radius / 2;
    var tx = a * (1 + math.cos(t)),
        ty = a * math.sin(t),
        tz = 2 * a * math.sin(t / 2);

    return new Vector3(tx, ty, tz);
  }
}

class KnotCurve extends Curve3D {
  Vector3 getPoint(double t) {
    t *= 2 * math.PI;

    var R = 10;
    var s = 50;
    var tx = s * math.sin(t),
        ty = math.cos(t) * (R + s * math.cos(t)),
        tz = math.sin(t) * (R + s * math.cos(t));

    return new Vector3(tx, ty, tz);
  }
}

class HelixCurve extends Curve3D {
  Vector3 getPoint(double t) {
    var radius = 30;
    var height = 150;
    var t2 = 2 * math.PI * t * height / 30;
    var tx = math.cos(t2) * radius,
        ty = math.sin(t2) * radius,
        tz = height * t;

    return new Vector3(tx, ty, tz);
  }
}

class TrefoilKnot extends Curve3D {
  double scale;

  TrefoilKnot([this.scale = 10.0]);

  Vector3 getPoint(double t) {
    t *= math.PI * 2;
    var tx = (2 + math.cos(3 * t)) * math.cos(2 * t),
        ty = (2 + math.cos(3 * t)) * math.sin(2 * t),
        tz = math.sin(3 * t);

    return new Vector3(tx, ty, tz)..scale(scale);
  }
}

class TorusKnot extends Curve3D {
  double scale;

  TorusKnot([this.scale = 10.0]);

  Vector3 getPoint(double t) {
    var p = 3, q = 4;
    t *= math.PI * 2;
    var tx = (2 + math.cos(q * t)) * math.cos(p * t),
        ty = (2 + math.cos(q * t)) * math.sin(p * t),
        tz = math.sin(q * t);

    return new Vector3(tx, ty, tz)..scale(scale);
  }
}

class CinquefoilKnot extends Curve3D {
  double scale;

  CinquefoilKnot([this.scale = 10.0]);

  Vector3 getPoint(double t) {
    var p = 2, q = 5;
    t *= math.PI * 2;
    var tx = (2 + math.cos(q * t)) * math.cos(p * t),
        ty = (2 + math.cos(q * t)) * math.sin(p * t),
        tz = math.sin(q * t);

    return new Vector3(tx, ty, tz)..scale(scale);
  }
}

class TrefoilPolynomialKnot extends Curve3D {
  double scale;

  TrefoilPolynomialKnot([this.scale = 10.0]);

  Vector3 getPoint(double t) {
    t = t * 4 - 2;
    var tx = math.pow(t, 3) - 3 * t,
        ty = math.pow(t, 4) - 4 * t * t,
        tz = 1 / 5 * math.pow(t, 5) - 2 * t;

    return new Vector3(tx, ty, tz)..scale(scale);
  }
}

class FigureEightPolynomialKnot extends Curve3D {
  double scale;

  FigureEightPolynomialKnot([this.scale = 1.0]);

  Vector3 getPoint(double t) {
    var scaleTo = (x, y, t) => t * (y - x) * x;
    t = scaleTo(-4.0, 4.0, t);
    var tx = 2 / 5 * t * (t * t - 7) * (t * t - 10),
        ty = math.pow(t, 4) - 13 * t * t,
        tz = 1 / 10 * t * (t * t - 4) * (t * t - 9) * (t * t - 12);

    return new Vector3(tx, ty, tz)..scale(scale);
  }
}

class DecoratedTorusKnot4a extends Curve3D {
  double scale;

  DecoratedTorusKnot4a([this.scale = 40.0]);

  Vector3 getPoint(double t) {
    t *= math.PI * 2;
    var x = math.cos(2 * t) * (1 + 0.6 * (math.cos(5 * t) + 0.75 * math.cos(10 * t))),
        y = math.sin(2 * t) * (1 + 0.6 * (math.cos(5 * t) + 0.75 * math.cos(10 * t))),
        z = 0.35 * math.sin(5 * t);

    return new Vector3(x, y, z)..scale(scale);
  }
}

class DecoratedTorusKnot4b extends Curve3D {
  double scale;

  DecoratedTorusKnot4b([this.scale = 40.0]);

  Vector3 getPoint(double t) {
    var fi = t * math.PI * 2;
    var x = math.cos(2 * fi) * (1 + 0.45 * math.cos(3 * fi) + 0.4 * math.cos(9 * fi)),
        y = math.sin(2 * fi) * (1 + 0.45 * math.cos(3 * fi) + 0.4 * math.cos(9 * fi)),
        z = 0.2 * math.sin(9 * fi);

    return new Vector3(x, y, z).scale(scale);
  }
}

class DecoratedTorusKnot5a extends Curve3D {
  double scale;

  DecoratedTorusKnot5a([this.scale = 40.0]);

  Vector3 getPoint(double t) {
    var fi = t * math.PI * 2;
    var x = math.cos(3 * fi) * (1 + 0.3 * math.cos(5 * fi) + 0.5 * math.cos(10 * fi)),
        y = math.sin(3 * fi) * (1 + 0.3 * math.cos(5 * fi) + 0.5 * math.cos(10 * fi)),
        z = 0.2 * math.sin(20 * fi);

    return new Vector3(x, y, z)..scale(scale);
  }
}

class DecoratedTorusKnot5c extends Curve3D {
  double scale;

  DecoratedTorusKnot5c([this.scale = 40.0]);

  Vector3 getPoint(double t) {
    var fi = t * math.PI * 2;
    var x = math.cos(4 * fi) * (1 + 0.5 * (math.cos(5 * fi) + 0.4 * math.cos(20 * fi))),
        y = math.sin(4 * fi) * (1 + 0.5 * (math.cos(5 * fi) + 0.4 * math.cos(20 * fi))),
        z = 0.35 * math.sin(15 * fi);

    return new Vector3(x, y, z)..scale(scale);
  }
}


