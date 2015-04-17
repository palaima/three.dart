/*
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

class WebGLShader {
  String _addLineNumbers(String string) {
    var lines = string.split('\n');

    for (var i = 0; i < lines.length; i++) {
      lines[i] = '${(i + 1)}: ${lines[i]}';
    }

    return lines.join('\n');
  }

  gl.Shader _shader;

  gl.Shader get() => _shader;

  WebGLShader(gl.RenderingContext _gl, int type, String string) {
    _shader = _gl.createShader(type);

    _gl.shaderSource(_shader, string);
    _gl.compileShader(_shader);

    if (!_gl.getShaderParameter(_shader, gl.COMPILE_STATUS)) {
      error('WebGLShader: Shader couldn\'t compile.');
    }

    if (_gl.getShaderInfoLog(_shader) != '') {
      warn('WebGLShader: gl.getShaderInfoLog() ${type == gl.VERTEX_SHADER ? 'vertex' : 'fragment'}' +
           '${_gl.getShaderInfoLog(_shader)} ${_addLineNumbers(string)}');
    }
  }
}
