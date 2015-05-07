import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Function random = new math.Random().nextDouble;

void init() {
  camera = new PerspectiveCamera(60.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 200.0;

  scene = new Scene();

  renderer = new WebGLRenderer()
    ..setClearColor(0xffffff)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);
}

CanvasElement createImage() {
  var canvas = new CanvasElement(width: 256, height: 256);

  canvas.context2D
    ..fillStyle = 'rgb(${(random() * 256).floor()},${(random() * 256).floor()},${(random() * 256).floor()})'
    ..fillRect(0, 0, 256, 256);

  return canvas;
}

void render() {
  var geometry = new SphereBufferGeometry(50.0, (random() * 64).toInt(), (random() * 32).toInt());

  var texture = new Texture(createImage())..needsUpdate = true;

  var material = new MeshBasicMaterial(map: texture, wireframe: true);

  var mesh = new Mesh(geometry, material);

  scene.add(mesh);

  renderer.render(scene, camera);

  scene.remove(mesh);

  // clean up

  geometry.dispose();
  material.dispose();
  texture.dispose();
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
