part of three.objects;

typedef void ImmediateRenderCallback(ImmediateRenderObject object);

abstract class ImmediateRenderObject extends Object3D {
  void render(ImmediateRenderCallback renderCallback);

  bool hasPositions;
  bool hasNormals;
  bool hasUvs;
  bool hasColors;

  Float32List positionArray;
  Float32List normalArray;
  Float32List colorArray;
  Float32List uvArray;

  int count;
}
