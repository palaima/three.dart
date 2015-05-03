import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Object3D root;

num windowHalfX = window.innerWidth / 2;
num windowHalfY = window.innerHeight / 2;

num mouseX = 0,
    mouseY = 0;

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}

void init() {
  camera = new PerspectiveCamera(60.0, window.innerWidth / window.innerHeight, 1.0, 15000.0)
    ..position.z = 500.0;

  scene = new Scene();

  var geometry = new BoxGeometry(100.0, 100.0, 100.0);
  var material = new MeshNormalMaterial();

  root = new Mesh(geometry, material)..position.x = 1000.0;
  scene.add(root);

  var amount = 200,
      object,
      parent = root;

  for (var i = 0; i < amount; i++) {
    object = new Mesh(geometry, material)
      ..position.x = 100.0;

    parent.add(object);
    parent = object;
  }

  parent = root;

  for (var i = 0; i < amount; i++) {
    object = new Mesh(geometry, material)
      ..position.x = -100.0;

    parent.add(object);
    parent = object;
  }

  parent = root;

  for (var i = 0; i < amount; i++) {
    object = new Mesh(geometry, material)
      ..position.y = -100.0;

    parent.add(object);
    parent = object;
  }

  parent = root;

  for (var i = 0; i < amount; i++) {
    object = new Mesh(geometry, material)
      ..position.y = 100.0;

    parent.add(object);
    parent = object;
  }

  parent = root;

  for (var i = 0; i < amount; i++) {
    object = new Mesh(geometry, material)
      ..position.z = -100.0;

    parent.add(object);
    parent = object;
  }

  parent = root;

  for (var i = 0; i < amount; i++) {
    object = new Mesh(geometry, material)
      ..position.z = 100.0;

    parent.add(object);
    parent = object;
  }

  renderer = new WebGLRenderer()
    ..setClearColor(0xffffff)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..sortObjects = false;
  document.body.append(renderer.domElement);

  document.onMouseMove.listen(onDocumentMouseMove);
  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  windowHalfX = window.innerWidth / 2;
  windowHalfY = window.innerHeight / 2;

  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void onDocumentMouseMove(MouseEvent event) {
  mouseX = (event.client.x - windowHalfX) * 10;
  mouseY = (event.client.y - windowHalfY) * 10;
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.001;

  var rx = math.sin(time * 0.7) * 0.2;
  var ry = math.sin(time * 0.3) * 0.1;
  var rz = math.sin(time * 0.2) * 0.1;

  camera.position.x += (mouseX - camera.position.x) * .05;
  camera.position.y += (-mouseY - camera.position.y) * .05;

  camera.lookAt(scene.position);

  root.traverse((object) {
    object.rotation.x = rx;
    object.rotation.y = ry;
    object.rotation.z = rz;
  });

  renderer.render(scene, camera);
}
