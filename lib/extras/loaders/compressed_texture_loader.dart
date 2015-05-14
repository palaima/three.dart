/*
 * @author mrdoob / http://mrdoob.com/
 *
 * Abstract Base class to block based textures loader (dds, pvr, ...)
 */

part of three.extras.loaders;

abstract class CompressedTextureLoader {
  StreamController _onLoadController = new StreamController();
  Stream get onLoad => _onLoadController.stream;

  parse(ByteBuffer buffer, bool loadMipmaps) {}

  CompressedTexture load(url) {
    var images = new ImageList(url.length);

    var texture = new CompressedTexture();
    texture.image = images;

    var loader = new XHRLoader();
    loader.setResponseType('arraybuffer');

    if (url is List) {
      var loaded = 0;

      loader.onLoad.listen((buffer) {
        var texDatas = parse(buffer, true);

        images[loaded] = new CompressedImage(
          width: texDatas['width'],
          height: texDatas['height'],
          format: texDatas['format'],
          mipmaps: texDatas['mipmaps']);

        loaded += 1;

        if (loaded == 6) {
          if (texDatas['mipmapCount'] == 1) texture.minFilter = LinearFilter;

          texture.format = texDatas['format'];
          texture.needsUpdate = true;

          _onLoadController.add(texture);
        }
      });

      for (var i = 0; i < url.length; ++i) {
        loader.load(url[i]);
      }
    } else {
      // compressed cubemap texture stored in a single DDS file

      loader.onLoad.listen((buffer) {
        var texDatas = parse(buffer, true);

        if (texDatas['isCubemap']) {
          var faces = texDatas['mipmaps'].length / texDatas['mipmapCount'];

          for (var f = 0; f < faces; f++) {
            images[f] = {'mipmaps': []};

            for (var i = 0; i < texDatas['mipmapCount']; i++) {
              images[f]['mipmaps'].add(texDatas['mipmaps'][f * texDatas['mipmapCount'] + i]);
              images[f]['format'] = texDatas['format'];
              images[f]['width'] = texDatas['width'];
              images[f]['height'] = texDatas['height'];
            }
          }
        } else {
          texture.image.width = texDatas['width'];
          texture.image.height = texDatas['height'];
          texture.mipmaps = texDatas['mipmaps'];
        }

        if (texDatas['mipmapCount'] == 1) {
          texture.minFilter = LinearFilter;
        }

        texture.format = texDatas['format'];
        texture.needsUpdate = true;

        _onLoadController.add(texture);
      });

      loader.load(url);
    }

    return texture;
  }
}
