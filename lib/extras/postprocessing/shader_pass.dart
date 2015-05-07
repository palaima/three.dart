/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.postprocessing;

class ShaderPass implements Pass {
  String textureID;

  Map<String, Uniform> uniforms;
  ShaderMaterial material;

  bool renderToScreen = false;

  bool enabled = true;
  bool needsSwap = true;
  bool clear = false;

  OrthographicCamera camera = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0.0, 1.0);
  Scene scene = new Scene();

  Mesh quad;

  ShaderPass(Map shader, {this.textureID: 'tDiffuse'}) {
    uniforms = uniforms_utils.clone(shader['uniforms']);

    material = new ShaderMaterial(
        defines: shader['defines'] != null ? shader['defines'] : {},
        uniforms: uniforms,
        vertexShader: shader['vertexShader'],
        fragmentShader: shader['fragmentShader']);

    quad = new Mesh(new PlaneBufferGeometry(2.0, 2.0), material);
    scene.add(quad);
  }

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,
              double delta, [bool maskActive]) {
    if (uniforms[textureID] != null) {
      uniforms[textureID].value = readBuffer;
    }

    quad.material = material;

    if (renderToScreen) {
      renderer.render(scene, camera);
    } else {
      renderer.render(scene, camera, renderTarget: writeBuffer, forceClear: clear);
    }
  }
}
