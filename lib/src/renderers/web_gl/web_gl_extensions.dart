/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

class WebGLExtensions {
  Map extensions = {};

  gl.RenderingContext _gl;

  WebGLExtensions(this._gl);

  Object get(String name) {
    if (extensions[name] != null) {
      return extensions[name];
    }

    var extension;

    try {
      switch (name) {
        case 'EXT_texture_filter_anisotropic':
          extension = [
            _gl.getExtension('EXT_texture_filter_anisotropic'),
            _gl.getExtension('MOZ_EXT_texture_filter_anisotropic'),
            _gl.getExtension('WEBKIT_EXT_texture_filter_anisotropic')
          ].firstWhere((e) => e != null);
          break;
        case 'WEBGL_compressed_texture_s3tc':
          extension = [
            _gl.getExtension('WEBGL_compressed_texture_s3tc'),
            _gl.getExtension('MOZ_WEBGL_compressed_texture_s3tc'),
            _gl.getExtension('WEBKIT_WEBGL_compressed_texture_s3tc')
          ].firstWhere((e) => e != null);
          break;
        case 'WEBGL_compressed_texture_pvrtc':
          extension = [
            _gl.getExtension('WEBGL_compressed_texture_pvrtc'),
            _gl.getExtension('WEBKIT_WEBGL_compressed_texture_pvrtc')
          ].firstWhere((e) => e != null);
          break;
      }
    } on StateError {
      warn('WebGLRenderer: $name extension not supported.');
    }

    extensions[name] = extension;

    return extension;
  }
}
