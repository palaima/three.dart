part of three;

class Attribute<T> {
  String type;
  List<T> value;

  Float32List array;
  Buffer buffer;
  int size = 1;

  String boundTo = null;
  bool needsUpdate = false;
  bool __webglInitialized = false;
  bool createUniqueBuffers = false;

  Attribute<T> __original;

  Attribute(this.type, this.value) {
    switch (type) {
      case 'v2': size = 2; break;
      case 'v3': size = 3; break;
      case 'v4': size = 4; break;
      case 'c': size = 3; break;
    }

    if (value == null) value = [];
  }

  Attribute clone() => new Attribute(type, value);

  factory Attribute.color([List<int> hex]) =>
      new Attribute<Color>("c", hex != null ? new List.generate(hex.length, (i) => hex[i]) : null);

  factory Attribute.float([List<double> v]) => new Attribute<double>("f", v);
  factory Attribute.int([List<int> v]) => new Attribute<int>("i", v);

  factory Attribute.vector2([List<Vector2> v]) => new Attribute<Vector2>("v2", v);
  factory Attribute.vector3([List<Vector3> v]) => new Attribute<Vector3>("v3", v);
  factory Attribute.vector4([List<Vector4> v]) => new Attribute<Vector4>("v4", v);
}