/*
 * @author mr.doob / http://mrdoob.com/
 * @author greggman / http://games.greggman.com/
 * @author zz85 / http://www.lab4games.net/zz85/blog
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * based on r71
 */

part of three;

/// Camera with orthographic projection.
class OrthographicCamera extends Camera {
  String type = 'OrthographicCamera';

  double zoom = 1.0;

  /// Camera frustum left plane.
  double left;

  /// Camera frustum right plane.
  double right;

  /// Camera frustum top plane.
  double top;

  /// Camera frustum bottom plane.
  double bottom;

  OrthographicCamera(this.left, this.right, this.top, this.bottom, [double near = 0.1, double far = 2000.0]) : super(near, far) {
    updateProjectionMatrix();
  }

  /// Updates the camera projection matrix.
  ///
  /// Must be called after change of parameters.
  void updateProjectionMatrix() {
    var dx = (right - left) / (2 * zoom);
    var dy = (top - bottom) / (2 * zoom);
    var cx = (right + left) / 2;
    var cy = (top + bottom) / 2;

    setOrthographicMatrix(projectionMatrix, cx - dx, cx + dx, cy - dy, cy + dy, near, far);
  }

  /// Returns clone of [this].
  OrthographicCamera clone([OrthographicCamera camera, bool recursive = true]) {
    camera = new OrthographicCamera(left, right, top, bottom, near, far)
      ..zoom = zoom;

    super.clone(camera, recursive);

    return camera;
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
