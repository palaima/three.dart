/*
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 */

part of three.objects;

class Sprite extends Object3D implements MaterialObject {
  SpriteMaterial material;

  Sprite(SpriteMaterial material)
      : material = material == null ? new SpriteMaterial() : material,
        super();

  void updateMatrix() {
    matrix.setFromTranslationRotationScale(position, quaternion, scale);
    matrixWorldNeedsUpdate = true;
  }
}