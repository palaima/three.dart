import 'dart:html';
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Mesh mesh;

void main() {
  init();
  animate(0);
}

void init() {
  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  camera = new PerspectiveCamera(70.0, window.innerWidth / window.innerHeight, 1.0, 1000.0)
    ..position.z = 400.0;

  scene = new Scene();

  var geometry = new BoxGeometry(200.0, 200.0, 200.0);

  var texture = image_utils.loadTexture('textures/crate.gif')
    ..anisotropy = renderer.getMaxAnisotropy();

  var material = new MeshBasicMaterial(map: texture);

  mesh = new Mesh(geometry, material);
  scene.add(mesh);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(Event e) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void animate(num time) {
  window.requestAnimationFrame(animate);

  mesh.rotation.x += 0.005;
  mesh.rotation.y += 0.01;

  renderer.render(scene, camera);
}