library SceneUtils;

import "package:three/three.dart";

Object3D createMultiMaterialObject(Geometry geometry, List<Material> materials) {
  var group = new Object3D();
  materials.forEach((material) => group.add(new Mesh(geometry, material)));
  return group;
}

void detach(Object3D child, Object3D parent, Scene scene) {
  child.applyMatrix(parent.matrixWorld);
  parent.remove(child);
  scene.add(child);
}

void attach(Object3D child, Scene scene, Object3D parent) {
  var matrixWorldInverse = new Matrix4.copy(parent.matrixWorld)..invert();
  child.applyMatrix(matrixWorldInverse);
  scene.remove(child);
  parent.add(child);
}
