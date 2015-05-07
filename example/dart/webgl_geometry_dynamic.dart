/*
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/controls.dart';
import 'package:three/extras/image_utils.dart' as image_utils;

PerspectiveCamera camera;
FirstPersonControls controls;
Scene scene;
WebGLRenderer renderer;

Texture texture;
DynamicGeometry geometry;
Material material;

int worldWidth = 128, worldDepth = 128;

Clock clock = new Clock();

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(60.0, window.innerWidth / window.innerHeight, 1.0, 20000.0)
    ..position.y = 200.0;

  controls = new FirstPersonControls(camera)
    ..movementSpeed = 500
    ..lookSpeed = 0.1;

  scene = new Scene()
    ..fog = new FogExp2(0xaaccff, 0.0007);

  var planeGeo = new PlaneGeometry(20000.0, 20000.0, worldWidth - 1, worldDepth - 1)
    ..applyMatrix(new Matrix4.rotationX(-math.PI / 2));

  for (var i = 0; i < planeGeo.vertices.length; i++) {
    planeGeo.vertices[i].y = 35 * math.sin(i / 2);
  }

  geometry = new DynamicGeometry.fromGeometry(planeGeo);

  var texture = image_utils.loadTexture('textures/water.jpg');
  texture.wrapS = texture.wrapT = RepeatWrapping;
  texture.repeat.splat(5.0);

  material = new MeshBasicMaterial(color: 0x0044ff, map: texture);

  var mesh = new Mesh(geometry, material);
  scene.add(mesh);

  renderer = new WebGLRenderer()
    ..setClearColor(0xaaccff)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);

  document.body.append(renderer.domElement);

  //

  window.onResize.listen(onWindowResize);
}

void onWindowResize(Event e) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);

  controls.handleResize();
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var delta = clock.getDelta();
  var time = clock.elapsedTime * 10;

  for (var i = 0; i < geometry.vertices.length; i++) {
    geometry.vertices[i].y = 35 * math.sin(i / 5 + (time + i) / 7);
  }

  geometry.verticesNeedUpdate = true;

  controls.update(delta);
  renderer.render(scene, camera);
}