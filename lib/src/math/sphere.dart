// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of three;

/// Defines a sphere with a [center] and a [radius].
class Sphere {
  final Vector3 _center;
  double _radius;

  /// The [center] of the sphere.
  Vector3 get center => _center;
  /// The [radius] of the sphere.
  double get radius => _radius;
  set radius(double value) => _radius = value;

  /// Create a new, uninitialized sphere.
  Sphere()
      : _center = new Vector3.zero(),
        _radius = 0.0;

  /// Create a sphere as a copy of [other].
  Sphere.copy(Sphere other)
      : _center = new Vector3.copy(other._center),
        _radius = other._radius;

  /// Create a sphere from a [center] and a [radius].
  Sphere.centerRadius(Vector3 center, double radius)
      : _center = new Vector3.copy(center),
        _radius = radius;

  /// Copy the sphere from [other] into [this].
  void copyFrom(Sphere other) {
    _center.setFrom(other._center);
    _radius = other._radius;
  }

  /// Return if [this] contains [other].
  bool containsVector3(Vector3 other) {
    return other.distanceToSquared(center) < radius * radius;
  }

  /// Return if [this] intersects with [other].
  bool intersectsWithVector3(Vector3 other) {
    return other.distanceToSquared(center) <= radius * radius;
  }

  /// Return if [this] intersects with [other].
  bool intersectsWithSphere(Sphere other) {
    var radiusSum = radius + other.radius;

    return other.center.distanceToSquared(center) <= (radiusSum * radiusSum);
  }

  /*
   * Additions from three.js
   */

  factory Sphere.fromPoints(List<Vector3> points) =>
      new Sphere()..setFromPoints(points);

  Sphere applyMatrix4(Matrix4 matrix) {
    center.applyMatrix4(matrix);
    radius *= matrix.getMaxScaleOnAxis();
    return this;
  }

  Sphere setFromPoints(List<Vector3> points) {
    center.setFrom(new Aabb3.fromPoints( points ).center);

    var maxRadiusSq = 0;

    points.forEach((point) {
      maxRadiusSq = math.max( maxRadiusSq, center.distanceToSquared( point) );
    });

    radius = math.sqrt(maxRadiusSq);

    return this;
  }

  Sphere clone() => new Sphere.copy(this);
}
