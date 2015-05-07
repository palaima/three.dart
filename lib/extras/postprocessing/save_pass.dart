/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.extras.postprocessing;

class SavePass implements Pass {
  String textureID = "tDiffuse";

  Map uniforms;

  ShaderMaterial material;

  WebGLRenderTarget renderTarget;

  bool enabled = true;
  bool needsSwap = false;
  bool clear = false;

  OrthographicCamera camera = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0.0, 1.0);
  Scene scene  = new Scene();

  Mesh quad;

  SavePass(this.renderTarget) {
    var shader = copyShader;

    uniforms = uniforms_utils.clone(shader['uniforms']);

    material = new ShaderMaterial(
        uniforms: this.uniforms,
        vertexShader: shader['vertexShader'],
        fragmentShader: shader['fragmentShader']);

    if (renderTarget == null) {
      renderTarget = new WebGLRenderTarget(window.innerWidth, window.innerHeight,
          minFilter: LinearFilter, magFilter: LinearFilter, format: RGBFormat, stencilBuffer: false);
    }

    quad = new Mesh(new PlaneBufferGeometry(2.0, 2.0), null);
    scene.add(quad);
  }

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,
              double delta, bool maskActive) {
    if (uniforms[textureID]) {
      uniforms[textureID].value = readBuffer;
    }

    quad.material = material;

    renderer.render(scene, camera, renderTarget: renderTarget, forceClear: clear);
  }
}