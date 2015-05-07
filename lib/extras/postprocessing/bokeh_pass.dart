/*
 * Depth-of-field post-process with bokeh shader
 *
 * based on r71
 */

part of three.extras.postprocessing;

class BokehPass implements Pass {
  Scene scene;
  PerspectiveCamera camera;

  WebGLRenderTarget renderTargetColor;
  WebGLRenderTarget renderTargetDepth;

  MeshDepthMaterial materialDepth;

  ShaderMaterial materialBokeh;

  Map<String, Uniform> uniforms;

  bool enabled = true;
  bool needsSwap = false;
  bool renderToScreen = false;
  bool clear = false;

  OrthographicCamera camera2 = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0.0, 1.0);
  Scene scene2  = new Scene();

  Mesh quad2;

  BokehPass(this.scene, this.camera, {double focus: 1.0, double aspect,
    double aperture: 0.025, double maxblur: 1.0, int width: 1,
    int height: 1}) {
    if (aspect == null) aspect = camera.aspect;

    renderTargetColor = new WebGLRenderTarget(width, height,
      minFilter: LinearFilter,
      magFilter: LinearFilter,
      format: RGBFormat);

    renderTargetDepth = renderTargetColor.clone();

    materialDepth = new MeshDepthMaterial();

    // bokeh material

    var shader = bokehShader;

    var bokehUniforms = uniforms_utils.clone(shader['uniforms']);

    bokehUniforms['tDepth'].value = this.renderTargetDepth;

    bokehUniforms['focus'].value = focus;
    bokehUniforms['aspect'].value = aspect;
    bokehUniforms['aperture'].value = aperture;
    bokehUniforms['maxblur'].value = maxblur;

    materialBokeh = new ShaderMaterial(
        uniforms: bokehUniforms,
        vertexShader: shader['vertexShader'],
        fragmentShader: shader['fragmentShader']);

    uniforms = bokehUniforms;

    quad2 = new Mesh(new PlaneBufferGeometry(2.0, 2.0), null);
    scene2.add(quad2);
  }

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,
              double delta, bool maskActive) {
    quad2.material = materialBokeh;

    // Render depth into texture

    scene.overrideMaterial = this.materialDepth;

    renderer.render(scene, camera, renderTarget: renderTargetDepth, forceClear: true);

    // Render bokeh composite

    uniforms['tColor'].value = readBuffer;

    if (renderToScreen) {
      renderer.render(scene2, camera2);
    } else {
      renderer.render(scene2, camera2, renderTarget: writeBuffer, forceClear: clear);
    }

    scene.overrideMaterial = null;
  }
}
