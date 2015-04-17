/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

class WebGLState {
  gl.RenderingContext _gl;
  Function _paramThreeToGL;

  Uint8List _newAttributes = new Uint8List(16);
  Uint8List _enabledAttributes = new Uint8List(16);

  var _currentBlending;
  var _currentBlendEquation;
  var _currentBlendSrc;
  var _currentBlendDst;
  var _currentBlendEquationAlpha;
  var _currentBlendSrcAlpha;
  var _currentBlendDstAlpha;

  var _currentDepthFunc;
  var _currentDepthTest;
  var _currentDepthWrite;

  var _currentColorWrite;

  var _currentDoubleSided;
  var _currentFlipSided;

  var _currentLineWidth;

  var _currentPolygonOffset;
  var _currentPolygonOffsetFactor;
  var _currentPolygonOffsetUnits;

  var _maxTextures;

  var _currentTextureSlot;
  var _currentBoundTextures = {};

  WebGLState(this._gl, this._paramThreeToGL) {
    _maxTextures = _gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS);
  }

  void initAttributes() {
    for (var i = 0; i < _newAttributes.length; i++) {
      _newAttributes[i] = 0;
    }
  }

  void enableAttribute(int attribute) {
    _newAttributes[attribute] = 1;

    if (_enabledAttributes[attribute] == 0) {
      _gl.enableVertexAttribArray(attribute);
      _enabledAttributes[attribute] = 1;
    }
  }

  void disableUnusedAttributes() {
    for (var i = 0; i < _enabledAttributes.length; i++) {
      if (_enabledAttributes[i] != _newAttributes[i]) {
        _gl.disableVertexAttribArray(i);
        _enabledAttributes[i] = 0;
      }
    }
  }

  void setBlending(int blending, int blendEquation, int blendSrc, int blendDst, int blendEquationAlpha, int blendSrcAlpha, int blendDstAlpha) {
    if (blending != _currentBlending) {
      if (blending == NoBlending) {
        _gl.disable(gl.BLEND);
      } else if (blending == AdditiveBlending) {
        _gl.enable(gl.BLEND);
        _gl.blendEquation(gl.FUNC_ADD);
        _gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
      } else if (blending == SubtractiveBlending) {
        _gl.enable(gl.BLEND);
        _gl.blendEquation(gl.FUNC_ADD);
        _gl.blendFunc(gl.ZERO, gl.ONE_MINUS_SRC_COLOR);
      } else if (blending == MultiplyBlending) {
        _gl.enable(gl.BLEND);
        _gl.blendEquation(gl.FUNC_ADD);
        _gl.blendFunc(gl.ZERO, gl.SRC_COLOR);
      } else if (blending == CustomBlending) {
        _gl.enable(gl.BLEND);
      } else {
        _gl.enable(gl.BLEND);
        _gl.blendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD);
        _gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      }

      _currentBlending = blending;
    }

    if (blending == CustomBlending) {
      blendEquationAlpha = [blendEquationAlpha, blendEquation].firstWhere((e) => e != null);
      blendSrcAlpha = [blendSrcAlpha, blendSrc].firstWhere((e) => e != null);
      blendDstAlpha = [blendDstAlpha, blendDst].firstWhere((e) => e != null);

      if (blendEquation != _currentBlendEquation || blendEquationAlpha != _currentBlendEquationAlpha) {
        _gl.blendEquationSeparate(_paramThreeToGL(blendEquation), _paramThreeToGL(blendEquationAlpha));

        _currentBlendEquation = blendEquation;
        _currentBlendEquationAlpha = blendEquationAlpha;
      }

      if (blendSrc != _currentBlendSrc ||
          blendDst != _currentBlendDst ||
          blendSrcAlpha != _currentBlendSrcAlpha ||
          blendDstAlpha != _currentBlendDstAlpha) {
        _gl.blendFuncSeparate(_paramThreeToGL(blendSrc), _paramThreeToGL(blendDst),
            _paramThreeToGL(blendSrcAlpha), _paramThreeToGL(blendDstAlpha));

        _currentBlendSrc = blendSrc;
        _currentBlendDst = blendDst;
        _currentBlendSrcAlpha = blendSrcAlpha;
        _currentBlendDstAlpha = blendDstAlpha;
      }
    } else {
      _currentBlendEquation = null;
      _currentBlendSrc = null;
      _currentBlendDst = null;
      _currentBlendEquationAlpha = null;
      _currentBlendSrcAlpha = null;
      _currentBlendDstAlpha = null;
    }
  }

  void setDepthFunc(int depthFunc) {
    if (_currentDepthFunc != depthFunc) {
      if (depthFunc != null) {
        switch (depthFunc) {
          case NeverDepth: _gl.depthFunc(gl.NEVER); break;
          case AlwaysDepth: _gl.depthFunc(gl.ALWAYS); break;
          case LessDepth: _gl.depthFunc(gl.LESS); break;
          case LessEqualDepth: _gl.depthFunc(gl.LEQUAL); break;
          case EqualDepth: _gl.depthFunc(gl.EQUAL); break;
          case GreaterEqualDepth: _gl.depthFunc(gl.GEQUAL); break;
          case GreaterDepth: _gl.depthFunc(gl.GREATER); break;
          case NotEqualDepth: _gl.depthFunc(gl.NOTEQUAL); break;
          default: _gl.depthFunc(gl.LEQUAL);
          }
      } else {
        _gl.depthFunc(gl.LEQUAL);
      }

      _currentDepthFunc = depthFunc;
    }
  }

  void setDepthTest(bool depthTest) {
    if (_currentDepthTest != depthTest) {
      if (depthTest) {
        _gl.enable(gl.DEPTH_TEST);
      } else {
        _gl.disable(gl.DEPTH_TEST);
      }

      _currentDepthTest = depthTest;
    }
  }

  void setDepthWrite(bool depthWrite) {
    if (_currentDepthWrite != depthWrite) {
      _gl.depthMask(depthWrite);
      _currentDepthWrite = depthWrite;
    }
  }

  void setColorWrite(bool colorWrite) {
    if (_currentColorWrite != colorWrite) {
      _gl.colorMask(colorWrite, colorWrite, colorWrite, colorWrite);
      _currentColorWrite = colorWrite;
    }
  }

  void setDoubleSided(bool doubleSided) {
    if (_currentDoubleSided != doubleSided) {
      if (doubleSided) {
        _gl.disable(gl.CULL_FACE);
      } else {
        _gl.enable(gl.CULL_FACE);
      }

      _currentDoubleSided = doubleSided;
    }
  }

  void setFlipSided(bool flipSided) {
    if (_currentFlipSided != flipSided) {
      if (flipSided) {
        _gl.frontFace(gl.CW);
      } else {
        _gl.frontFace(gl.CCW);
      }

      _currentFlipSided = flipSided;
    }
  }

  void setLineWidth(num width) {
    if (width != _currentLineWidth) {
      _gl.lineWidth(width);
      _currentLineWidth = width;
    }
  }

  void setPolygonOffset(polygonoffset, factor, units) {
    if (_currentPolygonOffset != polygonoffset) {
      if (polygonoffset) {
        _gl.enable(gl.POLYGON_OFFSET_FILL);
      } else {
        _gl.disable(gl.POLYGON_OFFSET_FILL);
      }

      _currentPolygonOffset = polygonoffset;
    }

    if (polygonoffset && (_currentPolygonOffsetFactor != factor || _currentPolygonOffsetUnits != units)) {
      _gl.polygonOffset(factor, units);

      _currentPolygonOffsetFactor = factor;
      _currentPolygonOffsetUnits = units;
    }
  }

  void activeTexture([int webglSlot]) {
    if (webglSlot == null) webglSlot = gl.TEXTURE0 + _maxTextures - 1;
    if (_currentTextureSlot != webglSlot) {
      _gl.activeTexture(webglSlot);
      _currentTextureSlot = webglSlot;
    }
  }

  void bindTexture(webglType, webglTexture) {
    if (_currentTextureSlot == null) {
      activeTexture();
    }

    var boundTexture = _currentBoundTextures[_currentTextureSlot];

    if (boundTexture == null) {
      boundTexture = {'type': null, 'texture': null};
      _currentBoundTextures[_currentTextureSlot] = boundTexture;
    }

    if (boundTexture.type != webglType || boundTexture.texture != webglTexture) {
      _gl.bindTexture(webglType, webglTexture);

      boundTexture.type = webglType;
      boundTexture.texture = webglTexture;
    }
  }

  void reset() {
    _enabledAttributes.map((_) => 0);

    _currentBlending = null;
    _currentDepthTest = null;
    _currentDepthWrite = null;
    _currentColorWrite = null;
    _currentDoubleSided = null;
    _currentFlipSided = null;
  }
}