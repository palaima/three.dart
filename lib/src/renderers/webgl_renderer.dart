/*
 * @author supereggbert / http://www.paulbrunt.co.uk/
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 * @author szimek / https://github.com/szimek/
 */

part of three.renderers;

/// The WebGL renderer displays your beautifully crafted scenes using WebGL,
/// if your device supports it.
///
/// This renderer has way better performance than CanvasRenderer.
class WebGLRenderer {
  WebGLState state;
  WebGLExtensions extensions;
  WebGLObjects objects;

  CanvasElement _canvas;
  gl.RenderingContext _gl;

  int _width, _height;

  double _pixelRatio = 1.0;

  String _precision;
  bool _premultipliedAlpha;
  bool _logarithmicDepthBuffer;

  Color _clearColor = new Color.black();
  double _clearAlpha = 0.0;

  List lights = [];

  List _opaqueObjects = [];
  List _transparentObjects = [];

  List _sprites = [];
  List _lensFlares = [];

  // GPU capabilities

  int _maxTextures;
  int _maxVertexTextures;
  int _maxTextureSize;
  int _maxCubemapSize;

  bool _supportsVertexTextures;
  bool _supportsBoneTextures;
  bool _supportsInstancedArrays;

  //

  gl.ShaderPrecisionFormat _vertexShaderPrecisionHighpFloat;
  gl.ShaderPrecisionFormat _vertexShaderPrecisionMediumpFloat;

  gl.ShaderPrecisionFormat _fragmentShaderPrecisionHighpFloat;
  gl.ShaderPrecisionFormat _fragmentShaderPrecisionMediumpFloat;

  //

  // public properties

  CanvasElement get domElement => _canvas;

  gl.RenderingContext get context => _gl;

  // clearing
  bool autoClear = true;
  bool autoClearColor = true;
  bool autoClearDepth = true;
  bool autoClearStencil = true;

  // scene graph
  bool sortObjects = true;

  // physically based shading
  double gammaFactor = 2.0; // for backwards compatibility
  bool gammaInput = false;
  bool gammaOutput = false;

  // shadow map
  WebGLShadowMap shadowMap;

  // morphs
  int maxMorphTargets = 8;
  int maxMorphNormals = 4;

  // flags
  bool autoScaleCubemaps = true;

  // info
  WebGLRendererInfo info = new WebGLRendererInfo();

  // internal properties

  List<WebGLProgram> _programs = [];

  // internal state cache

  int _currentProgram;
  gl.Framebuffer _currentFramebuffer;
  int _currentMaterialId = -1;
  GeometryProgram _currentGeometryProgram = new GeometryProgram();
  Camera _currentCamera;

  int _usedTextureUnits = 0;

  int _viewportX = 0;
  int _viewportY = 0;
  int _viewportWidth;
  int _viewportHeight;
  int _currentWidth = 0;
  int _currentHeight = 0;

  // frustum
  Frustum _frustum = new Frustum();

  // camera matrices cache
  Matrix4 _projScreenMatrix = new Matrix4.identity();

  Vector3 _vector3 = new Vector3.zero();

  // light arrays cache
  Vector3 _direction = new Vector3.zero();

  // light arrays cache
  bool _lightsNeedUpdate = true;

  Map _lights = {
    'ambient': new Float32List.fromList([0.0, 0.0, 0.0]),
    'directional': {
      'length': 0,
      'colors': new Float32List(0),
      'positions': new Float32List(0)
    },
    'point': {
      'length': 0,
      'colors': new Float32List(0),
      'positions': new Float32List(0),
      'distances': new Float32List(0),
      'decays': new Float32List(0)
    },
    'spot': {
      'length': 0,
      'colors': new Float32List(0),
      'positions': new Float32List(0),
      'distances': new Float32List(0),
      'directions': new Float32List(0),
      'anglesCos': new Float32List(0),
      'exponents': new Float32List(0),
      'decays': new Float32List(0)
    },
    'hemi': {
      'length': 0,
      'skyColors': new Float32List(0),
      'groundColors': new Float32List(0),
      'positions': new Float32List(0)
    }
  };

  WebGLRenderer({CanvasElement canvas, gl.RenderingContext context,
      String precision: 'highp', bool alpha: false, bool depth: true,
      bool stencil: true, bool antialias: false, bool premultipliedAlpha: true,
      bool preserveDrawingBuffer: false, bool logarithmicDepthBuffer: false}) {
    _canvas = canvas != null ? canvas : new CanvasElement();

    _precision = precision;
    _premultipliedAlpha = premultipliedAlpha;
    _logarithmicDepthBuffer = logarithmicDepthBuffer;

    _width = _canvas.width;
    _height = _canvas.height;

    _viewportWidth = _canvas.width;
    _viewportHeight = _canvas.height;

    // initialize

    var attributes = {
      'alpha': alpha,
      'depth': depth,
      'stencil': stencil,
      'antialias': antialias,
      'premultipliedAlpha': premultipliedAlpha,
      'preserveDrawingBuffer': preserveDrawingBuffer
    };

    _gl = [
      context,
      _canvas.getContext('webgl', attributes),
      _canvas.getContext('experimental-webgl', attributes)
    ].firstWhere((e) => e != null, orElse: () => null);

    if (_gl == null) {
      if (_canvas.getContext('webgl') != null) {
        throw new Exception(
            'Error creating WebGL context with your selected attributes.');
      } else {
        throw new Exception('Error creating WebGL context.');
      }
    }

    _canvas.onWebGlContextLost.listen((event) {
      event.preventDefault();

      resetGLState();
      setDefaultGLState();

      objects.objects = {};
    });

    state = new WebGLState(_gl, paramThreeToGL);

    extensions = new WebGLExtensions(_gl);
    objects = new WebGLObjects(_gl, info);

    extensions.get('OES_texture_float');
    extensions.get('OES_texture_float_linear');
    extensions.get('OES_texture_half_float');
    extensions.get('OES_texture_half_float_linear');
    extensions.get('OES_standard_derivatives');
    extensions.get('ANGLE_instanced_arrays');

    if (extensions.get('OES_element_index_uint') != null) {
      BufferGeometry.maxIndex = 4294967296;
    }

    if (logarithmicDepthBuffer) {
      extensions.get('EXT_frag_depth');
    }

    // shadow map

    shadowMap = new WebGLShadowMap(this, lights, objects);

    setDefaultGLState();

    // GPU capabilities

    _maxTextures = _gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS);
    _maxVertexTextures = _gl.getParameter(gl.MAX_VERTEX_TEXTURE_IMAGE_UNITS);
    _maxTextureSize = _gl.getParameter(gl.MAX_TEXTURE_SIZE);
    _maxCubemapSize = _gl.getParameter(gl.MAX_CUBE_MAP_TEXTURE_SIZE);

    _supportsVertexTextures = _maxVertexTextures > 0;
    _supportsBoneTextures =
        _supportsVertexTextures && extensions.get('OES_texture_float') != null;
    _supportsInstancedArrays = extensions.get('ANGLE_instanced_arrays') != null;

    //

    _vertexShaderPrecisionHighpFloat =
        _gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.HIGH_FLOAT);
    _vertexShaderPrecisionMediumpFloat =
        _gl.getShaderPrecisionFormat(gl.VERTEX_SHADER, gl.MEDIUM_FLOAT);

    _fragmentShaderPrecisionHighpFloat =
        _gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_FLOAT);
    _fragmentShaderPrecisionMediumpFloat =
        _gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.MEDIUM_FLOAT);

    // clamp precision to maximum available

    var highpAvailable = _vertexShaderPrecisionHighpFloat.precision > 0 &&
        _fragmentShaderPrecisionHighpFloat.precision > 0;
    var mediumpAvailable = _vertexShaderPrecisionMediumpFloat.precision > 0 &&
        _fragmentShaderPrecisionMediumpFloat.precision > 0;

    if (_precision == 'highp' && !highpAvailable) {
      if (mediumpAvailable) {
        _precision = 'mediump';
        warn('WebGLRenderer: highp not supported, using mediump.');
      } else {
        _precision = 'lowp';
        warn('WebGLRenderer: highp and mediump not supported, using lowp.');
      }
    }

    if (_precision == 'mediump' && !mediumpAvailable) {
      _precision = 'lowp';
      warn('WebGLRenderer: mediump not supported, using lowp.');
    }

    // Plugins

    //var spritePlugin = new SpritePlugin(this, _sprites);
    //var lensFlarePlugin = new LensFlarePlugin(this, _lensFlares);
  }

  void glClearColor(num r, num g, num b, num a) {
    if (_premultipliedAlpha) {
      r *= a;
      g *= a;
      b *= a;
    }

    _gl.clearColor(r, g, b, a);
  }

  void setDefaultGLState() {
    _gl.clearColor(0, 0, 0, 1);
    _gl.clearDepth(1);
    _gl.clearStencil(0);

    _gl.enable(gl.DEPTH_TEST);
    _gl.depthFunc(gl.LEQUAL);

    _gl.frontFace(gl.CCW);
    _gl.cullFace(gl.BACK);
    _gl.enable(gl.CULL_FACE);

    _gl.enable(gl.BLEND);
    _gl.blendEquation(gl.FUNC_ADD);
    _gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    _gl.viewport(_viewportX, _viewportY, _viewportWidth, _viewportHeight);

    glClearColor(_clearColor.r, _clearColor.g, _clearColor.b, _clearAlpha);
  }

  void resetGLState() {
    _currentProgram = null;
    _currentCamera = null;

    _currentGeometryProgram.reset();
    _currentMaterialId = -1;

    _lightsNeedUpdate = true;

    state.reset();
  }

  List<int> _array;

  List getCompressedTextureFormats() {
    if (_array != null) return _array;

    _array = [];

    if (extensions.get('WEBGL_compressed_texture_pvrtc') != null ||
        extensions.get('WEBGL_compressed_texture_s3tc') != null) {
      var formats = _gl.getParameter(gl.COMPRESSED_TEXTURE_FORMATS);

      for (var i = 0; i < formats.length; i++) {
        _array.add(formats[i]);
      }
    }

    return _array;
  }

  // API

  gl.RenderingContext getContext() => _gl;

  void forceContextLoss() {
    (extensions.get('WEBGL_lose_context') as gl.LoseContext).loseContext();
  }

  bool get supportsVertexTextures => _supportsVertexTextures;

  bool get supportsInstancedArrays => _supportsInstancedArrays;

  bool get supportsFloatTextures => extensions.get('OES_texture_float') != null;

  bool get supportsHalfFloatTextures =>
      extensions.get('OES_texture_half_float') != null;

  bool get supportsStandardDerivatives =>
      extensions.get('OES_standard_derivatives') != null;

  bool get supportsCompressedTextureS3TC =>
      extensions.get('WEBGL_compressed_texture_s3tc') != null;

  bool get supportsCompressedTexturePVRTC =>
      extensions.get('WEBGL_compressed_texture_pvrtc') != null;

  bool get supportsBlendMinMax => extensions.get('EXT_blend_minmax') != null;

  static int _maxAnisotropy;
  int getMaxAnisotropy() {
    if (_maxAnisotropy != null) return _maxAnisotropy;

    var extension = extensions.get('EXT_texture_filter_anisotropic');

    if (extension != null) {
      _maxAnisotropy = _gl.getParameter(
          gl.ExtTextureFilterAnisotropic.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
    } else {
      _maxAnisotropy = 0;
    }

    return _maxAnisotropy;
  }

  String getPrecision() => _precision;

  double getPixelRatio() => _pixelRatio;

  void setPixelRatio(double value) {
    if (value != null) _pixelRatio = value;
  }

  Map<String, int> getSize() => {'width': _width, 'height': _height};

  void setSize(int width, int height, {bool updateStyle: false}) {
    _width = width;
    _height = height;

    _canvas.width = (width * _pixelRatio).toInt();
    _canvas.height = (height * _pixelRatio).toInt();

    if (updateStyle) {
      _canvas.style.width = '${width}px';
      _canvas.style.height = '${height}px';
    }

    setViewport(0, 0, width, height);
  }

  void setViewport(int x, int y, int width, int height) {
    _viewportX = (x * _pixelRatio).toInt();
    _viewportY = (y * _pixelRatio).toInt();
    _viewportWidth = (width * _pixelRatio).toInt();
    _viewportHeight = (height * _pixelRatio).toInt();
    _gl.viewport(_viewportX, _viewportY, _viewportWidth, _viewportHeight);
  }

  void setScissor(int x, int y, int width, int height) {
    var _x = (x * _pixelRatio).toInt();
    var _y = (y * _pixelRatio).toInt();
    var _width = (width * _pixelRatio).toInt();
    var _height = (height * _pixelRatio).toInt();
    _gl.scissor(_x, _y, _width, _height);
  }

  void enableScissorTest(bool enable) {
    if (enable) {
      _gl.enable(gl.SCISSOR_TEST);
    } else {
      _gl.disable(gl.SCISSOR_TEST);
    }
  }

  // Clearing

  Color getClearColor() => _clearColor;

  void setClearColor(color, [double alpha = 1.0]) {
    if (color is num) color = new Color(color);
    _clearColor.setFrom(color);
    _clearAlpha = alpha;
    glClearColor(_clearColor.r, _clearColor.g, _clearColor.b, _clearAlpha);
  }

  double getClearAlpha() => _clearAlpha;

  void setClearAlpha(double alpha) {
    _clearAlpha = alpha;
    glClearColor(_clearColor.r, _clearColor.g, _clearColor.b, _clearAlpha);
  }

  void clear({bool color: true, bool depth: true, bool stencil: true}) {
    var bits = 0;

    if (color) bits |= gl.COLOR_BUFFER_BIT;
    if (depth) bits |= gl.DEPTH_BUFFER_BIT;
    if (stencil) bits |= gl.STENCIL_BUFFER_BIT;

    _gl.clear(bits);
  }

  void clearColor() {
    _gl.clear(gl.COLOR_BUFFER_BIT);
  }

  void clearDepth() {
    _gl.clear(gl.DEPTH_BUFFER_BIT);
  }

  void clearStencil() {
    _gl.clear(gl.STENCIL_BUFFER_BIT);
  }

  void clearTarget(WebGLRenderTarget renderTarget,
      {bool color: true, bool depth: true, bool stencil: true}) {
    setRenderTarget(renderTarget);
    clear(color: color, depth: depth, stencil: stencil);
  }

  // Events

  void onTextureDispose(Texture texture) {
    texture['_onDisposeSubscription'].cancel();
    deallocateTexture(texture);
    info.memory.textures--;
  }

  void onRenderTargetDispose(WebGLRenderTarget renderTarget) {
    renderTarget['_onDisposeSubscription'].cancel();
    deallocateRenderTarget(renderTarget);
    info.memory.textures--;
  }

  void onMaterialDispose(Material material) {
    material['_onDisposeSubscription'].cancel();
    deallocateMaterial(material);
  }

  // Buffer deallocation

  void deallocateTexture(Texture texture) {
    if (texture.image != null &&
        texture is ImageList &&
        texture.image.__webglTextureCube != null) {
      // cube texture
      _gl.deleteTexture(texture.image.__webglTextureCube);

      texture.image.__webglTextureCube = null;
    } else {
      // 2D texture
      if (texture['__webglInit'] == null) return;

      _gl.deleteTexture(texture['__webglTexture']);

      texture['__webglTexture'] = null;
      texture['__webglInit'] = false;
    }
  }

  void deallocateRenderTarget(WebGLRenderTarget renderTarget) {
    if (renderTarget == null || renderTarget['__webglTexture'] == null) return;

    _gl.deleteTexture(renderTarget['__webglTexture']);

    renderTarget['__webglTexture'] = null;

    if (renderTarget is WebGLRenderTargetCube) {
      for (var i = 0; i < 6; i++) {
        _gl.deleteFramebuffer(renderTarget.__webglFramebuffer[i]);
        _gl.deleteRenderbuffer(renderTarget.__webglRenderbuffer[i]);
      }
    } else {
      _gl.deleteFramebuffer(renderTarget.__webglFramebuffer);
      _gl.deleteRenderbuffer(renderTarget.__webglRenderbuffer);
    }

    renderTarget.__webglFramebuffer = null;
    renderTarget.__webglRenderbuffer = null;
  }

  void deallocateMaterial(Material material) {
    var program = material['_program'].program;

    if (program == null) return;

    material['_program'] = null;

    // only deallocate GL program if this was the last use of shared program
    // assumed there is only single copy of any program in the _programs list
    // (that's how it's constructed)

    var deleteProgram = false;

    for (var i = 0; i < _programs.length; i++) {
      var programInfo = _programs[i];

      if (programInfo.program == program) {
        programInfo.usedTimes--;

        if (programInfo.usedTimes == 0) {
          deleteProgram = true;
        }

        break;
      }
    }

    if (deleteProgram) {
      var newPrograms = [];

      for (var i = 0; i < _programs.length; i++) {
        var programInfo = _programs[i];

        if (programInfo.program != program) {
          newPrograms.add(programInfo);
        }
      }

      _programs = newPrograms;
      _gl.deleteProgram(program);
      info.memory.programs--;
    }
  }

  // Buffer rendering
  void renderBufferImmediate(
      ImmediateRenderObject object, WebGLProgram program, Material material) {
    state.initAttributes();

    if (object.hasPositions && object['__webglVertexBuffer'] == null) {
      object['__webglVertexBuffer'] = _gl.createBuffer();
    }
    if (object.hasNormals && object['__webglNormalBuffer'] == null) {
      object['__webglNormalBuffer'] = _gl.createBuffer();
    }
    if (object.hasUvs && object['__webglUVBuffer'] == null) {
      object['__webglUVBuffer'] = _gl.createBuffer();
    }
    if (object.hasColors && object['__webglColorBuffer'] == null) {
      object['__webglColorBuffer'] = _gl.createBuffer();
    }

    var attributes = program.getAttributes();

    if (object.hasPositions) {
      _gl.bindBuffer(gl.ARRAY_BUFFER, object['__webglVertexBuffer']);
      _gl.bufferDataTyped(
          gl.ARRAY_BUFFER, object.positionArray, gl.DYNAMIC_DRAW);

      state.enableAttribute(attributes['position']);

      _gl.vertexAttribPointer(attributes['position'], 3, gl.FLOAT, false, 0, 0);
    }

    if (object.hasNormals) {
      _gl.bindBuffer(gl.ARRAY_BUFFER, object['__webglNormalBuffer']);

      if (material is! MeshPhongMaterial && material.shading == FlatShading) {
        for (var i = 0; i < object.count * 3; i += 9) {
          var normalArray = object.normalArray;

          var nax = normalArray[i + 0];
          var nay = normalArray[i + 1];
          var naz = normalArray[i + 2];

          var nbx = normalArray[i + 3];
          var nby = normalArray[i + 4];
          var nbz = normalArray[i + 5];

          var ncx = normalArray[i + 6];
          var ncy = normalArray[i + 7];
          var ncz = normalArray[i + 8];

          var nx = (nax + nbx + ncx) / 3;
          var ny = (nay + nby + ncy) / 3;
          var nz = (naz + nbz + ncz) / 3;

          normalArray[i + 0] = nx;
          normalArray[i + 1] = ny;
          normalArray[i + 2] = nz;

          normalArray[i + 3] = nx;
          normalArray[i + 4] = ny;
          normalArray[i + 5] = nz;

          normalArray[i + 6] = nx;
          normalArray[i + 7] = ny;
          normalArray[i + 8] = nz;
        }
      }

      _gl.bufferDataTyped(gl.ARRAY_BUFFER, object.normalArray, gl.DYNAMIC_DRAW);
      state.enableAttribute(attributes['normal']);
      _gl.vertexAttribPointer(attributes['normal'], 3, gl.FLOAT, false, 0, 0);
    }

    var mat = material;

    if (object.hasUvs && mat is Mapping && mat.map != null) {
      _gl.bindBuffer(gl.ARRAY_BUFFER, object['__webglUVBuffer']);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, object.uvArray, gl.DYNAMIC_DRAW);

      state.enableAttribute(attributes['uv']);

      _gl.vertexAttribPointer(attributes['uv'], 2, gl.FLOAT, false, 0, 0);
    }

    if (object.hasColors && material.vertexColors != NoColors) {
      _gl.bindBuffer(gl.ARRAY_BUFFER, object['__webglColorBuffer']);
      _gl.bufferDataTyped(gl.ARRAY_BUFFER, object.colorArray, gl.DYNAMIC_DRAW);

      state.enableAttribute(attributes['color']);

      _gl.vertexAttribPointer(attributes['color'], 3, gl.FLOAT, false, 0, 0);
    }

    state.disableUnusedAttributes();

    _gl.drawArrays(gl.TRIANGLES, 0, object.count);

    object.count = 0;
  }

  void setupVertexAttributes(Material material, WebGLProgram program,
      BufferGeometry geometry, int startIndex) {
    var mat = material;
    var extension;

    if (geometry is InstancedBufferGeometry) {
      extension = extensions.get('ANGLE_instanced_arrays');
      if (extension == null) {
        error('WebGLRenderer.setupVertexAttributes: using InstancedBufferGeometry' +
            'but hardware does not support extension ANGLE_instanced_arrays.');
        return;
      }
    }

    var geometryAttributes = geometry.attributes;

    var programAttributes = program.getAttributes();

    var materialDefaultAttributeValues =
        material is ShaderMaterial ? material.defaultAttributeValues : null;

    programAttributes.forEach((name, programAttribute) {
      if (programAttribute >= 0) {
        var geometryAttribute = geometryAttributes[name];

        if (geometryAttribute != null) {
          var size = geometryAttribute.itemSize;
          state.enableAttribute(programAttribute);

          if (geometryAttribute is InterleavedBufferAttribute) {
            var data = geometryAttribute.data;
            var stride = data.stride;
            var offset = geometryAttribute.offset;

            geometryAttribute.data.buffer.bind(gl.ARRAY_BUFFER);
            _gl.vertexAttribPointer(programAttribute, size, gl.FLOAT, false,
                stride * data.bytesPerElement,
                (startIndex * stride + offset) * data.bytesPerElement);

            if (data is InstancedInterleavedBuffer) {
              if (extension == null) {
                error('WebGLRenderer.setupVertexAttributes: using InstancedBufferAttribute' +
                    'but hardware does not support extension ANGLE_instanced_arrays.');
                return;
              }

              extension.vertexAttribDivisorAngle(
                  programAttribute, data.meshPerAttribute);

              if (geometry.maxInstancedCount == null) {
                geometry.maxInstancedCount =
                    data.meshPerAttribute * (data.array.length ~/ data.stride);
              }
            }
          } else {
            geometryAttribute.buffer.bind(gl.ARRAY_BUFFER);
            _gl.vertexAttribPointer(programAttribute, size, gl.FLOAT, false, 0,
                startIndex * size * 4); // 4 bytes per Float32

            if (geometryAttribute is InstancedBufferAttribute &&
                geometry is InstancedBufferGeometry) {
              if (extension == null) {
                error('WebGLRenderer.setupVertexAttributes: using InstancedBufferAttribute' +
                    'but hardware does not support extension ANGLE_instanced_arrays.');
                return;
              }

              extension.vertexAttribDivisorAngle(
                  programAttribute, geometryAttribute.meshPerAttribute);

              if (geometry.maxInstancedCount == null) {
                geometry.maxInstancedCount =
                    geometryAttribute.meshPerAttribute *
                        (geometryAttribute.array.length ~/
                            geometryAttribute.itemSize);
              }
            }
          }
        } else if (materialDefaultAttributeValues != null) {
          var value = materialDefaultAttributeValues[name];

          if (value != null) {
            switch (value.length) {
              case 2:
                _gl.vertexAttrib2fv(programAttribute, value);
                break;
              case 3:
                _gl.vertexAttrib3fv(programAttribute, value);
                break;
              case 4:
                _gl.vertexAttrib4fv(programAttribute, value);
                break;
              default:
                _gl.vertexAttrib1fv(programAttribute, value);
            }
          }
        }
      }
    });

    state.disableUnusedAttributes();
  }

  static final GeometryProgram _geometryProgram = new GeometryProgram();

  void renderBufferDirect(
      Camera camera, List lights, Fog fog, Material material, Object3D object) {
    if (material.visible == false) return;

    var geometry = objects.geometries.get(object);
    var program = setProgram(camera, lights, fog, material, object);

    var updateBuffers = false,
        wireframeBit =
        (material is Wireframe) && (material as Wireframe).wireframe ? 1 : 0;

    _geometryProgram.set(geometry.id, program.id, wireframeBit);

    if (_geometryProgram != _currentGeometryProgram) {
      _currentGeometryProgram.set(_geometryProgram.geometryId,
          _geometryProgram.programId, _geometryProgram.wireframeBit);
      updateBuffers = true;
    }

    if (updateBuffers) {
      state.initAttributes();
    }

    if (object is Mesh) {
      renderMesh(material, geometry, object, program, updateBuffers);
    } else if (object is Line) {
      renderLine(material, geometry, object, program, updateBuffers);
    } else if (object is PointCloud) {
      renderPointCloud(material, geometry, object, program, updateBuffers);
    }
  }

  // render mesh

  void renderMesh(Material material, BufferGeometry geometry, Object3D object,
      WebGLProgram program, bool updateBuffers) {
    var mode = (material as Wireframe).wireframe ? gl.LINES : gl.TRIANGLES;

    var index = geometry.attributes['index'];

    if (index != null) {
      // indexed triangles
      var type, size;

      if (index.array is Uint32List &&
          extensions.get('OES_element_index_uint') != null) {
        type = gl.UNSIGNED_INT;
        size = 4;
      } else {
        type = gl.UNSIGNED_SHORT;
        size = 2;
      }

      var offsets = geometry.offsets;

      if (offsets.length == 0) {
        if (updateBuffers) {
          setupVertexAttributes(material, program, geometry, 0);
          index.buffer.bind(gl.ELEMENT_ARRAY_BUFFER);
        }

        if (geometry is InstancedBufferGeometry &&
            geometry.maxInstancedCount > 0) {
          gl.AngleInstancedArrays extension =
              extensions.get('ANGLE_instanced_arrays');

          if (extension == null) {
            error('THREE.WebGLRenderer.renderMesh: using InstancedBufferGeometry' +
                'but hardware does not support extension ANGLE_instanced_arrays.');
            return;
          }

          extension.drawElementsInstancedAngle(mode, index.array.length, type,
              0, geometry.maxInstancedCount); // Draw the instanced meshes

        } else {
          _gl.drawElements(mode, index.array.length, type, 0);
        }

        info.render.calls++;
        info.render.vertices +=
            index.array.length; // not really true, here vertices can be shared
        info.render.faces += index.array.length ~/ 3;
      } else {
        // if there is more than 1 chunk
        // must set attribute pointers to use new offsets for each chunk
        // even if geometry and materials didn't change

        updateBuffers = true;

        for (var i = 0; i < offsets.length; i++) {
          var startIndex = offsets[i].index;

          if (updateBuffers) {
            setupVertexAttributes(material, program, geometry, startIndex);
            index.buffer.bind(gl.ELEMENT_ARRAY_BUFFER);
          }

          // render indexed triangles

          if (geometry is InstancedBufferGeometry && offsets[i].instances > 0) {
            gl.AngleInstancedArrays extension =
                extensions.get('ANGLE_instanced_arrays');

            if (extension == null) {
              error('WebGLRenderer.renderMesh: using InstancedBufferGeometry' +
                  'but hardware does not support extension ANGLE_instanced_arrays.');
              return;
            }

            extension.drawElementsInstancedAngle(mode, offsets[i].count, type,
                offsets[i].start * size,
                offsets[i].instances); // Draw the instanced meshes

          } else {
            _gl.drawElements(
                mode, offsets[i].count, type, offsets[i].start * size);
          }

          info.render.calls++;
          info.render.vertices +=
              offsets[i].count; // not really true, here vertices can be shared
          info.render.faces += offsets[i].count ~/ 3;
        }
      }
    } else {
      // non-indexed triangles

      var offsets = geometry.offsets;

      if (offsets.length == 0) {
        if (updateBuffers) {
          setupVertexAttributes(material, program, geometry, 0);
        }

        var position = geometry.attributes['position'];

        // render non-indexed triangles

        if (geometry is InstancedBufferGeometry &&
            geometry.maxInstancedCount > 0) {
          gl.AngleInstancedArrays extension =
              extensions.get('ANGLE_instanced_arrays');

          if (extension == null) {
            error('THREE.WebGLRenderer.renderMesh: using THREE.InstancedBufferGeometry' +
                'but hardware does not support extension ANGLE_instanced_arrays.');
            return;
          }

          if (position is InterleavedBufferAttribute) {
            extension.drawArraysInstancedAngle(mode, 0,
                position.data.array.length ~/ position.data.stride,
                geometry.maxInstancedCount); // Draw the instanced meshes
          } else {
            extension.drawArraysInstancedAngle(mode, 0,
                position.array.length ~/ position.itemSize,
                geometry.maxInstancedCount); // Draw the instanced meshes
          }
        } else {
          if (position is InterleavedBufferAttribute) {
            _gl.drawArrays(
                mode, 0, position.data.array.length ~/ position.data.stride);
          } else {
            _gl.drawArrays(mode, 0, position.array.length ~/ position.itemSize);
          }
        }

        info.render.calls++;
        info.render.vertices += position.array.length ~/ position.itemSize;
        info.render.faces += position.array.length ~/ (3 * position.itemSize);
      } else {
        // if there is more than 1 chunk
        // must set attribute pointers to use new offsets for each chunk
        // even if geometry and materials didn't change

        if (updateBuffers) {
          setupVertexAttributes(material, program, geometry, 0);
        }

        for (var i = 0; i < offsets.length; i++) {
          // render non-indexed triangles

          if (geometry is InstancedBufferGeometry) {
            error(
                'THREE.WebGLRenderer.renderMesh: cannot use drawCalls with THREE.InstancedBufferGeometry.');
            return;
          } else {
            _gl.drawArrays(mode, offsets[i].start, offsets[i].count);
          }

          info.render.calls++;
          info.render.vertices += offsets[i].count;
          info.render.faces += (offsets[i].count) ~/ 3;
        }
      }
    }
  }

  void renderLine(Material material, BufferGeometry geometry, Line object,
      WebGLProgram program, bool updateBuffers) {
    var mode = object is LineSegments ? gl.LINES : gl.LINE_STRIP;

    state.setLineWidth((material as LineMaterial).linewidth * _pixelRatio);

    var index = geometry.attributes['index'];

    if (index != null) {
      // indexed points
      var type, size;

      if (index.array is Uint32List) {
        type = gl.UNSIGNED_INT;
        size = 4;
      } else {
        type = gl.UNSIGNED_SHORT;
        size = 2;
      }

      var offsets = geometry.offsets;

      if (offsets.length == 0) {
        if (updateBuffers) {
          setupVertexAttributes(material, program, geometry, 0);
          index.buffer.bind(gl.ELEMENT_ARRAY_BUFFER);
        }

        _gl.drawElements(mode, index.array.length, type, 0);

        info.render.calls++;
        info.render.points += index.array.length;
      } else {
        // if there is more than 1 chunk
        // must set attribute pointers to use new offsets for each chunk
        // even if geometry and materials didn't change

        if (offsets.length > 1) updateBuffers = true;

        for (var i = 0; i < offsets.length; i++) {
          var startIndex = offsets[i].index;

          if (updateBuffers) {
            setupVertexAttributes(material, program, geometry, startIndex);
            index.buffer.bind(gl.ELEMENT_ARRAY_BUFFER);
          }

          // render indexed points

          _gl.drawElements(
              mode, offsets[i].count, type, offsets[i].start * size);

          info.render.calls++;
          info.render.points += offsets[i].count;
        }
      }
    } else {
      // non-indexed points
      if (updateBuffers) {
        setupVertexAttributes(material, program, geometry, 0);
      }

      var position = geometry.attributes['position'];
      var offsets = geometry.offsets;

      if (offsets.length == 0) {
        _gl.drawArrays(mode, 0, position.array.length ~/ 3);

        info.render.calls++;
        info.render.points += position.array.length ~/ 3;
      } else {
        for (var i = 0; i < offsets.length; i++) {
          _gl.drawArrays(mode, offsets[i].index, offsets[i].count);

          info.render.calls++;
          info.render.points += offsets[i].count;
        }
      }
    }
  }

  void renderPointCloud(Material material, BufferGeometry geometry,
      Object3D object, WebGLProgram program, bool updateBuffers) {
    var mode = gl.POINTS;

    var index = geometry.attributes['index'];

    if (index != null) {
      // indexed points
      var type, size;

      if (index.array is Uint32List &&
          extensions.get('OES_element_index_uint') != null) {
        type = gl.UNSIGNED_INT;
        size = 4;
      } else {
        type = gl.UNSIGNED_SHORT;
        size = 2;
      }

      var offsets = geometry.offsets;

      if (offsets.length == 0) {
        if (updateBuffers) {
          setupVertexAttributes(material, program, geometry, 0);
          index.buffer.bind(gl.ELEMENT_ARRAY_BUFFER);
        }

        _gl.drawElements(mode, index.array.length, type, 0);

        info.render.calls++;
        info.render.points += index.array.length;
      } else {

        // if there is more than 1 chunk
        // must set attribute pointers to use new offsets for each chunk
        // even if geometry and materials didn't change

        if (offsets.length > 1) updateBuffers = true;

        for (var i = 0; i < offsets.length; i++) {
          var startIndex = offsets[i].index;

          if (updateBuffers) {
            setupVertexAttributes(material, program, geometry, startIndex);
            index.buffer.bind(gl.ELEMENT_ARRAY_BUFFER);
          }

          // render indexed points

          _gl.drawElements(mode, offsets[i].count, type,
              offsets[i].start * size); // 2 bytes per Uint16Array

          info.render.calls++;
          info.render.points +=
              offsets[i].count; // not really true, here vertices can be shared
        }
      }
    } else {
      // non-indexed points
      if (updateBuffers) {
        setupVertexAttributes(material, program, geometry, 0);
      }

      var position = geometry.attributes['position'];
      var offsets = geometry.offsets;

      if (offsets.length == 0) {
        _gl.drawArrays(mode, 0, position.array.length ~/ 3);

        info.render.calls++;
        info.render.points += position.array.length ~/ 3;
      } else {
        for (var i = 0; i < offsets.length; i++) {
          _gl.drawArrays(mode, offsets[i].index, offsets[i].count);

          info.render.calls++;
          info.render.points += offsets[i].count;
        }
      }
    }
  }

  // Sorting

  int painterSortStable(WebGLObject a, WebGLObject b) {
    var aMat = (a.object as MaterialObject).material;
    var bMat = (b.object as MaterialObject).material;

    if (a.object.renderOrder != b.object.renderOrder) {
      return a.object.renderOrder.compareTo(b.object.renderOrder);
    } else if (aMat.id != bMat.id) {
      return aMat.id.compareTo(bMat.id);
    } else if (a.z != b.z) {
      return a.z.compareTo(b.z);
    } else {
      return a.id.compareTo(b.id);
    }
  }

  int reversePainterSortStable(WebGLObject a, WebGLObject b) {
    if (a.object.renderOrder != b.object.renderOrder) {
      return a.object.renderOrder.compareTo(b.object.renderOrder);
    }
    if (a.z != b.z) {
      return b.z.compareTo(a.z);
    } else {
      return a.id.compareTo(b.id);
    }
  }

  // Rendering

  void render(Scene scene, Camera camera,
      {WebGLRenderTarget renderTarget, bool forceClear: false}) {
    var fog = scene.fog;

    // reset caching for this frame

    _currentGeometryProgram.reset();
    _currentMaterialId = -1;
    _currentCamera = null;
    _lightsNeedUpdate = true;

    // update scene graph

    if (scene.autoUpdate) scene.updateMatrixWorld();

    // update camera matrices and frustum

    if (camera.parent == null) camera.updateMatrixWorld();

    camera.matrixWorldInverse.copyInverse(camera.matrixWorld);

    _projScreenMatrix.multiplyMatrices(
        camera.projectionMatrix, camera.matrixWorldInverse);
    _frustum.setFromMatrix(_projScreenMatrix);

    lights.length = 0;
    _opaqueObjects.length = 0;
    _transparentObjects.length = 0;

    _sprites.length = 0;
    _lensFlares.length = 0;

    projectObject(scene);

    if (sortObjects) {
      _opaqueObjects.sort(painterSortStable);
      _transparentObjects.sort(reversePainterSortStable);
    }

    objects.update(_opaqueObjects);
    objects.update(_transparentObjects);

    //

    shadowMap.render(scene, camera);

    //

    info.render.calls = 0;
    info.render.vertices = 0;
    info.render.faces = 0;
    info.render.points = 0;

    setRenderTarget(renderTarget);

    if (autoClear || forceClear) {
      clear(
          color: autoClearColor,
          depth: autoClearDepth,
          stencil: autoClearStencil);
    }

    // set matrices for immediate objects

    for (var i = 0; i < objects.objectsImmediate.length; i++) {
      var webglObject = objects.objectsImmediate[i];
      var object = webglObject.object;

      if (object.visible) {
        setupMatrices(object, camera);
        var material = (object as MaterialObject).material;

        if (material.transparent) {
          webglObject.transparent = material;
          webglObject.opaque = null;
        } else {
          webglObject.opaque = material;
          webglObject.transparent = null;
        }
      }
    }

    if (scene.overrideMaterial != null) {
      var overrideMaterial = scene.overrideMaterial;

      setMaterial(overrideMaterial);

      renderObjects(_opaqueObjects, camera, lights, fog, overrideMaterial);
      renderObjects(_transparentObjects, camera, lights, fog, overrideMaterial);
      renderObjectsImmediate(
          objects.objectsImmediate, '', camera, lights, fog, overrideMaterial);
    } else {
      // opaque pass (front-to-back order)
      state.setBlending(blending: NoBlending);

      renderObjects(_opaqueObjects, camera, lights, fog, null);
      renderObjectsImmediate(
          objects.objectsImmediate, 'opaque', camera, lights, fog, null);

      // transparent pass (back-to-front order)

      renderObjects(_transparentObjects, camera, lights, fog, null);
      renderObjectsImmediate(
          objects.objectsImmediate, 'transparent', camera, lights, fog, null);
    }

    // custom render plugins (post pass)

    //spritePlugin.render(scene, camera); TODO
    //lensFlarePlugin.render(scene, camera, _currentWidth, _currentHeight);

    // Generate mipmap if we're using any kind of mipmap filtering

    if (renderTarget != null &&
        renderTarget.generateMipmaps &&
        renderTarget.minFilter != NearestFilter &&
        renderTarget.minFilter != LinearFilter) {
      updateRenderTargetMipmap(renderTarget);
    }

    // Ensure depth buffer writing is enabled so it can be cleared on next render

    state.setDepthTest(true);
    state.setDepthWrite(true);
    state.setColorWrite(true);
  }

  void projectObject(Object3D object) {
    if (!object.visible) return;

    if (object is Scene || object is Group) {
      // skip
    } else {
      if (object is SkinnedMesh) {
        object.skeleton.update();
      }

      objects.init(object);

      if (object is Light) {
        lights.add(object);
      } else if (object is Sprite) {
        _sprites.add(object);
      } else if (false) {
        //object is LensFlare) {
        _lensFlares.add(object);
      } else {
        var webglObject = objects.objects[object.id];

        if (webglObject != null && !object.frustumCulled ||
            (object is GeometryObject &&
                _frustum.intersectsWithObject(object))) {
          var material = (object as MaterialObject).material;

          if (material.transparent) {
            _transparentObjects.add(webglObject);
          } else {
            _opaqueObjects.add(webglObject);
          }

          if (sortObjects) {
            _vector3.setFromMatrixTranslation(object.matrixWorld);
            _vector3.applyProjection(_projScreenMatrix);
            webglObject.z = _vector3.z;
          }
        }
      }
    }

    for (var i = 0; i < object.children.length; i++) {
      projectObject(object.children[i]);
    }
  }

  void renderObjects(List renderList, Camera camera, List<Light> lights,
      Fog fog, Material overrideMaterial) {
    var material;

    for (var i = 0; i < renderList.length; i++) {
      var webglObject = renderList[i];

      var object = webglObject.object;

      setupMatrices(object, camera);

      if (overrideMaterial != null) {
        material = overrideMaterial;
      } else {
        material = object.material;

        if (material == null) continue;

        setMaterial(material);
      }

      setMaterialFaces(material);
      renderBufferDirect(camera, lights, fog, material, object);
    }
  }

  void renderObjectsImmediate(List<WebGLObject> renderList, String materialType,
      Camera camera, List<Light> lights, Fog fog, Material overrideMaterial) {
    var material;

    for (var i = 0; i < renderList.length; i++) {
      var webglObject = renderList[i];
      var object = webglObject.object;

      if (object.visible) {
        if (overrideMaterial != null) {
          material = overrideMaterial;
        } else {
          if (materialType == 'opaque') {
            material = webglObject.opaque;
          } else if (materialType == 'transparent') {
            material = webglObject.transparent;
          }

          if (material == null) continue;

          setMaterial(material);
        }

        renderImmediateObject(camera, lights, fog, material, object);
      }
    }
  }

  void renderImmediateObject(Camera camera, List<Light> lights, Fog fog,
      Material material, Object3D object) {
    var program = setProgram(camera, lights, fog, material, object);

    _currentGeometryProgram.reset();

    setMaterialFaces(material);

    if (object.immediateRenderCallback != null) {
      object.immediateRenderCallback(program, _gl, _frustum);
    } else {
      (object as ImmediateRenderObject)
          .render((object) => renderBufferImmediate(object, program, material));
    }
  }

  // Materials

  var shaderIDs = {
    'MeshDepthMaterial': 'depth',
    'MeshNormalMaterial': 'normal',
    'MeshBasicMaterial': 'basic',
    'MeshLambertMaterial': 'lambert',
    'MeshPhongMaterial': 'phong',
    'LineBasicMaterial': 'basic',
    'LineDashedMaterial': 'dashed',
    'PointCloudMaterial': 'particle_basic'
  };

  void initMaterial(
      Material material, List<Light> lights, Fog fog, Object3D object) {
    var shaderID = shaderIDs[material.type];

    // heuristics to create shader parameters according to lights in the scene
    // (not to blow over maxLights budget)

    var maxLightCount = allocateLights(lights);
    var maxShadows = allocateShadows(lights);
    var maxBones = allocateBones(object);

    nn(o) => o != null;

    var mat = material;

    var parameters = {
      'precision': _precision,
      'supportsVertexTextures': _supportsVertexTextures,
      'map': mat is Mapping && nn(mat.map),
      'envMap': mat is Mapping && nn(mat.envMap),
      'envMapMode': mat is Mapping && nn(mat.envMap) && nn(mat.envMap.mapping),
      'lightMap': mat is Mapping && nn(mat.lightMap),
      'aoMap': mat is Mapping && nn(mat.aoMap),
      'bumpMap': mat is Mapping && nn(mat.bumpMap),
      'normalMap': mat is Mapping && nn(mat.normalMap),
      'specularMap': mat is Mapping && nn(mat.specularMap),
      'alphaMap': mat is Mapping && nn(mat.alphaMap),
      'combine': mat is Mapping ? mat.combine : null, // TODO this right?

      'vertexColors': material.vertexColors,
      'fog': fog != null,
      'useFog': material.fog,
      'fogExp': fog is FogExp2,
      'flatShading': material.shading == FlatShading,
      'sizeAttenuation': mat is PointCloudMaterial && mat.sizeAttenuation,
      'logarithmicDepthBuffer': _logarithmicDepthBuffer,
      'skinning': mat is Morphing && mat.skinning,
      'maxBones': maxBones,
      'useVertexTexture': _supportsBoneTextures &&
          nn(object) &&
          object is SkinnedMesh &&
          nn(object.skeleton) &&
          nn(object.skeleton.useVertexTexture),
      'morphTargets':
          mat is Morphing && nn(mat.morphTargets) && mat.morphTargets,
      'morphNormals':
          mat is Morphing && nn(mat.morphNormals) && mat.morphNormals,
      'maxMorphTargets': maxMorphTargets,
      'maxMorphNormals': maxMorphNormals,
      'maxDirLights': maxLightCount['directional'],
      'maxPointLights': maxLightCount['point'],
      'maxSpotLights': maxLightCount['spot'],
      'maxHemiLights': maxLightCount['hemi'],
      'maxShadows': maxShadows,
      'shadowMapEnabled':
          shadowMap.enabled && object.receiveShadow && maxShadows > 0,
      'shadowMapType': shadowMap.type,
      'shadowMapDebug': shadowMap.debug,
      'shadowMapCascade': shadowMap.cascade,
      'alphaTest': material.alphaTest,
      'metal': (material is MeshPhongMaterial) && material.metal,
      'doubleSided': material.side == DoubleSide,
      'flipSided': material.side == BackSide
    };

    // Generate code

    var chunks = [];

    if (shaderID != null) {
      chunks.add(shaderID);
    } else {
      chunks.add((material as ShaderMaterial).fragmentShader);
      chunks.add((material as ShaderMaterial).vertexShader);
    }

    if (mat is ShaderMaterial && mat.defines != null) {
      for (var name in mat.defines.keys) {
        chunks.add(name);
        chunks.add(mat.defines[name]);
      }
    }

    for (var name in parameters.keys) {
      chunks.add(name);
      chunks.add(parameters[name]);
    }

    var code = chunks.join(',');

    if (material['_program'] == null) {
      // new material
      material['_onDisposeSubscription'] =
          mat.onDispose.listen(onMaterialDispose);
    } else if (material['_program'].code != code) {
      // changed glsl or parameters
      deallocateMaterial(mat);
    } else if (shaderID != null) {
      // same glsl
      return;
    } else if (mat is ShaderMaterial &&
        mat.uniforms == material['__webglShader']['uniforms']) {
      // same uniforms (container object)
      return;
    }

    if (shaderID != null) {
      var shader = ShaderLib[shaderID];

      material['__webglShader'] = {
        'uniforms': uniforms_utils.clone(shader['uniforms']),
        'vertexShader': shader['vertexShader'],
        'fragmentShader': shader['fragmentShader']
      };
    } else if (mat is ShaderMaterial) {
      material['__webglShader'] = {
        'uniforms': mat.uniforms,
        'vertexShader': mat.vertexShader,
        'fragmentShader': mat.fragmentShader
      };
    }

    WebGLProgram program;

    // Check if code has been already compiled

    for (var p = 0; p < _programs.length; p++) {
      var programInfo = _programs[p];

      if (programInfo.code == code) {
        program = programInfo;
        program.usedTimes++;
        break;
      }
    }

    if (program == null) {
      var p = parameters;
      program = new WebGLProgram._(this, code, material,
          precision: p['precision'],
          supportsVertexTextures: p['supportsVertexTextures'],
          map: p['map'],
          envMap: p['envMap'],
          envMapMode: p['envMapMode'],
          lightMap: p['lightMap'],
          aoMap: p['aoMap'],
          bumpMap: p['bumpMap'],
          normalMap: p['normalMap'],
          specularMap: p['specularMap'],
          alphaMap: p['alphaMap'],
          combine: p['combine'],
          vertexColors: p['vertexColors'],
          fog: p['fog'],
          useFog: p['useFog'],
          fogExp: p['fogExp'],
          flatShading: p['flatShading'],
          sizeAttenuation: p['sizeAttenuation'],
          logarithmicDepthBuffer: p['logarithmicDepthBuffer'],
          skinning: p['skinning'],
          maxBones: p['maxBones'],
          useVertexTexture: p['useVertexTexture'],
          morphTargets: p['morphTargets'],
          morphNormals: p['morphNormals'],
          maxMorphTargets: p['maxMorphTargets'],
          maxMorphNormals: p['maxMorphNormals'],
          maxDirLights: p['maxDirLights'],
          maxPointLights: p['maxPointLights'],
          maxSpotLights: p['maxSpotLights'],
          maxHemiLights: p['maxHemiLights'],
          maxShadows: p['maxShadows'],
          shadowMapEnabled: p['shadowMapEnabled'],
          shadowMapType: p['shadowMapType'],
          shadowMapDebug: p['shadowMapDebug'],
          shadowMapCascade: p['shadowMapCascade'],
          alphaTest: p['alphaTest'],
          metal: p['metal'],
          doubleSided: p['doubleSided'],
          flipSided: p['flipSided']);

      _programs.add(program);

      info.memory.programs = _programs.length;
    }

    material['_program'] = program;

    var attributes = program.getAttributes();

    if (mat is Morphing && mat.morphTargets != null && mat.morphTargets) {
      material['_numSupportedMorphTargets'] = 0;

      for (var i = 0; i < maxMorphTargets; i++) {
        var id = 'morphTarget$i';

        if (attributes[id] >= 0) {
          material['_numSupportedMorphTargets']++;
        }
      }
    }

    if (mat is Morphing && mat.morphNormals != null && mat.morphNormals) {
      material['_numSupportedMorphNormals'] = 0;

      for (var i = 0; i < maxMorphNormals; i++) {
        var id = 'morphNormal$i';

        if (attributes[id] >= 0) {
          material['_numSupportedMorphNormals']++;
        }
      }
    }

    material['_uniformsList'] = [];

    var uniformLocations = material['_program'].getUniforms();

    for (var u in material['__webglShader']['uniforms'].keys) {
      var location = uniformLocations[u];

      if (location != null) {
        material['_uniformsList']
            .add([material['__webglShader']['uniforms'][u], location]);
      }
    }
  }

  void setMaterial(Material material) {
    if (material.transparent) {
      state.setBlending(
          blending: material.blending,
          blendEquation: material.blendEquation,
          blendSrc: material.blendSrc,
          blendDst: material.blendDst,
          blendEquationAlpha: material.blendEquationAlpha,
          blendSrcAlpha: material.blendSrcAlpha,
          blendDstAlpha: material.blendDstAlpha);
    } else {
      state.setBlending(blending: NoBlending);
    }

    state.setDepthFunc(material.depthFunc);
    state.setDepthTest(material.depthTest);
    state.setDepthWrite(material.depthWrite);
    state.setColorWrite(material.colorWrite);
    state.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor,
        material.polygonOffsetUnits);
  }

  WebGLProgram setProgram(Camera camera, List<Light> lights, Fog fog,
      Material material, Object3D object) {
    _usedTextureUnits = 0;

    if (material.needsUpdate) {
      initMaterial(material, lights, fog, object);
      material.needsUpdate = false;
    }

    var refreshProgram = false;
    var refreshMaterial = false;
    var refreshLights = false;

    var program = material['_program'],
        p_uniforms = program.getUniforms(),
        m_uniforms = material['__webglShader']['uniforms'];

    if (program.id != _currentProgram) {
      _gl.useProgram(program.program);
      _currentProgram = program.id;

      refreshProgram = true;
      refreshMaterial = true;
      refreshLights = true;
    }

    if (material.id != _currentMaterialId) {
      if (_currentMaterialId == -1) refreshLights = true;
      _currentMaterialId = material.id;

      refreshMaterial = true;
    }

    if (refreshProgram || camera != _currentCamera) {
      _gl.uniformMatrix4fv(p_uniforms['projectionMatrix'], false,
          camera.projectionMatrix.storage);

      if (_logarithmicDepthBuffer) {
        _gl.uniform1f(p_uniforms['logDepthBufFC'],
            2.0 / (math.log(camera.far + 1.0) / math.LN2));
      }

      if (camera != _currentCamera) _currentCamera = camera;

      // load material specific uniforms
      // (shader material also gets them for the sake of genericity)

      var mat = material;

      if (mat is ShaderMaterial ||
          mat is MeshPhongMaterial ||
          mat is Mapping && mat.envMap != null) {
        if (p_uniforms['cameraPosition'] != null) {
          _vector3.setFromMatrixTranslation(camera.matrixWorld);
          _gl.uniform3f(
              p_uniforms['cameraPosition'], _vector3.x, _vector3.y, _vector3.z);
        }
      }

      if (mat is MeshPhongMaterial ||
          mat is MeshLambertMaterial ||
          mat is MeshBasicMaterial ||
          mat is ShaderMaterial ||
          mat is Morphing && mat.skinning) {
        if (p_uniforms['viewMatrix'] != null) {
          _gl.uniformMatrix4fv(p_uniforms['viewMatrix'], false,
              camera.matrixWorldInverse.storage);
        }
      }
    }

    // skinning uniforms must be set even if material didn't change
    // auto-setting of texture unit for bone texture must go before other textures
    // not sure why, but otherwise weird things happen

    var mat = material;

    if (mat is Morphing && mat.skinning) {
      var obj = object as SkinnedMesh;

      if (obj.bindMatrix != null && p_uniforms['bindMatrix'] != null) {
        _gl.uniformMatrix4fv(
            p_uniforms['bindMatrix'], false, obj.bindMatrix.storage);
      }

      if (obj.bindMatrixInverse != null &&
          p_uniforms['bindMatrixInverse'] != null) {
        _gl.uniformMatrix4fv(p_uniforms['bindMatrixInverse'], false,
            obj.bindMatrixInverse.storage);
      }

      if (_supportsBoneTextures &&
          obj.skeleton != null &&
          obj.skeleton.useVertexTexture) {
        if (p_uniforms['boneTexture'] != null) {
          var textureUnit = getTextureUnit();

          _gl.uniform1i(p_uniforms['boneTexture'], textureUnit);
          setTexture(obj.skeleton.boneTexture, textureUnit);
        }

        if (p_uniforms['boneTextureWidth'] != null) {
          _gl.uniform1i(
              p_uniforms['boneTextureWidth'], obj.skeleton.boneTextureWidth);
        }

        if (p_uniforms['boneTextureHeight'] != null) {
          _gl.uniform1i(
              p_uniforms['boneTextureHeight'], obj.skeleton.boneTextureHeight);
        }
      } else if (obj.skeleton != null && obj.skeleton.boneMatrices) {
        if (p_uniforms['boneGlobalMatrices'] != null) {
          _gl.uniformMatrix4fv(p_uniforms['boneGlobalMatrices'], false,
              obj.skeleton.boneMatrices);
        }
      }
    }

    if (refreshMaterial) {
      // refresh uniforms common to several materials

      if (fog != null && material.fog) {
        refreshUniformsFog(m_uniforms, fog);
      }

      var mat = material;

      if (mat is MeshPhongMaterial ||
          mat is MeshLambertMaterial ||
          mat is ShaderMaterial && mat.lights) {
        if (_lightsNeedUpdate) {
          refreshLights = true;
          setupLights(lights);
          _lightsNeedUpdate = false;
        }

        if (refreshLights) {
          refreshUniformsLights(m_uniforms, _lights);
          markUniformsLightsNeedsUpdate(m_uniforms, true);
        } else {
          markUniformsLightsNeedsUpdate(m_uniforms, false);
        }
      }

      if (material is MeshBasicMaterial ||
          material is MeshLambertMaterial ||
          material is MeshPhongMaterial) {
        refreshUniformsCommon(m_uniforms, material);
      }

      // refresh single material specific uniforms

      if (material is LineBasicMaterial) {
        refreshUniformsLine(m_uniforms, material);
      } else if (material is LineDashedMaterial) {
        refreshUniformsLine(m_uniforms, material);
        refreshUniformsDash(m_uniforms, material);
      } else if (material is PointCloudMaterial) {
        refreshUniformsParticle(m_uniforms, material);
      } else if (material is MeshPhongMaterial) {
        refreshUniformsPhong(m_uniforms, material);
      } else if (material is MeshLambertMaterial) {
        refreshUniformsLambert(m_uniforms, material);
      } else if (material is MeshBasicMaterial) {
        refreshUniformsBasic(m_uniforms, material);
      } else if (material is MeshDepthMaterial) {
        m_uniforms['mNear'].value = camera.near;
        m_uniforms['mFar'].value = camera.far;
        m_uniforms['opacity'].value = material.opacity;
      } else if (material is MeshNormalMaterial) {
        m_uniforms['opacity'].value = material.opacity;
      }

      if (object.receiveShadow && material['_shadowPass'] != true) {
        refreshUniformsShadow(m_uniforms, lights);
      }

      // load common uniforms
      loadUniformsGeneric(material['_uniformsList']);
    }

    loadUniformsMatrices(p_uniforms, object);

    if (p_uniforms['modelMatrix'] != null) {
      _gl.uniformMatrix4fv(
          p_uniforms['modelMatrix'], false, object.matrixWorld.storage);
    }

    return program;
  }

  // Uniforms (refresh uniforms objects)

  void refreshUniformsCommon(Map<String, Uniform> uniforms, Material material) {
    uniforms['opacity'].value = material.opacity;

    uniforms['diffuse'].value = material.color;

    var mat = material as Mapping;

    uniforms['map'].value = mat.map;
    uniforms['specularMap'].value = mat.specularMap;
    uniforms['alphaMap'].value = mat.alphaMap;

    if (mat.bumpMap != null) {
      uniforms['bumpMap'].value = mat.bumpMap;
      uniforms['bumpScale'].value = mat.bumpScale;
    }

    if (mat.normalMap != null) {
      uniforms['normalMap'].value = mat.normalMap;
      uniforms['normalScale'].value.setFrom(mat.normalScale);
    }

    // uv repeat and offset setting priorities
    // 1. color map
    // 2. specular map
    // 3. normal map
    // 4. bump map
    // 5. alpha map

    Texture uvScaleMap;

    if (mat.map != null) {
      uvScaleMap = mat.map;
    } else if (mat.specularMap != null) {
      uvScaleMap = mat.specularMap;
    } else if (mat.normalMap != null) {
      uvScaleMap = mat.normalMap;
    } else if (mat.bumpMap != null) {
      uvScaleMap = mat.bumpMap;
    } else if (mat.alphaMap != null) {
      uvScaleMap = mat.alphaMap;
    }

    if (uvScaleMap != null) {
      var offset = uvScaleMap.offset;
      var repeat = uvScaleMap.repeat;

      uniforms['offsetRepeat'].value.setValues(
          offset.x, offset.y, repeat.x, repeat.y);
    }

    uniforms['envMap'].value = mat.envMap;
    uniforms['flipEnvMap'].value =
        (mat.envMap is WebGLRenderTargetCube) ? 1 : -1;

    uniforms['reflectivity'].value = mat.reflectivity;
    uniforms['refractionRatio'].value = mat.refractionRatio;
  }

  void refreshUniformsLine(Map<String, Uniform> uniforms, material) {
    uniforms['diffuse'].value = material.color;
    uniforms['opacity'].value = material.opacity;
  }

  void refreshUniformsDash(
      Map<String, Uniform> uniforms, LineDashedMaterial material) {
    uniforms['dashSize'].value = material.dashSize;
    uniforms['totalSize'].value = material.dashSize + material.gapSize;
    uniforms['scale'].value = material.scale;
  }

  void refreshUniformsParticle(
      Map<String, Uniform> uniforms, PointCloudMaterial material) {
    uniforms['psColor'].value = material.color;
    uniforms['opacity'].value = material.opacity;
    uniforms['size'].value = material.size;
    uniforms['scale'].value = _canvas.height / 2.0; // TODO: Cache this.

    uniforms['map'].value = material.map;

    if (material.map != null) {
      var offset = material.map.offset;
      var repeat = material.map.repeat;

      uniforms['offsetRepeat'].value.setValues(
          offset.x, offset.y, repeat.x, repeat.y);
    }
  }

  void refreshUniformsFog(Map<String, Uniform> uniforms, Fog fog) {
    uniforms['fogColor'].value = fog.color;

    if (fog is FogLinear) {
      uniforms['fogNear'].value = fog.near;
      uniforms['fogFar'].value = fog.far;
    } else if (fog is FogExp2) {
      uniforms['fogDensity'].value = fog.density;
    }
  }

  void refreshUniformsPhong(
      Map<String, Uniform> uniforms, MeshPhongMaterial material) {
    uniforms['shininess'].value = material.shininess;

    uniforms['emissive'].value = material.emissive;
    uniforms['specular'].value = material.specular;

    uniforms['lightMap'].value = material.lightMap;
    uniforms['lightMapIntensity'].value = material.lightMapIntensity;

    uniforms['aoMap'].value = material.aoMap;
    uniforms['aoMapIntensity'].value = material.aoMapIntensity;
  }

  void refreshUniformsLambert(
      Map<String, Uniform> uniforms, MeshLambertMaterial material) {
    uniforms['emissive'].value = material.emissive;
  }

  void refreshUniformsBasic(
      Map<String, Uniform> uniforms, MeshBasicMaterial material) {
    uniforms['aoMap'].value = material.aoMap;
    uniforms['aoMapIntensity'].value = material.aoMapIntensity;
  }

  void refreshUniformsLights(Map<String, Uniform> uniforms, Map lights) {
    uniforms['ambientLightColor'].value = lights['ambient'];

    uniforms['directionalLightColor'].value = lights['directional']['colors'];
    uniforms['directionalLightDirection'].value =
        lights['directional']['positions'];

    uniforms['pointLightColor'].value = lights['point']['colors'];
    uniforms['pointLightPosition'].value = lights['point']['positions'];
    uniforms['pointLightDistance'].value = lights['point']['distances'];
    uniforms['pointLightDecay'].value = lights['point']['decays'];

    uniforms['spotLightColor'].value = lights['spot']['colors'];
    uniforms['spotLightPosition'].value = lights['spot']['positions'];
    uniforms['spotLightDistance'].value = lights['spot']['distances'];
    uniforms['spotLightDirection'].value = lights['spot']['directions'];
    uniforms['spotLightAngleCos'].value = lights['spot']['anglesCos'];
    uniforms['spotLightExponent'].value = lights['spot']['exponents'];
    uniforms['spotLightDecay'].value = lights['spot']['decays'];

    uniforms['hemisphereLightSkyColor'].value = lights['hemi']['skyColors'];
    uniforms['hemisphereLightGroundColor'].value =
        lights['hemi']['groundColors'];
    uniforms['hemisphereLightDirection'].value = lights['hemi']['positions'];
  }

  // If uniforms are marked as clean, they don't need to be loaded to the GPU.

  void markUniformsLightsNeedsUpdate(
      Map<String, Uniform> uniforms, bool value) {
    uniforms['ambientLightColor'].needsUpdate = value;

    uniforms['directionalLightColor'].needsUpdate = value;
    uniforms['directionalLightDirection'].needsUpdate = value;

    uniforms['pointLightColor'].needsUpdate = value;
    uniforms['pointLightPosition'].needsUpdate = value;
    uniforms['pointLightDistance'].needsUpdate = value;
    uniforms['pointLightDecay'].needsUpdate = value;

    uniforms['spotLightColor'].needsUpdate = value;
    uniforms['spotLightPosition'].needsUpdate = value;
    uniforms['spotLightDistance'].needsUpdate = value;
    uniforms['spotLightDirection'].needsUpdate = value;
    uniforms['spotLightAngleCos'].needsUpdate = value;
    uniforms['spotLightExponent'].needsUpdate = value;
    uniforms['spotLightDecay'].needsUpdate = value;

    uniforms['hemisphereLightSkyColor'].needsUpdate = value;
    uniforms['hemisphereLightGroundColor'].needsUpdate = value;
    uniforms['hemisphereLightDirection'].needsUpdate = value;
  }

  void refreshUniformsShadow(
      Map<String, Uniform> uniforms, List<Light> lights) {
    if (uniforms['shadowMatrix'] != null) {
      var maxShadows = allocateShadows(lights);

      // Grow typed arrays if neccesary
      if (maxShadows > uniforms['shadowMap'].value.length) {
        uniforms['shadowMap'].value.length = maxShadows;
        uniforms['shadowMapSize'].value.length = maxShadows;

        uniforms['shadowMatrix'].value.length = maxShadows;

        uniforms['shadowBias'].value = new Float32List(maxShadows);
        uniforms['shadowDarkness'].value = new Float32List(maxShadows);
      }

      var j = 0;

      for (var i = 0; i < lights.length; i++) {
        var light = lights[i];

        if (!light.castShadow) continue;

        if (light is SpotLight ||
            (light is DirectionalLight && !light.shadowCascade)) {
          uniforms['shadowMap'].value[j] = light.shadowMap;
          uniforms['shadowMapSize'].value[j] = light.shadowMapSize;

          uniforms['shadowMatrix'].value[j] = light.shadowMatrix;

          uniforms['shadowDarkness'].value[j] = light.shadowDarkness;
          uniforms['shadowBias'].value[j] = light.shadowBias;

          j++;
        }
      }
    }
  }

  // Uniforms (load to GPU)

  void loadUniformsMatrices(
      Map<String, gl.UniformLocation> uniforms, Object3D object) {
    _gl.uniformMatrix4fv(
        uniforms['modelViewMatrix'], false, object['_modelViewMatrix'].storage);

    if (uniforms['normalMatrix'] != null) {
      _gl.uniformMatrix3fv(
          uniforms['normalMatrix'], false, object['_normalMatrix'].storage);
    }
  }

  int getTextureUnit() {
    var textureUnit = _usedTextureUnits;

    if (textureUnit >= _maxTextures) {
      warn(
          'WebGLRenderer: trying to use $textureUnit texture units while this GPU supports only $_maxTextures');
    }

    _usedTextureUnits += 1;

    return textureUnit;
  }

  void loadUniformsGeneric(List<List> uniforms) {
    for (var j = 0; j < uniforms.length; j++) {
      Uniform uniform = uniforms[j][0];

      // needsUpdate property is not added to all uniforms.
      if (uniform.needsUpdate != null && !uniform.needsUpdate) continue;

      String type = uniform.type;
      var value = uniform.value;
      gl.UniformLocation location = uniforms[j][1];

      switch (type) {
        case '1i':
          _gl.uniform1i(location, value);
          break;
        case '1f':
          _gl.uniform1f(location, value);
          break;
        case '2f':
          _gl.uniform2f(location, value[0], value[1]);
          break;
        case '3f':
          _gl.uniform3f(location, value[0], value[1], value[2]);
          break;
        case '4f':
          _gl.uniform4f(location, value[0], value[1], value[2], value[3]);
          break;
        case '1iv':
          _gl.uniform1iv(location, value);
          break;
        case '3iv':
          _gl.uniform3iv(location, value);
          break;
        case '1fv':
          _gl.uniform1fv(location, value);
          break;
        case '2fv':
          _gl.uniform2fv(location, value);
          break;
        case '3fv':
          _gl.uniform3fv(location, value);
          break;
        case '4fv':
          _gl.uniform4fv(location, value);
          break;
        case 'Matrix3fv':
          _gl.uniformMatrix3fv(location, false, value);
          break;
        case 'Matrix4fv':
          _gl.uniformMatrix4fv(location, false, value);
          break;
        // single integer
        case 'i':
          _gl.uniform1i(location, value);
          break; // TODO automatically convert bool to int?
        // single float
        case 'f':
          _gl.uniform1f(location, value);
          break;
        // single Vector2
        case 'v2':
          _gl.uniform2f(location, value.x, value.y);
          break;
        // single Vector3
        case 'v3':
          _gl.uniform3f(location, value.x, value.y, value.z);
          break;
        // single Vector4
        case 'v4':
          _gl.uniform4f(location, value.x, value.y, value.z, value.w);
          break;
        // single Color
        case 'c':
          _gl.uniform3f(location, value.r, value.g, value.b);
          break;
        // flat array of integers (JS or typed array)
        case 'iv1':
          _gl.uniform1iv(location, value);
          break;
        // flat array of integers with 3 x N size (JS or typed array)
        case 'iv':
          _gl.uniform3iv(location, value);
          break;
        // flat array of floats (JS or typed array)
        case 'fv1':
          _gl.uniform1fv(location, value);
          break;
        // flat array of floats with 3 x N size (JS or typed array)
        case 'fv':
          _gl.uniform3fv(location, value);
          break;
        // array of Vector2
        case 'v2v':
          if (uniform._array == null) {
            uniform._array = new Float32List(2 * value.length);
          }

          for (var i = 0; i < value.length; i++) {
            var offset = i * 2;

            uniform._array[offset] = value[i].x;
            uniform._array[offset + 1] = value[i].y;
          }

          _gl.uniform2fv(location, uniform._array);
          break;
        // array of Vector3
        case 'v3v':
          if (uniform._array == null) {
            uniform._array = new Float32List(3 * value.length);
          }

          for (var i = 0; i < value.length; i++) {
            var offset = i * 3;

            uniform._array[offset] = value[i].x;
            uniform._array[offset + 1] = value[i].y;
            uniform._array[offset + 2] = value[i].z;
          }

          _gl.uniform3fv(location, uniform._array);
          break;
        // array of Vector4
        case 'v4v':
          if (uniform._array == null) {
            uniform._array = new Float32List(4 * value.length);
          }

          for (var i = 0; i < value.length; i++) {
            var offset = i * 4;

            uniform._array[offset] = value[i].x;
            uniform._array[offset + 1] = value[i].y;
            uniform._array[offset + 2] = value[i].z;
            uniform._array[offset + 3] = value[i].w;
          }

          _gl.uniform4fv(location, uniform._array);
          break;
        // single Matrix3
        case 'm3':
          _gl.uniformMatrix3fv(location, false, value.storage);
          break;
        // array of Matrix3
        case 'm3v':
          if (uniform._array == null) {
            uniform._array = new Float32List(9 * value.length);
          }

          for (var i = 0; i < value.length; i++) {
            value[i].copyIntoArray(uniform._array, i * 9);
          }

          _gl.uniformMatrix3fv(location, false, uniform._array);
          break;
        // single Matrix4
        case 'm4':
          _gl.uniformMatrix4fv(location, false, value.storage);
          break;
        // array of Matrix4
        case 'm4v':
          if (uniform._array == null) {
            uniform._array = new Float32List(16 * value.length);
          }

          for (var i = 0; i < value.length; i++) {
            value[i].copyIntoArray(uniform._array, i * 16);
          }

          _gl.uniformMatrix4fv(location, false, uniform._array);
          break;
        // single Texture (2d or cube)
        case 't':
          var texture = value;
          var textureUnit = getTextureUnit();

          _gl.uniform1i(location, textureUnit);

          if (texture == null) continue;

          var img = texture.image;

          if (texture is CubeTexture || (img is List && img.length == 6)) {
            // CompressedTexture can have Array in image :/
            setCubeTexture(texture, textureUnit);
          } else if (texture is WebGLRenderTargetCube) {
            setCubeTextureDynamic(texture, textureUnit);
          } else {
            setTexture(texture, textureUnit);
          }
          break;
        case 'tv':
          // array of Texture (2d)
          if (uniform._array == null) {
            uniform._array = new Int32List(value.length);
          }

          for (var i = 0; i < uniform.value.length; i++) {
            uniform._array[i] = getTextureUnit();
          }

          _gl.uniform1iv(location, uniform._array);

          for (var i = 0; i < value.length; i++) {
            var texture = value[i];
            var textureUnit = uniform._array[i];

            if (texture == null) continue;

            setTexture(texture, textureUnit);
          }
          break;
        default:
          warn('WebGLRenderer: Unknown uniform type: $type');
      }
    }
  }

  void setupMatrices(Object3D object, Camera camera) {
    object['_modelViewMatrix'].multiplyMatrices(
        camera.matrixWorldInverse, object.matrixWorld);
    object['_normalMatrix'].copyNormalMatrix(object['_modelViewMatrix']);
  }

  void setColorLinear(List array, int offset, Color color, double intensity) {
    array[offset] = color.r * intensity;
    array[offset + 1] = color.g * intensity;
    array[offset + 2] = color.b * intensity;
  }

  void setupLights(List<Light> lights) {
    var zlights = _lights;

    var maxLightCount = allocateLights(lights);
    // Grow typed arrays if necessary.
    ['directional', 'point', 'spot', 'hemi'].forEach((name) {
      if (zlights[name]['length'] < maxLightCount[name]) {
        zlights[name].keys.forEach(
            (k) => zlights[name][k] = new Float32List(maxLightCount[name] * 3));
      }
    });

    var r = 0.0,
        g = 0.0,
        b = 0.0;

    var dirColors = zlights['directional']['colors'],
        dirPositions = zlights['directional']['positions'],
        pointColors = zlights['point']['colors'],
        pointPositions = zlights['point']['positions'],
        pointDistances = zlights['point']['distances'],
        pointDecays = zlights['point']['decays'],
        spotColors = zlights['spot']['colors'],
        spotPositions = zlights['spot']['positions'],
        spotDistances = zlights['spot']['distances'],
        spotDirections = zlights['spot']['directions'],
        spotAnglesCos = zlights['spot']['anglesCos'],
        spotExponents = zlights['spot']['exponents'],
        spotDecays = zlights['spot']['decays'],
        hemiSkyColors = zlights['hemi']['skyColors'],
        hemiGroundColors = zlights['hemi']['groundColors'],
        hemiPositions = zlights['hemi']['positions'],
        dirLength = 0,
        pointLength = 0,
        spotLength = 0,
        hemiLength = 0,
        dirCount = 0,
        pointCount = 0,
        spotCount = 0,
        hemiCount = 0,
        dirOffset = 0,
        pointOffset = 0,
        spotOffset = 0,
        hemiOffset = 0;

    for (var l = 0; l < lights.length; l++) {
      var light = lights[l];

      if (light is ShadowCaster && light.onlyShadow) continue;

      var color = light.color;

      if (light is AmbientLight) {
        if (!light.visible) continue;

        r += color.r;
        g += color.g;
        b += color.b;
      } else if (light is DirectionalLight) {
        var intensity = light.intensity;

        dirCount += 1;

        if (!light.visible) continue;

        _direction.setFromMatrixTranslation(light.matrixWorld);
        _vector3.setFromMatrixTranslation(light.target.matrixWorld);
        _direction.sub(_vector3);
        _direction.normalize();

        dirOffset = dirLength * 3;

        dirPositions[dirOffset] = _direction.x;
        dirPositions[dirOffset + 1] = _direction.y;
        dirPositions[dirOffset + 2] = _direction.z;

        setColorLinear(dirColors, dirOffset, color, intensity);

        dirLength += 1;
      } else if (light is PointLight) {
        var intensity = light.intensity;
        var distance = light.distance;

        pointCount += 1;

        if (!light.visible) continue;

        pointOffset = pointLength * 3;

        setColorLinear(pointColors, pointOffset, color, intensity);

        _vector3.setFromMatrixTranslation(light.matrixWorld);

        pointPositions[pointOffset] = _vector3.x;
        pointPositions[pointOffset + 1] = _vector3.y;
        pointPositions[pointOffset + 2] = _vector3.z;

        // distance is 0 if decay is 0, because there is no attenuation at all.
        pointDistances[pointLength] = distance;
        pointDecays[pointLength] = (light.distance == 0) ? 0.0 : light.decay;

        pointLength += 1;
      } else if (light is SpotLight) {
        var intensity = light.intensity;
        var distance = light.distance;

        spotCount += 1;

        if (!light.visible) continue;

        spotOffset = spotLength * 3;

        setColorLinear(spotColors, spotOffset, color, intensity);

        _direction.setFromMatrixTranslation(light.matrixWorld);

        spotPositions[spotOffset] = _direction.x;
        spotPositions[spotOffset + 1] = _direction.y;
        spotPositions[spotOffset + 2] = _direction.z;

        spotDistances[spotLength] = distance;

        _vector3.setFromMatrixTranslation(light.target.matrixWorld);
        _direction.sub(_vector3);
        _direction.normalize();

        spotDirections[spotOffset] = _direction.x;
        spotDirections[spotOffset + 1] = _direction.y;
        spotDirections[spotOffset + 2] = _direction.z;

        spotAnglesCos[spotLength] = math.cos(light.angle);
        spotExponents[spotLength] = light.exponent;
        spotDecays[spotLength] = (light.distance == 0) ? 0.0 : light.decay;

        spotLength += 1;
      } else if (light is HemisphereLight) {
        var intensity = light.intensity;

        hemiCount += 1;

        if (!light.visible) continue;

        _direction.setFromMatrixTranslation(light.matrixWorld);
        _direction.normalize();

        hemiOffset = hemiLength * 3;

        hemiPositions[hemiOffset] = _direction.x;
        hemiPositions[hemiOffset + 1] = _direction.y;
        hemiPositions[hemiOffset + 2] = _direction.z;

        var skyColor = light.color;
        var groundColor = light.groundColor;

        setColorLinear(hemiSkyColors, hemiOffset, skyColor, intensity);
        setColorLinear(hemiGroundColors, hemiOffset, groundColor, intensity);

        hemiLength += 1;
      }
    }

    // null eventual remains from removed lights
    // (this is to avoid if in shader)

    for (var l = dirLength * 3;
        l < math.max(dirColors.length, dirCount * 3);
        l++) {
      dirColors[l] = 0.0;
    }

    for (var l = pointLength * 3;
        l < math.max(pointColors.length, pointCount * 3);
        l++) {
      pointColors[l] = 0.0;
    }

    for (var l = spotLength * 3;
        l < math.max(spotColors.length, spotCount * 3);
        l++) {
      spotColors[l] = 0.0;
    }

    for (var l = hemiLength * 3;
        l < math.max(hemiSkyColors.length, hemiCount * 3);
        l++) {
      hemiSkyColors[l] = 0.0;
    }

    for (var l = hemiLength * 3;
        l < math.max(hemiGroundColors.length, hemiCount * 3);
        l++) {
      hemiGroundColors[l] = 0.0;
    }

    zlights['directional']['length'] = dirLength;
    zlights['point']['length'] = pointLength;
    zlights['spot']['length'] = spotLength;
    zlights['hemi']['length'] = hemiLength;

    zlights['ambient'][0] = r;
    zlights['ambient'][1] = g;
    zlights['ambient'][2] = b;
  }

  // GL state setting

  void setFaceCulling(int cullFace, int frontFaceDirection) {
    if (cullFace == CullFaceNone) {
      _gl.disable(gl.CULL_FACE);
    } else {
      if (frontFaceDirection == FrontFaceDirectionCW) {
        _gl.frontFace(gl.CW);
      } else {
        _gl.frontFace(gl.CCW);
      }

      if (cullFace == CullFaceBack) {
        _gl.cullFace(gl.BACK);
      } else if (cullFace == CullFaceFront) {
        _gl.cullFace(gl.FRONT);
      } else {
        _gl.cullFace(gl.FRONT_AND_BACK);
      }

      _gl.enable(gl.CULL_FACE);
    }
  }

  void setMaterialFaces(Material material) {
    state.setDoubleSided(material.side == DoubleSide);
    state.setFlipSided(material.side == BackSide);
  }

  // Textures

  void setTextureParameters(
      int textureType, Texture texture, bool isImagePowerOfTwo) {
    var extension;

    if (isImagePowerOfTwo) {
      _gl.texParameteri(
          textureType, gl.TEXTURE_WRAP_S, paramThreeToGL(texture.wrapS));
      _gl.texParameteri(
          textureType, gl.TEXTURE_WRAP_T, paramThreeToGL(texture.wrapT));

      _gl.texParameteri(textureType, gl.TEXTURE_MAG_FILTER,
          paramThreeToGL(texture.magFilter));
      _gl.texParameteri(textureType, gl.TEXTURE_MIN_FILTER,
          paramThreeToGL(texture.minFilter));
    } else {
      _gl.texParameteri(textureType, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      _gl.texParameteri(textureType, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

      if (texture.wrapS != ClampToEdgeWrapping ||
          texture.wrapT != ClampToEdgeWrapping) {
        warn('WebGLRenderer: Texture is not power of two. Texture.wrapS and Texture.wrapT ' +
            'should be set to ClampToEdgeWrapping. (${texture.sourceFile})');
      }

      _gl.texParameteri(textureType, gl.TEXTURE_MAG_FILTER,
          filterFallback(texture.magFilter));
      _gl.texParameteri(textureType, gl.TEXTURE_MIN_FILTER,
          filterFallback(texture.minFilter));

      if (texture.minFilter != NearestFilter &&
          texture.minFilter != LinearFilter) {
        warn('WebGLRenderer: Texture is not power of two. Texture.minFilter should' +
            'be set to NearestFilter or LinearFilter. (${texture.sourceFile})');
      }
    }

    extension = extensions.get('EXT_texture_filter_anisotropic');

    if (extension != null &&
        texture.type != FloatType &&
        texture.type != HalfFloatType) {
      if (texture.anisotropy > 1 || texture['__currentAnisotropy'] != null) {
        _gl.texParameterf(textureType,
            gl.ExtTextureFilterAnisotropic.TEXTURE_MAX_ANISOTROPY_EXT,
            math.min(texture.anisotropy, getMaxAnisotropy()));
        texture['__currentAnisotropy'] = texture.anisotropy;
      }
    }
  }

  void uploadTexture(Texture texture, int slot) {
    if (texture['__webglInit'] != true) {
      texture['__webglInit'] = true;
      texture['_onDisposeSubscription'] =
          texture.onDispose.listen(onTextureDispose);
      texture['__webglTexture'] = _gl.createTexture();

      info.memory.textures++;
    }

    state.activeTexture(gl.TEXTURE0 + slot);
    state.bindTexture(gl.TEXTURE_2D, texture['__webglTexture']);

    _gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, texture.flipY ? 1 : 0);
    _gl.pixelStorei(
        gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha ? 1 : 0);
    _gl.pixelStorei(gl.UNPACK_ALIGNMENT, texture.unpackAlignment);

    texture.image = clampToMaxSize(texture.image, _maxTextureSize);

    var image = texture.image,
        isImagePowerOfTwo =
        isPowerOfTwo(image.width) && isPowerOfTwo(image.height),
        glFormat = paramThreeToGL(texture.format),
        glType = paramThreeToGL(texture.type);

    setTextureParameters(gl.TEXTURE_2D, texture, isImagePowerOfTwo);

    var mipmaps = texture.mipmaps;

    if (texture is DataTexture) {
      // use manually created mipmaps if available
      // if there are no manual mipmaps
      // set 0 level mipmap and then use GL to generate other mipmap levels

      if (mipmaps.length > 0 && isImagePowerOfTwo) {
        for (var i = 0; i < mipmaps.length; i++) {
          var mipmap = mipmaps[i];
          state.texImage2D(gl.TEXTURE_2D, i, glFormat, mipmap.width,
              mipmap.height, 0, glFormat, glType, mipmap.data);
        }

        texture.generateMipmaps = false;
      } else {
        state.texImage2D(gl.TEXTURE_2D, 0, glFormat, image.width, image.height,
            0, glFormat, glType, image.data);
      }
    } else if (texture is CompressedTexture) {
      for (var i = 0; i < mipmaps.length; i++) {
        var mipmap = mipmaps[i];

        if (texture.format != RGBAFormat && texture.format != RGBFormat) {
          if (getCompressedTextureFormats().indexOf(glFormat) > -1) {
            state.compressedTexImage2D(gl.TEXTURE_2D, i, glFormat, mipmap.width,
                mipmap.height, 0, mipmap.data);
          } else {
            warn(
                "WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()");
          }
        } else {
          state.texImage2D(gl.TEXTURE_2D, i, glFormat, mipmap.width,
              mipmap.height, 0, glFormat, glType, mipmap.data);
        }
      }
    } else {
      // regular Texture (image, video, canvas)

      // use manually created mipmaps if available
      // if there are no manual mipmaps
      // set 0 level mipmap and then use GL to generate other mipmap levels

      if (mipmaps.length > 0 && isImagePowerOfTwo) {
        for (var i = 0; i < mipmaps.length; i++) {
          var mipmap = mipmaps[i];
          state.texImage2D(
              gl.TEXTURE_2D, i, glFormat, glFormat, glType, mipmap);
        }

        texture.generateMipmaps = false;
      } else {
        state.texImage2D(
            gl.TEXTURE_2D, 0, glFormat, glFormat, glType, texture.image);
      }
    }

    if (texture.generateMipmaps && isImagePowerOfTwo) _gl
        .generateMipmap(gl.TEXTURE_2D);

    texture.needsUpdate = false;

    texture.update();
  }

  void setTexture(Texture texture, int slot) {
    if (texture.needsUpdate) {
      var image = texture.image;

      if (image == null) {
        warn(
            'WebGLRenderer: Texture marked for update but image is undefined $texture');
        return;
      }

      if (image is ImageElement && !image.complete) {
        warn(
            'WebGLRenderer: Texture marked for update but image is incomplete $texture');
        return;
      }

      uploadTexture(texture, slot);
      return;
    }

    state.activeTexture(gl.TEXTURE0 + slot);
    state.bindTexture(gl.TEXTURE_2D, texture['__webglTexture']);
  }

  clampToMaxSize(image, int maxSize) {
    if (image.width > maxSize || image.height > maxSize) {
      // Warning: Scaling through the canvas will only work with images that use
      // premultiplied alpha.

      var scale = maxSize / math.max(image.width, image.height);

      var canvas = new CanvasElement(
          width: (image.width * scale).floor(),
          height: (image.height * scale).floor());
      var context = canvas.context2D;

      context.drawImageScaledFromSource(image, 0, 0, image.width, image.height,
          0, 0, canvas.width, canvas.height);

      warn(
          'WebGLRenderer: image is too big (${image.width}x${image.height}). ' +
              'Resized to ${canvas.width}x${canvas.height} $image');

      return canvas;
    }

    return image;
  }

  void setCubeTexture(Texture texture, int slot) {
    if (texture.image.length == 6) {
      if (texture.needsUpdate) {
        if (texture.image.__webglTextureCube == null) {
          texture['_onDisposeSubscription'] =
              texture.onDispose.listen(onTextureDispose);

          texture.image.__webglTextureCube = _gl.createTexture();

          info.memory.textures++;
        }

        state.activeTexture(gl.TEXTURE0 + slot);
        state.bindTexture(
            gl.TEXTURE_CUBE_MAP, texture.image.__webglTextureCube);

        _gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, texture.flipY ? 1 : 0);

        var isCompressed = texture is CompressedTexture;
        var isDataTexture = texture.image[0] is DataTexture;

        var cubeImage = [];

        for (var i = 0; i < 6; i++) {
          if (autoScaleCubemaps && !isCompressed && !isDataTexture) {
            cubeImage.add(clampToMaxSize(texture.image[i], _maxCubemapSize));
          } else {
            cubeImage
                .add(isDataTexture ? texture.image[i].image : texture.image[i]);
          }
        }

        var image = cubeImage[0],
            isImagePowerOfTwo =
            isPowerOfTwo(image.width) && isPowerOfTwo(image.height),
            glFormat = paramThreeToGL(texture.format),
            glType = paramThreeToGL(texture.type);

        setTextureParameters(gl.TEXTURE_CUBE_MAP, texture, isImagePowerOfTwo);

        for (var i = 0; i < 6; i++) {
          if (!isCompressed) {
            if (isDataTexture) {
              state.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glFormat,
                  cubeImage[i].width, cubeImage[i].height, 0, glFormat, glType,
                  cubeImage[i].data);
            } else {
              state.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glFormat,
                  glFormat, glType, cubeImage[i]);
            }
          } else {
            var mipmaps = cubeImage[i].mipmaps;

            for (var j = 0; j < mipmaps.length; j++) {
              var mipmap = mipmaps[j];

              if (texture.format != RGBAFormat && texture.format != RGBFormat) {
                if (getCompressedTextureFormats().indexOf(glFormat) > -1) {
                  state.compressedTexImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i,
                      j, glFormat, mipmap['width'].toInt(),
                      mipmap['height'].toInt(), 0, mipmap['data']);
                } else {
                  warn(
                      'WebGLRenderer: Attempt to load unsupported compressed texture format' +
                          'in .setCubeTexture()');
                }
              } else {
                state.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, j,
                    glFormat, mipmap['width'].toInt(), mipmap['height'].toInt(),
                    0, glFormat, glType, mipmap['data']);
              }
            }
          }
        }

        if (texture.generateMipmaps && isImagePowerOfTwo) {
          _gl.generateMipmap(gl.TEXTURE_CUBE_MAP);
        }

        texture.needsUpdate = false;
        texture.update();
      } else {
        state.activeTexture(gl.TEXTURE0 + slot);
        state.bindTexture(
            gl.TEXTURE_CUBE_MAP, texture.image.__webglTextureCube);
      }
    }
  }

  void setCubeTextureDynamic(Texture texture, int slot) {
    state.activeTexture(gl.TEXTURE0 + slot);
    state.bindTexture(gl.TEXTURE_CUBE_MAP, texture['__webglTexture']);
  }

  // Render targets

  void setupFrameBuffer(gl.Framebuffer framebuffer,
      WebGLRenderTarget renderTarget, int textureTarget) {
    _gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
    _gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0,
        textureTarget, renderTarget['__webglTexture'], 0);
  }

  void setupRenderBuffer(
      gl.Renderbuffer renderbuffer, WebGLRenderTarget renderTarget) {
    _gl.bindRenderbuffer(gl.RENDERBUFFER, renderbuffer);

    if (renderTarget.depthBuffer && !renderTarget.stencilBuffer) {
      _gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16,
          renderTarget.width, renderTarget.height);
      _gl.framebufferRenderbuffer(
          gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, renderbuffer);
    } else if (renderTarget.depthBuffer && renderTarget.stencilBuffer) {
      _gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_STENCIL,
          renderTarget.width, renderTarget.height);
      _gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT,
          gl.RENDERBUFFER, renderbuffer);
    } else {
      _gl.renderbufferStorage(
          gl.RENDERBUFFER, gl.RGBA4, renderTarget.width, renderTarget.height);
    }
  }

  void setRenderTarget(WebGLRenderTarget renderTarget) {
    var isCube = (renderTarget is WebGLRenderTargetCube);

    if (renderTarget != null && renderTarget.__webglFramebuffer == null) {
      if (renderTarget.depthBuffer == null) renderTarget.depthBuffer = true;
      if (renderTarget.stencilBuffer == null) renderTarget.stencilBuffer = true;

      renderTarget['_onDisposeSubscription'] =
          renderTarget.onDispose.listen(onRenderTargetDispose);
      renderTarget['__webglTexture'] = _gl.createTexture();

      info.memory.textures++;

      // Setup texture, create render and frame buffers

      var isTargetPowerOfTwo =
          isPowerOfTwo(renderTarget.width) && isPowerOfTwo(renderTarget.height);

      var glFormat = paramThreeToGL(renderTarget.format);
      var glType = paramThreeToGL(renderTarget.type);

      if (isCube) {
        renderTarget.__webglFramebuffer = [];
        renderTarget.__webglRenderbuffer = [];

        state.bindTexture(gl.TEXTURE_CUBE_MAP, renderTarget['__webglTexture']);
        setTextureParameters(
            gl.TEXTURE_CUBE_MAP, renderTarget, isTargetPowerOfTwo);

        for (var i = 0; i < 6; i++) {
          renderTarget.__webglFramebuffer[i] = _gl.createFramebuffer();
          renderTarget.__webglRenderbuffer[i] = _gl.createRenderbuffer();

          state.texImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, glFormat,
              renderTarget.width, renderTarget.height, 0, glFormat, glType,
              null);

          setupFrameBuffer(renderTarget.__webglFramebuffer[i], renderTarget,
              gl.TEXTURE_CUBE_MAP_POSITIVE_X + i);
          setupRenderBuffer(renderTarget.__webglRenderbuffer[i], renderTarget);
        }

        if (renderTarget.generateMipmaps && isTargetPowerOfTwo) {
          _gl.generateMipmap(gl.TEXTURE_CUBE_MAP);
        }
      } else {
        renderTarget.__webglFramebuffer = _gl.createFramebuffer();

        if (renderTarget.shareDepthFrom != null) {
          renderTarget.__webglRenderbuffer =
              renderTarget.shareDepthFrom.__webglRenderbuffer;
        } else {
          renderTarget.__webglRenderbuffer = _gl.createRenderbuffer();
        }

        state.bindTexture(gl.TEXTURE_2D, renderTarget['__webglTexture']);
        setTextureParameters(gl.TEXTURE_2D, renderTarget, isTargetPowerOfTwo);

        state.texImage2D(gl.TEXTURE_2D, 0, glFormat, renderTarget.width,
            renderTarget.height, 0, glFormat, glType, null);

        setupFrameBuffer(
            renderTarget.__webglFramebuffer, renderTarget, gl.TEXTURE_2D);

        if (renderTarget.shareDepthFrom != null) {
          if (renderTarget.depthBuffer && !renderTarget.stencilBuffer) {
            _gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT,
                gl.RENDERBUFFER, renderTarget.__webglRenderbuffer);
          } else if (renderTarget.depthBuffer && renderTarget.stencilBuffer) {
            _gl.framebufferRenderbuffer(gl.FRAMEBUFFER,
                gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER,
                renderTarget.__webglRenderbuffer);
          }
        } else {
          setupRenderBuffer(renderTarget.__webglRenderbuffer, renderTarget);
        }

        if (renderTarget.generateMipmaps && isTargetPowerOfTwo) _gl
            .generateMipmap(gl.TEXTURE_2D);
      }

      // Release everything

      if (isCube) {
        state.bindTexture(gl.TEXTURE_CUBE_MAP, null);
      } else {
        state.bindTexture(gl.TEXTURE_2D, null);
      }

      _gl.bindRenderbuffer(gl.RENDERBUFFER, null);
      _gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    }

    var framebuffer, width, height, vx, vy;

    if (renderTarget != null) {
      if (isCube) {
        framebuffer =
            renderTarget.__webglFramebuffer[renderTarget.activeCubeFace];
      } else {
        framebuffer = renderTarget.__webglFramebuffer;
      }

      width = renderTarget.width;
      height = renderTarget.height;

      vx = 0;
      vy = 0;
    } else {
      framebuffer = null;

      width = _viewportWidth;
      height = _viewportHeight;

      vx = _viewportX;
      vy = _viewportY;
    }

    if (framebuffer != _currentFramebuffer) {
      _gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
      _gl.viewport(vx, vy, width, height);

      _currentFramebuffer = framebuffer;
    }

    _currentWidth = width;
    _currentHeight = height;
  }

  void readRenderTargetPixels(WebGLRenderTarget renderTarget, int x, int y,
      int width, int height, TypedData buffer) {
    if (renderTarget.__webglFramebuffer != null) {
      if (renderTarget.format != RGBAFormat) {
        error(
            'WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA format. readPixels can read only RGBA format.');
        return;
      }

      var restore = false;

      if (renderTarget.__webglFramebuffer != _currentFramebuffer) {
        _gl.bindFramebuffer(gl.FRAMEBUFFER, renderTarget.__webglFramebuffer);

        restore = true;
      }

      if (_gl.checkFramebufferStatus(gl.FRAMEBUFFER) ==
          gl.FRAMEBUFFER_COMPLETE) {
        _gl.readPixels(x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, buffer);
      } else {
        error(
            'WebGLRenderer.readRenderTargetPixels: readPixels from renderTarget failed. Framebuffer not complete.');
      }

      if (restore) {
        _gl.bindFramebuffer(gl.FRAMEBUFFER, _currentFramebuffer);
      }
    }
  }

  void updateRenderTargetMipmap(WebGLRenderTarget renderTarget) {
    if (renderTarget is WebGLRenderTargetCube) {
      state.bindTexture(gl.TEXTURE_CUBE_MAP, renderTarget['__webglTexture']);
      _gl.generateMipmap(gl.TEXTURE_CUBE_MAP);
      state.bindTexture(gl.TEXTURE_CUBE_MAP, null);
    } else {
      state.bindTexture(gl.TEXTURE_2D, renderTarget['__webglTexture']);
      _gl.generateMipmap(gl.TEXTURE_2D);
      state.bindTexture(gl.TEXTURE_2D, null);
    }
  }

  // Fallback filters for non-power-of-2 textures

  int filterFallback(f) {
    if (f == NearestFilter ||
        f == NearestMipMapNearestFilter ||
        f == NearestMipMapLinearFilter) {
      return gl.NEAREST;
    }

    return gl.LINEAR;
  }

  // Map js constants to WebGL constants

  int paramThreeToGL(int p) {
    var extension;

    if (p == RepeatWrapping) return gl.REPEAT;
    if (p == ClampToEdgeWrapping) return gl.CLAMP_TO_EDGE;
    if (p == MirroredRepeatWrapping) return gl.MIRRORED_REPEAT;

    if (p == NearestFilter) return gl.NEAREST;
    if (p == NearestMipMapNearestFilter) return gl.NEAREST_MIPMAP_NEAREST;
    if (p == NearestMipMapLinearFilter) return gl.NEAREST_MIPMAP_LINEAR;

    if (p == LinearFilter) return gl.LINEAR;
    if (p == LinearMipMapNearestFilter) return gl.LINEAR_MIPMAP_NEAREST;
    if (p == LinearMipMapLinearFilter) return gl.LINEAR_MIPMAP_LINEAR;

    if (p == UnsignedByteType) return gl.UNSIGNED_BYTE;
    if (p == UnsignedShort4444Type) return gl.UNSIGNED_SHORT_4_4_4_4;
    if (p == UnsignedShort5551Type) return gl.UNSIGNED_SHORT_5_5_5_1;
    if (p == UnsignedShort565Type) return gl.UNSIGNED_SHORT_5_6_5;

    if (p == ByteType) return gl.BYTE;
    if (p == ShortType) return gl.SHORT;
    if (p == UnsignedShortType) return gl.UNSIGNED_SHORT;
    if (p == IntType) return gl.INT;
    if (p == UnsignedIntType) return gl.UNSIGNED_INT;
    if (p == FloatType) return gl.FLOAT;

    extension = extensions.get('OES_texture_half_float');

    if (extension != null) {
      if (p == HalfFloatType) return gl.OesTextureHalfFloat.HALF_FLOAT_OES;
    }

    if (p == AlphaFormat) return gl.ALPHA;
    if (p == RGBFormat) return gl.RGB;
    if (p == RGBAFormat) return gl.RGBA;
    if (p == LuminanceFormat) return gl.LUMINANCE;
    if (p == LuminanceAlphaFormat) return gl.LUMINANCE_ALPHA;

    if (p == AddEquation) return gl.FUNC_ADD;
    if (p == SubtractEquation) return gl.FUNC_SUBTRACT;
    if (p == ReverseSubtractEquation) return gl.FUNC_REVERSE_SUBTRACT;

    if (p == ZeroFactor) return gl.ZERO;
    if (p == OneFactor) return gl.ONE;
    if (p == SrcColorFactor) return gl.SRC_COLOR;
    if (p == OneMinusSrcColorFactor) return gl.ONE_MINUS_SRC_COLOR;
    if (p == SrcAlphaFactor) return gl.SRC_ALPHA;
    if (p == OneMinusSrcAlphaFactor) return gl.ONE_MINUS_SRC_ALPHA;
    if (p == DstAlphaFactor) return gl.DST_ALPHA;
    if (p == OneMinusDstAlphaFactor) return gl.ONE_MINUS_DST_ALPHA;

    if (p == DstColorFactor) return gl.DST_COLOR;
    if (p == OneMinusDstColorFactor) return gl.ONE_MINUS_DST_COLOR;
    if (p == SrcAlphaSaturateFactor) return gl.SRC_ALPHA_SATURATE;

    extension = extensions.get('WEBGL_compressed_texture_s3tc');

    if (extension != null) {
      if (p == RGB_S3TC_DXT1_Format) {
        return gl.CompressedTextureS3TC.COMPRESSED_RGB_S3TC_DXT1_EXT;
      }
      if (p == RGBA_S3TC_DXT1_Format) {
        return gl.CompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT1_EXT;
      }
      if (p == RGBA_S3TC_DXT3_Format) {
        return gl.CompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT3_EXT;
      }
      if (p == RGBA_S3TC_DXT5_Format) {
        return gl.CompressedTextureS3TC.COMPRESSED_RGBA_S3TC_DXT5_EXT;
      }
    }

    extension = extensions.get('WEBGL_compressed_texture_pvrtc');

    if (extension != null) {
      if (p == RGB_PVRTC_4BPPV1_Format) {
        return gl.CompressedTexturePvrtc.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;
      }
      if (p == RGB_PVRTC_2BPPV1_Format) {
        return gl.CompressedTexturePvrtc.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;
      }
      if (p == RGBA_PVRTC_4BPPV1_Format) {
        return gl.CompressedTexturePvrtc.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;
      }
      if (p == RGBA_PVRTC_2BPPV1_Format) {
        return gl.CompressedTexturePvrtc.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG;
      }
    }

    extension = extensions.get('EXT_blend_minmax');

    if (extension != null) {
      if (p == MinEquation) return gl.ExtBlendMinMax.MIN_EXT;
      if (p == MaxEquation) return gl.ExtBlendMinMax.MAX_EXT;
    }

    return 0;
  }

  // Allocations

  int allocateBones(Object3D object) {
    if (_supportsBoneTextures &&
        object != null &&
        object is SkinnedMesh &&
        object.skeleton != null &&
        object.skeleton.useVertexTexture) {
      return 1024;
    } else {
      // default for when object is not specified
      // (for example when prebuilding shader to be used with multiple objects)
      //
      //  - leave some extra space for other uniforms
      //  - limit here is ANGLE's 254 max uniform vectors
      //    (up to 54 should be safe)

      var nVertexUniforms = _gl.getParameter(gl.MAX_VERTEX_UNIFORM_VECTORS);
      var nVertexMatrices = ((nVertexUniforms - 20) / 4).floor();

      var maxBones = nVertexMatrices;

      if (object != null && object is SkinnedMesh) {
        maxBones = math.min(object.skeleton.bones.length, maxBones);

        if (maxBones < object.skeleton.bones.length) {
          warn('WebGLRenderer: too many bones - ${object.skeleton.bones.length}' +
              ', this GPU supports just $maxBones (try OpenGL instead of ANGLE)');
        }
      }

      return maxBones;
    }
  }

  Map<String, int> allocateLights(List<Light> lights) {
    var dirLights = 0;
    var pointLights = 0;
    var spotLights = 0;
    var hemiLights = 0;

    for (var l = 0; l < lights.length; l++) {
      var light = lights[l];

      if (light is ShadowCaster && light.onlyShadow || !light.visible) continue;

      if (light is DirectionalLight) dirLights++;
      if (light is PointLight) pointLights++;
      if (light is SpotLight) spotLights++;
      if (light is HemisphereLight) hemiLights++;
    }

    return {
      'directional': dirLights,
      'point': pointLights,
      'spot': spotLights,
      'hemi': hemiLights
    };
  }

  int allocateShadows(List<Light> lights) {
    var maxShadows = 0;

    lights.where((l) => l.castShadow).forEach((light) {
      if (light is SpotLight) maxShadows++;
      if (light is DirectionalLight && !light.shadowCascade) maxShadows++;
    });

    return maxShadows;
  }
}

//
// Rendering Info classes by nelsonsilva
//

/// An object with a series of statistical information about the graphics board
/// memory and the rendering process.
///
/// Useful for debugging or just for the sake of curiosity.
class WebGLRendererInfo {
  WebGLRendererMemoryInfo memory = new WebGLRendererMemoryInfo();
  WebGLRendererRenderInfo render = new WebGLRendererRenderInfo();
}

class WebGLRendererMemoryInfo {
  int programs = 0;
  int geometries = 0;
  int textures = 0;
  String toString() =>
      '{programs: $programs, geometries: $geometries, textures: $textures}';
}

class WebGLRendererRenderInfo {
  int calls = 0;
  int vertices = 0;
  int faces = 0;
  int points = 0;
  String toString() =>
      '{calls: $calls, vertices: $vertices, faces: $faces, points: $points}';
}

//
// Wrapper classes for WebGL stuff by nelsonsilva
//

class WebGLObject {
  int id;
  Object3D object;
  Material opaque, transparent;
  bool render;
  double z;
  Material material;

  WebGLObject({this.id, this.material, this.object, this.opaque,
      this.transparent, this.render: true, this.z: 0.0});
}

class GeometryProgram {
  int geometryId, programId, wireframeBit;
  void set(int geometryId, int programId, int wireframeBit) {
    this.geometryId = geometryId;
    this.programId = programId;
    this.wireframeBit = wireframeBit;
  }
  void reset() {
    geometryId = programId = wireframeBit = null;
  }
  bool operator ==(GeometryProgram other) => geometryId == other.geometryId &&
      programId == other.programId &&
      wireframeBit == other.wireframeBit;
}

class ImageList extends Object with ListMixin {
  int loadCount;
  List _images;
  Map<String, dynamic> props;

  // WebGL
  gl.Texture __webglTextureCube;

  ImageList(size)
      : props = {},
        _images = new List(size);

  ImageList.from(ImageList other)
      : props = {},
        _images = new List.from(other._images);

  operator [](int index) => _images[index];
  void operator []=(int index, img) {
    _images[index] = img;
  }
  int get length => _images.length;
  void set length(int size) {
    _images.length = size;
  }
}
