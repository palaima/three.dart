import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/controls.dart' show OrbitControls;
import 'package:three/extras/objects/mirror.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

OrbitControls cameraControls;

Mirror verticalMirror, groundMirror;

Object3D sphereGroup;
Mesh smallSphere;

void init() {
  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);

  scene = new Scene();

  camera = new PerspectiveCamera(
      45.0, window.innerWidth / window.innerHeight, 1.0, 500.0);
  camera.position.setValues(0.0, 75.0, 160.0);

  cameraControls = new OrbitControls(camera, renderer.domElement)
    ..target.setValues(0.0, 40.0, 0.0)
    ..maxDistance = 400
    ..minDistance = 10
    ..update();

  document.body.append(renderer.domElement);
}

void fillScene() {
  var planeGeo = new PlaneBufferGeometry(100.1, 100.1);

  // MIRROR planes
  groundMirror = new Mirror(renderer, camera,
      clipBias: 0.003,
      textureWidth: window.innerWidth,
      textureHeight: window.innerHeight,
      color: 0x777777);

  var mirrorMesh = new Mesh(planeGeo, groundMirror.material)
    ..add(groundMirror)
    ..rotateX(-math.PI / 2);
  scene.add(mirrorMesh);

  verticalMirror = new Mirror(renderer, camera,
      clipBias: 0.003,
      textureWidth: window.innerWidth,
      textureHeight: window.innerHeight,
      color: 0x889999);

  var verticalMirrorMesh = new Mesh(
      new PlaneBufferGeometry(60.0, 60.0), verticalMirror.material)
    ..add(verticalMirror)
    ..position.y = 35.0
    ..position.z = -45.0;
  scene.add(verticalMirrorMesh);

  sphereGroup = new Object3D();
  scene.add(sphereGroup);

  var cylinderGeo =
      new CylinderGeometry(0.1, 15 * math.cos(math.PI / 180 * 30), 0.1, 24, 1);
  var mat1 = new MeshPhongMaterial(color: 0xffffff, emissive: 0x444444);
  var sphereCap = new Mesh(cylinderGeo, mat1)
    ..position.y = -15 * math.sin(math.PI / 180 * 30) - 0.05
    ..rotateX(-math.PI);

  var sphereGeo = new SphereGeometry(
      15.0, 24, 24, math.PI / 2, math.PI * 2, 0.0, math.PI / 180 * 120);
  var halfSphere = new Mesh(sphereGeo, mat1)
    ..add(sphereCap)
    ..rotateX(-math.PI / 180 * 135)
    ..rotateZ(-math.PI / 180 * 20)
    ..position.y = 7.5 + 15 * math.sin(math.PI / 180 * 30);

  sphereGroup.add(halfSphere);

  var icoGeo = new IcosahedronGeometry(5.0, 0);
  var mat2 = new MeshPhongMaterial(
      color: 0xffffff, emissive: 0x333333, shading: FlatShading);
  smallSphere = new Mesh(icoGeo, mat2);
  scene.add(smallSphere);

  // walls
  var planeTop = new Mesh(planeGeo, new MeshPhongMaterial(color: 0xffffff))
    ..position.y = 100.0
    ..rotateX(math.PI / 2);
  scene.add(planeTop);

  var planeBack = new Mesh(planeGeo, new MeshPhongMaterial(color: 0xffffff))
    ..position.z = -50.0
    ..position.y = 50.0;
  scene.add(planeBack);

  var planeFront = new Mesh(planeGeo, new MeshPhongMaterial(color: 0x7f7fff))
    ..position.z = 50.0
    ..position.y = 50.0
    ..rotateY(math.PI);
  scene.add(planeFront);

  var planeRight = new Mesh(planeGeo, new MeshPhongMaterial(color: 0x00ff00))
    ..position.x = 50.0
    ..position.y = 50.0
    ..rotateY(-math.PI / 2);
  scene.add(planeRight);

  var planeLeft = new Mesh(planeGeo, new MeshPhongMaterial(color: 0xff0000))
    ..position.x = -50.0
    ..position.y = 50.0
    ..rotateY(math.PI / 2);
  scene.add(planeLeft);

  // lights
  var mainLight = new PointLight(0xcccccc, 1.5, 250.0)..position.y = 60.0;
  scene.add(mainLight);

  var greenLight = new PointLight(0x00ff00, 0.25, 1000.0)
    ..position.setValues(550.0, 50.0, 0.0);
  scene.add(greenLight);

  var redLight = new PointLight(0xff0000, 0.25, 1000.0)
    ..position.setValues(-550.0, 50.0, 0.0);
  scene.add(redLight);

  var blueLight = new PointLight(0x7f7fff, 0.25, 1000.0)
    ..position.setValues(0.0, 50.0, 550.0);
  scene.add(blueLight);
}

void render() {
  // render (update) the mirrors
  groundMirror.renderWithMirror(verticalMirror);
  verticalMirror.renderWithMirror(groundMirror);

  renderer.render(scene, camera);
}

void update(num time) {
  window.animationFrame.then(update);

  var timer = new DateTime.now().millisecondsSinceEpoch * 0.01;

  sphereGroup.rotation.y -= 0.002;

  smallSphere.position.setValues(math.cos(timer * 0.1) * 30,
      (math.cos(timer * 0.2)).abs() * 20 + 5, math.sin(timer * 0.1) * 30);
  smallSphere.rotation.y = (math.PI / 2) - timer * 0.1;
  smallSphere.rotation.z = timer * 0.8;

  cameraControls.update();

  render();
}

void main() {
  init();
  fillScene();
  update(0);
}
