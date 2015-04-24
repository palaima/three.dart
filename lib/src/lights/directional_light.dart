/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three;

/// Affects objects using MeshLambertMaterial or MeshPhongMaterial.
class DirectionalLight extends Light implements ShadowCaster {
  String type = 'DirectionalLight';

  Object3D target = new Object3D();

  double intensity;

  bool castShadow = false;
  bool onlyShadow = false;

  //

  double shadowCameraNear = 50.0;
  double shadowCameraFar = 5000.0;

  double shadowCameraLeft = -500.0;
  double shadowCameraRight = 500.0;
  double shadowCameraTop = 500.0;
  double shadowCameraBottom = -500.0;

  bool shadowCameraVisible = false;

  double shadowBias = 0.0;
  double shadowDarkness = 0.5;

  double shadowMapWidth = 512.0;
  double shadowMapHeight = 512.0;

  //

  bool shadowCascade = false;

  Vector3 shadowCascadeOffset = new Vector3(0.0, 0.0, -1000.0);
  int shadowCascadeCount = 2;

  List<double> shadowCascadeBias = [0, 0, 0];
  List<double> shadowCascadeWidth = [512, 512, 512];
  List<double> shadowCascadeHeight = [512, 512, 512];

  List<double> shadowCascadeNearZ = [-1.000, 0.990, 0.998];
  List<double> shadowCascadeFarZ = [0.990, 0.998, 1.000];

  List<VirtualLight> shadowCascadeArray = [];

  //

  WebGLRenderTarget shadowMap;
  Vector2 shadowMapSize;
  Camera shadowCamera;
  Matrix4 shadowMatrix;

  DirectionalLight(num color, [this.intensity = 1.0])
      : super(color) {
    position.setValues(0.0, 1.0, 0.0);
  }

  DirectionalLight clone([DirectionalLight light, bool recursive = true]) {
    light = new DirectionalLight(color.getHex(), intensity);

    super.clone(light);

    light.target = target.clone();

    light.castShadow = castShadow;
    light.onlyShadow = onlyShadow;

    //

    light.shadowCameraNear = shadowCameraNear;
    light.shadowCameraFar = shadowCameraFar;

    light.shadowCameraLeft = shadowCameraLeft;
    light.shadowCameraRight = shadowCameraRight;
    light.shadowCameraTop = shadowCameraTop;
    light.shadowCameraBottom = shadowCameraBottom;

    light.shadowCameraVisible = shadowCameraVisible;

    light.shadowBias = shadowBias;
    light.shadowDarkness = shadowDarkness;

    light.shadowMapWidth = shadowMapWidth;
    light.shadowMapHeight = shadowMapHeight;

    //

    light.shadowCascade = shadowCascade;

    light.shadowCascadeOffset.setFrom(shadowCascadeOffset);
    light.shadowCascadeCount = shadowCascadeCount;

    light.shadowCascadeBias = new List.from(shadowCascadeBias);
    light.shadowCascadeWidth = new List.from(shadowCascadeWidth);
    light.shadowCascadeHeight = new List.from(shadowCascadeHeight);

    light.shadowCascadeNearZ = new List.from(shadowCascadeNearZ);
    light.shadowCascadeFarZ = new List.from(shadowCascadeFarZ);

    return light;
  }
}
