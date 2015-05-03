/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on https://github.com/mrdoob/three.js/blob/c9f111c3109b98b2449cf8849787096594e3282e/src/renderers/webgl/WebGLExtensions.js
 */

part of three;

class WebGLExtensions {
  Map extensions = {};

  gl.RenderingContext _gl;

  WebGLExtensions(this._gl);

  get(String name) {
    if (extensions[name] != null) {
      return extensions[name];
    }

    var extension;

    switch (name) {
      case 'EXT_texture_filter_anisotropic':
        extension = [
          _gl.getExtension('EXT_texture_filter_anisotropic'),
          _gl.getExtension('MOZ_EXT_texture_filter_anisotropic'),
          _gl.getExtension('WEBKIT_EXT_texture_filter_anisotropic')
        ].firstWhere((e) => e != null, orElse: () => null);
        break;
      case 'WEBGL_compressed_texture_s3tc':
        extension = [
          _gl.getExtension('WEBGL_compressed_texture_s3tc'),
          _gl.getExtension('MOZ_WEBGL_compressed_texture_s3tc'),
          _gl.getExtension('WEBKIT_WEBGL_compressed_texture_s3tc')
        ].firstWhere((e) => e != null, orElse: () => null);
        break;
      case 'WEBGL_compressed_texture_pvrtc':
        extension = [
          _gl.getExtension('WEBGL_compressed_texture_pvrtc'),
          _gl.getExtension('WEBKIT_WEBGL_compressed_texture_pvrtc')
        ].firstWhere((e) => e != null, orElse: () => null);
        break;
      default:
        extension = _gl.getExtension(name);
    }

    if (extension == null) {
      warn('WebGLRenderer: $name extension not supported.');
    }

    extensions[name] = extension;

    return extension;
  }
}
