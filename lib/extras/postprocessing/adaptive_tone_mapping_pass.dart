/*
 * @author miibond
 * Generate a texture that represents the luminosity of the current scene, adapted over time
 * to simulate the optic nerve responding to the amount of light it is receiving.
 * Based on a GDC2007 presentation by Wolfgang Engel titled "Post-Processing Pipeline"
 *
 * Full-screen tone-mapping shader based on http://www.graphics.cornell.edu/~jaf/publications/sig02_paper.pdf
 *
 * based on r71
 */

part of three.postprocessing;

class AdaptiveToneMappingPass implements Pass {
  int resolution;
  bool needsInit = true;
  bool adaptive;

  WebGLRenderTarget luminanceRT;
  WebGLRenderTarget previousLuminanceRT;
  WebGLRenderTarget currentLuminanceRT;

  Map<String, Uniform> copyUniforms;

  ShaderMaterial materialCopy;

  ShaderMaterial materialLuminance;

  Map adaptLuminanceShader;

  ShaderMaterial materialAdaptiveLum;

  ShaderMaterial materialToneMap;

  bool enabled = true;
  bool needsSwap = true;
  bool clear = false;

  OrthographicCamera camera = new OrthographicCamera(-1.0, 1.0, 1.0, -1.0, 0.0, 1.0);
  Scene scene  = new Scene();

  Mesh quad;

  AdaptiveToneMappingPass({this.adaptive: true, this.resolution: 256}) {
    var shader = copyShader;

    copyUniforms = uniforms_utils.clone(shader['uniforms']);

    materialCopy = new ShaderMaterial(
        uniforms: copyUniforms,
        vertexShader: shader['vertexShader'],
        fragmentShader: shader['fragmentShader'],
        blending: NoBlending,
        depthTest: false);

    var shader2 = luminosityShader;

    materialLuminance = new ShaderMaterial(
        uniforms:uniforms_utils.clone(shader2['uniforms']),
        vertexShader: shader2['vertexShader'],
        fragmentShader: shader2['fragmentShader'],
        blending: NoBlending);

    adaptLuminanceShader = {
      'define': {
        "MIP_LEVEL_1X1" : (math.log(resolution) / math.log(2.0)).toStringAsFixed(1),
      },
      'uniforms': {
        "lastLum": new Uniform.texture(),
        "currentLum": new Uniform.texture(),
        "delta": new Uniform.float(0.016),
        "tau": new Uniform.float(1.0)
      },
      'vertexShader': '''
        varying vec2 vUv;
        void main() {
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      ''',
      'fragmentShader': '''
        varying vec2 vUv;

        uniform sampler2D lastLum;
        uniform sampler2D currentLum;
        uniform float delta;
        uniform float tau;

        void main() {

          vec4 lastLum = texture2D(lastLum, vUv, MIP_LEVEL_1X1);
          vec4 currentLum = texture2D(currentLum, vUv, MIP_LEVEL_1X1);

          float fLastLum = lastLum.r;
          float fCurrentLum = currentLum.r;

          //The adaption seems to work better in extreme lighting differences
          //if the input luminance is squared.
          fCurrentLum *= fCurrentLum;

          // Adapt the luminance using Pattanaik's technique
          float fAdaptedLum = fLastLum + (fCurrentLum - fLastLum) * (1.0 - exp(-delta * tau));
          gl_FragColor = vec4(vec3(fAdaptedLum), 1.0);
        }
    '''
    };

    var shader3 = adaptLuminanceShader;

    materialAdaptiveLum = new ShaderMaterial(
      uniforms: uniforms_utils.clone(shader3['uniforms']),
      vertexShader: shader3['vertexShader'],
      fragmentShader: shader3['fragmentShader'],
      defines: shader3['defines'],
      blending: NoBlending);

    var shader4 = toneMapShader;

    materialToneMap = new ShaderMaterial(
      uniforms: uniforms_utils.clone(shader4['uniforms']),
      vertexShader: shader4['vertexShader'],
      fragmentShader: shader4['fragmentShader'],
      blending: NoBlending);

    quad = new Mesh(new PlaneBufferGeometry(2.0, 2.0), null);
    scene.add(quad);
  }

  void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer,
              double delta, bool maskActive) {
    if (needsInit) {
      reset(renderer);
      luminanceRT.type = readBuffer.type;
      previousLuminanceRT.type = readBuffer.type;
      currentLuminanceRT.type = readBuffer.type;
      needsInit = false;
    }

    if (adaptive) {
      //Render the luminance of the current scene into a render target with mipmapping enabled
      quad.material = materialLuminance;
      materialLuminance.uniforms['tDiffuse'].value = readBuffer;
      renderer.render(scene, camera, renderTarget: currentLuminanceRT);

      //Use the new luminance values, the previous luminance and the frame delta to
      //adapt the luminance over time.
      quad.material = materialAdaptiveLum;
      materialAdaptiveLum.uniforms['delta'].value = delta;
      materialAdaptiveLum.uniforms['lastLum'].value = previousLuminanceRT;
      materialAdaptiveLum.uniforms['currentLum'].value = currentLuminanceRT;
      renderer.render(scene, camera, renderTarget: luminanceRT);

      //Copy the new adapted luminance value so that it can be used by the next frame.
      quad.material = materialCopy;
      copyUniforms['tDiffuse'].value = luminanceRT;
      renderer.render(scene, camera, renderTarget: previousLuminanceRT);
    }

    quad.material = materialToneMap;
    materialToneMap.uniforms['tDiffuse'].value = readBuffer;
    renderer.render(scene, camera, renderTarget: writeBuffer, forceClear: clear);
  }

  void reset(WebGLRenderer renderer) {
    // render targets
    if (luminanceRT != null) {
      luminanceRT.dispose();
    }
    if (currentLuminanceRT != null) {
      currentLuminanceRT.dispose();
    }
    if (previousLuminanceRT != null) {
      previousLuminanceRT.dispose();
    }

    luminanceRT = new WebGLRenderTarget(resolution, resolution, minFilter: LinearFilter,
        magFilter: LinearFilter, format: RGBFormat)
      ..generateMipmaps = false;
    previousLuminanceRT = new WebGLRenderTarget(resolution, resolution, minFilter: LinearFilter,
        magFilter: LinearFilter, format: RGBFormat)
      ..generateMipmaps = false;

    //We only need mipmapping for the current luminosity because we want a down-sampled version to sample in our adaptive shader
    currentLuminanceRT = new WebGLRenderTarget(resolution, resolution, minFilter: LinearMipMapLinearFilter, magFilter: LinearFilter, format: RGBFormat);

    if (adaptive) {
      materialToneMap.defines["ADAPTED_LUMINANCE"] = "";
      materialToneMap.uniforms['luminanceMap'].value = luminanceRT;
    }
    //Put something in the adaptive luminance texture so that the scene can render initially
    quad.material = new MeshBasicMaterial(color: 0x777777);
    materialLuminance.needsUpdate = true;
    materialAdaptiveLum.needsUpdate = true;
    materialToneMap.needsUpdate = true;
  }

  void setAdaptive(adaptive) {
    if (adaptive) {
      adaptive = true;
      materialToneMap.defines["ADAPTED_LUMINANCE"] = "";
      materialToneMap.uniforms['luminanceMap'].value = luminanceRT;
    }
    else {
      adaptive = false;
      materialToneMap.defines["ADAPTED_LUMINANCE"] = null;
      materialToneMap.uniforms['luminanceMap'].value = null;
    }
    materialToneMap.needsUpdate = true;
  }

  void setAdaptionRate(num rate) {
    if (rate != null) { // TODO maybe rate != 0 instead?
      materialAdaptiveLum.uniforms['tau'].value = rate.abs();
    }
  }

  void setMaxLuminance(num maxLum) {
    if (maxLum != null) {
      materialToneMap.uniforms['maxLuminance'].value = maxLum;
    }
  }

  void setAverageLuminance(num avgLum) {
    if (avgLum != null) {
      materialToneMap.uniforms['averageLuminance'].value = avgLum;
    }
  }

  void setMiddleGrey(num middleGrey) {
    if (middleGrey != null) {
      materialToneMap.uniforms['middleGrey'].value = middleGrey;
    }
  }

  void dispose() {
    if (luminanceRT != null) {
      luminanceRT.dispose();
    }
    if (previousLuminanceRT != null) {
      previousLuminanceRT.dispose();
    }
    if (currentLuminanceRT != null) {
      currentLuminanceRT.dispose();
    }
    if (materialLuminance != null) {
      materialLuminance.dispose();
    }
    if (materialAdaptiveLum != null) {
      materialAdaptiveLum.dispose();
    }
    if (materialCopy != null) {
      materialCopy.dispose();
    }
    if (materialToneMap != null) {
      materialToneMap.dispose();
    }
  }

}
