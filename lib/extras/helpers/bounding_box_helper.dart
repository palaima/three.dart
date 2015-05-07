/*
 * @author WestLangley / http://github.com/WestLangley
 */

part of three;

/// a helper to show the world-axis-aligned bounding box for an object
class BoundingBoxHelper extends Mesh {
  Object3D object;
  Aabb3 box = new Aabb3();

  BoundingBoxHelper(this.object, [num hex = 0x888888])
      : super(new BoxGeometry(1.0, 1.0, 1.0), new MeshBasicMaterial(color: hex, wireframe: true));

  void update() {
    box.setFromObject(object);
    scale.setFrom(box.size);
    box.copyCenter(position);
  }
}
