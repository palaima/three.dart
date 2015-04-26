/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.postprocessing;

class TexturePass implements Pass {
  Map<String, Uniform> uniforms;

  ShaderMaterial material;

  bool enabled = true;
  bool needsSwap = false;

  OrthographicCamera camera = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0.0, 1.0);
  Scene scene  = new Scene();

  Mesh quad;

  TexturePass(Texture texture, {double opacity: 1.0}) {
    var shader = Shaders.copy;

    uniforms = UniformsUtils.clone(shader['uniforms']);

    uniforms['opacity'].value = opacity;
    uniforms['tDiffuse'].value = texture;

    material = new ShaderMaterial(
      uniforms: uniforms,
      vertexShader: shader['vertexShader'],
      fragmentShader: shader['fragmentShader']);

    quad = new Mesh(new PlaneBufferGeometry(2.0, 2.0), null);
    scene.add(quad);
  }

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,
              double delta, bool maskActive) {
    quad.material = material;
    renderer.render(scene, camera, renderTarget: readBuffer);
  }
}