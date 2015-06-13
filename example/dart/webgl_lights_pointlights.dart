import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/loaders.dart' show BinaryLoader;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

PointLight light1, light2, light3, light4;

Mesh object;

BinaryLoader loader;

Clock clock = new Clock();

void init() {
  camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 1000.0)
    ..position.z = 100.0;

  scene = new Scene();

  loader = new BinaryLoader(showStatus: true);
  document.body.append(loader.statusDomElement);

  loader.load('obj/walt/WaltHead_bin.js').then((result) {
    object = new Mesh(result.geometry, new MeshPhongMaterial(color: 0x555555, specular: 0xffffff, shininess: 50.0));
    object.scale.splat(0.80);
    scene.add(object);

    loader.statusDomElement.style.display = 'none';
  });

  scene.add(new AmbientLight(0x000000));

  var sphere = new SphereGeometry(0.5, 16, 8);

  light1 = new PointLight(0xff0040, 2.0, 50.0);
  light1.add(new Mesh(sphere, new MeshBasicMaterial(color: 0xff0040)));
  scene.add(light1);

  light2 = new PointLight(0x0040ff, 2.0, 50.0);
  light2.add(new Mesh(sphere, new MeshBasicMaterial(color: 0x0040ff)));
  scene.add(light2);

  light3 = new PointLight(0x80ff80, 2.0, 50.0);
  light3.add(new Mesh(sphere, new MeshBasicMaterial(color: 0x80ff80)));
  scene.add(light3);

  light4 = new PointLight(0xffaa00, 2.0, 50.0);
  light4.add(new Mesh(sphere, new MeshBasicMaterial(color: 0xffaa00)));
  scene.add(light4);

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  //

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.0005;
  var delta = clock.getDelta();

  if (object != null) object.rotation.y -= 0.5 * delta;

  light1.position.x = math.sin(time * 0.7) * 30;
  light1.position.y = math.cos(time * 0.5) * 40;
  light1.position.z = math.cos(time * 0.3) * 30;

  light2.position.x = math.cos(time * 0.3) * 30;
  light2.position.y = math.sin(time * 0.5) * 40;
  light2.position.z = math.sin(time * 0.7) * 30;

  light3.position.x = math.sin(time * 0.7) * 30;
  light3.position.y = math.cos(time * 0.3) * 40;
  light3.position.z = math.sin(time * 0.5) * 30;

  light4.position.x = math.sin(time * 0.3) * 30;
  light4.position.y = math.cos(time * 0.7) * 40;
  light4.position.z = math.sin(time * 0.5) * 30;

  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
