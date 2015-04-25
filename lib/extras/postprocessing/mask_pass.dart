/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.postprocessing;

class MaskPass {
  Scene scene;
  Camera camera;

  bool enabled = true;
  bool clear = true;
  bool needsSwap = false;

  bool inverse = false;

  MaskPass(this.scene, this.camera);

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, delta, maskActive) {
    var context = renderer.context;

    // don't update color or depth

    context.colorMask(false, false, false, false);
    context.depthMask(false);

    // set up stencil

    var writeValue, clearValue;

    if (inverse) {
      writeValue = 0;
      clearValue = 1;
    } else {
      writeValue = 1;
      clearValue = 0;
    }

    context.enable(gl.STENCIL_TEST);
    context.stencilOp(gl.REPLACE, gl.REPLACE, gl.REPLACE);
    context.stencilFunc(gl.ALWAYS, writeValue, 0xffffffff);
    context.clearStencil(clearValue);

    // draw into the stencil buffer

    renderer.render(this.scene, this.camera, renderTarget: readBuffer, forceClear: clear);
    renderer.render(this.scene, this.camera, renderTarget: writeBuffer, forceClear: clear);

    // re-enable update of color and depth

    context.colorMask(true, true, true, true);
    context.depthMask(true);

    // only render where stencil is set to 1

    context.stencilFunc(gl.EQUAL, 1, 0xffffffff);  // draw if == 1
    context.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
  }
}

class ClearMaskPass {
  bool enabled = true;

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, delta) {
    renderer.context.disable(gl.STENCIL_TEST);
  }
}