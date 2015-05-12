/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r72-dev
 */


library three;

import 'dart:collection';
import 'dart:html' hide Path;
import 'dart:typed_data';
import 'dart:web_gl' as gl;
import 'dart:math' as math;

import 'src/core.dart';
export 'src/core.dart';

import 'src/objects.dart';
export 'src/objects.dart';

import 'src/cameras.dart';
export 'src/cameras.dart';

import 'src/math.dart';
export 'src/math.dart';

import 'src/scenes.dart';
export 'src/scenes.dart';

import 'src/textures.dart';
export 'src/textures.dart';

import 'src/lights.dart';
export 'src/lights.dart';

import 'src/materials.dart';
export 'src/materials.dart';

import 'src/constants.dart';
export 'src/constants.dart';

import 'extras/helpers.dart' show CameraHelper;

import 'extras/font_utils.dart' as font_utils;

import 'extras/core/curve_utils.dart' as curve_utils;
import 'extras/core/shape_utils.dart' as shape_utils;

import 'extras/uniforms_utils.dart' as uniforms_utils;

part 'extras/geometries/circle_geometry.dart';
part 'extras/geometries/circle_buffer_geometry.dart';
part 'extras/geometries/convex_geometry.dart';
part 'extras/geometries/box_geometry.dart';
part 'extras/geometries/cylinder_geometry.dart';
part 'extras/geometries/extrude_geometry.dart';
part 'extras/geometries/hilbert_geometry.dart';
part 'extras/geometries/icosahedron_geometry.dart';
part 'extras/geometries/lathe_geometry.dart';
part 'extras/geometries/octahedron_geometry.dart';
part 'extras/geometries/parametric_geometry.dart';
part 'extras/geometries/plane_geometry.dart';
part 'extras/geometries/plane_buffer_geometry.dart';
part 'extras/geometries/polyhedron_geometry.dart';
part 'extras/geometries/shape_geometry.dart';
part 'extras/geometries/sphere_geometry.dart';
part 'extras/geometries/sphere_buffer_geometry.dart';
part 'extras/geometries/tetrahedron_geometry.dart';
part 'extras/geometries/text_geometry.dart';
part 'extras/geometries/torus_geometry.dart';
part 'extras/geometries/torus_knot_geometry.dart';
part 'extras/geometries/tube_geometry.dart';
part 'extras/geometries/ring_geometry.dart';
part 'extras/geometries/wireframe_geometry.dart';
part 'extras/geometries/edges_geometry.dart';

part 'extras/core/curve.dart';
part 'extras/core/curve_path.dart';
part 'extras/core/path.dart';
part 'extras/core/shape.dart';
part 'extras/core/line_curve.dart';
part 'extras/core/quadratic_bezier_curve.dart';
part 'extras/core/cubic_bezier_curve.dart';
part 'extras/core/spline_curve.dart';
part 'extras/core/arc_curve.dart';
part 'extras/core/ellipse_curve.dart';

part 'extras/core/line_curve3.dart';
part 'extras/core/quadratic_bezier_curve3.dart';
part 'extras/core/cubic_bezier_curve3.dart';
part 'extras/core/spline_curve3.dart';
part 'extras/core/closed_spline_curve3.dart';

part 'extras/core/gyroscope.dart';

part 'extras/objects/lens_flare.dart';
part 'extras/objects/immediate_render_object.dart';

part 'src/renderers/shaders/attribute.dart';
part 'src/renderers/shaders/shader_chunk.dart';
part 'src/renderers/shaders/shader_lib.dart';
part 'src/renderers/shaders/uniform.dart';
part 'src/renderers/shaders/uniforms_lib.dart';

part 'src/renderers/webgl/webgl_extensions.dart';
part 'src/renderers/webgl/webgl_geometries.dart';
part 'src/renderers/webgl/webgl_objects.dart';
part 'src/renderers/webgl/webgl_program.dart';
part 'src/renderers/webgl/webgl_shader.dart';
part 'src/renderers/webgl/webgl_shadow_map.dart';
part 'src/renderers/webgl/webgl_state.dart';
part 'src/renderers/webgl/webgl_textures.dart';

part 'src/renderers/webgl_renderer.dart';
part 'src/renderers/webgl_render_target.dart';
part 'src/renderers/webgl_render_target_cube.dart';

// from _geometry
int GeometryIdCount = 0;

// from Object3D
int Object3DIdCount = 0;

// from _material
int MaterialIdCount = 0;

// from Texture
int TextureIdCount = 0;

warn(String msg) => window.console.warn(msg);
log(String msg) => window.console.log(msg);
error(String msg) => window.console.error(msg);
