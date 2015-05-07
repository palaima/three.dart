library uniform_utils;

import 'package:three/three.dart' show Uniform;

Map<String, Uniform> merge(List<Map<String, Uniform>> uniformsList) {
  var merged = {};

  uniformsList.forEach((uniforms) {
    uniforms.forEach((k, uniform) => merged[k] = uniform.clone());
  });

  return merged;
}

Map<String, Uniform> clone(Map<String, Uniform> uniforms) {
  var result = {};
  uniforms.forEach((k, uniform) => result[k] = uniform.clone());
  return result;
}
