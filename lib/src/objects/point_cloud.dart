part of three;

class PointCloud extends Object3D {

  bool sortParticles;

  PointCloud(Geometry geometry, [Material material = null])
      : sortParticles = false,
        super() {
    if (material == null) {
      material = new PointCloudMaterial(color: new Math.Random().nextDouble() * 0xffffff);
    }
    this.material = material;

    if (geometry != null) {
      // calc bound radius
      if (geometry.boundingSphere == null) {
        geometry.computeBoundingSphere();
      }
      boundRadius = geometry.boundingSphere.radius;
      this.geometry = geometry;
    }

    frustumCulled = false;
  }

}
