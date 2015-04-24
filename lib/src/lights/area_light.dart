/*
 * @author MPanknin / http://www.redplant.de/
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three;

class AreaLight extends Light {
  String type = 'AreaLight';

  Vector3 normal = new Vector3(0.0, -1.0, 0.0);
  Vector3 right = new Vector3(1.0, 0.0, 0.0);

  double intensity;

  double width = 1.0;
  double height = 1.0;

  double constantAttenuation = 1.5;
  double linearAttenuation = 0.5;
  double quadraticAttenuation = 0.1;

  AreaLight(num color, [this.intensity = 1.0])
    : super(color);
}
