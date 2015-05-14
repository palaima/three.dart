library three.materials;

import 'dart:async';
import 'dart:typed_data' show Float32List;

import 'constants.dart';
import 'textures.dart';
import 'math.dart';

import 'renderers.dart' show Uniform, Attribute, WebGLProgram;

part 'materials/line_basic_material.dart';
part 'materials/line_dashed_material.dart';
part 'materials/material.dart';
part 'materials/mesh_basic_material.dart';
part 'materials/mesh_depth_material.dart';
part 'materials/mesh_face_material.dart';
part 'materials/mesh_lambert_material.dart';
part 'materials/mesh_normal_material.dart';
part 'materials/mesh_phong_material.dart';
part 'materials/particle_canvas_material.dart';
part 'materials/point_cloud_material.dart';
part 'materials/raw_shader_material.dart';
part 'materials/shader_material.dart';
part 'materials/sprite_material.dart';

int MaterialIdCount = 0;