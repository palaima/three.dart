/*
 * @author alteredq / http://alteredqualia.com/
 */

part of three.textures;

class DataTexture extends Texture {
  DataTexture._internal(DataImage image, int width, int height, int format,
      int type, int mapping, int wrapS, int wrapT, int magFilter, int minFilter)
      : super(image, mapping, wrapS, wrapT, magFilter, minFilter, format, type);

  factory DataTexture(TypedData data, int width, int height,
      {int format: RGBAFormat, int type: UnsignedByteType,
      int mapping: Texture.defaultMapping, int wrapS: ClampToEdgeWrapping,
      int wrapT: ClampToEdgeWrapping, int magFilter: LinearFilter,
      int minFilter: LinearMipMapLinearFilter}) {
    return new DataTexture._internal(new DataImage(data, width, height), width,
        height, format, type, mapping, wrapS, wrapT, magFilter, minFilter);
  }

  DataTexture clone([DataTexture texture]) {
    texture = new DataTexture(null, null, null);
    super.clone(texture);
    return texture;
  }
}

class DataImage {
  TypedData data;
  int width, height;
  DataImage(this.data, this.width, this.height);
}
