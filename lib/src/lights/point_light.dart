/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r71
 */

part of three.lights;

/// Affects objects using MeshLambertMaterial or MeshPhongMaterial.
class PointLight extends Light {
  String type = 'PointLight';

  /// Light's intensity.
  double intensity;

  /// If non-zero, light will attenuate linearly from maximum intensity at light position down to zero at distance.
  double distance;

  double decay;

  /// Creates a light at a specific position in the scene.
  ///
  /// The light shines in all directions (roughly similar to a light bulb.)
  PointLight(num color, [this.intensity = 1.0, this.distance = 0.0, this.decay = 1.0])
      : super(color) {
  }

  clone([light, recursive = true]) {
    throw new UnimplementedError();
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
