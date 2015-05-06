/*
 * @author mr.doob / http://mrdoob.com/
 * @author mikael emtinger / http://gomo.se
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * based on r71
 */

part of three;

class Camera extends Object3D {
  Matrix4 matrixWorldInverse = new Matrix4.identity();
  Matrix4 projectionMatrix = new Matrix4.identity();

  double near;
  double far;

  Camera([this.near, this.far]) : super();

  Vector3 getWorldDirection([Vector3 optionalTarget]) {
    var result = optionalTarget != null ? optionalTarget : new Vector3.zero();
    getWorldQuaternion(_q);
    return result.setValues(0.0, 0.0, -1.0)..applyQuaternion(_q);
  }

  void lookAt(Vector3 vector) {
    setViewMatrix(_m, position, vector, up);
    _m.invert();
    quaternion.setFromRotation4(_m);
  }

  /// Returns clone of [this].
  Camera clone([Camera camera, bool recursive = true]) {
    if (camera == null) camera = new Camera(near, far);

    super.clone(camera, recursive);

    camera.matrixWorldInverse.setFrom(matrixWorldInverse);
    camera.projectionMatrix.setFrom(projectionMatrix);

    return camera;
  }

  static final Matrix4 _m = new Matrix4.zero();
  static final Quaternion _q = new Quaternion.identity();
}
