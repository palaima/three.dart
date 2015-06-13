part of three.renderers;

class WebGLProgram {
  static int programIdCount = 0;

  Map<String, gl.UniformLocation> uniforms;
  Map<String, int> attributes;

  int id = WebGLProgram.programIdCount++;
  String code;
  int usedTimes = 1;
  gl.Program program;
  gl.Shader vertexShader;
  gl.Shader fragmentShader;

  String generateDefines(Map defines) {
    var chunks = [];

    for (var name in defines.keys) {
      var value = defines[name];

      if (value == null) continue;

      chunks.add('#define $name $value');
    }

    return chunks.join('\n');
  }

  Map fetchUniformLocations(gl.RenderingContext _gl, gl.Program program) {
    var uniforms = {};

    var n = _gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);

    for (var i = 0; i < n; i++) {
      var info = _gl.getActiveUniform(program, i);
      var name = info.name;
      var location = _gl.getUniformLocation(program, name);

      //console.log("THREE.WebGLProgram: ACTIVE UNIFORM:", name);

      var suffixPos = name.lastIndexOf('[0]');
      if (suffixPos != -1 && suffixPos == name.length - 3) {
        uniforms[name.substring(0, suffixPos)] = location;
      }

      uniforms[name] = location;
    }

    return uniforms;
  }

  Map fetchAttributeLocations(gl.RenderingContext _gl, gl.Program program) {
    var attributes = {};

    var n = _gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);

    for (var i = 0; i < n; i++) {
      var info = _gl.getActiveAttrib(program, i);
      var name = info.name;

      //console.log("THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:", name);

      attributes[name] = _gl.getAttribLocation(program, name);
    }

    return attributes;
  }

  gl.RenderingContext _gl;

  WebGLProgram._(WebGLRenderer renderer, this.code, Material material,
      {String precision, bool supportsVertexTextures, bool map, bool envMap,
      bool envMapMode, bool lightMap, bool aoMap, bool bumpMap, bool normalMap,
      bool specularMap, bool alphaMap, int combine, int vertexColors, bool fog,
      bool useFog, bool fogExp, bool flatShading, bool sizeAttenuation,
      bool logarithmicDepthBuffer, bool skinning, int maxBones,
      bool useVertexTexture, bool morphTargets, bool morphNormals,
      int maxMorphTargets, int maxMorphNormals, int maxDirLights,
      int maxPointLights, int maxSpotLights, int maxHemiLights, int maxShadows,
      bool shadowMapEnabled, int shadowMapType, bool shadowMapDebug,
      bool shadowMapCascade, double alphaTest, bool metal, bool doubleSided,
      bool flipSided}) {
    _gl = renderer._gl;

    var mat = material;

    var defines = mat is ShaderMaterial ? mat.defines : {};

    var vertexShader = material['__webglShader']['vertexShader'];
    var fragmentShader = material['__webglShader']['fragmentShader'];

    var index0AttributeName =
        material is ShaderMaterial ? material.index0AttributeName : null;

//    if (index0AttributeName == null && morphTargets) {
//      // programs with morphTargets displace position out of attribute 0
//      index0AttributeName = 'position';
//    }

    var shadowMapTypeDefine = 'SHADOWMAP_TYPE_BASIC';

    if (shadowMapType == PCFShadowMap) {
      shadowMapTypeDefine = 'SHADOWMAP_TYPE_PCF';
    } else if (shadowMapType == PCFSoftShadowMap) {
      shadowMapTypeDefine = 'SHADOWMAP_TYPE_PCF_SOFT';
    }

    var envMapTypeDefine = 'ENVMAP_TYPE_CUBE';
    var envMapModeDefine = 'ENVMAP_MODE_REFLECTION';
    var envMapBlendingDefine = 'ENVMAP_BLENDING_MULTIPLY';

    if (envMap && mat is Mapping) {
      switch (mat.envMap.mapping) {
        case CubeReflectionMapping:
        case CubeRefractionMapping:
          envMapTypeDefine = 'ENVMAP_TYPE_CUBE';
          break;
        case EquirectangularReflectionMapping:
        case EquirectangularRefractionMapping:
          envMapTypeDefine = 'ENVMAP_TYPE_EQUIREC';
          break;
        case SphericalReflectionMapping:
          envMapTypeDefine = 'ENVMAP_TYPE_SPHERE';
          break;
      }

      switch (mat.envMap.mapping) {
        case CubeRefractionMapping:
        case EquirectangularRefractionMapping:
          envMapModeDefine = 'ENVMAP_MODE_REFRACTION';
          break;
      }

      switch (mat.combine) {
        case MultiplyOperation:
          envMapBlendingDefine = 'ENVMAP_BLENDING_MULTIPLY';
          break;
        case MixOperation:
          envMapBlendingDefine = 'ENVMAP_BLENDING_MIX';
          break;
        case AddOperation:
          envMapBlendingDefine = 'ENVMAP_BLENDING_ADD';
          break;
      }
    }

    var gammaFactorDefine =
        (renderer.gammaFactor > 0) ? renderer.gammaFactor : 1.0;

    // log('building new program ');

    //

    var customDefines = generateDefines(defines);

    //

    var program = _gl.createProgram();

    var prefixVertex, prefixFragment;

    nn(o) => o != null;

    if (material is RawShaderMaterial) {
      prefixVertex = '';
      prefixFragment = '';
    } else {
      prefixVertex = [
        'precision $precision float;',
        'precision $precision int;',
        customDefines,
        supportsVertexTextures ? '#define VERTEX_TEXTURES' : '',
        renderer.gammaInput ? '#define GAMMA_INPUT' : '',
        renderer.gammaOutput ? '#define GAMMA_OUTPUT' : '',
        '#define GAMMA_FACTOR $gammaFactorDefine',
        '#define MAX_DIR_LIGHTS $maxDirLights',
        '#define MAX_POINT_LIGHTS $maxPointLights',
        '#define MAX_SPOT_LIGHTS $maxSpotLights',
        '#define MAX_HEMI_LIGHTS $maxHemiLights',
        '#define MAX_SHADOWS $maxShadows',
        '#define MAX_BONES $maxBones',
        map ? '#define USE_MAP' : '',
        envMap ? '#define USE_ENVMAP' : '',
        envMap ? '#define $envMapModeDefine' : '',
        lightMap ? '#define USE_LIGHTMAP' : '',
        aoMap ? '#define USE_AOMAP' : '',
        bumpMap ? '#define USE_BUMPMAP' : '',
        normalMap ? '#define USE_NORMALMAP' : '',
        specularMap ? '#define USE_SPECULARMAP' : '',
        alphaMap ? '#define USE_ALPHAMAP' : '',
        vertexColors != NoColors ? '#define USE_COLOR' : '',
        flatShading ? '#define FLAT_SHADED' : '',
        skinning ? '#define USE_SKINNING' : '',
        useVertexTexture ? '#define BONE_TEXTURE' : '',
        morphTargets ? '#define USE_MORPHTARGETS' : '',
        morphNormals ? '#define USE_MORPHNORMALS' : '',
        doubleSided ? '#define DOUBLE_SIDED' : '',
        flipSided ? '#define FLIP_SIDED' : '',
        shadowMapEnabled ? '#define USE_SHADOWMAP' : '',
        shadowMapEnabled ? '#define $shadowMapTypeDefine' : '',
        shadowMapDebug ? '#define SHADOWMAP_DEBUG' : '',
        shadowMapCascade ? '#define SHADOWMAP_CASCADE' : '',
        sizeAttenuation ? '#define USE_SIZEATTENUATION' : '',
        logarithmicDepthBuffer ? '#define USE_LOGDEPTHBUF' : '',
        logarithmicDepthBuffer &&
                renderer.extensions.get('EXT_frag_depth') != null
            ? '#define USE_LOGDEPTHBUF_EXT'
            : '',
        'uniform mat4 modelMatrix;',
        'uniform mat4 modelViewMatrix;',
        'uniform mat4 projectionMatrix;',
        'uniform mat4 viewMatrix;',
        'uniform mat3 normalMatrix;',
        'uniform vec3 cameraPosition;',
        'attribute vec3 position;',
        'attribute vec3 normal;',
        'attribute vec2 uv;',
        '#ifdef USE_COLOR',
        ' attribute vec3 color;',
        '#endif',
        '#ifdef USE_MORPHTARGETS',
        ' attribute vec3 morphTarget0;',
        ' attribute vec3 morphTarget1;',
        ' attribute vec3 morphTarget2;',
        ' attribute vec3 morphTarget3;',
        ' #ifdef USE_MORPHNORMALS',
        '   attribute vec3 morphNormal0;',
        '   attribute vec3 morphNormal1;',
        '   attribute vec3 morphNormal2;',
        '   attribute vec3 morphNormal3;',
        ' #else',
        '   attribute vec3 morphTarget4;',
        '   attribute vec3 morphTarget5;',
        '   attribute vec3 morphTarget6;',
        '   attribute vec3 morphTarget7;',
        ' #endif',
        '#endif',
        '#ifdef USE_SKINNING',
        ' attribute vec4 skinIndex;',
        ' attribute vec4 skinWeight;',
        '#endif',
        '\n'
      ].where((s) => s != '').join('\n');

      prefixFragment = [
        (bumpMap ||
                normalMap ||
                flatShading ||
                (material is ShaderMaterial) && material.derivatives)
            ? '#extension GL_OES_standard_derivatives : enable'
            : '',
        'precision $precision float;',
        'precision $precision int;',
        customDefines,
        '#define MAX_DIR_LIGHTS $maxDirLights',
        '#define MAX_POINT_LIGHTS $maxPointLights',
        '#define MAX_SPOT_LIGHTS $maxSpotLights',
        '#define MAX_HEMI_LIGHTS $maxHemiLights',
        '#define MAX_SHADOWS $maxShadows',
        nn(alphaTest)
            ? '#define ALPHATEST ${alphaTest.toStringAsPrecision(2)}'
            : '',
        renderer.gammaInput ? '#define GAMMA_INPUT' : '',
        renderer.gammaOutput ? '#define GAMMA_OUTPUT' : '',
        '#define GAMMA_FACTOR $gammaFactorDefine',
        (useFog && fog) ? '#define USE_FOG' : '',
        (useFog && fogExp) ? '#define FOG_EXP2' : '',
        map ? '#define USE_MAP' : '',
        envMap ? '#define USE_ENVMAP' : '',
        envMap ? '#define $envMapTypeDefine' : '',
        envMap ? '#define $envMapModeDefine' : '',
        envMap ? '#define $envMapBlendingDefine' : '',
        lightMap ? '#define USE_LIGHTMAP' : '',
        aoMap ? '#define USE_AOMAP' : '',
        bumpMap ? '#define USE_BUMPMAP' : '',
        normalMap ? '#define USE_NORMALMAP' : '',
        specularMap ? '#define USE_SPECULARMAP' : '',
        alphaMap ? '#define USE_ALPHAMAP' : '',
        vertexColors != NoColors ? '#define USE_COLOR' : '',
        flatShading ? '#define FLAT_SHADED' : '',
        metal ? '#define METAL' : '',
        doubleSided ? '#define DOUBLE_SIDED' : '',
        flipSided ? '#define FLIP_SIDED' : '',
        shadowMapEnabled ? '#define USE_SHADOWMAP' : '',
        shadowMapEnabled ? '#define $shadowMapTypeDefine' : '',
        shadowMapDebug ? '#define SHADOWMAP_DEBUG' : '',
        shadowMapCascade ? '#define SHADOWMAP_CASCADE' : '',
        logarithmicDepthBuffer ? '#define USE_LOGDEPTHBUF' : '',
        logarithmicDepthBuffer &&
                renderer.extensions.get('EXT_frag_depth') != null
            ? '#define USE_LOGDEPTHBUF_EXT'
            : '',
        'uniform mat4 viewMatrix;',
        'uniform vec3 cameraPosition;',
        '\n'
      ].where((s) => s != '').join('\n');
    }

    var vertexGlsl = prefixVertex + vertexShader;
    var fragmentGlsl = prefixFragment + fragmentShader;

    var glVertexShader = new WebGLShader(_gl, gl.VERTEX_SHADER, vertexGlsl)();
    var glFragmentShader =
        new WebGLShader(_gl, gl.FRAGMENT_SHADER, fragmentGlsl)();

    _gl.attachShader(program, glVertexShader);
    _gl.attachShader(program, glFragmentShader);

    if (index0AttributeName != null) {
      // Force a particular attribute to index 0.
      // because potentially expensive emulation is done by browser if attribute 0 is disabled.
      // And, color, for example is often automatically bound to index 0 so disabling it

      _gl.bindAttribLocation(program, 0, index0AttributeName);
    }

    _gl.linkProgram(program);

    var programLogInfo = _gl.getProgramInfoLog(program);
    var vertexErrorLogInfo = _gl.getShaderInfoLog(glVertexShader);
    var fragmentErrorLogInfo = _gl.getShaderInfoLog(glFragmentShader);

    if (!_gl.getProgramParameter(program, gl.LINK_STATUS)) {
      error('WebGLProgram: shader error: ${_gl.getError()} gl.VALIDATE_STATUS' +
          '${_gl.getProgramParameter(program, gl.VALIDATE_STATUS)} gl.getProgramInfoLog' +
          '$programLogInfo $vertexErrorLogInfo $fragmentErrorLogInfo');
    }

    if (programLogInfo != '') {
      warn('WebGLProgram: gl.getProgramInfoLog() $programLogInfo');
    }

    // clean up

    _gl.deleteShader(glVertexShader);
    _gl.deleteShader(glFragmentShader);

    //

    this.program = program;
    this.vertexShader = glVertexShader;
    this.fragmentShader = glFragmentShader;
  }

  Map _cachedUniforms;
  Map _cachedAttributes;

  // set up caching for uniform locations
  Map getUniforms() {
    if (_cachedUniforms != null) {
      return _cachedUniforms;
    }

    _cachedUniforms = fetchUniformLocations(_gl, program);;
    return _cachedUniforms;
  }

  // set up caching for attribute locations
  Map getAttributes() {
    if (_cachedAttributes != null) {
      return _cachedAttributes;
    }

    _cachedAttributes = fetchAttributeLocations(_gl, program);;
    return _cachedAttributes;
  }
}
