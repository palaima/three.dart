library three.math;

import 'dart:async' show Stream, StreamController;
import 'dart:collection' show UnmodifiableListView;
import 'dart:math' as math;
import 'dart:typed_data' show Float32List, ByteBuffer;
import 'package:three/three.dart' show Geometry, BufferGeometry, Object3D, GeometryObject, Camera;

part 'math/aabb2.dart';
part 'math/aabb3.dart';
part 'math/color.dart';
part 'math/euler.dart';
part 'math/frustum.dart';
part 'math/matrix2.dart';
part 'math/matrix3.dart';
part 'math/matrix4.dart';
part 'math/opengl.dart';
part 'math/plane.dart';
part 'math/quaternion.dart';
part 'math/ray.dart';
part 'math/sphere.dart';
part 'math/spline.dart';
part 'math/triangle.dart';
part 'math/vector.dart';
part 'math/vector2.dart';
part 'math/vector3.dart';
part 'math/vector4.dart';

/*
 * three.js math utility functions
 *
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * based on r70
 */

const double _degreeToRadiansFactor = math.PI / 180;
const double _radianToDegreesFactor = 180 / math.PI;

math.Random _rnd = new math.Random();

final List<String> _uuid = new List<String>(36);
final List<String> _chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split('');
String generateUUID() {
  var rnd = 0;

  for (var i = 0; i < 36; i++) {
    if (i == 8 || i == 13 || i == 18 || i == 23) {
      _uuid[i] = '-';
    } else if (i == 14) {
      _uuid[i] = '4';
    } else {
      if (rnd <= 0x02) rnd = 0x2000000 + (random16() * 0x1000000).toInt() | 0;
      var r = rnd & 0xf;
      rnd = rnd >> 4;
      _uuid[i] = _chars[(i == 19) ? (r & 0x3) | 0x8 : r];
    }
  }

  return _uuid.join('');
}

/// Clamps the x to be larger than a.
num clampBottom(num x, num a) => x < a ? a : x;

/// Linear mapping of x from range [a1, a2] to range [b1, b2].
double mapLinear(num x, num a1, num a2, num b1, num b2) => b1 + (x - a1) * (b2 - b1) / (a2 - a1);

/// Returns a value between 0-1 that represents the percentage that x has moved between min and max,
/// but smoothed or slowed down the closer X is to the min and max.
double smoothstep(double x, double min, double max) {
  if (x <= min) return 0.0;
  if (x >= max) return 1.0;

  x = (x - min) / (max - min);

  return x * x * (3 - 2 * x);
}

/// Returns a value between 0-1. It works the same as smoothstep, but more smooth.
double smootherstep(double x, double min, double max) {
  if (x <= min) return 0.0;
  if (x >= max) return 1.0;

  x = (x - min) / (max - min);

  return x * x * x * (x * (x * 6 - 15) + 10);
}

/// Random float from 0 to 1 with 16 bits of randomness.
/// Standard Math.Random() creates repetitive patterns when applied over larger space.
double random16() => (65280 * _rnd.nextDouble() + 255 * _rnd.nextDouble()) / 65535;

/// Random integer from low to high interval.
int randInt(int low, int high) => randFloat(low.toDouble(), high.toDouble()).floor();

/// Random float from low to high interval.
double randFloat(double low, double high) => low + _rnd.nextDouble() * (high - low);

/// Random float from - range / 2 to range / 2 interval.
double randFloatSpread(double range) => range * (0.5 - _rnd.nextDouble());

/// Converts degrees to radians
double degToRad(double degrees) => degrees * _degreeToRadiansFactor;

/// Converts radians to degrees
double radToDeg(double radians) => radians * _radianToDegreesFactor;

bool isPowerOfTwo(int value) => (value & (value - 1)) == 0 && value != 0;

int nextPowerOfTwo(int value) {
  value--;
  value |= value >> 1;
  value |= value >> 2;
  value |= value >> 4;
  value |= value >> 8;
  value |= value >> 16;
  value++;
  return value;
}