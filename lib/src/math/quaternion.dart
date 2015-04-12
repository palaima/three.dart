// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of three;

/// Defines a [Quaternion] (a four-dimensional vector) for efficient rotation
/// calculations.
///
/// Quaternion are better for interpolating between rotations and avoid the
/// [gimbal lock](http://de.wikipedia.org/wiki/Gimbal_Lock) problem compared to
/// euler rotations.
class Quaternion {
  final Float32List _storage;

  /// Access the internal [storage] of the quaternions components.
  Float32List get storage => _storage;

  /// Access the [x] component of the quaternion.
  double get x => _storage[0];
  set x(double x) {
    _storage[0] = x;
    _onChangeController.add(null);
  }
  /// Access the [y] component of the quaternion.
  double get y => _storage[1];
  set y(double y) {
    _storage[1] = y;
    _onChangeController.add(null);
  }
  /// Access the [z] component of the quaternion.
  double get z => _storage[2];
  set z(double z) {
    _storage[2] = z;
    _onChangeController.add(null);
  }
  /// Access the [w] component of the quaternion.
  double get w => _storage[3];
  set w(double w) {
    _storage[3] = w;
    _onChangeController.add(null);
  }

  Quaternion._() : _storage = new Float32List(4);

  /// Constructs a quaternion using the raw values [x], [y], [z], and [w].
  factory Quaternion(double x, double y, double z, double w) =>
      new Quaternion._()..setValues(x, y, z, w);

  /// Constructs a quaternion from a rotation matrix [rotationMatrix].
  factory Quaternion.fromRotation(Matrix3 rotationMatrix) =>
      new Quaternion._()..setFromRotation(rotationMatrix);

  /// Constructs a quaternion from a rotation of [angle] around [axis].
  factory Quaternion.axisAngle(Vector3 axis, double angle) =>
      new Quaternion._()..setAxisAngle(axis, angle);

  /// Constructs a quaternion as a copy of [original].
  factory Quaternion.copy(Quaternion original) =>
      new Quaternion._()..setFrom(original);

  /// Constructs a quaternion with a random rotation. The random number
  /// generator [rn] is used to generate the random numbers for the rotation.
  factory Quaternion.random(Math.Random rn) =>
      new Quaternion._()..setRandom(rn);

  /// Constructs a quaternion set to the identity quaternion.
  factory Quaternion.identity() => new Quaternion._().._storage[3] = 1.0;

  /// Constructs a quaternion from time derivative of [q] with angular
  /// velocity [omega].
  factory Quaternion.dq(Quaternion q, Vector3 omega) =>
      new Quaternion._()..setDQ(q, omega);

  /// Constructs a quaternion from [yaw], [pitch] and [roll].
  factory Quaternion.euler(double yaw, double pitch, double roll) =>
      new Quaternion._()..setEuler(yaw, pitch, roll);

  /// Constructs a quaternion with given Float32List as [storage].
  Quaternion.fromFloat32List(this._storage);

  /// Constructs a quaternion with a [storage] that views given [buffer]
  /// starting at [offset]. [offset] has to be multiple of
  /// [Float32List.BYTES_PER_ELEMENT].
  Quaternion.fromBuffer(ByteBuffer buffer, int offset)
      : _storage = new Float32List.view(buffer, offset, 4);

  /// Returns a new copy of [this].
  Quaternion clone() => new Quaternion.copy(this);

  /// Copy [source] into [this].
  void setFrom(Quaternion source) {
    final sourceStorage = source._storage;
    _storage[0] = sourceStorage[0];
    _storage[1] = sourceStorage[1];
    _storage[2] = sourceStorage[2];
    _storage[3] = sourceStorage[3];
    _onChangeController.add(null);
  }

  /// Set the quaternion to the raw values [x], [y], [z], and [w].
  void setValues(double x, double y, double z, double w) {
    _storage[0] = x;
    _storage[1] = y;
    _storage[2] = z;
    _storage[3] = w;
    _onChangeController.add(null);
  }

  /// Set the quaternion with rotation of [radians] around [axis].
  void setAxisAngle(Vector3 axis, double radians) {
    final len = axis.length;
    if (len == 0.0) {
      return;
    }
    final halfSin = Math.sin(radians * 0.5) / len;
    final axisStorage = axis.storage;
    _storage[0] = axisStorage[0] * halfSin;
    _storage[1] = axisStorage[1] * halfSin;
    _storage[2] = axisStorage[2] * halfSin;
    _storage[3] = Math.cos(radians * 0.5);
    _onChangeController.add(null);
  }

  /// Set the quaternion with rotation from a rotation matrix [rotationMatrix].
  void setFromRotation(Matrix3 rotationMatrix) {
    final rotationMatrixStorage = rotationMatrix.storage;
    final trace = rotationMatrix.trace();
    if (trace > 0.0) {
      var s = Math.sqrt(trace + 1.0);
      _storage[3] = s * 0.5;
      s = 0.5 / s;
      _storage[0] = (rotationMatrixStorage[5] - rotationMatrixStorage[7]) * s;
      _storage[1] = (rotationMatrixStorage[6] - rotationMatrixStorage[2]) * s;
      _storage[2] = (rotationMatrixStorage[1] - rotationMatrixStorage[3]) * s;
    } else {
      var i = rotationMatrixStorage[0] < rotationMatrixStorage[4]
          ? (rotationMatrixStorage[4] < rotationMatrixStorage[8] ? 2 : 1)
          : (rotationMatrixStorage[0] < rotationMatrixStorage[8] ? 2 : 0);
      var j = (i + 1) % 3;
      var k = (i + 2) % 3;
      var s = Math.sqrt(rotationMatrixStorage[rotationMatrix.index(i, i)] -
          rotationMatrixStorage[rotationMatrix.index(j, j)] -
          rotationMatrixStorage[rotationMatrix.index(k, k)] +
          1.0);
      _storage[i] = s * 0.5;
      s = 0.5 / s;
      _storage[3] = (rotationMatrixStorage[rotationMatrix.index(k, j)] -
              rotationMatrixStorage[rotationMatrix.index(j, k)]) *
          s;
      _storage[j] = (rotationMatrixStorage[rotationMatrix.index(j, i)] +
              rotationMatrixStorage[rotationMatrix.index(i, j)]) *
          s;
      _storage[k] = (rotationMatrixStorage[rotationMatrix.index(k, i)] +
              rotationMatrixStorage[rotationMatrix.index(i, k)]) *
          s;
    }
    _onChangeController.add(null);
  }

  /// Set the quaternion to a random rotation. The random number generator [rn]
  /// is used to generate the random numbers for the rotation.
  void setRandom(Math.Random rn) {
    // From: "Uniform Random Rotations", Ken Shoemake, Graphics Gems III,
    // pg. 124-132.
    final x0 = rn.nextDouble();
    final r1 = Math.sqrt(1.0 - x0);
    final r2 = Math.sqrt(x0);
    final t1 = Math.PI * 2.0 * rn.nextDouble();
    final t2 = Math.PI * 2.0 * rn.nextDouble();
    final c1 = Math.cos(t1);
    final s1 = Math.sin(t1);
    final c2 = Math.cos(t2);
    final s2 = Math.sin(t2);
    _storage[0] = s1 * r1;
    _storage[1] = c1 * r1;
    _storage[2] = s2 * r2;
    _storage[3] = c2 * r2;
  }

  /// Set the quaternion to the time derivative of [q] with angular velocity
  /// [omega].
  void setDQ(Quaternion q, Vector3 omega) {
    final qStorage = q._storage;
    final omegaStorage = omega.storage;
    final qx = qStorage[0];
    final qy = qStorage[1];
    final qz = qStorage[2];
    final qw = qStorage[3];
    final ox = omegaStorage[0];
    final oy = omegaStorage[1];
    final oz = omegaStorage[2];
    final _x = ox * qw + oy * qz - oz * qy;
    final _y = oy * qw + oz * qx - ox * qz;
    final _z = oz * qw + ox * qy - oy * qx;
    final _w = -ox * qx - oy * qy - oz * qz;
    _storage[0] = _x * 0.5;
    _storage[1] = _y * 0.5;
    _storage[2] = _z * 0.5;
    _storage[3] = _w * 0.5;
  }

  /// Set quaternion with rotation of [yaw], [pitch] and [roll].
  void setEuler(double yaw, double pitch, double roll) {
    final halfYaw = yaw * 0.5;
    final halfPitch = pitch * 0.5;
    final halfRoll = roll * 0.5;
    final cosYaw = Math.cos(halfYaw);
    final sinYaw = Math.sin(halfYaw);
    final cosPitch = Math.cos(halfPitch);
    final sinPitch = Math.sin(halfPitch);
    final cosRoll = Math.cos(halfRoll);
    final sinRoll = Math.sin(halfRoll);
    _storage[0] = cosRoll * sinPitch * cosYaw + sinRoll * cosPitch * sinYaw;
    _storage[1] = cosRoll * cosPitch * sinYaw - sinRoll * sinPitch * cosYaw;
    _storage[2] = sinRoll * cosPitch * cosYaw - cosRoll * sinPitch * sinYaw;
    _storage[3] = cosRoll * cosPitch * cosYaw + sinRoll * sinPitch * sinYaw;
  }

  /// Normalize [this].
  Quaternion normalize() {
    var l = length;
    if (l == 0.0) {
      return this;
    }
    l = 1.0 / l;
    _storage[3] = _storage[3] * l;
    _storage[2] = _storage[2] * l;
    _storage[1] = _storage[1] * l;
    _storage[0] = _storage[0] * l;
    return this;
  }

  /// Conjugate [this].
  Quaternion conjugate() {
    _storage[2] = -_storage[2];
    _storage[1] = -_storage[1];
    _storage[0] = -_storage[0];
    _onChangeController.add(null);
    return this;
  }

  /// Invert [this].
  Quaternion inverse() {
    final l = 1.0 / length2;
    _storage[3] = _storage[3] * l;
    _storage[2] = -_storage[2] * l;
    _storage[1] = -_storage[1] * l;
    _storage[0] = -_storage[0] * l;
    _onChangeController.add(null);
    return this;
  }

  /// Normalized copy of [this].
  Quaternion normalized() => clone()..normalize();

  /// Conjugated copy of [this].
  Quaternion conjugated() => clone()..conjugate();

  /// Inverted copy of [this].
  Quaternion inverted() => clone()..inverse();

  /// [radians] of rotation around the [axis] of the rotation.
  double get radians => 2.0 * Math.acos(_storage[3]);

  /// [axis] of rotation.
  Vector3 get axis {
    final scale = 1.0 / (1.0 - (_storage[3] * _storage[3]));
    return new Vector3(
        _storage[0] * scale, _storage[1] * scale, _storage[2] * scale);
  }

  /// Length squared.
  double get length2 {
    final x = _storage[0];
    final y = _storage[1];
    final z = _storage[2];
    final w = _storage[3];
    return (x * x) + (y * y) + (z * z) + (w * w);
  }

  /// Length.
  double get length => Math.sqrt(length2);

  /// Returns a copy of [v] rotated by quaternion.
  Vector3 rotated(Vector3 v) {
    final out = v.clone();
    rotate(out);
    return out;
  }

  /// Rotates [v] by [this].
  Vector3 rotate(Vector3 v) {
    // conjugate(this) * [v,0] * this
    final _w = _storage[3];
    final _z = _storage[2];
    final _y = _storage[1];
    final _x = _storage[0];
    final tiw = _w;
    final tiz = -_z;
    final tiy = -_y;
    final tix = -_x;
    final tx = tiw * v.x + tix * 0.0 + tiy * v.z - tiz * v.y;
    final ty = tiw * v.y + tiy * 0.0 + tiz * v.x - tix * v.z;
    final tz = tiw * v.z + tiz * 0.0 + tix * v.y - tiy * v.x;
    final tw = tiw * 0.0 - tix * v.x - tiy * v.y - tiz * v.z;
    final result_x = tw * _x + tx * _w + ty * _z - tz * _y;
    final result_y = tw * _y + ty * _w + tz * _x - tx * _z;
    final result_z = tw * _z + tz * _w + tx * _y - ty * _x;
    final vStorage = v.storage;
    vStorage[2] = result_z;
    vStorage[1] = result_y;
    vStorage[0] = result_x;
    _onChangeController.add(null);
    return v;
  }

  /// Add [arg] to [this].
  void add(Quaternion arg) {
    final argStorage = arg._storage;
    _storage[0] = _storage[0] + argStorage[0];
    _storage[1] = _storage[1] + argStorage[1];
    _storage[2] = _storage[2] + argStorage[2];
    _storage[3] = _storage[3] + argStorage[3];
    _onChangeController.add(null);
  }

  /// Subtracts [arg] from [this].
  void sub(Quaternion arg) {
    final argStorage = arg._storage;
    _storage[0] = _storage[0] - argStorage[0];
    _storage[1] = _storage[1] - argStorage[1];
    _storage[2] = _storage[2] - argStorage[2];
    _storage[3] = _storage[3] - argStorage[3];
    _onChangeController.add(null);
  }

  /// Scales [this] by [scale].
  void scale(double scale) {
    _storage[3] = _storage[3] * scale;
    _storage[2] = _storage[2] * scale;
    _storage[1] = _storage[1] * scale;
    _storage[0] = _storage[0] * scale;
    _onChangeController.add(null);
  }

  /// Scaled copy of [this].
  Quaternion scaled(double scale) => clone()..scale(scale);

  /// [this] rotated by [other].
  Quaternion operator *(Quaternion other) {
    double _w = _storage[3];
    double _z = _storage[2];
    double _y = _storage[1];
    double _x = _storage[0];
    final otherStorage = other._storage;
    double ow = otherStorage[3];
    double oz = otherStorage[2];
    double oy = otherStorage[1];
    double ox = otherStorage[0];
    return new Quaternion(_w * ox + _x * ow + _y * oz - _z * oy,
        _w * oy + _y * ow + _z * ox - _x * oz, _w * oz +
            _z * ow +
            _x * oy -
            _y * ox, _w * ow - _x * ox - _y * oy - _z * oz);
  }

  /// Returns copy of [this] + [other].
  Quaternion operator +(Quaternion other) => clone()..add(other);

  /// Returns copy of [this] - [other].
  Quaternion operator -(Quaternion other) => clone()..sub(other);

  /// Returns negated copy of [this].
  Quaternion operator -() => conjugated();

  /// Access the component of the quaternion at the index [i].
  double operator [](int i) => _storage[i];

  /// Set the component of the quaternion at the index [i].
  void operator []=(int i, double arg) {
    _storage[i] = arg;
  }

  /// Returns a rotation matrix containing the same rotation as [this].
  Matrix3 asRotationMatrix() => copyRotationInto(new Matrix3.zero());

  /// Set [rotationMatrix] to a rotation matrix containing the same rotation as
  /// [this].
  Matrix3 copyRotationInto(Matrix3 rotationMatrix) {
    final d = length2;
    assert(d != 0.0);
    final s = 2.0 / d;

    final _x = _storage[0];
    final _y = _storage[1];
    final _z = _storage[2];
    final _w = _storage[3];

    final xs = _x * s;
    final ys = _y * s;
    final zs = _z * s;

    final wx = _w * xs;
    final wy = _w * ys;
    final wz = _w * zs;

    final xx = _x * xs;
    final xy = _x * ys;
    final xz = _x * zs;

    final yy = _y * ys;
    final yz = _y * zs;
    final zz = _z * zs;

    final rotationMatrixStorage = rotationMatrix.storage;
    rotationMatrixStorage[0] = 1.0 - (yy + zz); // column 0
    rotationMatrixStorage[1] = xy + wz;
    rotationMatrixStorage[2] = xz - wy;
    rotationMatrixStorage[3] = xy - wz; // column 1
    rotationMatrixStorage[4] = 1.0 - (xx + zz);
    rotationMatrixStorage[5] = yz + wx;
    rotationMatrixStorage[6] = xz + wy; // column 2
    rotationMatrixStorage[7] = yz - wx;
    rotationMatrixStorage[8] = 1.0 - (xx + yy);
    return rotationMatrix;
  }

  /// Printable string.
  String toString() => '${_storage[0]}, ${_storage[1]},'
      ' ${_storage[2]} @ ${_storage[3]}';

  /// Relative error between [this] and [correct].
  double relativeError(Quaternion correct) {
    final diff = correct - this;
    final norm_diff = diff.length;
    final correct_norm = correct.length;
    return norm_diff / correct_norm;
  }

  /// Absolute error between [this] and [correct].
  double absoluteError(Quaternion correct) {
    final this_norm = length;
    final correct_norm = correct.length;
    final norm_diff = (this_norm - correct_norm).abs();
    return norm_diff;
  }

  /*
   * Additions from three.js r68.
   */

  StreamController _onChangeController = new StreamController(sync: true);
  Stream get onChange => _onChangeController.stream;

  factory Quaternion.fromEuler(Euler euler, {bool update: true}) =>
      new Quaternion._()..setFromEuler(euler, update: update);

  Quaternion setFromEuler(Euler euler, {bool update: true}) {
    // http://www.mathworks.com/matlabcentral/fileexchange/
    //  20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/
    //  content/SpinCalc.m

    var c1 = Math.cos(euler._x / 2);
    var c2 = Math.cos(euler._y / 2);
    var c3 = Math.cos(euler._z / 2);
    var s1 = Math.sin(euler._x / 2);
    var s2 = Math.sin(euler._y / 2);
    var s3 = Math.sin(euler._z / 2);

    if (euler.order == 'XYZ') {
      storage[0] = s1 * c2 * c3 + c1 * s2 * s3;
      storage[1] = c1 * s2 * c3 - s1 * c2 * s3;
      storage[2] = c1 * c2 * s3 + s1 * s2 * c3;
      storage[3] = c1 * c2 * c3 - s1 * s2 * s3;
    } else if (euler.order == 'YXZ') {
      storage[0] = s1 * c2 * c3 + c1 * s2 * s3;
      storage[1] = c1 * s2 * c3 - s1 * c2 * s3;
      storage[2] = c1 * c2 * s3 - s1 * s2 * c3;
      storage[3] = c1 * c2 * c3 + s1 * s2 * s3;
    } else if (euler.order == 'ZXY') {
      storage[0] = s1 * c2 * c3 - c1 * s2 * s3;
      storage[1] = c1 * s2 * c3 + s1 * c2 * s3;
      storage[2] = c1 * c2 * s3 + s1 * s2 * c3;
      storage[3] = c1 * c2 * c3 - s1 * s2 * s3;
    } else if (euler.order == 'ZYX') {
      storage[0] = s1 * c2 * c3 - c1 * s2 * s3;
      storage[1] = c1 * s2 * c3 + s1 * c2 * s3;
      storage[2] = c1 * c2 * s3 - s1 * s2 * c3;
      storage[3] = c1 * c2 * c3 + s1 * s2 * s3;
    } else if (euler.order == 'YZX') {
      storage[0] = s1 * c2 * c3 + c1 * s2 * s3;
      storage[1] = c1 * s2 * c3 + s1 * c2 * s3;
      storage[2] = c1 * c2 * s3 - s1 * s2 * c3;
      storage[3] = c1 * c2 * c3 - s1 * s2 * s3;
    } else if (euler.order == 'XZY') {
      storage[0] = s1 * c2 * c3 - c1 * s2 * s3;
      storage[1] = c1 * s2 * c3 - s1 * c2 * s3;
      storage[2] = c1 * c2 * s3 + s1 * s2 * c3;
      storage[3] = c1 * c2 * c3 + s1 * s2 * s3;
    }

    if (update) _onChangeController.add(null);

    return this;
  }
}
