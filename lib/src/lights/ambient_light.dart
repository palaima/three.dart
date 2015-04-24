/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r71
 */

part of three;

/// This light's color gets applied to all the objects in the scene globally.
class AmbientLight extends Light {
  String type = 'AmbientLight';

  /// This creates an Ambientlight with a color.
  AmbientLight(num hex) : super(hex);

  Light clone([AmbientLight light, bool recursive = true]) {
    light = new AmbientLight(color.getHex());
    super.clone(light, recursive);
    return light;
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
