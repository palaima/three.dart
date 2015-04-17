/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
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

  factory BufferAttribute.int8(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Int8List(length), itemSize)..numItems = length;

  factory BufferAttribute.uint8(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Uint8List(length), itemSize)..numItems = length;

  factory BufferAttribute.int16(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Int16List(length), itemSize)..numItems = length;

  factory BufferAttribute.uint16(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Uint16List(length), itemSize)..numItems = length;

  factory BufferAttribute.int32(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Int32List(length), itemSize)..numItems = length;

  factory BufferAttribute.uint32(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Uint32List(length), itemSize)..numItems = length;

  factory BufferAttribute.float32(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Float32List(length), itemSize)..numItems = length;

  factory BufferAttribute.float64(int length, [int itemSize = 1]) =>
      new BufferAttribute(new Float64List(length), itemSize)..numItems = length;

  int get length => array.length;

  void copyAt(int index1, BufferAttribute attribute, int index2) {
    index1 *= itemSize;
    index2 *= attribute.itemSize;

    for (var i = 0; i < itemSize; i++) {
      array[index1 + i] = attribute.array[index2 + i];
    }

  }

  void copyArray(List array) {
    for (var i = 0; i < this.array.length; i++) {
      this.array[i] = array[i];
    }
  }

  void copyColorsArray(List<Color> colors) {
    var offset = 0;

    for (var i = 0; i < colors.length; i++) {
      var color = colors[i];

      if (color == null) {
        warn('BufferAttribute.copyColorsArray(): color is null $i');
        color = new Color.white();
      }

      array[offset++] = color.r;
      array[offset++] = color.g;
      array[offset++] = color.b;
    }
  }

  void copyFacesArray(List<Face3> faces) {
    var offset = 0;

    for (var i = 0; i < faces.length; i++) {
      var face = faces[i];

      array[offset++] = face.a;
      array[offset++] = face.b;
      array[offset++] = face.c;
    }
  }

  void copyVector2sArray(List<Vector2> vectors) {
    var offset = 0;

    for (var i = 0; i < vectors.length; i++) {
      var vector = vectors[i];

      if (vector == null) {
        warn('BufferAttribute.copyVector2sArray(): vector is null $i');
        vector = new Vector2.zero();
      }

      array[offset++] = vector.x;
      array[offset++] = vector.y;
    }
  }

  void copyVector3sArray(List<Vector3> vectors) {
    var offset = 0;

    for (var i = 0; i < vectors.length; i ++) {
      var vector = vectors[i];

      if (vector == null) {
        warn('BufferAttribute.copyVector3sArray(): vector is null $i');
        vector = new Vector3.zero();
      }

      array[offset++] = vector.x;
      array[offset++] = vector.y;
      array[offset++] = vector.z;
    }
  }

  void set(value, offset) {
    if (offset == null) offset = 0;
    array[offset] = value;
  }

  void setX(int index, x) {
    array[index * itemSize] = x;
  }

  void setY(int index, y) {
    array[index * itemSize + 1] = y;
  }

  void setZ(int index, z) {
    array[index * itemSize + 2] = z;
  }

  void setXY(int index, x, y) {
    index *= itemSize;
    array[index    ] = x;
    array[index + 1] = y;
  }

  void setXYZ(int index, x, y, z) {
    index *= itemSize;
    array[index    ] = x;
    array[index + 1] = y;
    array[index + 2] = z;
  }

  void setXYZW(int index, x, y, z, w) {
    index *= itemSize;
    array[index    ] = x;
    array[index + 1] = y;
    array[index + 2] = z;
    array[index + 3] = w;
  }

  BufferAttribute clone() {
    //return new BufferAttribute(new array.constructor(array), itemSize);
  }
}