import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

double mouseX = 0.0,
    mouseY = 0.0;

double windowHalfX = window.innerWidth / 2;
double windowHalfY = window.innerHeight / 2;

void init() {
  camera = new PerspectiveCamera(60.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.setValues(100000.0, 0.0, 3200.0);

  scene = new Scene();

  var colors = [0x000000, 0xff0080, 0x8000ff, 0xffffff];
  var geometry = new Geometry();

  var random = new math.Random().nextDouble;

  for (var i = 0; i < 2000; i++) {
    geometry.vertices.add(new Vector3.zero()
      ..x = random() * 4000 - 2000
      ..y = random() * 4000 - 2000
      ..z = random() * 4000 - 2000);
    geometry.colors.add(new Color(colors[(random() * colors.length).floor()]));
  }

  var material = new PointCloudMaterial(
      size: 1.0,
      vertexColors: VertexColors,
      depthTest: false,
      opacity: 0.5,
      sizeAttenuation: false,
      transparent: true);

  var mesh = new PointCloud(geometry, material);
  scene.add(mesh);

  renderer = new WebGLRenderer(preserveDrawingBuffer: true)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..sortObjects = false
    ..autoClearColor = false;
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
  mouseX = (event.client.x - windowHalfX) * 10;
  mouseY = (event.client.y - windowHalfY) * 10;
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
