import 'dart:io';
import 'package:http/http.dart' as http;

final List<String> files = [
  'alphamap_fragment.glsl',
  'alphamap_pars_fragment.glsl',
  'alphatest_fragment.glsl',
  'aomap_fragment.glsl',
  'aomap_pars_fragment.glsl',
  'bumpmap_pars_fragment.glsl',
  'color_fragment.glsl',
  'color_pars_fragment.glsl',
  'color_pars_vertex.glsl',
  'color_vertex.glsl',
  'common.glsl',
  'defaultnormal_vertex.glsl',
  'default_vertex.glsl',
  'envmap_fragment.glsl',
  'envmap_pars_fragment.glsl',
  'envmap_pars_vertex.glsl',
  'envmap_vertex.glsl',
  'fog_fragment.glsl',
  'fog_pars_fragment.glsl',
  'lightmap_fragment.glsl',
  'lightmap_pars_fragment.glsl',
  'lights_lambert_pars_vertex.glsl',
  'lights_lambert_vertex.glsl',
  'lights_phong_fragment.glsl',
  'lights_phong_pars_fragment.glsl',
  'lights_phong_pars_vertex.glsl',
  'lights_phong_vertex.glsl',
  'linear_to_gamma_fragment.glsl',
  'logdepthbuf_fragment.glsl',
  'logdepthbuf_pars_fragment.glsl',
  'logdepthbuf_pars_vertex.glsl',
  'logdepthbuf_vertex.glsl',
  'map_fragment.glsl',
  'map_pars_fragment.glsl',
  'map_particle_fragment.glsl',
  'map_particle_pars_fragment.glsl',
  'morphnormal_vertex.glsl',
  'morphtarget_pars_vertex.glsl',
  'morphtarget_vertex.glsl',
  'normalmap_pars_fragment.glsl',
  'shadowmap_fragment.glsl',
  'shadowmap_pars_fragment.glsl',
  'shadowmap_pars_vertex.glsl',
  'shadowmap_vertex.glsl',
  'skinbase_vertex.glsl',
  'skinning_pars_vertex.glsl',
  'skinning_vertex.glsl',
  'skinnormal_vertex.glsl',
  'specularmap_fragment.glsl',
  'specularmap_pars_fragment.glsl',
  'uv2_pars_fragment.glsl',
  'uv2_pars_vertex.glsl',
  'uv2_vertex.glsl',
  'uv_pars_fragment.glsl',
  'uv_pars_vertex.glsl',
  'uv_vertex.glsl',
  'worldpos_vertex.glsl'
];

final baseUrl = 'https://raw.githubusercontent.com/mrdoob/three.js/dev/src/renderers/shaders/ShaderChunk/';

main() async {
  print('Generating shader_chunk.dart...');

  var output = new File('lib/src/renderers/shaders/shader_chunk.dart').openWrite();

  output.write('part of three;\n\n');

  output.write('final Map<String, String> ShaderChunk = {\n');

  for (var f in files) {
    var key = f.substring(0, f.length - 5);
    var shader = await http.read('$baseUrl$f');
    output.write("'$key': '''\n$shader\n");
    output.write(f == files.last ? "'''\n};\n" : "''',\n");
  }

  print('Done');
}
