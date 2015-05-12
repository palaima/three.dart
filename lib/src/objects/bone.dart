/*
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r66
 */

part of three.objects;

/// A bone which is part of a SkinnedMesh.
class Bone extends Object3D {
  /// The skin that contains this bone.
  SkinnedMesh skin;

  /// The matrix of the bone.
  Matrix4 skinMatrix = new Matrix4.identity();

  Bone(this.skin) : super();

  /// This updates the matrix of the bone and the matrices of its children.
  void update([Matrix4 parentSkinMatrix, bool forceUpdate = false]) {
    // update local
    if (matrixAutoUpdate) {
      if (forceUpdate) updateMatrix();
    }

    // update skin matrix
    if (forceUpdate || matrixWorldNeedsUpdate) {
      if (parentSkinMatrix != null) {
        skinMatrix = parentSkinMatrix * matrix;
      } else {
        skinMatrix.setFrom(matrix);
      }

      matrixWorldNeedsUpdate = false;
      forceUpdate = true;
    }

    // update children
    children.forEach((child) => child.update(skinMatrix, forceUpdate));
  }
}
