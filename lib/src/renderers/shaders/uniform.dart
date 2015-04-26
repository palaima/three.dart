part of three;

class Uniform<T> {
  String type;
  T _value;
  bool needsUpdate;

  // cache the typed value
  bool _dirty = true;
  var _array;

  Uniform(this.type, value) {
    this.value = value;
  }

  T get value => _value;
  set value(v) {
     if (type == "f") v = v.toDouble();
    _dirty = true;
    _value = v;
  }

  get typedValue {
    if (!_dirty && (_array != null)) {
      return _array;
    }

    if ((type == "fv" || type == "fv1") && _value is! Float32List) {
      _array = new Float32List.fromList((_value as List).map((_) => _.toDouble()).toList());
    } else if ((type == "iv" || type == "iv1") && _value is! Int32List) {
      _array = new Int32List.fromList((_value as List).map((_) => _.toInt()).toList());
    } else if (type == "v2v") { // array of Vector2
      var values = _value as List<Vector2>;

        if (_array == null){
          _array = new Float32List(2 * values.length);
        }

        var typedValues = _array as Float32List;
        var offset;

        for (int i = 0; i < values.length; i ++){
          offset = i * 2;

          typedValues[offset]   = values[i].x;
          typedValues[offset + 1] = values[i].y;
        }

    } else if (type == "v3v"){ // array of Vector3
      var values = _value as List<Vector3>;
      if (_array == null){
        _array = new Float32List(3 * values.length);
      }

      var typedValues = _array as Float32List;
      var offset;

      for (int i = 0; i < values.length; i++){
        offset = i * 3;

        typedValues[offset]     = values[i].x;
        typedValues[offset + 1] = values[i].y;
        typedValues[offset + 2] = values[i].z;
      }
    } else if (type == "v4v") { // array of Vector4
      var values = _value as List<Vector4>;

      if (_array == null){
        _array = new Float32List(4 * values.length );
      }

      var typedValues = _array as Float32List;
      var offset;

      for (int i = 0; i < values.length; i++){
        offset = i * 4;

        typedValues[offset]     = values[i].x;
        typedValues[offset + 1] = values[i].y;
        typedValues[offset + 2] = values[i].z;
        typedValues[offset + 3] = values[i].w;
      }
    } else if (type == "m2") { // single Matrix2
      _array = (_value as Matrix2).storage;
    } else if (type == "m3") { // single Matrix3
      _array = (_value as Matrix3).storage;
    } else if (type == "m4") { // single Matrix4
      _array = (_value as Matrix4).storage;
    } else if (type == "m4v") { // array of Matrix4
      var lst = [];

      (_value as List<Matrix4>).forEach((m) { lst.addAll(m.storage); });
      _array = new Float32List.fromList(lst);
    } else {
      return _value;
    }

    return _array;
  }

  Uniform<T> clone() {
    var dst;

    if (value is Color ||
        value is Vector2 ||
        value is Vector3 ||
        value is Vector4 ||
        value is Matrix4 ||
        value is Texture){
      dst = (value as dynamic).clone();
    } else if (value is List){
      dst = new List.from(value as List);
    } else {
      dst = value;
    }

    return new Uniform(type, dst);
  }

  factory Uniform.color(num hex) => new Uniform<Color>("c", new Color(hex));

  factory Uniform.float([double v]) => new Uniform<double>("f", v);
  factory Uniform.floatv(List<double> v) => new Uniform<List<double>>("fv", v);
  factory Uniform.floatv1(List<double> v) => new Uniform<List<double>>("fv1", v);

  factory Uniform.int([int v]) => new Uniform<int>("i", v);
  factory Uniform.intv(List<int> v) => new Uniform<List<int>>("iv", v);
  factory Uniform.intv1(List<int> v) => new Uniform<List<int>>("iv1", v);

  factory Uniform.texture([Texture texture]) => new Uniform<Texture>("t", texture);
  factory Uniform.texturev([List<Texture> textures]) => new Uniform<List<Texture>>("tv", textures);

  factory Uniform.vector2v(List<Vector2> vectors) => new Uniform<List<Vector2>>("v2v", vectors);

  factory Uniform.vector2(double x, double y) => new Uniform<Vector2>("v2", new Vector2(x, y));
  factory Uniform.vector3(double x, double y, double z) => new Uniform<Vector3>("v3", new Vector3(x, y, z));
  factory Uniform.vector4(double x, double y, num z, double w) => new Uniform<Vector4>("v4", new Vector4(x, y, z, w));

  factory Uniform.matrix2(Matrix2 m) => new Uniform<Matrix2>("m2", m);
  factory Uniform.matrix3(Matrix3 m) => new Uniform<Matrix3>("m3", m);
  factory Uniform.matrix4(Matrix4 m) => new Uniform<Matrix4>("m4", m);

  factory Uniform.matrix4v(List<Matrix4> m) => new Uniform<List<Matrix4>>("m4v", m);
}