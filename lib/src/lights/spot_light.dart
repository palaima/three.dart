/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three;

/// A point light that can cast shadow in one direction.
///
/// Affects objects using MeshLambertMaterial or MeshPhongMaterial.
class SpotLight extends Light implements ShadowCaster {
  String type = 'SpotLight';

  Object3D target = new Object3D();

  double intensity;
  double distance;
  double angle;
  int exponent;
  double decay;

  bool castShadow = false;
  bool onlyShadow = false;

  //

  double shadowCameraNear = 50.0;
  double shadowCameraFar = 5000.0;
  double shadowCameraFov = 50.0;

  bool shadowCameraVisible = false;

  double shadowBias = 0.0;
  double shadowDarkness = 0.5;

  int shadowMapWidth = 512;
  int shadowMapHeight = 512;

  //

  WebGLRenderTarget shadowMap;
  Vector2 shadowMapSize;
  Camera shadowCamera;
  Matrix4 shadowMatrix;

  SpotLight(num color, {this.intensity: 1.0, this.distance: 0.0, this.angle: Math.PI / 3,
    this.exponent: 10, this.decay: 1.0})
      : super(color) {
    position.setValues(0.0, 1.0, 0.0);
  }

  clone([light, recursive = true]) {
    throw new UnimplementedError();
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
