import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;
import 'package:three/extras/effects.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

AnaglyphEffect effect;

List<Mesh> spheres = [];

double mouseX = 0.0;
double mouseY = 0.0;

double windowHalfX = window.innerWidth / 2;
double windowHalfY = window.innerHeight / 2;

void init() {
  camera = new PerspectiveCamera(
      60.0, window.innerWidth / window.innerHeight, 1.0, 100000.0)
    ..position.z = 3200.0;

  scene = new Scene();

  var geometry = new SphereGeometry(100.0, 32, 16);

  var urls = new List.generate(6, (i) =>
      'textures/cube/pisa/${['px', 'nx', 'py', 'ny', 'pz', 'nz'][i]}.png');

  var textureCube = image_utils.loadTextureCube(urls);
  var material = new MeshBasicMaterial(color: 0xffffff, envMap: textureCube);

  var random = new math.Random().nextDouble;

  for (var i = 0; i < 500; i++) {
    var mesh = new Mesh(geometry, material);

    mesh.position.x = random() * 10000 - 5000;
    mesh.position.y = random() * 10000 - 5000;
    mesh.position.z = random() * 10000 - 5000;

    mesh.scale.splat(random() * 3 + 1);

    scene.add(mesh);

    spheres.add(mesh);
  }

  //Skybox

  var shader = ShaderLib["cube"];
  shader['uniforms']["tCube"].value = textureCube;

  var material2 = new ShaderMaterial(
      fragmentShader: shader['fragmentShader'],
      vertexShader: shader['vertexShader'],
      uniforms: shader['uniforms'],
      depthWrite: false,
      side: BackSide);
  var mesh = new Mesh(new BoxGeometry(10000.0, 10000.0, 10000.0), material2);

  scene.add(mesh);

  //

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  effect = new AnaglyphEffect(renderer);
  effect.setSize(window.innerWidth, window.innerHeight);

  //

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
  var timer = 0.0001 * new DateTime.now().millisecondsSinceEpoch;

  camera.position.x += (mouseX - camera.position.x) * .05;
  camera.position.y += (-mouseY - camera.position.y) * .05;

  camera.lookAt(scene.position);

  for (var i = 0; i < spheres.length; i++) {
    var sphere = spheres[i];

    sphere.position.x = 5000 * math.cos(timer + i);
    sphere.position.y = 5000 * math.sin(timer + i * 1.1);
  }

  effect.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
