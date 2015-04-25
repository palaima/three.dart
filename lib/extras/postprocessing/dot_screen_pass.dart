/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.postprocessing;

class DotScreenPass {
  Map uniforms;
  ShaderMaterial material;

  bool enabled = true;
  bool renderToScreen = false;
  bool needsSwap = true;

  OrthographicCamera camera = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0, 1);
  Scene scene = new Scene();

  Mesh quad;

  DotScreenPass(center, double angle, double scale) {
    var shader = Shaders.dotScreen;

    uniforms = UniformsUtils.clone(shader['uniforms']);

    if (center != null) uniforms['center'].value.copy(center);
    if (angle != null) uniforms['angle'].value = angle;
    if (scale != null) uniforms['scale'].value = scale;

    material = new ShaderMaterial(
        uniforms: uniforms,
        vertexShader: shader['vertexShader'],
        fragmentShader: shader['fragmentShader']);

    quad = new Mesh(new PlaneBufferGeometry(2.0, 2.0), null);
    scene.add(quad);
  }

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, delta, maskActive) {
    uniforms['tDiffuse'].value = readBuffer;
    uniforms['tSize'].value.set(readBuffer.width, readBuffer.height);

    quad.material = material;

    if (renderToScreen) {
      renderer.render(scene, camera);
    } else {
      renderer.render(scene, camera, renderTarget: writeBuffer, forceClear: false);
    }
  }
}