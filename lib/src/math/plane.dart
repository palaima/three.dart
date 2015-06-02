// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of three.math;

class Plane {
  final Vector3 _normal;
  double _constant;

  /// Find the intersection point between the three planes [a], [b] and [c] and
  /// copy it into [result].
  static void intersection(Plane a, Plane b, Plane c, Vector3 result) {
    final cross = new Vector3.zero();

    b.normal.crossInto(c.normal, cross);

    final f = -a.normal.dot(cross);

    final v1 = cross.scaled(a.constant);

    c.normal.crossInto(a.normal, cross);

    final v2 = cross.scaled(b.constant);

    a.normal.crossInto(b.normal, cross);

    final v3 = cross.scaled(c.constant);

    result.x = (v1.x + v2.x + v3.x) / f;
    result.y = (v1.y + v2.y + v3.y) / f;
    result.z = (v1.z + v2.z + v3.z) / f;
  }

  Vector3 get normal => _normal;
  double get constant => _constant;
  set constant(double value) => _constant = value;

  Plane()
      : _normal = new Vector3.zero(),
        _constant = 0.0;

  Plane.copy(Plane other)
      : _normal = new Vector3.copy(other._normal),
        _constant = other._constant;

  Plane.components(double x, double y, double z, double w)
      : _normal = new Vector3(x, y, z),
        _constant = w;

  Plane.normalconstant(Vector3 normal_, double constant_)
      : _normal = new Vector3.copy(normal_),
        _constant = constant_;

  void copyFrom(Plane o) {
    _normal.setFrom(o._normal);
    _constant = o._constant;
  }

  void setFromComponents(double x, double y, double z, double w) {
    _normal.setValues(x, y, z);
    _constant = w;
  }

  void setFromNormalAndCoplanarPoint(Vector3 normal, Vector3 point) {
    this.normal.setFrom(normal);
    this.constant = -point.dot(this.normal);
  }

  void normalize() {
    var inverseLength = 1.0 / normal.length;
    _normal.scale(inverseLength);
    _constant *= inverseLength;
  }

  static final Vector3 _v1 = new Vector3.zero();
  static final Vector3 _v2 = new Vector3.zero();
  static final Matrix3 _m1 = new Matrix3.zero();

  void applyMatrix4(Matrix4 matrix, [Matrix3 optionalNormalMatrix]) {
    // compute new normal based on theory here:
    // http://www.songho.ca/opengl/gl_normaltransform.html
    final normalMatrix = optionalNormalMatrix != null
        ? optionalNormalMatrix
        : _m1..copyNormalMatrix(matrix);
    final newNormal = _v1
      ..setFrom(normal)
      ..applyMatrix3(normalMatrix);
    final newCoplanarPoint = coplanarPoint(_v2)..applyMatrix4(matrix);
    setFromNormalAndCoplanarPoint(newNormal, newCoplanarPoint);
  }

  double distanceToVector3(Vector3 point) {
    return _normal.dot(point) + _constant;
  }

  Vector3 coplanarPoint([Vector3 optionalTarget]) {
    var result = optionalTarget != null ? optionalTarget : new Vector3.zero();
    return result
      ..setFrom(normal)
      ..scale(-constant);
  }
}
