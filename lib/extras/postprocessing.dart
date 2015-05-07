library three.postprocessing;

import 'dart:html';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:web_gl' as gl;
import 'package:three/three.dart';
import 'package:three/extras/shaders.dart';
export 'package:three/extras/shaders.dart';
import 'package:three/src/renderers/shaders/uniforms_utils.dart' as UniformsUtils;
import 'package:three/extras/three_math.dart' as ThreeMath;

part 'postprocessing/adaptive_tone_mapping_pass.dart';
part 'postprocessing/bloom_pass.dart';
part 'postprocessing/bokeh_pass.dart';
part 'postprocessing/dot_screen_pass.dart';
part 'postprocessing/effect_composer.dart';
part 'postprocessing/film_pass.dart';
part 'postprocessing/glitch_pass.dart';
part 'postprocessing/mask_pass.dart';
part 'postprocessing/render_pass.dart';
part 'postprocessing/save_pass.dart';
part 'postprocessing/shader_pass.dart';
part 'postprocessing/texture_pass.dart';

abstract class Pass {
  bool enabled;
  bool needsSwap;
  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, double delta, bool maskActive);
}

