/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r71
 */

part of three.textures;

class CubeTexture extends Texture {
  List images;

  CubeTexture._(List images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy)
      : this.images = images,
        super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

  factory CubeTexture(List images, [mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy]) {
    if (mapping == null) mapping  = CubeReflectionMapping;

    return new CubeTexture._(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
  }

  clone() {
    throw new UnimplementedError();
  }
}
