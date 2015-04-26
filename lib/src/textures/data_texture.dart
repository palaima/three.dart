part of three;

class DataTexture extends Texture {
  DataTexture._internal(image, data, width, height, format, [type, mapping, wrapS, wrapT, magFilter, minFilter])
      : super(image, mapping, wrapS, wrapT, magFilter, minFilter, format, type);

  factory DataTexture(data, width, height, format, {type, mapping, wrapS, wrapT, magFilter, minFilter}) {
    return new DataTexture._internal(new DataImage(data, width, height), data, width, height, format, type, mapping, wrapS, wrapT, magFilter, minFilter);
  }
}

class DataImage {
  Float32List data;
  int width, height;
  DataImage(this.data, this.width, this.height);
}
