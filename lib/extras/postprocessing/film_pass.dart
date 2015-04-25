/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.postprocessing;

class FilmPass implements Pass {
  Map<String, Uniform> uniforms;

  ShaderMaterial material;

  bool enabled = true;
  bool renderToScreen = false;
  bool needsSwap = true;

  OrthographicCamera camera = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0, 1);
  Scene scene  = new Scene();

  Mesh quad;

  FilmPass(double noiseIntensity, double scanlinesIntensity, double scanlinesCount, int grayscale) {
    var shader = Shaders.film;

    uniforms = UniformsUtils.clone(shader['uniforms']);

    material = new ShaderMaterial(
      uniforms: uniforms,
      vertexShader: shader['vertexShader'],
      fragmentShader: shader['fragmentShader']);

    if (grayscale != null) uniforms['grayscale'].value = grayscale;
    if (noiseIntensity != null) uniforms['nIntensity'].value = noiseIntensity;
    if (scanlinesIntensity != null) uniforms['sIntensity'].value = scanlinesIntensity;
    if (scanlinesCount != null) uniforms['sCount'].value = scanlinesCount;

    quad = new Mesh(new PlaneBufferGeometry(2.0, 2.0), null);
    scene.add(quad);
  }

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,
              double delta, bool maskActive) {
    uniforms['tDiffuse'].value = readBuffer;
    uniforms['time'].value += delta;

    quad.material = material;

    if (renderToScreen) {
      renderer.render(scene, camera);
    } else {
      renderer.render(scene, camera, renderTarget: writeBuffer, forceClear: false);
    }
  }
}