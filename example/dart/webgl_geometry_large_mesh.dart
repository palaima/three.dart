import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/loaders.dart' show BinaryLoader;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

BinaryLoader loader;

Mesh lightMesh;

PointLight pointLight;

double mouseX = 0.0,
    mouseY = 0.0;

double windowHalfX = window.innerWidth / 2;
double windowHalfY = window.innerHeight / 2;

void addMesh(Geometry geometry, Material material,
    {scale: 1.0, x: 0.0, y: 0.0, z: 0.0, rx: 0.0, ry: 0.0, rz: 0.0}) {
  scene.add(new Mesh(geometry, material)
    ..scale.splat(scale)
    ..position.setValues(x, y, z)
    ..rotation.setValues(rx, ry, rz));
}

void init() {
  camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 100000.0)
    ..position.z = 1500.0;

  scene = new Scene();

  // LIGHTS

  var directionalLight = new DirectionalLight(0xffffff, 0.5);
  directionalLight.position
    ..setValues(1.0, 1.0, 2.0)
    ..normalize();
  scene.add(directionalLight);

  pointLight = new PointLight(0xffffff, intensity: 3.0, distance: 1000.0);
  scene.add(pointLight);

  // light representation

  var sphere = new SphereGeometry(10.0, 16, 8, 1.0);

  lightMesh = new Mesh(sphere, new MeshBasicMaterial(color: 0xffffff));
  scene.add(lightMesh);

  renderer = new WebGLRenderer(antialias: true, alpha: true)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..domElement.style.position = 'relative';
  document.body.append(renderer.domElement);

  loader = new BinaryLoader(showStatus: true);
  document.body.append(loader.statusDomElement);

  var start = new DateTime.now();

  loader.load('obj/lucy/Lucy100k_bin.js').then((result) {
    addMesh(result.geometry, new MeshPhongMaterial(color: 0x030303, specular: 0x990000, shininess: 30.0),
        scale: 0.75, x: 900.0);

    addMesh(result.geometry, new MeshPhongMaterial(color: 0x005555, specular: 0xffaa00, shininess: 10.0),
        scale: 0.75, x: 300.0);

    addMesh(result.geometry, new MeshPhongMaterial(color: 0x111111, specular: 0xffaa00, shininess: 10.0),
        scale: 0.75, x: -300.0);

    addMesh(result.geometry, new MeshPhongMaterial(color: 0x555555, specular: 0x666666, shininess: 10.0),
        scale: 0.75, x: -900.0);

    loader.statusDomElement.style.display = 'none';

    log('geometry.vertices: ${result.geometry.vertices.length}');
    log('geometry.faces: ${result.geometry.faces.length}');

    log('model loaded and created in ${new DateTime.now().difference(start).inMilliseconds} ms');
  });

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
  mouseX = (event.client.x - windowHalfX);
  mouseY = (event.client.y - windowHalfY);
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.001;

  camera.position.x += (mouseX - camera.position.x) * 0.05;
  camera.position.y += (-mouseY - camera.position.y) * 0.05;

  camera.lookAt(scene.position);

  pointLight.position.x = 600 * math.cos(time);
  pointLight.position.y = 400 * math.cos(time * 1.25);
  pointLight.position.z = 300 * math.sin(time);

  lightMesh.position.setFrom(pointLight.position);

  renderer.render(scene, camera);
}

void log(String text) {
  var e = querySelector('#log');
  e.innerHtml = '$text<br/>${e.innerHtml}';
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
