/*
 * Based on r71
 */

part of three.postprocessing;

class GlitchPass implements Pass {
  Map<String, Uniform> uniforms;

  ShaderMaterial material;

  bool enabled = true;
  bool renderToScreen = false;
  bool needsSwap = true;

  OrthographicCamera camera = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0.0, 1.0);
  Scene scene  = new Scene();

  Mesh quad;

  bool goWild = false;
  int curF = 0;

  int _randX;
  math.Random _rnd = new math.Random();

  GlitchPass({int dtSize: 64}) {
    var shader = digitalGlitchShader;

    uniforms = uniforms_utils.clone(shader['uniforms']);

    uniforms["tDisp"].value = generateHeightmap(dtSize);

    material = new ShaderMaterial(
        uniforms: this.uniforms,
        vertexShader: shader['vertexShader'],
        fragmentShader: shader['fragmentShader']
   );

    quad = new Mesh(new PlaneGeometry(2.0, 2.0), null);
    scene.add(quad);

    generateTrigger();
  }

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,
              double delta, bool maskActive) {
    uniforms["tDiffuse"].value = readBuffer;
    uniforms['seed'].value = _rnd.nextDouble();//default seeding
    uniforms['byp'].value=0;

    if (curF % _randX == 0 || goWild) {
      uniforms['amount'].value = _rnd.nextDouble() / 30;
      uniforms['angle'].value = three_math.randFloat(-math.PI, math.PI);
      uniforms['seed_x'].value = three_math.randFloat(-1.0, 1.0);
      uniforms['seed_y'].value = three_math.randFloat(-1.0, 1.0);
      uniforms['distortion_x'].value = three_math.randFloat(0.0, 1.0);
      uniforms['distortion_y'].value = three_math.randFloat(0.0, 1.0);
      curF=0;
      generateTrigger();
    } else if (curF % _randX < _randX / 5) {
      uniforms['amount'].value = _rnd.nextDouble() / 90;
      uniforms['angle'].value = three_math.randFloat(-math.PI, math.PI);
      uniforms['distortion_x'].value = three_math.randFloat(0.0, 1.0);
      uniforms['distortion_y'].value = three_math.randFloat(0.0, 1.0);
      uniforms['seed_x'].value = three_math.randFloat(-0.3, 0.3);
      uniforms['seed_y'].value = three_math.randFloat(-0.3, 0.3);
    } else if (!goWild){
      uniforms['byp'].value = 1;
    }

    curF++;

    quad.material = material;
    if (renderToScreen) {
      renderer.render(scene, camera);
    } else {
      renderer.render(scene, camera, renderTarget: writeBuffer, forceClear: false);
    }
  }

  void generateTrigger() {
    _randX = three_math.randInt(120, 240);
  }

  DataTexture generateHeightmap(int dtSize) {
    var dataArr = new Float32List(dtSize * dtSize * 3);

    var length = dtSize * dtSize;

    for (var i = 0; i < length; i++) {
      var val = three_math.randFloat(0.0, 1.0);
      dataArr[i * 3 + 0] = val;
      dataArr[i * 3 + 1] = val;
      dataArr[i * 3 + 2] = val;
    }

    var texture = new DataTexture(dataArr, dtSize, dtSize, RGBFormat, type: FloatType)
      ..minFilter = NearestFilter
      ..magFilter = NearestFilter
      ..needsUpdate = true
      ..flipY = false;

    return texture;
  }
}