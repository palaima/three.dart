library controls;

import 'dart:html';
import 'dart:async';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'three_math.dart' as ThreeMath;

part 'controls/first_person_controls.dart';
part 'controls/fly_controls.dart';
part 'controls/orbit_controls.dart';
part 'controls/orthographic_trackball_controls.dart';
part 'controls/trackball_controls.dart';

enum State {
  ROTATE,
  ZOOM,
  PAN,
  DOLLY,
  TOUCH_ROTATE,
  TOUCH_ZOOM,
  TOUCH_PAN,
  TOUCH_ZOOM_PAN,
  TOUCH_DOLLY,
  NONE
}