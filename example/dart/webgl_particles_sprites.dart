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

List parameters;
List<Material> materials;

void init() {
  camera = new PerspectiveCamera(75.0, window.innerWidth / window.innerHeight, 1.0, 2000.0)
    ..position.z = 1000.0;

  scene = new Scene();
  scene.fog = new FogExp2(0x000000, 0.0008);

  geometry = new Geometry();

  var sprite1 = ImageUtils.loadTexture('textures/sprites/snowflake1.png');
  var sprite2 = ImageUtils.loadTexture('textures/sprites/snowflake2.png');
  var sprite3 = ImageUtils.loadTexture('textures/sprites/snowflake3.png');
  var sprite4 = ImageUtils.loadTexture('textures/sprites/snowflake4.png');
  var sprite5 = ImageUtils.loadTexture('textures/sprites/snowflake5.png');

  for (var i = 0; i < 10000; i ++) {
    var vertex = new Vector3.zero()
      ..x = rnd.nextDouble() * 2000 - 1000
      ..y = rnd.nextDouble() * 2000 - 1000
      ..z = rnd.nextDouble() * 2000 - 1000;

    geometry.vertices.add(vertex);
  }

  parameters = [
    [[1.0, 0.2, 0.5], sprite2, 20.0],
    [[0.95, 0.1, 0.5], sprite3, 15.0],
    [[0.90, 0.05, 0.5], sprite1, 10.0],
    [[0.85, 0.0, 0.5], sprite5, 8.0],
    [[0.80, 0.0, 0.5], sprite4, 5.0],
  ];

  materials = new List(parameters.length);

  for (var i = 0; i < parameters.length; i++) {
    var color  = parameters[i][0];
    var sprite = parameters[i][1];
    var size   = parameters[i][2];

    materials[i] = new PointCloudMaterial(size: size, map: sprite, blending: AdditiveBlending, depthTest: false, transparent : true)
      ..color.setHSL(color[0], color[1], color[2]);

    particles = new PointCloud(geometry, materials[i])
      ..rotation.x = rnd.nextDouble() * 6
      ..rotation.y = rnd.nextDouble() * 6
      ..rotation.z = rnd.nextDouble() * 6;

    scene.add(particles);
  }

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);

  document.body.append(renderer.domElement);

  document.onMouseMove.listen(onDocumentMouseMove);
  document.onTouchStart.listen(onDocumentTouchStart);
  document.onTouchMove.listen(onDocumentTouchMove);

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
  camera.position.y += (- mouseY - camera.position.y) * 0.05;

  camera.lookAt(scene.position);

  for (var i = 0; i < scene.children.length; i++) {
    var object = scene.children[i];

    if (object is PointCloud) {
      object.rotation.y = time * (i < 4 ? i + 1 : -(i + 1));
    }
  }

  for (var i = 0; i < materials.length; i ++) {
    var color = parameters[i][0];

    var h = (360 * (color[0] + time) % 360) / 360;
    materials[i].color.setHSL(h, color[1], color[2]);
  }

  renderer.render(scene, camera);
}
