part of three;

class ImageLoader {
  String crossOrigin;

  StreamController _onLoadController = new StreamController();
  Stream get onLoad => _onLoadController.stream;

  StreamController _onErrorController = new StreamController();
  Stream get onError => _onErrorController.stream;

  ImageLoader()
      : crossOrigin = null,
        super();

  load(String url, [ImageElement image = null]) {

    if (image == null) image = new ImageElement();

    image.onLoad.listen((_) {
      _onLoadController.add(image);
    });

    image.onError.listen((_) {
      _onErrorController.addError("Couldn\'t load URL [$url]");
    });

    if (crossOrigin != null) image.crossOrigin = crossOrigin;

    image.src = url;

  }

}
