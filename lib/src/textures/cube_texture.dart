/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r71
 */

part of three.textures;

class CubeTexture extends Texture {
  List images;

  CubeTexture(List images, {int mapping: CubeReflectionMapping,
      int wrapS: ClampToEdgeWrapping, int wrapT: ClampToEdgeWrapping,
      int magFilter: LinearFilter, int minFilter: LinearMipMapLinearFilter,
      int format: RGBAFormat, int type: UnsignedByteType, int anisotropy: 1})
      : this.images = images,
        super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type,
            anisotropy);

  CubeTexture clone([CubeTexture texture]) {
    if (texture == null) texture = new CubeTexture(images);
    super.clone(texture);
    return texture;
  }
}
