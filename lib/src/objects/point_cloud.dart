/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */


part of three.objects;

class PointCloud extends Object3D implements GeometryMaterialObject {
  String type = 'PointCloud';

  IGeometry geometry;
  Material material;

  PointCloud([IGeometry geometry, Material material])
      : geometry = geometry != null ? geometry : new Geometry(),
        material = material != null ? material : new PointCloudMaterial(
            color: new math.Random().nextDouble() * 0xffffff);

  raycast(raycaster, intersects) {
    throw new UnimplementedError();
  }

  clone([Object3D object, bool recursive = true]) {
    throw new UnimplementedError();
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
