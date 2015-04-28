/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three;

/// Abstract base class for lights.
class Light extends Object3D {
  String type = 'Light';

  /// Color of the light.
  Color color;

  CameraHelper _cameraHelper;

  /// This creates a light with color.
  Light(num hex)
      : color = new Color(hex),
        super();

  Light clone([Light light, bool recursive = true]) {
    if (light == null) light = new Light(color.getHex());
    super.clone(light, recursive);
    return light;
  }
}

abstract class ShadowCaster {
  bool castShadow;
  bool onlyShadow;

  //

  double shadowCameraNear;
  double shadowCameraFar;

  double shadowCameraLeft;
  double shadowCameraRight;
  double shadowCameraTop;
  double shadowCameraBottom;

  bool shadowCameraVisible;

  double shadowBias;
  double shadowDarkness;

  int shadowMapWidth;
  int shadowMapHeight;

  //

  bool shadowCascade;

  Vector3 shadowCascadeOffset;
  int shadowCascadeCount;

  List<double>  shadowCascadeBias;
  List<double> shadowCascadeWidth;
  List<double>  shadowCascadeHeight;

  List<double>  shadowCascadeNearZ;
  List<double>  shadowCascadeFarZ;

  List<VirtualLight> shadowCascadeArray;

  WebGLRenderTarget shadowMap;
  Vector2 shadowMapSize;
  Camera shadowCamera;
  Matrix4 shadowMatrix;
}