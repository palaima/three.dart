/*
 * @author zz85 https://github.com/zz85
 *
 * Centripetal CatmullRom Curve - which is useful for avoiding
 * cusps and self-intersections in non-uniform catmull rom curves.
 * http://www.cemyuksel.com/research/catmullrom_param/catmullrom.pdf
 *
 * curve.type accepts centripetal(default), chordal and catmullrom
 * curve.tension is used for catmullrom which defaults to 0.5
 */

part of three.extras.curves;

enum CurveType { CENTRIPETAL, CHORDAL, CATMULLROM }

class CatmullRomCurve3 extends Curve {
  Vector3 _tmp = new Vector3.zero();

  CubicPoly _px = new CubicPoly();
  CubicPoly _py = new CubicPoly();
  CubicPoly _pz = new CubicPoly();

  List<Vector3> points;

  double tension;

  CurveType type;

  CatmullRomCurve3([List<Vector3> points, this.type = CurveType.CENTRIPETAL, this.tension = 0.5])
      : this.points = points != null ? points : [];

  Vector3 getPoint(double t) {
    var l = points.length;

    if (l < 2) print('duh, you need at least 2 points');

    var point = (l - 1) * t;
    var intPoint = point.floor();
    var weight = (point - intPoint).toDouble();

    if (weight == 0.0 && intPoint == l - 1) {
      intPoint = l - 2;
      weight = 1.0;
    }

    Vector3 p0, p1, p2, p3;

    if (intPoint == 0) {
      // extrapolate first point
      _tmp.subVectors(points[0], points[1]).add(points[0]);
      p0 = _tmp;
    } else {
      p0 = points[intPoint - 1];
    }

    p1 = points[intPoint];
    p2 = points[intPoint + 1];

    if (intPoint + 2 < l) {
      p3 = points[intPoint + 2];
    } else {

      // extrapolate last point
      _tmp.subVectors(points[l - 1], points[l - 2]).add(points[l - 2]);
      p3 = _tmp;
    }

    if (type == CurveType.CENTRIPETAL || type == CurveType.CHORDAL) {

      // init Centripetal / Chordal Catmull-Rom
      var pow = this.type == CurveType.CHORDAL ? 0.5 : 0.25;
      var dt0 = math.pow(p0.distanceToSquared(p1), pow);
      var dt1 = math.pow(p1.distanceToSquared(p2), pow);
      var dt2 = math.pow(p2.distanceToSquared(p3), pow);

      // safety check for repeated points
      if (dt1 < 1e-4) dt1 = 1.0;
      if (dt0 < 1e-4) dt0 = dt1;
      if (dt2 < 1e-4) dt2 = dt1;

      _px.initNonuniformCatmullRom(p0.x, p1.x, p2.x, p3.x, dt0, dt1, dt2);
      _py.initNonuniformCatmullRom(p0.y, p1.y, p2.y, p3.y, dt0, dt1, dt2);
      _pz.initNonuniformCatmullRom(p0.z, p1.z, p2.z, p3.z, dt0, dt1, dt2);
    } else if (type == CurveType.CATMULLROM) {
      _px.initCatmullRom(p0.x, p1.x, p2.x, p3.x, tension);
      _py.initCatmullRom(p0.y, p1.y, p2.y, p3.y, tension);
      _pz.initCatmullRom(p0.z, p1.z, p2.z, p3.z, tension);
    }

    var v = new Vector3(_px.calc(weight), _py.calc(weight), _pz.calc(weight));

    return v;
  }
}

/// Based on an optimized c++ solution in
///   - http://stackoverflow.com/questions/9489736/catmull-rom-curve-with-no-cusps-and-no-self-intersections/
///   - http://ideone.com/NoEbVM
///  This CubicPoly class could be used for reusing some variables and calculations,
///  but for three.js curve use, it could be possible inlined and flatten into a single function call
///  which can be placed in CurveUtils.
class CubicPoly {
  double c0, c1, c2, c3;

  /*
   * Compute coefficients for a cubic polynomial
   *   p(s) = c0 + c1*s + c2*s^2 + c3*s^3
   * such that
   *   p(0) = x0, p(1) = x1
   *  and
   *   p'(0) = t0, p'(1) = t1.
   */
  void init(double x0, double x1, double t0, double t1) {
    this.c0 = x0;
    this.c1 = t0;
    this.c2 = -3 * x0 + 3 * x1 - 2 * t0 - t1;
    this.c3 = 2 * x0 - 2 * x1 + t0 + t1;
  }

  void initNonuniformCatmullRom(
      double x0, double x1, double x2, double x3, double dt0, double dt1, double dt2) {
    // compute tangents when parameterized in [t1,t2]
    var t1 = (x1 - x0) / dt0 - (x2 - x0) / (dt0 + dt1) + (x2 - x1) / dt1;
    var t2 = (x2 - x1) / dt1 - (x3 - x1) / (dt1 + dt2) + (x3 - x2) / dt2;

    // rescale tangents for parametrization in [0,1]
    t1 *= dt1;
    t2 *= dt1;

    // initCubicPoly
    init(x1, x2, t1, t2);
  }

  // standard Catmull-Rom spline: interpolate between x1 and x2 with previous/following points x1/x4
  void initCatmullRom(double x0, double x1, double x2, double x3, double tension) {
    init(x1, x2, tension * (x2 - x0), tension * (x3 - x1));
  }

  double calc(double t) {
    var t2 = t * t;
    var t3 = t2 * t;
    return c0 + c1 * t + c2 * t2 + c3 * t3;
  }
}
