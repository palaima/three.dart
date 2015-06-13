/*
 * Based on https://github.com/mrdoob/three.js/tree/da8ef6db17c718e5b15eb86a88ba13338c3d61ee/src/renderers
 */

library three.renderers;

import 'dart:collection';
import 'dart:html' hide Path;
import 'dart:typed_data';
import 'dart:web_gl' as gl;
import 'dart:math' as math;

import '../extras/uniforms_utils.dart' as uniforms_utils;

import '../extras/helpers.dart' show CameraHelper;
import '../extras/core.dart' show Gyroscope;

import 'logging.dart';
import 'constants.dart';
import 'core.dart';
import 'math.dart';
import 'materials.dart';
import 'lights.dart';
import 'objects.dart';
import 'textures.dart';
import 'scenes.dart';
import 'cameras.dart';

part 'renderers/shaders/attribute.dart';
part 'renderers/shaders/shader_chunk.dart';
part 'renderers/shaders/shader_lib.dart';
part 'renderers/shaders/uniform.dart';
part 'renderers/shaders/uniforms_lib.dart';

part 'renderers/webgl/webgl_extensions.dart';
part 'renderers/webgl/webgl_geometries.dart';
part 'renderers/webgl/webgl_objects.dart';
part 'renderers/webgl/webgl_program.dart';
part 'renderers/webgl/webgl_shader.dart';
part 'renderers/webgl/webgl_shadow_map.dart';
part 'renderers/webgl/webgl_state.dart';
part 'renderers/webgl/webgl_textures.dart';

part 'renderers/webgl_renderer.dart';
part 'renderers/webgl_render_target.dart';
part 'renderers/webgl_render_target_cube.dart';
