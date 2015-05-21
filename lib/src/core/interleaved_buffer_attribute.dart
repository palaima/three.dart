part of three.core;

class InterleavedBufferAttribute implements BufferAttribute {
  InterleavedBuffer data;
  int itemSize;
  int offset;

  InterleavedBufferAttribute(this.data, this.itemSize, this.offset);

  @Deprecated('.length has been renamed to .count.')
  int get length {
    return count;
  }

  int get count => data.array.length ~/ data.stride;

  void setX(int index, num x) {
    data.array[index * data.stride + offset] = x;
  }

  void setY(int index, num y) {
    data.array[index * data.stride + offset + 1] = y;
  }

  void setZ(int index, num z) {
    data.array[index * data.stride + offset + 2] = z;
  }

  void setW(int index, num w) {
    data.array[index * data.stride + offset + 3] = w;
  }

  num getX(int index) => data.array[index * data.stride + offset];

  num getY(int index) => data.array[index * data.stride + offset + 1];

  num getZ(int index) => data.array[index * data.stride + offset + 2];

  num getW(int index) => data.array[index * data.stride + offset + 3];

  void setXY(int index, num x, num y) {
    index = index * data.stride + offset;

    data.array[index + 0] = x;
    data.array[index + 1] = y;
  }

  void setXYZ(int index, num x, num y, num z) {
    index = index * data.stride + offset;

    data.array[index + 0] = x;
    data.array[index + 1] = y;
    data.array[index + 2] = z;
  }

  void setXYZW(int index, num x, num y, num z, num w) {
    index = index * data.stride + offset;

    data.array[index + 0] = x;
    data.array[index + 1] = y;
    data.array[index + 2] = z;
    data.array[index + 3] = w;
  }

  noSuchMethod(Invocation invocation) {
    print("'${invocation.memberName}' not available in InterleavedBufferAttribute");
  }
}
