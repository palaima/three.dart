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

  Vector3 getWorldDirection() =>
      new Vector3(0.0, 0.0, -1.0)..applyQuaternion(getWorldQuaternion());

  void lookAt(Vector3 vector) {
    var lookAt = makeViewMatrix(position, vector, up)..invert();
    quaternion.setFromRotation(lookAt.getRotation());
  }

  /// Returns clone of [this].
  Camera clone([Camera camera, bool recursive = true]) {
    if (camera == null) camera = new Camera(near, far);

    super.clone(camera, recursive);

    camera.matrixWorldInverse.setFrom(matrixWorldInverse);
    camera.projectionMatrix.setFrom(projectionMatrix);

    return camera;
  }
}
