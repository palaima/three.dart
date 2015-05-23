/*
 * @author mrdoob / http://mrdoob.com/
 * @author marklundin / http://mark-lundin.com/
 * @author alteredq / http://alteredqualia.com/
 */

part of three.extras.effects;

class AnaglyphEffect {
  WebGLRenderer renderer;

  Matrix4 eyeRight = new Matrix4.identity();
  Matrix4 eyeLeft = new Matrix4.identity();
  double focalLength = 125.0;

  double _aspect;
  double _near;
  double _far;
  double _fov;

  PerspectiveCamera _cameraL;

  PerspectiveCamera _cameraR;

  OrthographicCamera _camera =
      new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0.0, 1.0);

  Scene _scene = new Scene();

  WebGLRenderTarget _renderTargetL;
  WebGLRenderTarget _renderTargetR;

  ShaderMaterial _material;

  AnaglyphEffect(this.renderer, [int width = 512, int height = 512]) {
    _cameraL = new PerspectiveCamera()..matrixAutoUpdate = false;

    _cameraR = new PerspectiveCamera()..matrixAutoUpdate = false;

    _renderTargetL = new WebGLRenderTarget(width, height,
        minFilter: LinearFilter, magFilter: NearestFilter, format: RGBAFormat);
    _renderTargetR = new WebGLRenderTarget(width, height,
        minFilter: LinearFilter, magFilter: NearestFilter, format: RGBAFormat);

    var uniforms = {
      "mapLeft": new Uniform.texture(_renderTargetL),
      "mapRight": new Uniform.texture(_renderTargetR)
    };

    var vertexShader = '''
varying vec2 vUv;
void main() {
 vUv = vec2( uv.x, uv.y );
 gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}
''';

    var fragmentShader = '''
uniform sampler2D mapLeft;
uniform sampler2D mapRight;
varying vec2 vUv;
void main() {
 vec4 colorL, colorR;
 vec2 uv = vUv;
 colorL = texture2D( mapLeft, uv );
 colorR = texture2D( mapRight, uv );

  // http://3dtv.at/Knowhow/AnaglyphComparison_en.aspx

 gl_FragColor = vec4( colorL.g * 0.7 + colorL.b * 0.3, colorR.g, colorR.b, colorL.a + colorR.a ) * 1.1;
}
''';

    _material = new ShaderMaterial(
        uniforms: uniforms,
        vertexShader: vertexShader,
        fragmentShader: fragmentShader);

    var mesh = new Mesh(new PlaneBufferGeometry(2.0, 2.0), _material);
    _scene.add(mesh);
  }

  void setSize(int width, int height) {
    if (_renderTargetL != null) _renderTargetL.dispose();
    if (_renderTargetR != null) _renderTargetR.dispose();
    _renderTargetL = new WebGLRenderTarget(width, height,
        minFilter: LinearFilter, magFilter: NearestFilter, format: RGBAFormat);
    _renderTargetR = new WebGLRenderTarget(width, height,
        minFilter: LinearFilter, magFilter: NearestFilter, format: RGBAFormat);

    _material.uniforms["mapLeft"].value = _renderTargetL;
    _material.uniforms["mapRight"].value = _renderTargetR;

    renderer.setSize(width, height);
  }

  /*
   * Renderer now uses an asymmetric perspective projection
   * (http://paulbourke.net/miscellaneous/stereographics/stereorender/).
   *
   * Each camera is offset by the eye seperation and its projection matrix is
   * also skewed asymetrically back to converge on the same projection plane.
   * Added a focal length parameter to, this is where the parallax is equal to 0.
   */

  void render(Scene scene, PerspectiveCamera camera) {
    scene.updateMatrixWorld();

    if (camera.parent == null) camera.updateMatrixWorld();

    var hasCameraChanged = (_aspect != camera.aspect) ||
        (_near != camera.near) ||
        (_far != camera.far) ||
        (_fov != camera.fov);

    if (hasCameraChanged) {
      _aspect = camera.aspect;
      _near = camera.near;
      _far = camera.far;
      _fov = camera.fov;

      var projectionMatrix = camera.projectionMatrix.clone();
      var eyeSep = focalLength / 30 * 0.5;
      var eyeSepOnProjection = eyeSep * _near / focalLength;
      var ymax = _near * math.tan(degToRad(_fov * 0.5));
      var xmin, xmax;

      // translate xOffset

      eyeRight.storage[12] = eyeSep;
      eyeLeft.storage[12] = -eyeSep;

      // for left eye

      xmin = -ymax * _aspect + eyeSepOnProjection;
      xmax = ymax * _aspect + eyeSepOnProjection;

      projectionMatrix.storage[0] = 2 * _near / (xmax - xmin);
      projectionMatrix.storage[8] = (xmax + xmin) / (xmax - xmin);

      _cameraL.projectionMatrix.setFrom(projectionMatrix);

      // for right eye

      xmin = -ymax * _aspect - eyeSepOnProjection;
      xmax = ymax * _aspect - eyeSepOnProjection;

      projectionMatrix.storage[0] = 2 * _near / (xmax - xmin);
      projectionMatrix.storage[8] = (xmax + xmin) / (xmax - xmin);

      _cameraR.projectionMatrix.setFrom(projectionMatrix);
    }

    _cameraL.matrixWorld.setFrom(camera.matrixWorld).multiply(eyeLeft);
    _cameraL.position.setFrom(camera.position);
    _cameraL.near = camera.near;
    _cameraL.far = camera.far;

    renderer.render(scene, _cameraL,
        renderTarget: _renderTargetL, forceClear: true);

    _cameraR.matrixWorld.setFrom(camera.matrixWorld).multiply(eyeRight);
    _cameraR.position.setFrom(camera.position);
    _cameraR.near = camera.near;
    _cameraR.far = camera.far;

    renderer.render(scene, _cameraR,
        renderTarget: _renderTargetR, forceClear: true);

    renderer.render(_scene, _camera);
  }

  void dispose() {
    if (_renderTargetL != null) _renderTargetL.dispose();
    if (_renderTargetR != null) _renderTargetR.dispose();
  }
}
