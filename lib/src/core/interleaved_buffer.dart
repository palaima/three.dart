/*
 * @author benaadams / https://twitter.com/ben_a_adams
 */

part of three;

class InterleavedBuffer {
  List array;
  int stride;

  bool needsUpdate = false;

  bool dynamic;

  Map updateRange = {'offset': 0, 'count': -1};

  InterleavedBuffer(TypedData array, this.stride, {this.dynamic: false}) {
    this.array = array as List;
  }
}