/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r71
 */

part of three;

class ImageLoader {
  String crossOrigin;

  LoadingManager manager;

  StreamController _onLoadController = new StreamController();
  Stream get onLoad => _onLoadController.stream;

  StreamController _onErrorController = new StreamController();
  Stream get onError => _onErrorController.stream;

  ImageLoader([LoadingManager manager]) : this.manager = manager != null ? manager : defaultLoadingManager;

  ImageElement load(String url) {
    var cached = _cache[url];

    if (cached != null) {
      _onLoadController.add(cached);
      return null;
    }

    var image = new ImageElement();

    image.onLoad.listen((_) {
      _cache[url] = image;
      _onLoadController.add(image);
      manager.itemEnd(url);
    });

    image.onError.listen((event) {
      _onErrorController.add(event);
    });

    if (crossOrigin != null) {
      image.crossOrigin = crossOrigin;
    }

    image.src = url;

    manager.itemStart(url);

    return image;
  }
}
