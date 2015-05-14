/*
 * @author mrdoob / http://mrdoob.com/
 */

part of three.extras.loaders;

class XHRLoader {
  LoadingManager manager;

  String crossOrigin;
  String responseType;

  StreamController _onLoadController = new StreamController();
  Stream get onLoad => _onLoadController.stream;

  StreamController _onProgressController = new StreamController();
  Stream get onProgress => _onProgressController.stream;

  StreamController _onErrorController = new StreamController();
  Stream get onError => _onErrorController.stream;

  XHRLoader([LoadingManager manager])
      : this.manager = manager != null ? manager : defaultLoadingManager;

  void load(String url) {
    var scope = this;

    var cached = Cache.get(url);

    if (cached != null) {
      _onLoadController.add(cached);
      return; // return cached;
    }

    var request = new HttpRequest();
    request.open('GET', url, async: true);

    request.onLoad.listen((event) {
      Cache.add(url, request.response);
      _onLoadController.add(request.response);
      scope.manager.itemEnd(url);
    });

    request.onProgress.listen((event) {
      _onProgressController.add(event); // TODO try .pipe
    });

    request.onError.listen((event) {
      _onErrorController.add(event);
    });

//    if (crossOrigin != null) request.crossOrigin = crossOrigin;
    if (responseType != null) request.responseType = responseType;

    request.send(null);

    scope.manager.itemStart(url);
  }

  void setResponseType(String value) {
    responseType = value;
  }

  void setCrossOrigin(String value) {
    crossOrigin = value;
  }
}
