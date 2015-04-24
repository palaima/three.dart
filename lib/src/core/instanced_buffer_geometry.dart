part of three;

class InstancedBufferGeometry extends BufferGeometry {
  String type = 'InstancedBufferGeometry';
  int maxInstancedCount;

  void addDrawCall({int start, int count, int indexOffset: 0, int instances}) {
    drawcalls.add(new DrawCall(start: start, count: count, index: indexOffset, instances: instances));
  }

  clone() {
    throw new UnimplementedError();
  }

  noSuchMethod(Invocation invocation) {
    throw new UnimplementedError('Unimplemented ${invocation.memberName}');
  }
}