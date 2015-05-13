part of three.renderers;

class Attribute {
  String type;
  List value;

  Attribute._(this.type, value)
      : this.value = value != null ? value : [];

  factory Attribute.float([List<double> v]) => new Attribute._('f', v);
  factory Attribute.color([List<int> hex]) => new Attribute._('c', hex);
  factory Attribute.vector3([List<Vector3> v]) => new Attribute._('v3', v);
}
