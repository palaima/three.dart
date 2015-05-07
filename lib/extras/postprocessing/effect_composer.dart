/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.extras.postprocessing;

class EffectComposer {
  WebGLRenderer renderer;

  WebGLRenderTarget renderTarget1;
  WebGLRenderTarget renderTarget2;

  WebGLRenderTarget writeBuffer;
  WebGLRenderTarget readBuffer;

  WebGLRenderTarget writeTarget;
  WebGLRenderTarget readTarget;

  List<Pass> passes = [];

  ShaderPass copyPass;

  EffectComposer(this.renderer, [WebGLRenderTarget renderTarget]) {
    if (renderTarget == null) {
      var pixelRatio = renderer.getPixelRatio();

      var width  = (renderer.context.canvas.width / pixelRatio).floor();
      var height = (renderer.context.canvas.height / pixelRatio).floor();

      if (width == 0) width = 1;
      if (height == 0) height = 1;

      renderTarget = new WebGLRenderTarget(width, height, minFilter: LinearFilter,
          magFilter: LinearFilter, format: RGBFormat, stencilBuffer: false);
    }

    renderTarget1 = renderTarget;
    renderTarget2 = renderTarget.clone();

    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;

    copyPass = new ShaderPass(copyShader);
  }

  void swapBuffers() {
    var tmp = readBuffer;
    readBuffer = writeBuffer;
    writeBuffer = tmp;
  }

  void addPass(Pass pass) {
    passes.add(pass);
  }

  void insertPass(Pass pass, int index) {
    passes.insert(index, pass);
  }

  void render([double delta]) {
    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;

    var maskActive = false;

    passes.where((p) => p.enabled).forEach((pass) {
      pass.render(renderer, writeBuffer, readBuffer, delta, maskActive);

      if (pass.needsSwap) {
        if (maskActive) {
          var context = renderer.context;

          context.stencilFunc(context.NOTEQUAL, 1, 0xffffffff);

          copyPass.render(renderer, writeBuffer, readBuffer, delta);

          context.stencilFunc(context.EQUAL, 1, 0xffffffff);
        }

        swapBuffers();
      }

      if (pass is MaskPass) {
        maskActive = true;
      } else if (pass is ClearMaskPass) {
        maskActive = false;
      }
    });
  }

  void reset([WebGLRenderTarget renderTarget]) {
    if (renderTarget == null) {
      renderTarget = renderTarget1.clone();

      var pixelRatio = renderer.getPixelRatio();

      renderTarget.width  = (renderer.context.canvas.width  / pixelRatio).floor();
      renderTarget.height = (renderer.context.canvas.height / pixelRatio).floor();
    }

    renderTarget1 = renderTarget;
    renderTarget2 = renderTarget.clone();

    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;
  }

  void setSize(int width, int height) {
    var renderTarget = renderTarget1.clone();

    renderTarget.width = width;
    renderTarget.height = height;

    reset(renderTarget);
  }
}
