/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r71
 */

part of three;

class BufferAttribute {
  List array;
  int itemSize;
  int numItems;

  bool needsUpdate = false;
  BufferAttribute(this.array, this.itemSize);

  // Used in WebGL Renderer
  Buffer buffer;

  factory BufferAttribute.float32(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Float32List(length), itemSize)..numItems = length;

  factory BufferAttribute.int32(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Int32List(length), itemSize)..numItems = length;

  factory BufferAttribute.int16(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Int16List(length), itemSize)..numItems = length;


  get length => array.length;

  BufferAttribute copyAt(int index1, BufferAttribute attribute, int index2) {
    index1 *= itemSize;
    index2 *= attribute.itemSize;

    for (var i = 0; i < itemSize; i++) {
      array[index1 + i] = attribute.array[index2 + i];
    }

    return this;
  }

  BufferAttribute set(value, offset) {
    if (offset == null) offset = 0;
    array[offset] = value;
    return this;
  }

  BufferAttribute setX(int index, x) {
    array[index * itemSize] = x;
    return this;
  }

  BufferAttribute setY(int index, y) {
    array[index * itemSize + 1] = y;
    return this;
  }

  BufferAttribute setZ(int index, z) {
    array[index * itemSize + 2] = z;
    return this;
  }

  BufferAttribute setXY(int index, x, y) {
    index *= itemSize;
    array[index    ] = x;
    array[index + 1] = y;
    return this;
  }

  BufferAttribute setXYZ(int index, x, y, z) {
    index *= itemSize;
    array[index    ] = x;
    array[index + 1] = y;
    array[index + 2] = z;
    return this;
  }

  BufferAttribute setXYZW(int index, x, y, z, w) {
    index *= itemSize;
    array[index    ] = x;
    array[index + 1] = y;
    array[index + 2] = z;
    array[index + 3] = w;
    return this;
  }

  BufferAttribute clone() {
    //return new BufferAttribute(new array.constructor(array), itemSize);
  }
}