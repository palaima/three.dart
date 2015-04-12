/**
 * @author mrdoob / http://mrdoob.com/
 * @author WestLangley / http://github.com/WestLangley
 * @author bhouston / http://exocortex.com
 *
 * based on r68
 */

part of three;

class Euler {
  static const rotationOrder = const ['XYZ', 'YZX', 'ZXY', 'XZY', 'YXZ', 'ZYX'];
  static const defaultOrder = 'XYZ';

  StreamController _onChangeController = new StreamController.broadcast();
  Stream get onChange => _onChangeController.stream;

  double _x, _y, _z;
  String _order;

  Euler([this._x = 0.0, this._y = 0.0, this._z = 0.0, this._order = Euler.defaultOrder]);

  Euler.copy(Euler other) {
    _x = other._x;
    _y = other._y;
    _z = other._z;
    _order = other._order;
  }

  Euler.fromList(List array, [int offset = 0]) {
    var i = offset;
    _x = array[i + 0];
    _y = array[i + 1];
    _z = array[i + 2];
    if (array.length > i + 3) {
      _order = array[i + 3];
    }
  }

  Euler.fromQuaternion(Quaternion q, {String order, bool update: true}) {
    setFromQuaternion(q, order: order, update: update);
  }

  Euler.fromRotationMatrix(Matrix4 matrix, {String order}) {
    setFromRotationMatrix(matrix, order: order);
  }

  double get x => _x;
  set x(double x) {
    _x = x;
    _onChangeController.add(null);
  }

  double get y => _y;
  set y(double y) {
    _y = y;
    _onChangeController.add(null);
  }

  double get z => _z;
  set z(double z) {
    _z = z;
    _onChangeController.add(null);
  }

  String get order => _order;
  set order(String order) {
    _order = order;
    _onChangeController.add(null);
  }

  Euler setValues(double x, double y, double z, {String order}){
    _x = x;
    _y = y;
    _z = z;

    if (order != null) _order = order;

    _onChangeController.add(null);
    return this;
  }

  Euler setFrom(Euler euler) {
    _x = euler.x;
    _y = euler.y;
    _z = euler.z;

    _order = euler._order;

    _onChangeController.add(null);
    return this;
  }

  Euler setFromRotationMatrix(Matrix4 matrix, {String order}) {
    var m11 = matrix.storage[0], m12 = matrix.storage[4], m13 = matrix.storage[8];
    var m21 = matrix.storage[1], m22 = matrix.storage[5], m23 = matrix.storage[9];
    var m31 = matrix.storage[2], m32 = matrix.storage[6], m33 = matrix.storage[10];

    order = order != null ? order : _order;

    switch (order) {
      case 'XYZ':
        _y = Math.asin(m13.clamp(-1.0, 1.0));

        if (m13.abs() < 0.99999) {
          _x = Math.atan2(-m23, m33);
          _z = Math.atan2(-m12, m11);
        } else {
          _x = Math.atan2(m32, m22);
          _z = 0.0;
        }
        break;
      case 'YXZ':
        _x = Math.asin(-m23.clamp(-1.0, 1.0));

        if (m23.abs() < 0.99999) {
          _y = Math.atan2(m13, m33);
          _z = Math.atan2(m21, m22);
        } else {
          _y = Math.atan2(-m31, m11);
          _z = 0.0;
        }
        break;
      case 'ZXY':
        _x = Math.asin(m32.clamp(-1.0, 1.0));

        if (m32.abs() < 0.99999) {
          _y = Math.atan2(-m31, m33);
          _z = Math.atan2(-m12, m22);
        } else {
          _y = 0.0;
          _z = Math.atan2(m21, m11);
        }
        break;
      case 'ZYX':
        _y = Math.asin(-m31.clamp(-1.0, 1.0));

        if (m31.abs() < 0.99999 ) {
          _x = Math.atan2(m32, m33);
          _z = Math.atan2(m21, m11);
        } else {
          _x = 0.0;
          _z = Math.atan2(-m12, m22);
        }
        break;
      case 'YZX':
        _z = Math.asin(m21.clamp(-1.0, 1.0));

        if (m21.abs() < 0.99999) {
          _x = Math.atan2(-m23, m22);
          _y = Math.atan2(-m31, m11);
        } else {
          _x = 0.0;
          _y = Math.atan2(m13, m33);
        }
        break;
      case 'XZY':
        _z = Math.asin(-m12.clamp(-1.0, 1.0));

        if (m12.abs() < 0.99999) {
          _x = Math.atan2(m32, m22);
          _y = Math.atan2(m13, m11);
        } else {
          _x = Math.atan2(-m23, m33);
          _y = 0.0;
        }
        break;
      default:
        print ('WARNING: Euler.setFromRotationMatrix() given unsupported order: [$order]');
        break;
    }

    _order = order;
    _onChangeController.add(null);
    return this;
  }

  Euler setFromQuaternion(Quaternion q, {String order, bool update: true}) {
    var sqx = q.x * q.x;
    var sqy = q.y * q.y;
    var sqz = q.z * q.z;
    var sqw = q.w * q.w;

    order = order != null ? order : _order;

    switch (_order) {
      case 'XYZ':
        _x = Math.atan2(2 * (q.x * q.w - q.y * q.z), (sqw - sqx - sqy + sqz));
        _y = Math.asin((2 * (q.x * q.z + q.y * q.w)).clamp(-1.0, 1.0));
        _z = Math.atan2(2 * (q.z * q.w - q.x * q.y), (sqw + sqx - sqy - sqz));
        break;
      case 'YXZ':
        _x = Math.asin((2 * (q.x * q.w - q.y * q.z)).clamp(-1.0, 1.0));
        _y = Math.atan2(2 * (q.x * q.z + q.y * q.w), (sqw - sqx - sqy + sqz));
        _z = Math.atan2(2 * (q.x * q.y + q.z * q.w), (sqw - sqx + sqy - sqz));
        break;
      case 'ZXY':
        _x = Math.asin((2 * (q.x * q.w + q.y * q.z)).clamp(-1.0, 1.0));
        _y = Math.atan2(2 * (q.y * q.w - q.z * q.x), (sqw - sqx - sqy + sqz));
        _z = Math.atan2(2 * (q.z * q.w - q.x * q.y), (sqw - sqx + sqy - sqz));

        break;
      case 'ZYX':
        _x = Math.atan2(2 * (q.x * q.w + q.z * q.y), (sqw - sqx - sqy + sqz));
        _y = Math.asin((2 * (q.y * q.w - q.x * q.z)).clamp(-1.0, 1.0));
        _z = Math.atan2(2 * (q.x * q.y + q.z * q.w), ( sqw + sqx - sqy - sqz));

        break;
      case 'YZX':
        _x = Math.atan2(2 * (q.x * q.w - q.z * q.y), (sqw - sqx + sqy - sqz));
        _y = Math.atan2(2 * (q.y * q.w - q.x * q.z), (sqw + sqx - sqy - sqz));
        _z = Math.asin((2 * (q.x * q.y + q.z * q.w)).clamp(-1.0, 1.0));
        break;
      case 'XZY':
        _x = Math.atan2(2 * (q.x * q.w + q.y * q.z), (sqw - sqx + sqy - sqz) );
        _y = Math.atan2(2 * (q.x * q.z + q.y * q.w), (sqw + sqx - sqy - sqz) );
        _z = Math.asin((2 * (q.z * q.w - q.x * q.y) ).clamp(-1.0, 1.0));
        break;
      default:
        print('WARNING: Euler.setFromQuaternion() given unsupported order: [$order]');
        break;
    }

    _order = order;
    if (update) _onChangeController.add(null);
    return this;
  }

  void reorder(String newOrder) {
    setFromQuaternion(new Quaternion.fromEuler(this), order: newOrder);
  }

  List toArray() => [_x, _y, _z, _order];

  bool operator ==(Euler euler) =>
      (euler._x == _x) && (euler._y == _y) && (euler._z == _z) && (euler._order == order);

  Euler clone() => new Euler.copy(this);
}