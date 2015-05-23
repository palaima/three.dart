import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;
import 'package:three/extras/loaders.dart' show BinaryLoader;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

PerspectiveCamera cameraCube;
Scene sceneCube;

BinaryLoader loader;

PointLight pointLight;

double mouseX = 0.0;
double mouseY = 0.0;

double windowHalfX = window.innerWidth / 2;
double windowHalfY = window.innerHeight / 2;

void init() {
  camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 5000.0)
    ..position.z = 2000.0;

  cameraCube = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 100.0);

  scene = new Scene();
  sceneCube = new Scene();

  // LIGHTS

  scene.add(new AmbientLight(0xffffff));

  pointLight = new PointLight(0xffffff, intensity: 2.0);
  scene.add(pointLight);

  // light representation

  var sphere = new SphereGeometry(100.0, 16, 8);

  pointLight.add(new Mesh(sphere, new MeshBasicMaterial(color: 0xffaa00))
    ..scale.setValues(0.05, 0.05, 0.05));

  var urls = new List.generate(
      6, (i) => 'textures/cube/SwedishRoyalCastle/${['px', 'nx', 'py', 'ny', 'pz', 'nz'][i]}.jpg');

  var reflectionCube = image_utils.loadTextureCube(urls)
    ..format = RGBFormat;

  var refractionCube = new CubeTexture(reflectionCube.image, mapping: CubeRefractionMapping)
    ..format = RGBFormat;

  var cubeMaterial3 = new MeshLambertMaterial(
      color: 0xff6600, envMap: reflectionCube, combine: MixOperation, reflectivity: 0.3);
  var cubeMaterial2 = new MeshLambertMaterial(color: 0xffee00, envMap: refractionCube, refractionRatio: 0.95);
  var cubeMaterial1 = new MeshLambertMaterial(color: 0xffffff, envMap: reflectionCube, combine: MixOperation);

  // TODO investigate why I need to add `combine: MixOperation` to cubeMaterial1 to make it look right.

  // Skybox

  var shader = ShaderLib['cube'];
  shader['uniforms']['tCube'].value = reflectionCube;

  var material = new ShaderMaterial(
      fragmentShader: shader['fragmentShader'],
      vertexShader: shader['vertexShader'],
      uniforms: shader['uniforms'],
      depthWrite: false,
      side: BackSide),
      mesh = new Mesh(new BoxGeometry(100.0, 100.0, 100.0), material);
  sceneCube.add(mesh);

  //

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..autoClear = false;
  document.body.append(renderer.domElement);

  //

  loader = new BinaryLoader(showStatus: true);
  document.body.append(loader.statusDomElement);

  loader.load('obj/walt/WaltHead_bin.js').then((geometry) =>
      createScene(geometry, cubeMaterial1, cubeMaterial2, cubeMaterial3));

  // createScene(await loader.load('obj/walt/WaltHead_bin.js'),
  //     cubeMaterial1, cubeMaterial2, cubeMaterial3));

  document.onMouseMove.listen(onDocumentMouseMove);
  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  windowHalfX = window.innerWidth / 2;
  windowHalfY = window.innerHeight / 2;

  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  cameraCube.aspect = window.innerWidth / window.innerHeight;
  cameraCube.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void onDocumentMouseMove(MouseEvent event) {
  mouseX = (event.client.x - windowHalfX) * 4;
  mouseY = (event.client.y - windowHalfY) * 4;
}

void createScene(Geometry geometry, MeshLambertMaterial m1, MeshLambertMaterial m2, MeshLambertMaterial m3) {
  var s = 15.0;

  scene.add(new Mesh(geometry, m1)
    ..position.z = -100.0
    ..scale.splat(s));

  scene.add(new Mesh(geometry, m2)
    ..position.x = -900.0
    ..position.z = -100.0
    ..scale.splat(s));

  scene.add(new Mesh(geometry, m3)
    ..position.x = 900.0
    ..position.z = -100.0
    ..scale.splat(s));

  loader.statusDomElement.style.display = 'none';
}

void render() {
  var timer = new DateTime.now().millisecondsSinceEpoch * -0.0002;

  pointLight.position.x = 1500 * math.cos(timer);
  pointLight.position.z = 1500 * math.sin(timer);

  camera.position.x += (mouseX - camera.position.x) * .05;
  camera.position.y += (-mouseY - camera.position.y) * .05;

  camera.lookAt(scene.position);
  cameraCube.rotation.setFrom(camera.rotation);

  renderer.render(sceneCube, cameraCube);
  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
