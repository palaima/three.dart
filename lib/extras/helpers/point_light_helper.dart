part of three.extras.helpers;

class PointLightHelper extends Mesh {
  PointLight light;
  PointLightHelper(this.light, double sphereSize)
      : super(new SphereGeometry(sphereSize, 4, 2),
          new MeshBasicMaterial(wireframe: true, fog: false)) {
    light.updateMatrixWorld();

    material.color.setFrom(light.color);
    material.color.multiplyScalar(light.intensity);

    matrix = light.matrixWorld;
    matrixAutoUpdate = false;
  }

  void dispose() {
    geometry.dispose();
    material.dispose();
  }

  void update() {
    material.color.setFrom(light.color);
    material.color.multiplyScalar(light.intensity);
  }
}
