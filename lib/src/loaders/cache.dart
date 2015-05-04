part of three;

class Cache {
  static final Cache _cache = new Cache._();
  Map files = {};

  Cache._();

  factory Cache() => _cache;

  void add(String key, Object file) {
    files[key] = file;
  }

  Object get(String key) => files[key];

  void remove(String key) {
    files.remove(key);
  }

  void clear() {
    files = {};
  }

  Object operator [](String key) => files[key];
  void operator []=(String key, Object value) {
    files[key] = value;
  }
}
