/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.lights;

/// A light source positioned directly above the scene.
class HemisphereLight extends Light {
  String type = 'HemisphereLight';

  /// Light's ground color.
  Color groundColor;

  /// Light's intensity.
  double intensity;

  HemisphereLight(num skyColor, num groundColor, {this.intensity: 1.0})
      : groundColor = new Color(groundColor),
        super(skyColor) {
    position = new Vector3(0.0, 100.0, 0.0);
  }

  clone([light, recursive = true]) {
    throw new UnimplementedError();
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
