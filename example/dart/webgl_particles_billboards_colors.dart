import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as ImageUtils;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

PointCloud particles;
Geometry geometry;

Material material;

double mouseX = 0.0, mouseY = 0.0;

double windowHalfX = window.innerWidth / 2;
double windowHalfY = window.innerHeight / 2;

Math.Random rnd = new Math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 3000.0)
    ..position.z = 1400.0;

  scene = new Scene()
    ..fog = new FogExp2(0x000000, 0.0009);

  geometry = new Geometry();

  var sprite = ImageUtils.loadTexture("textures/sprites/ball.png");

  var colors = new List(5000);

  for (var i = 0; i < 5000; i ++) {
    var vertex = new Vector3.zero()
      ..x = 2000 * rnd.nextDouble() - 1000
      ..y = 2000 * rnd.nextDouble() - 1000
      ..z = 2000 * rnd.nextDouble() - 1000;

    geometry.vertices.add(vertex);

    colors[i] = new Color(0xffffff);
    colors[i].setHSL((vertex.x + 1000) / 2000, 1.0, 0.5);
  }

  geometry.colors = colors;

  material = new PointCloudMaterial(size: 85.0, map: sprite, vertexColors: VertexColors, alphaTest: 0.5, transparent: true)
    ..color.setHSL(1.0, 0.2, 0.7);

  particles = new PointCloud(geometry, material);
  scene.add(particles);

  //

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  document.onMouseMove.listen(onDocumentMouseMove);
  document.onTouchStart.listen(onDocumentTouchStart);
  document.onTouchMove.listen(onDocumentTouchMove);

  //

  document.onResize.listen(onWindowResize);
}

void onWindowResize(Event event) {
  windowHalfX = window.innerWidth / 2;
  windowHalfY = window.innerHeight / 2;

  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void onDocumentMouseMove(MouseEvent event) {
  mouseX = event.client.x - windowHalfX;
  mouseY = event.client.y - windowHalfY;
}

void onDocumentTouchStart(TouchEvent event) {
  if (event.touches.length == 1) {
    event.preventDefault();

    mouseX = event.touches[0].page.x - windowHalfX;
    mouseY = event.touches[0].page.y - windowHalfY;
  }
}

void onDocumentTouchMove(TouchEvent event) {
  if (event.touches.length == 1) {
    event.preventDefault();

    mouseX = event.touches[0].page.x - windowHalfX;
    mouseY = event.touches[0].page.y - windowHalfY;
  }
}

//

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.00005;

  camera.position.x += (mouseX - camera.position.x) * 0.05;
  camera.position.y += (-mouseY - camera.position.y) * 0.05;

  camera.lookAt(scene.position);

  var h = (360 * (1.0 + time) % 360) / 360;
  material.color.setHSL(h, 0.5, 0.5);

  renderer.render(scene, camera);
}
