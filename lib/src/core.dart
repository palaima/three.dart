library three.core;

import 'dart:async';
import 'dart:html' hide Path;
import 'dart:typed_data';
import 'dart:web_gl' as gl;
import 'dart:math' as math;

import 'logging.dart';
import 'constants.dart';
import 'cameras.dart';
import 'math.dart';
import 'materials.dart';
import 'objects.dart';
import 'scenes.dart';
import 'lights.dart' show Light;

part 'core/buffer_attribute.dart';
part 'core/buffer_geometry.dart';
part 'core/clock.dart';
part 'core/dynamic_buffer_attribute.dart';
part 'core/dynamic_geometry.dart';
part 'core/face3.dart';
part 'core/geometry.dart';
part 'core/instanced_buffer_attribute.dart';
part 'core/instanced_buffer_geometry.dart';
part 'core/instanced_interleaved_buffer.dart';
part 'core/interleaved_buffer.dart';
part 'core/interleaved_buffer_attribute.dart';
part 'core/object3d.dart';
part 'core/projector.dart';
part 'core/raycaster.dart';
part 'core/rectangle.dart';

int GeometryIdCount = 0;

int Object3DIdCount = 0;
