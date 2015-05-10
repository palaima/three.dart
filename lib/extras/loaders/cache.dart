part of three.extras.loaders;

abstract class Cache {
  static final Map _files = {};

  static void add(String key, Object file) {
    _files[key] = file;
  }

  static Object get(String key) => _files[key];

  static void remove(String key) {
    _files.remove(key);
  }

  static void clear() {
    _files.clear();
  }
}
