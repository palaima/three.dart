import 'dart:html';
import 'package:three/three.dart';
import 'package:three/extras/loaders.dart' show DDSLoader;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

double mouseX = 0.0;
double mouseY = 0.0;

double windowHalfX = window.innerWidth / 2;
double windowHalfY = window.innerHeight / 2;

init() {
  camera = new PerspectiveCamera(75.0, window.innerWidth / window.innerHeight, 1.0, 100000.0);
  camera.position.z = 3200.0;

  scene = new Scene();

  /*
  var r = "textures/cube/Escher/";

  var urls = [ r + "px.jpg", r + "nx.jpg",
         r + "py.jpg", r + "ny.jpg",
         r + "pz.jpg", r + "nz.jpg" ];

  var textureCube = ImageUtils.loadTextureCube( urls );
  */

  var r = "textures/cube/Escher/dds/";

  var urls = [r + "px.dds", r + "nx.dds", r + "py.dds", r + "ny.dds", r + "pz.dds", r + "nz.dds"];

  var loader = new DDSLoader();

  var textureCube = loader.load(urls);
  var material = new MeshBasicMaterial(color: 0xffffff, envMap: textureCube);
  var geometry = new SphereGeometry(100.0, 96, 64);

  var mesh = new Mesh(geometry, material);
  mesh.scale.splat(16.0);
  scene.add(mesh);

  // Skybox

  var shader = ShaderLib["cube"];
  shader['uniforms']["tCube"].value = textureCube;

  material = new ShaderMaterial(
      fragmentShader: shader['fragmentShader'],
      vertexShader: shader['vertexShader'],
      uniforms: shader['uniforms'],
      side: BackSide);

  mesh = new Mesh(new BoxGeometry(6000.0, 6000.0, 6000.0), material);
  scene.add(mesh);

  //

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

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
  mouseX = (event.client.x - windowHalfX);
  mouseY = (event.client.y - windowHalfY);
}

void render() {
  camera.position.x += (mouseX - camera.position.x) * .05;
  camera.position.y += (-mouseY - camera.position.y) * .05;

  camera.lookAt(scene.position);

  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
