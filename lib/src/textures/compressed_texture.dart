part of three.textures;

class CompressedTexture extends Texture {
  List<Map> mipmaps;

  bool flipY = false;

  bool generateMipmaps = false;

  CompressedTexture({this.mipmaps, int width, int height,
      int format: RGBAFormat, int type: UnsignedByteType,
      int mapping: Texture.defaultMapping, int wrapS: ClampToEdgeWrapping,
      int wrapT: ClampToEdgeWrapping, int magFilter: LinearFilter,
      int minFilter: LinearMipMapLinearFilter, int anisotropy: 1})
      : super(new CompressedImage(width: width, height: height), mapping, wrapS,
          wrapT, magFilter, minFilter, format, type, anisotropy);

  CompressedTexture clone([CompressedTexture texture]) {
    texture = new CompressedTexture();
    super.clone(texture);
    return texture;
  }
}

class CompressedImage {
  int width, height;
  int format;
  List<Map> mipmaps;
  CompressedImage({this.width, this.height, this.format, this.mipmaps});
}
