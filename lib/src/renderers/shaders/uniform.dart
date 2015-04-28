part of three;

class Uniform<T> {
  String type;

  var value;

  bool needsUpdate;

  var _array;

  Uniform(this.type, this.value);

  Uniform<T> clone() {
    var dst;

    if (value is Color ||
        value is Vector2 ||
        value is Vector3 ||
        value is Vector4 ||
        value is Matrix4 ||
        value is Texture) {
      dst = value.clone();
    } else if (value is List) {
      dst = value.toList();
    } else {
      dst = value;
    }

    return new Uniform(type, dst);
  }

  factory Uniform.color(num hex) => new Uniform('c', new Color(hex));

  factory Uniform.float([double v]) => new Uniform('f', v);
  factory Uniform.floatv([Float32List v]) => new Uniform('fv', v);
  factory Uniform.floatv1([Float32List v]) => new Uniform('fv1', v);

  factory Uniform.int([int v]) => new Uniform('i', v);
  factory Uniform.intv([Int32List v]) => new Uniform('iv', v);
  factory Uniform.intv1([Int32List v]) => new Uniform('iv1', v);

  factory Uniform.texture([Texture texture]) => new Uniform('t', texture);
  factory Uniform.texturev([List<Texture> textures]) => new Uniform('tv', textures);

  factory Uniform.vector2v([List<Vector2> vectors]) => new Uniform('v2v', vectors);

  factory Uniform.vector2(double x, double y) => new Uniform('v2', new Vector2(x, y));
  factory Uniform.vector3(double x, double y, double z) => new Uniform('v3', new Vector3(x, y, z));
  factory Uniform.vector4(double x, double y, num z, double w) =>
      new Uniform('v4', new Vector4(x, y, z, w));

  factory Uniform.matrix2([Matrix2 m]) => new Uniform('m2', m);
  factory Uniform.matrix3([Matrix3 m]) => new Uniform('m3', m);
  factory Uniform.matrix4([Matrix4 m]) => new Uniform('m4', m);

  factory Uniform.matrix4v([List<Matrix4> m]) => new Uniform('m4v', m);
}