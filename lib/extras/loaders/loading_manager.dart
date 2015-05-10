/*
 * @author mrdoob / http://mrdoob.com/
 */

part of three.extras.loaders;

class LoadingManager {
  int loaded = 0;
  int total = 0;

  StreamController _onLoadController = new StreamController();
  Stream get onLoad => _onLoadController.stream;

  void itemStart(url) {
    total++;
  }

  void itemEnd(url) {
    loaded++;

    if (loaded == total) {
      _onLoadController.add(null);
    }
  }
}

final LoadingManager defaultLoadingManager = new LoadingManager();
