import 'dart:html';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;

final vertexShader = '''
precision highp float;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

attribute vec3 position;
attribute vec2 uv;
attribute vec3 normal;

attribute vec4 translateScale;
attribute vec3 color;

varying vec2 vUv;
varying vec3 vColor;

void main() {

  vec4 positionAdj = vec4( translateScale.xyz, 1.0 );
  vec4 mvPosition = modelViewMatrix * positionAdj;

  mvPosition.xyz += position * translateScale.w;

  vUv = uv;
  vColor = color;

  gl_Position = projectionMatrix * mvPosition;

}
''';

final fragmentShader = '''
precision highp float;

uniform sampler2D map;

varying vec2 vUv;
varying vec3 vColor;

void main() {
  vec4 diffuseColor = texture2D( map, vUv );
  gl_FragColor = vec4( diffuseColor.xyz * vColor, diffuseColor.w );

  if ( diffuseColor.w < 0.5 ) discard; 
}
''';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

InstancedBufferGeometry geometry;
RawShaderMaterial material;

Texture sprite;

num mouseX = 0,
    mouseY = 0;

num windowHalfX = window.innerWidth / 2;
num windowHalfY = window.innerHeight / 2;

Function random = new math.Random().nextDouble;

bool init() {
  renderer = new WebGLRenderer();

  if (!renderer.supportsInstancedArrays) {
    document.getElementById("notSupported").style.display = "";
    return false;
  }

  camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 3000.0)
    ..position.z = 1400.0;

  scene = new Scene();

  geometry = new InstancedBufferGeometry.copy(new CircleBufferGeometry(1.0, 16));

  sprite = image_utils.loadTexture("textures/sprites/ball.png");

  var particleCount = 5000;

  var translateScaleArray = new Float32List(4 * particleCount);
  var colorsArray = new Float32List(3 * particleCount);

  var color = new Color(0xffffff);
  for (var i = 0, ii = 0; i < particleCount * 4; i += 4, ii += 3) {
    translateScaleArray[i] = 2000 * random() - 1000;
    translateScaleArray[i + 1] = 2000 * random() - 1000;
    translateScaleArray[i + 2] = 2000 * random() - 1000;
    translateScaleArray[i + 3] = 24.0;

    color.setHSL((translateScaleArray[i] + 1000) / 2000, 1.0, 0.5);

    colorsArray[ii] = color.r;
    colorsArray[ii + 1] = color.g;
    colorsArray[ii + 2] = color.b;
  }

  geometry.addAttribute("translateScale", new InstancedBufferAttribute(translateScaleArray, 4));
  geometry.addAttribute("color", new InstancedBufferAttribute(colorsArray, 3));

  material = new RawShaderMaterial(
      uniforms: {'map': new Uniform.texture(sprite)},
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
      depthTest: true,
      depthWrite: true,
      attributes: {'translateScale': 1, 'color': 2});

  scene.add(new Mesh(geometry, material));

  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  document.onMouseMove.listen(onDocumentMouseMove);
  document.onTouchStart.listen(onDocumentTouchStart);
  document.onTouchMove.listen(onDocumentTouchMove);

  window.onResize.listen(onWindowResize);

  return true;
}

void onDocumentMouseMove(MouseEvent event) {
  mouseX = event.client.x - windowHalfX;
  mouseY = event.client.y - windowHalfY;
}

void onDocumentTouchStart(TouchEvent event) {
  if (event.touches.length == 1) {
    event.preventDefault();

    mouseX = event.touches[0].page.x - windowHalfX;
    mouseY = event.touches[0].page.y - windowHalfY;
  }
}

void onDocumentTouchMove(TouchEvent event) {
  if (event.touches.length == 1) {
    event.preventDefault();

    mouseX = event.touches[0].page.x - windowHalfX;
    mouseY = event.touches[0].page.y - windowHalfY;
  }
}

void onWindowResize(Event event) {
  windowHalfX = window.innerWidth / 2;
  windowHalfY = window.innerHeight / 2;

  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void render() {
  camera.position.x += (mouseX - camera.position.x) * 0.05;
  camera.position.y += (-mouseY - camera.position.y) * 0.05;

  camera.lookAt(scene.position);

  renderer.render(scene, camera);
}

main() async {
  if (!init()) return;

  while (true) {
    await window.animationFrame;
    render();
  }
}
