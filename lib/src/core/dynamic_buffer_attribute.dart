/*
 * @author benaadams / https://twitter.com/ben_a_adams
 */

part of three.core;

class DynamicBufferAttribute extends BufferAttribute {
  Map updateRange = {'offset': 0, 'count': -1};

  DynamicBufferAttribute(TypedData array, int itemSize)
      : super(array, itemSize);

  clone() {
    throw new UnimplementedError();
  }
}