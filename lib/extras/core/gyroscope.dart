/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.extras.core;

class Gyroscope extends Object3D {
  Vector3 translationWorld = new Vector3.zero();
  Quaternion quaternionObject = new Quaternion.identity();
  Vector3 scaleObject = new Vector3.zero();

  Vector3 translationObject = new Vector3.zero();
  Quaternion quaternionWorld = new Quaternion.identity();
  Vector3 scaleWorld = new Vector3.zero();

  void updateMatrixWorld({bool force: false}) {
    if (matrixAutoUpdate) {
      updateMatrix();
    }

    // Update matrixWorld.
    if (matrixWorldNeedsUpdate || force) {
      if (parent != null) {
        matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);

        matrixWorld.decompose(translationWorld, quaternionWorld, scaleWorld);
        matrix.decompose(translationObject, quaternionObject, scaleObject);

        matrixWorld.setFromTranslationRotationScale(translationWorld, quaternionObject, scaleWorld);
      } else {
        matrixWorld.setFrom(matrix);
      }

      matrixWorldNeedsUpdate = false;

      force = true;
    }

    // Update children.
    for (var i = 0; i < children.length; i++) {
      children[i].updateMatrixWorld(force: force);
    }
  }
}
