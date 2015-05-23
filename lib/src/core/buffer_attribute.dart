/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three.core;

class Buffer {
  gl.RenderingContext context;
  gl.Buffer _glbuffer;
  String belongsToAttribute;

  Buffer(this.context) {
    _glbuffer = context.createBuffer();
  }

  void bind(int target) {
    context.bindBuffer(target, _glbuffer);
  }
}

class BufferAttribute {
  List array;
  int itemSize;
  int numItems;

  bool needsUpdate = false;
  BufferAttribute(TypedData array, this.itemSize) {
    this.array = array as List;

    if (array is Float32List) bytesPerElement = Float32List.BYTES_PER_ELEMENT;
    else if (array is Int16List) bytesPerElement = Int16List.BYTES_PER_ELEMENT;
    else if (array is Int8List) bytesPerElement = Int8List.BYTES_PER_ELEMENT;
    else if (array is Uint8List) bytesPerElement = Uint8List.BYTES_PER_ELEMENT;
    else if (array is Uint16List) bytesPerElement = Uint16List.BYTES_PER_ELEMENT;
    else if (array is Int32List) bytesPerElement = Int32List.BYTES_PER_ELEMENT;
    else if (array is Uint32List) bytesPerElement = Uint32List.BYTES_PER_ELEMENT;
    else if (array is Float64List) bytesPerElement = Float64List.BYTES_PER_ELEMENT;
  }

  // Used in WebGL Renderer
  Buffer buffer;
  int bytesPerElement;

  var updateRange;

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

  @Deprecated('.length has been renamed to .count.')
  int get length {
    return count;
  }

  int get count => array.length ~/ itemSize;

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

    for (var i = 0; i < vectors.length; i++) {
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

  void copyVector4sArray(List<Vector4> vectors) {
    var offset = 0;

    for (var i = 0; i < vectors.length; i++) {
      var vector = vectors[i];

      if (vector == null) {
        warn('BufferAttribute.copyVector4sArray(): vector is undefined $i');
        vector = new Vector4.identity();
      }

      array[offset++] = vector.x;
      array[offset++] = vector.y;
      array[offset++] = vector.z;
      array[offset++] = vector.w;
    }
  }

  void set(num value, int offset) {
    if (offset == null) offset = 0;
    array[offset] = value;
  }

  num getX(int index) => array[index * itemSize];

  void setX(int index, num x) {
    array[index * itemSize] = x;
  }

  num getY(int index) => array[index * itemSize + 1];

  void setY(int index, num y) {
    array[index * itemSize + 1] = y;
  }

  num getZ(int index) => array[index * itemSize + 2];

  void setZ(int index, num z) {
    array[index * itemSize + 2] = z;
  }

  num getW(int index) => array[index * itemSize + 3];

  void setW(int index, num w) {
    array[index * itemSize + 3] = w;
  }

  void setXY(int index, num x, num y) {
    index *= itemSize;
    array[index] = x;
    array[index + 1] = y;
  }

  void setXYZ(int index, num x, num y, num z) {
    index *= itemSize;
    array[index] = x;
    array[index + 1] = y;
    array[index + 2] = z;
  }

  void setXYZW(int index, num x, num y, num z, num w) {
    index *= itemSize;
    array[index] = x;
    array[index + 1] = y;
    array[index + 2] = z;
    array[index + 3] = w;
  }

  BufferAttribute clone() {
    var array;
    if (this.array is Float32List) array = new Float32List.fromList(this.array);
    else if (this.array is Int16List) array = new Int16List.fromList(this.array);
    else if (this.array is Int8List) array = new Int8List.fromList(this.array);
    else if (this.array is Uint8List) array = new Uint8List.fromList(this.array);
    else if (this.array is Uint16List) array = new Uint16List.fromList(this.array);
    else if (this.array is Int32List) array = new Int32List.fromList(this.array);
    else if (this.array is Uint32List) array = new Uint32List.fromList(this.array);
    else if (this.array is Float64List) array = new Float64List.fromList(this.array);
    return new BufferAttribute(array, itemSize);
  }
}
