/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.extras.postprocessing;

class RenderPass implements Pass {
  Scene scene;
  Camera camera;

  Material overrideMaterial;

  Color clearColor;
  double clearAlpha;

  Color oldClearColor = new Color.white();
  double oldClearAlpha = 1.0;

  bool enabled = true;
  bool clear = true;
  bool needsSwap = false;

  RenderPass(this.scene, this.camera, {this.overrideMaterial, this.clearColor, this.clearAlpha: 1.0});

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,
              double delta, bool maskActive) {
    scene.overrideMaterial = overrideMaterial;

    if (clearColor != null) {
      oldClearColor.setFrom(renderer.getClearColor());
      oldClearAlpha = renderer.getClearAlpha();

      renderer.setClearColor(clearColor, clearAlpha);
    }

    renderer.render(scene, camera, renderTarget: readBuffer, forceClear: clear);

    if (clearColor != null) {
      renderer.setClearColor(oldClearColor, oldClearAlpha);
    }

    scene.overrideMaterial = null;
  }
}
