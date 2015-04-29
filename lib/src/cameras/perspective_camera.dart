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

/// Camera with perspective projection.
class PerspectiveCamera extends Camera {
  String type = 'PerspectiveCamera';

  double zoom = 1.0;

  /// Camera frustum vertical field of view, from bottom to top of view, in degrees.
  double fov;

  /// Camera frustum aspect ratio, window width divided by window height.
  double aspect;

  double _fullWidth;
  double _fullHeight;
  double _x;
  double _y;
  double _width;
  double _height;

  PerspectiveCamera([this.fov = 50.0, this.aspect = 1.0, double near = 0.1, double far = 2000.0])
      : super(near, far) {

    updateProjectionMatrix();
  }

  /// Uses Focal Length (in mm) to estimate and set FOV
  /// 35mm (fullframe) camera is used if frame size is not specified.
  ///
  /// Formula based on http://www.bobatkins.com/photography/technical/field_of_view.html
  void setLens(double focalLength, [double frameHeight = 24.0]) {
    fov = 2 * ThreeMath.radToDeg(Math.atan(frameHeight / (focalLength * 2)));
    updateProjectionMatrix();
  }

  /**
   * Sets an offset in a larger frustum. This is useful for multi-window or
   * multi-monitor/multi-machine setups.
   *
   * For example, if you have 3x2 monitors and each monitor is 1920x1080 and
   * the monitors are in grid like this
   *
   *   +---+---+---+
   *   | A | B | C |
   *   +---+---+---+
   *   | D | E | F |
   *   +---+---+---+
   *
   * then for each monitor you would call it like this
   *
   *   var w = 1920;
   *   var h = 1080;
   *   var fullWidth = w * 3;
   *   var fullHeight = h * 2;
   *
   *   --A--
   *   camera.setOffset( fullWidth, fullHeight, w * 0, h * 0, w, h );
   *   --B--
   *   camera.setOffset( fullWidth, fullHeight, w * 1, h * 0, w, h );
   *   --C--
   *   camera.setOffset( fullWidth, fullHeight, w * 2, h * 0, w, h );
   *   --D--
   *   camera.setOffset( fullWidth, fullHeight, w * 0, h * 1, w, h );
   *   --E--
   *   camera.setOffset( fullWidth, fullHeight, w * 1, h * 1, w, h );
   *   --F--
   *   camera.setOffset( fullWidth, fullHeight, w * 2, h * 1, w, h );
   *
   *   Note there is no reason monitors have to be the same size or in a grid.
   */
  void setViewOffset(double fullWidth, double fullHeight, double x, double y, double width, double height) {
    _fullWidth = fullWidth;
    _fullHeight = fullHeight;
    _x = x;
    _y = y;
    _width = width;
    _height = height;

    updateProjectionMatrix();
  }

  /// Updates the camera projection matrix.
  ///
  /// Must be called after change of parameters.
  void updateProjectionMatrix() {
    var _fov = 2 * Math.atan(Math.tan(ThreeMath.degToRad(fov) * 0.5) / zoom);

    if (_fullWidth != null) {
      var aspect = _fullWidth / _fullHeight;
      var top = Math.tan(_fov * 0.5) * near;
      var bottom = -top;
      var left = aspect * bottom;
      var right = aspect * top;
      var width = (right - left).abs();
      var height = (top - bottom).abs();

      setFrustumMatrix(
          projectionMatrix,
          left + _x * width / _fullWidth,
          left + (_x + _width) * width / _fullWidth,
          top - (_y + _height) * height / _fullHeight,
          top - _y * height / _fullHeight,
          near,
          far);
    } else {
      projectionMatrix = makePerspectiveMatrix(_fov, aspect, near, far);
    }
  }

  /// Returns clone of [this].
  PerspectiveCamera clone([PerspectiveCamera camera, bool recursive = true]) {
    camera = new PerspectiveCamera();

    super.clone(camera);

    camera.zoom = zoom;

    camera.fov = fov;
    camera.aspect = aspect;
    camera.near = near;
    camera.far = far;

    return camera;
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
