/*
 * @author mrdoob / http://mrdoob.com/
 */

part of three.renderers;

class WebGLTextures {
  Map _textures = {};
  gl.RenderingContext _gl;

  WebGLTextures(this._gl);

  Texture get(Texture texture) {
    if (_textures[texture.id] != null) {
      return _textures[texture.id];
    }

    return create(texture);
  }

  Texture create(Texture texture) {
    //texture._onDisposeSubscription = texture.onDispose.listen(delete);
    _textures[texture.id] = _gl.createTexture();
    return _textures[texture.id];
  }

  void delete(Texture texture) {
    //texture._onDisposeSubscription.cancel();
    _gl.deleteTexture(_textures[texture.id]);
    _textures[texture.id] = null;
  }
}
