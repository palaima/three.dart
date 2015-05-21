/*
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three.renderers;

final Map<String, Map<String, Uniform>> UniformsLib = {
  'common': {
    'diffuse': new Uniform.color(0xeeeeee),
    'opacity': new Uniform.float(1.0),
    'map': new Uniform.texture(),
    'offsetRepeat': new Uniform.vector4(0.0, 0.0, 1.0, 1.0),
    'specularMap': new Uniform.texture(),
    'alphaMap': new Uniform.texture(),
    'envMap': new Uniform.texture(),
    'flipEnvMap': new Uniform.float(-1.0),
    'reflectivity': new Uniform.float(1.0),
    'refractionRatio': new Uniform.float(0.98)
  },
  'aomap': {
    'aoMap': new Uniform.texture(),
    'aoMapIntensity': new Uniform.float(1.0),
  },
  'lightmap': {
    'lightMap': new Uniform.texture(),
    'lightMapIntensity': new Uniform.float(1.0),
  },
  'bump': {
    'bumpMap': new Uniform.texture(),
    'bumpScale': new Uniform.float(1.0)
  },
  'normalmap': {
    'normalMap': new Uniform.texture(),
    'normalScale': new Uniform.vector2(1.0, 1.0)
  },
  'fog': {
    'fogDensity': new Uniform.float(0.00025),
    'fogNear': new Uniform.float(1.0),
    'fogFar': new Uniform.float(2000.0),
    'fogColor': new Uniform.color(0xffffff)
  },
  'lights': {
    'ambientLightColor': new Uniform.floatv(),
    'directionalLightDirection': new Uniform.floatv(),
    'directionalLightColor': new Uniform.floatv(),
    'hemisphereLightDirection': new Uniform.floatv(),
    'hemisphereLightSkyColor': new Uniform.floatv(),
    'hemisphereLightGroundColor': new Uniform.floatv(),
    'pointLightColor' : new Uniform.floatv(),
    'pointLightPosition' : new Uniform.floatv() ,
    'pointLightDistance' : new Uniform.floatv1(),
    'pointLightDecay' : new Uniform.floatv1(),
    'spotLightColor' : new Uniform.floatv(),
    'spotLightPosition' : new Uniform.floatv(),
    'spotLightDirection' : new Uniform.floatv(),
    'spotLightDistance' : new Uniform.floatv1(),
    'spotLightAngleCos' : new Uniform.floatv1(),
    'spotLightExponent' : new Uniform.floatv1(),
    'spotLightDecay' : new Uniform.floatv1(),
  },
  'particle': {
    'psColor' : new Uniform.color(0xeeeeee),
    'opacity' : new Uniform.float(1.0),
    'size' : new Uniform.float(1.0),
    'scale' : new Uniform.float(1.0),
    'map' : new Uniform.texture(),
    'offsetRepeat': new Uniform.vector4(0.0, 0.0, 1.0, 1.0),

    'fogDensity' : new Uniform.float(0.00025),
    'fogNear' : new Uniform.float(1.0),
    'fogFar' : new Uniform.float(2000.0),
    'fogColor' : new Uniform.color(0xffffff)
  },
  'shadowmap': {
    'shadowMap': new Uniform.texturev([]),
    'shadowMapSize': new Uniform.vector2v([]),
    'shadowBias' : new Uniform.floatv1(),
    'shadowDarkness': new Uniform.floatv1(),
    'shadowMatrix' : new Uniform.matrix4v([])
  }
};