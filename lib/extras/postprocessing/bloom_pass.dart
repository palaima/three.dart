/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.postprocessing;

class BloomPass implements Pass {
  static final blurX = new Vector2(0.001953125, 0.0);
  static final blurY = new Vector2(0.0, 0.001953125);

  WebGLRenderTarget renderTargetX;
  WebGLRenderTarget renderTargetY;

  Map<String, Uniform> copyUniforms;

  ShaderMaterial materialCopy;

  Map<String, Uniform> convolutionUniforms;

  ShaderMaterial materialConvolution;

  bool enabled = true;
  bool needsSwap = false;
  bool clear = false;

  OrthographicCamera camera = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0.0, 1.0);
  Scene scene = new Scene();

  Mesh quad;

  BloomPass({double strength: 1.0, double kernelSize: 25.0, double sigma: 4.0, int resolution: 256}) {
    renderTargetX = new WebGLRenderTarget(resolution, resolution, minFilter: LinearFilter, magFilter: LinearFilter, format: RGBFormat);
    renderTargetY = new WebGLRenderTarget(resolution, resolution, minFilter: LinearFilter, magFilter: LinearFilter, format: RGBFormat);

    // copy material

    var shader = copyShader;

    copyUniforms = uniforms_utils.clone(shader['uniforms']);

    copyUniforms['opacity'].value = strength;

    materialCopy = new ShaderMaterial(
        uniforms: this.copyUniforms,
        vertexShader: shader['vertexShader'],
        fragmentShader: shader['fragmentShader'],
        blending: AdditiveBlending,
        transparent: true);

    // convolution material

    var shader2 = convolutionShader;

    convolutionUniforms = uniforms_utils.clone(shader2['uniforms']);

    convolutionUniforms['uImageIncrement'].value = BloomPass.blurX;
    convolutionUniforms['cKernel'].value = shader2['buildKernel'](sigma);

    materialConvolution = new ShaderMaterial(
        uniforms: this.convolutionUniforms,
        vertexShader:  shader2['vertexShader'],
        fragmentShader: shader2['fragmentShader'],
        defines: {
          'KERNEL_SIZE_FLOAT': kernelSize.toStringAsFixed(1),
          'KERNEL_SIZE_INT': kernelSize.toStringAsFixed(0)
        });

    quad = new Mesh(new PlaneBufferGeometry(2.0, 2.0), null);
    scene.add(quad);
  }

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,
              double delta, bool maskActive) {
    if (maskActive) renderer.context.disable(gl.STENCIL_TEST);

    // Render quad with blured scene into texture (convolution pass 1)

    quad.material = materialConvolution;

    convolutionUniforms['tDiffuse'].value = readBuffer;
    convolutionUniforms['uImageIncrement'].value = BloomPass.blurX;

    renderer.render(scene, camera, renderTarget: renderTargetX, forceClear: true);


    // Render quad with blured scene into texture (convolution pass 2)

    convolutionUniforms['tDiffuse'].value = renderTargetX;
    convolutionUniforms['uImageIncrement'].value = BloomPass.blurY;

    renderer.render(scene, camera, renderTarget: renderTargetY, forceClear: true);

    // Render original scene with superimposed blur to texture

    quad.material = materialCopy;

    copyUniforms['tDiffuse'].value = renderTargetY;

    if (maskActive) renderer.context.enable(gl.STENCIL_TEST);

    renderer.render(scene, camera, renderTarget: readBuffer, forceClear: clear);
  }
}