/*
 * @author benaadams / https://twitter.com/ben_a_adams
 */


part of three;

class InstancedInterleavedBuffer extends InterleavedBuffer {
  int meshPerAttribute;

  InstancedInterleavedBuffer(TypedData array, stride, {bool dynamic: false, this.meshPerAttribute: 1})
      : super(array, stride, dynamic: dynamic);
}