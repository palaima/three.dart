/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r72-dev
 */


library three;

import 'dart:async';
import 'dart:collection';
import 'dart:html' hide Path;
import 'dart:typed_data';
import 'dart:web_gl' as gl;
import 'dart:math' as Math;
import 'dart:convert' show JSON;

import 'extras/three_math.dart' as ThreeMath;
export 'extras/three_math.dart';

// TODO - Use M1 Re-export ( see: http://code.google.com/p/dart/issues/detail?id=760)
import 'extras/image_utils.dart' as ImageUtils;
import 'extras/font_utils.dart' as FontUtils;
import 'extras/shader_utils.dart' as ShaderUtils;

import 'extras/core/curve_utils.dart' as CurveUtils;
import 'extras/core/shape_utils.dart' as ShapeUtils;

part 'src/cameras/camera.dart';
part 'src/cameras/perspective_camera.dart';
part 'src/cameras/orthographic_camera.dart';

part 'src/core/buffer_attribute.dart';
part 'src/core/buffer_geometry.dart';
part 'src/core/clock.dart';
part 'src/core/object3d.dart';
part 'src/core/color.dart';
part 'src/core/dynamic_buffer_attribute.dart';
part 'src/core/dynamic_geometry.dart';
part 'src/core/face3.dart';
part 'src/core/geometry.dart';
part 'src/core/instanced_buffer_attribute.dart';
part 'src/core/instanced_buffer_geometry.dart';
part 'src/core/instanced_interleaved_buffer.dart';
part 'src/core/interleaved_buffer.dart';
part 'src/core/interleaved_buffer_attribute.dart';
part 'src/core/projector.dart';
part 'src/core/ray.dart';
part 'src/core/rectangle.dart';

part 'src/math/aabb2.dart';
part 'src/math/aabb3.dart';
part 'src/math/frustum.dart';
part 'src/math/matrix2.dart';
part 'src/math/matrix3.dart';
part 'src/math/matrix4.dart';
part 'src/math/opengl.dart';
part 'src/math/plane.dart';
part 'src/math/quaternion.dart';
part 'src/math/sphere.dart';
part 'src/math/triangle.dart';
part 'src/math/vector.dart';
part 'src/math/vector2.dart';
part 'src/math/vector3.dart';
part 'src/math/vector4.dart';
part 'src/math/euler.dart';

part 'src/loaders/loader.dart';
part 'src/loaders/json_loader.dart';
part 'src/loaders/image_loader.dart';
part 'src/loaders/stl_loader.dart';
part 'src/loaders/mtl_loader.dart';
part 'src/loaders/obj_loader.dart';

part 'extras/geometries/circle_geometry.dart';
part 'extras/geometries/convex_geometry.dart';
part 'extras/geometries/cube_geometry.dart';
part 'extras/geometries/cylinder_geometry.dart';
part 'extras/geometries/extrude_geometry.dart';
part 'extras/geometries/icosahedron_geometry.dart';
part 'extras/geometries/lathe_geometry.dart';
part 'extras/geometries/octahedron_geometry.dart';
part 'extras/geometries/parametric_geometry.dart';
part 'extras/geometries/plane_geometry.dart';
part 'extras/geometries/polyhedron_geometry.dart';
part 'extras/geometries/shape_geometry.dart';
part 'extras/geometries/sphere_geometry.dart';
part 'extras/geometries/tetrahedron_geometry.dart';
part 'extras/geometries/text_geometry.dart';
part 'extras/geometries/torus_geometry.dart';
part 'extras/geometries/torus_knot_geometry.dart';
part 'extras/geometries/tube_geometry.dart';
part 'extras/geometries/ring_geometry.dart';

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

part 'extras/helpers/arrow_helper.dart';
part 'extras/helpers/axis_helper.dart';
part 'extras/helpers/camera_helper.dart';

part 'src/lights/ambient_light.dart';
part 'src/lights/directional_light.dart';
part 'src/lights/point_light.dart';
part 'src/lights/spot_light.dart';
part 'src/lights/hemisphere_light.dart';
part 'src/lights/light.dart';
part 'src/lights/shadow_caster.dart';

part 'src/materials/material.dart';
part 'src/materials/mesh_basic_material.dart';
part 'src/materials/mesh_face_material.dart';
part 'src/materials/point_cloud_material.dart';
part 'src/materials/particle_canvas_material.dart';
part 'src/materials/line_basic_material.dart';
part 'src/materials/line_dashed_material.dart';
part 'src/materials/mesh_lambert_material.dart';
part 'src/materials/mesh_depth_material.dart';
part 'src/materials/mesh_normal_material.dart';
part 'src/materials/mesh_phong_material.dart';
part 'src/materials/shader_material.dart';
part 'src/materials/raw_shader_material.dart';
part 'src/materials/sprite_material.dart';

part 'src/objects/bone.dart';
part 'src/objects/group.dart';
part 'src/objects/mesh.dart';
part 'src/objects/line.dart';
part 'src/objects/particle.dart';
part 'src/objects/point_cloud.dart';
part 'src/objects/sprite.dart';
part 'src/objects/skinned_mesh.dart';
part 'src/objects/lod.dart';
part 'src/objects/morph_anim_mesh.dart';

part 'src/renderers/web_gl/web_gl_extensions.dart';
part 'src/renderers/web_gl/web_gl_geometries.dart';
part 'src/renderers/web_gl/web_gl_objects.dart';
part 'src/renderers/web_gl/web_gl_program.dart';
part 'src/renderers/web_gl/web_gl_shader.dart';
part 'src/renderers/web_gl/web_gl_shadow_map.dart';
part 'src/renderers/web_gl/web_gl_state.dart';
part 'src/renderers/web_gl/web_gl_textures.dart';

part 'src/renderers/renderer.dart';
part 'src/renderers/web_gl_renderer.dart';
part 'src/renderers/web_gl_render_target.dart';
part 'src/renderers/web_gl_render_target_cube.dart';
part 'src/renderers/web_gl_shaders.dart';

part 'src/scenes/scene.dart';
part 'src/scenes/fog.dart';
part 'src/scenes/fog_linear.dart';
part 'src/scenes/fog_exp2.dart';

part 'src/textures/texture.dart';
part 'src/textures/cube_texture.dart';
part 'src/textures/data_texture.dart';
part 'src/textures/compressed_texture.dart';

// from _geometry
int GeometryIdCount = 0;

// from Object3D
int Object3DIdCount = 0;

// from _material
int MaterialIdCount = 0;

// from Texture
int TextureIdCount = 0;

// GL STATE CONSTANTS

const int CullFaceNone = 0;
const int CullFaceBack = 1;
const int CullFaceFront = 2;
const int CullFaceFrontBack = 3;

const int FrontFaceDirectionCW = 0;
const int FrontFaceDirectionCCW = 1;

// SHADOWING TYPES

const int BasicShadowMap = 0;
const int PCFShadowMap = 1;
const int PCFSoftShadowMap = 2;

// MATERIAL CONSTANTS

// side

const int FrontSide = 0;
const int BackSide = 1;
const int DoubleSide = 2;

// shading

const int NoShading = 0;
const int FlatShading = 1;
const int SmoothShading = 2;

// colors

const int NoColors = 0;
const int FaceColors = 1;
const int VertexColors = 2;

// blending modes

const int NoBlending = 0;
const int NormalBlending = 1;
const int AdditiveBlending = 2;
const int SubtractiveBlending = 3;
const int MultiplyBlending = 4;
const int CustomBlending = 5;

// custom blending equations
// (numbers start from 100 not to clash with other
//  mappings to OpenGL constants defined in Texture.js)

const int AddEquation = 100;
const int SubtractEquation = 101;
const int ReverseSubtractEquation = 102;
const int MinEquation = 103;
const int MaxEquation = 104;

// custom blending destination factors

const int ZeroFactor = 200;
const int OneFactor = 201;
const int SrcColorFactor = 202;
const int OneMinusSrcColorFactor = 203;
const int SrcAlphaFactor = 204;
const int OneMinusSrcAlphaFactor = 205;
const int DstAlphaFactor = 206;
const int OneMinusDstAlphaFactor = 207;

// custom blending source factors

//const int ZeroFactor = 200;
//const int OneFactor = 201;
//const int SrcAlphaFactor = 204;
//const int OneMinusSrcAlphaFactor = 205;
//const int DstAlphaFactor = 206;
//const int OneMinusDstAlphaFactor = 207;
const int DstColorFactor = 208;
const int OneMinusDstColorFactor = 209;
const int SrcAlphaSaturateFactor = 210;

// depth modes

const int NeverDepth = 0;
const int AlwaysDepth = 1;
const int LessDepth = 2;
const int LessEqualDepth = 3;
const int EqualDepth = 4;
const int GreaterEqualDepth = 5;
const int GreaterDepth = 6;
const int NotEqualDepth = 7;


// TEXTURE CONSTANTS

const int MultiplyOperation = 0;
const int MixOperation = 1;
const int AddOperation = 2;

// Mapping modes

const int UVMapping = 300;

const int CubeReflectionMapping = 301;
const int CubeRefractionMapping = 302;

const int EquirectangularReflectionMapping = 303;
const int EquirectangularRefractionMapping = 304;

const int SphericalReflectionMapping = 305;

// Wrapping modes

const int RepeatWrapping = 1000;
const int ClampToEdgeWrapping = 1001;
const int MirroredRepeatWrapping = 1002;

// Filters

const int NearestFilter = 1003;
const int NearestMipMapNearestFilter = 1004;
const int NearestMipMapLinearFilter = 1005;
const int LinearFilter = 1006;
const int LinearMipMapNearestFilter = 1007;
const int LinearMipMapLinearFilter = 1008;

// Data types

const int UnsignedByteType = 1009;
const int ByteType = 1010;
const int ShortType = 1011;
const int UnsignedShortType = 1012;
const int IntType = 1013;
const int UnsignedIntType = 1014;
const int FloatType = 1015;
const int HalfFloatType = 1025;

// Pixel types

//const int UnsignedByteType = 1009;
const int UnsignedShort4444Type = 1016;
const int UnsignedShort5551Type = 1017;
const int UnsignedShort565Type = 1018;

// Pixel formats

const int AlphaFormat = 1019;
const int RGBFormat = 1020;
const int RGBAFormat = 1021;
const int LuminanceFormat = 1022;
const int LuminanceAlphaFormat = 1023;
// const int RGBEFormat handled as const int RGBAFormat in shaders
const int RGBEFormat = RGBAFormat; //1024;

// DDS / ST3C Compressed texture formats

const int RGB_S3TC_DXT1_Format = 2001;
const int RGBA_S3TC_DXT1_Format = 2002;
const int RGBA_S3TC_DXT3_Format = 2003;
const int RGBA_S3TC_DXT5_Format = 2004;


// PVRTC compressed texture formats

const int RGB_PVRTC_4BPPV1_Format = 2100;
const int RGB_PVRTC_2BPPV1_Format = 2101;
const int RGBA_PVRTC_4BPPV1_Format = 2102;
const int RGBA_PVRTC_2BPPV1_Format = 2103;

warn(String msg) => window.console.warn(msg);
log(String msg) => window.console.log(msg);
error(String msg) => window.console.error(msg);
