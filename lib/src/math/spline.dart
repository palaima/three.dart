/*
 * Spline from Tween.js, slightly optimized (and trashed)
 * http://sole.github.com/tween.js/examples/05_spline.html
 *
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 */

part of three.math;

class Spline {
  List<Vector3> points;

  List _c = new List(4);
  Vector3 _v3 = new Vector3.zero();

  Spline(this.points);

  Spline.fromArray(List<List<double>> array) : points = [] {
    for (var i = 0; i < array.length; i++) {
      points[i] = new Vector3.array(array[i]);
    }
  }

  Vector3 getPoint(double k) {
    var point = (points.length - 1) * k;
    var intPoint = point.floor();
    var weight = point - intPoint;

    _c[0] = intPoint == 0 ? intPoint : intPoint - 1;
    _c[1] = intPoint;
    _c[2] = intPoint > points.length - 2 ? points.length - 1 : intPoint + 1;
    _c[3] = intPoint > points.length - 3 ? points.length - 1 : intPoint + 2;

    var pa = points[_c[0]];
    var pb = points[_c[1]];
    var pc = points[_c[2]];
    var pd = points[_c[3]];

    var w2 = weight * weight;
    var w3 = weight * w2;

    _v3.x = interpolate(pa.x, pb.x, pc.x, pd.x, weight, w2, w3);
    _v3.y = interpolate(pa.y, pb.y, pc.y, pd.y, weight, w2, w3);
    _v3.z = interpolate(pa.z, pb.z, pc.z, pd.z, weight, w2, w3);

    return _v3;
  }

  List<List<double>> getControlPointsArray() =>
      new List.generate(points.length, (i) => [points[i].x, points[i].y, points[i].z]);

  // approximate length by summing linear segments

  Map getLength([int nSubDivisions = 100]) {
    var oldIntPoint = 0,
        chunkLengths = [],
        totalLength = 0;

    // first point has 0 length

    chunkLengths[0] = 0;

    var nSamples = points.length * nSubDivisions;

    var oldPosition = new Vector3.copy(points[0]);

    for (var i = 1; i < nSamples; i++) {
      var index = i / nSamples;

      var position = getPoint(index);

      totalLength += position.distanceTo(oldPosition);

      oldPosition.setFrom(position);

      var point = (points.length - 1) * index;
      var intPoint = point.floor();

      if (intPoint != oldIntPoint) {
        chunkLengths[intPoint] = totalLength;
        oldIntPoint = intPoint;
      }
    }

    // last point ends with total length

    chunkLengths[chunkLengths.length] = totalLength;

    return {'chunks': chunkLengths, 'total': totalLength};
  }

  void reparametrizeByArcLength(double samplingCoef) {
    var newpoints = [],
        sl = getLength();

    newpoints.add(points[0].clone());

    for (var i = 1; i < points.length; i++) {
      var realDistance = sl['chunks'][i] - sl['chunks'][i - 1];

      var sampling = (samplingCoef * realDistance / sl['total']).ceil();

      var indexCurrent = (i - 1) / (points.length - 1);
      var indexNext = i / (points.length - 1);

      for (var j = 1; j < sampling - 1; j++) {
        var index = indexCurrent + j * (1 / sampling) * (indexNext - indexCurrent);

        var position = getPoint(index);
        newpoints.add(position.clone());
      }

      newpoints.add(points[i].clone());
    }

    points = newpoints;
  }

  // Catmull-Rom

  double interpolate(double p0, double p1, double p2, double p3, double t, double t2, double t3) {
    var v0 = (p2 - p0) * 0.5,
        v1 = (p3 - p1) * 0.5;
    return (2 * (p1 - p2) + v0 + v1) * t3 + (-3 * (p1 - p2) - 2 * v0 - v1) * t2 + v0 * t + p1;
  }
}
