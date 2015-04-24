part of three;

class InstancedBufferAttribute extends DynamicBufferAttribute {
  bool dynamic;
  int meshPerAttribute;

  InstancedBufferAttribute(TypedData array, int itemSize, {this.meshPerAttribute: 1, this.dynamic: false})
      : super(array, itemSize);

  clone() {
    throw new UnimplementedError();
  }
}