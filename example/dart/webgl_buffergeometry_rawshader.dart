import 'dart:html';
import 'dart:typed_data' show Float32List;
import 'dart:math' as Math;
import 'package:three/three.dart';

final vertexShader = '''
precision mediump float;
precision mediump int;

uniform mat4 modelViewMatrix; // optional
uniform mat4 projectionMatrix; // optional

attribute vec3 position;
attribute vec4 color;

varying vec3 vPosition;
varying vec4 vColor;

void main() {
  vPosition = position;
  vColor = color;

  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''';

final fragmentShader = '''
precision mediump float;
precision mediump int;

uniform float time;

varying vec3 vPosition;
varying vec4 vColor;

void main() {
  vec4 color = vec4(vColor);
  color.r += sin(vPosition.x * 10.0 + time) * 0.5;

  gl_FragColor = color;
}
''';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Math.Random rnd = new Math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 10.0)
    ..position.z = 2.0;

  scene = new Scene();

  // geometry

  var triangles = 500;

  var geometry = new BufferGeometry();

  var vertices = new BufferAttribute(new Float32List(triangles * 3 * 3), 3);

  for (var i = 0; i < vertices.length; i++) {
    vertices.setXYZ(i, rnd.nextDouble() - 0.5, rnd.nextDouble() - 0.5, rnd.nextDouble() - 0.5);
  }

  geometry.addAttribute('position', vertices);

  var colors = new BufferAttribute(new Float32List(triangles * 3 * 4), 4);

  for (var i = 0; i < colors.length; i++) {
    colors.setXYZW(i, rnd.nextDouble() , rnd.nextDouble(), rnd.nextDouble(), rnd.nextDouble());
  }

  geometry.addAttribute('color', colors);

  // material

  var material = new RawShaderMaterial(
    uniforms: {
      'time': new Uniform.float(1.0)
    },
    vertexShader: vertexShader,
    fragmentShader: fragmentShader,
    side: DoubleSide,
    transparent: true);

  var mesh = new Mesh(geometry, material);
  scene.add(mesh);

  renderer = new WebGLRenderer()
    ..setClearColor(0x101010)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  window.onResize.listen((event) {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);
  });
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var time = window.performance.now();

  var object = scene.children[0];

  object.rotation.y = time * 0.0005;
  object.material.uniforms['time'].value = time * 0.005;

  renderer.render(scene, camera);
}
