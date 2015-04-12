/*
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 */

part of three;

class Sprite extends Object3D {
  SpriteMaterial material;

  Sprite(SpriteMaterial material)
      : material = material == null ? new SpriteMaterial() : material,
        super();

  void updateMatrix() {
    matrix.setFromTranslationRotationScale(position, quaternion, scale);
    matrixWorldNeedsUpdate = true;
  }
}