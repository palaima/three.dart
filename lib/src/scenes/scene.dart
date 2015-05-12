/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * based on r71
 */

part of three.scenes;

class Scene extends Object3D {
  String type = 'Scene';

  Fog fog;
  Material overrideMaterial;

  bool autoUpdate = true;
}
