/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r72-dev
 */


library three;

import 'dart:typed_data';
import 'dart:math' as math;

import 'src/core.dart';
export 'src/core.dart';

export 'src/objects.dart';
export 'src/cameras.dart';

import 'src/math.dart';
export 'src/math.dart';

export 'src/scenes.dart';
export 'src/textures.dart';
export 'src/lights.dart';
export 'src/materials.dart';
export 'src/renderers.dart';
export 'src/constants.dart';

import 'extras/font_utils.dart' as font_utils;

import 'extras/core/curve_utils.dart' as curve_utils;
import 'extras/core/shape_utils.dart' as shape_utils;

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
