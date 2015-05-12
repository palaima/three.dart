/*
 * @author benaadams / https://twitter.com/ben_a_adams
 */

part of three.core;

class InterleavedBuffer {
  List array;
  int stride;

  bool needsUpdate = false;

  bool dynamic;

  Map updateRange = {'offset': 0, 'count': -1};

  Buffer buffer;

  int bytesPerElement;

  InterleavedBuffer(TypedData array, this.stride, {this.dynamic: false}) {
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
}