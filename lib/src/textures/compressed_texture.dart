part of three.textures;

class CompressedTexture extends Texture {
  List<Map> mipmaps;

  bool flipY = false;

  bool generateMipmaps = false;

  CompressedTexture({this.mipmaps, width, height, format, type, mapping, wrapS, wrapT, magFilter, minFilter, anisotropy: 1})
      : super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy) {
    image = new CompressedImage(width: width, height: height);
  }
}

class CompressedImage {
  int width, height;
  int format;
  List<Map> mipmaps;
  CompressedImage({this.width, this.height, this.format, this.mipmaps});
}
