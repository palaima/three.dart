import 'dart:html' show window, document;
import 'package:three/three.dart';
import 'package:three/extras/postprocessing.dart';
import 'package:three/extras/image_utils.dart' as image_utils;

final fragmentShader = '''
uniform float time;
uniform vec2 resolution;

uniform float fogDensity;
uniform vec3 fogColor;

uniform sampler2D texture1;
uniform sampler2D texture2;

varying vec2 vUv;

void main(void) {
  vec2 position = -1.0 + 2.0 * vUv;

  vec4 noise = texture2D(texture1, vUv);
  vec2 T1 = vUv + vec2(1.5, -1.5) * time  *0.02;
  vec2 T2 = vUv + vec2(-0.5, 2.0) * time * 0.01;

  T1.x += noise.x * 2.0;
  T1.y += noise.y * 2.0;
  T2.x -= noise.y * 0.2;
  T2.y += noise.z * 0.2;

  float p = texture2D(texture1, T1 * 2.0).a;

  vec4 color = texture2D(texture2, T2 * 2.0);
  vec4 temp = color * (vec4(p, p, p, p) * 2.0) + (color * color - 0.1);

  if(temp.r > 1.0){ temp.bg += clamp(temp.r - 2.0, 0.0, 100.0); }
  if(temp.g > 1.0){ temp.rb += temp.g - 1.0; }
  if(temp.b > 1.0){ temp.rg += temp.b - 1.0; }

  gl_FragColor = temp;

  float depth = gl_FragCoord.z / gl_FragCoord.w;
  const float LOG2 = 1.442695;
  float fogFactor = exp2(- fogDensity * fogDensity * depth * depth * LOG2);
  fogFactor = 1.0 - clamp(fogFactor, 0.0, 1.0);

  gl_FragColor = mix(gl_FragColor, vec4(fogColor, gl_FragColor.w), fogFactor);
}
''';

final vertexShader = '''
uniform vec2 uvScale;
varying vec2 vUv;

void main() {
  vUv = uvScale * uv;
  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  gl_Position = projectionMatrix * mvPosition;
}
''';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

EffectComposer composer;

Clock clock = new Clock();

Map uniforms;
ShaderMaterial material;
Mesh mesh;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(35.0, window.innerWidth / window.innerHeight, 1.0, 3000.0)
    ..position.z = 4.0;

  scene = new Scene();

  uniforms = {
    'fogDensity': new Uniform.float(0.45),
    'fogColor': new Uniform.vector3(0.0, 0.0, 0.0),
    'time': new Uniform.float(1.0),
    'resolution': new Uniform.vector2(0.0, 0.0),
    'uvScale': new Uniform.vector2(3.0, 1.0),
    'texture1': new Uniform.texture(image_utils.loadTexture('textures/lava/cloud.png')),
    'texture2': new Uniform.texture(image_utils.loadTexture('textures/lava/lavatile.jpg'))
  };

  uniforms['texture1'].value.wrapS = uniforms['texture1'].value.wrapT = RepeatWrapping;
  uniforms['texture2'].value.wrapS = uniforms['texture2'].value.wrapT = RepeatWrapping;

  var size = 0.65;

  material = new ShaderMaterial(
      uniforms: uniforms,
      vertexShader: vertexShader,
      fragmentShader: fragmentShader);

  mesh = new Mesh(new TorusGeometry(size, 0.3, 30, 30), material)
    ..rotation.x = 0.3;
  scene.add(mesh);

  //

  renderer = new WebGLRenderer(antialias: true)
    ..setPixelRatio(window.devicePixelRatio);
  document.body.append(renderer.domElement);
  renderer.autoClear = false;

  var renderModel = new RenderPass(scene, camera);
  var effectBloom = new BloomPass(strength: 1.25);
  var effectFilm = new FilmPass(0.35, 0.95, 2048.0, false);

  effectFilm.renderToScreen = true;

  composer = new EffectComposer(renderer);

  composer.addPass(renderModel);
  composer.addPass(effectBloom);
  composer.addPass(effectFilm);

  onWindowResize(null);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  uniforms['resolution'].value.x = window.innerWidth.toDouble();
  uniforms['resolution'].value.y = window.innerHeight.toDouble();

  renderer.setSize(window.innerWidth, window.innerHeight);

  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  composer.reset();
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var delta = 5 * clock.getDelta();

  uniforms['time'].value += 0.2 * delta;

  mesh.rotation.y += 0.0125 * delta;
  mesh.rotation.x += 0.05 * delta;

  renderer.clear();
  composer.render(0.01);
}
