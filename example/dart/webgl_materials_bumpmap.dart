import 'dart:html';
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;
import 'package:three/extras/loaders.dart' show JSONLoader;

/*
 * TODO Investigate why skin is so dark...
 */

WebGLRenderer renderer;
PerspectiveCamera camera;
Scene scene;

JSONLoader loader;

Mesh mesh;

num mouseX = 0;
num mouseY = 0;

num targetX = 0;
num targetY = 0;

num windowHalfX = window.innerWidth / 2;
num windowHalfY = window.innerHeight / 2;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(27.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 1200.0;

  scene = new Scene();

  // LIGHTS
  scene.add(new AmbientLight(0x444444));

  //

  var pointLight = new PointLight(0xffffff, intensity: 1.5, distance: 1000.0)
    ..color.setHSL(0.05, 1.0, 0.95)
    ..position.setValues(0.0, 0.0, 600.0);
  scene.add(pointLight);

  // shadow for PointLight

  var spotLight = new SpotLight(0xffffff, intensity: 1.5)
    ..position.setValues(0.05, 0.05, 1.0)
    ..color.setHSL(0.6, 1.0, 0.95);
  scene.add(spotLight);

  spotLight.position.scale(700.0);

  spotLight.castShadow = true;
  spotLight.onlyShadow = true;

  spotLight.shadowMapWidth = 2048;
  spotLight.shadowMapHeight = 2048;

  spotLight.shadowCameraNear = 200.0;
  spotLight.shadowCameraFar = 1500.0;

  spotLight.shadowCameraFov = 40.0;

  spotLight.shadowBias = -0.005;
  spotLight.shadowDarkness = 0.35;

  //

  var directionalLight = new DirectionalLight(0xffffff, 1.5);
  directionalLight.position.setValues(1.0, -0.5, 1.0);
  directionalLight.color.setHSL(0.6, 1.0, 0.95);
  scene.add(directionalLight);

  directionalLight.position.scale(500.0);

  directionalLight.castShadow = true;

  directionalLight.shadowMapWidth = 2048;
  directionalLight.shadowMapHeight = 2048;

  directionalLight.shadowCameraNear = 200.0;
  directionalLight.shadowCameraFar = 1500.0;

  directionalLight.shadowCameraLeft = -500.0;
  directionalLight.shadowCameraRight = 500.0;
  directionalLight.shadowCameraTop = 500.0;
  directionalLight.shadowCameraBottom = -500.0;

  directionalLight.shadowBias = -0.005;
  directionalLight.shadowDarkness = 0.35;

  //

  var directionalLight2 = new DirectionalLight(0xffffff, 1.2)
    ..position.setValues(1.0, -0.5, -1.0)
    ..color.setHSL(0.08, 1.0, 0.825);
  scene.add(directionalLight2);

  var mapHeight = image_utils.loadTexture('obj/leeperrysmith/Infinite-Level_02_Disp_NoSmoothUV-4096.jpg');

  mapHeight.anisotropy = 4;
  mapHeight.repeat.setValues(0.998, 0.998);
  mapHeight.offset.setValues(0.001, 0.001);
  mapHeight.wrapS = mapHeight.wrapT = RepeatWrapping;
  mapHeight.format = RGBFormat;

  var material = new MeshPhongMaterial(color: 0x552811, specular: 0x333333, shininess: 25.0, bumpMap: mapHeight, bumpScale: 19.0, metal: false);

  loader = new JSONLoader(showStatus: true);
  document.body.append(loader.statusDomElement);

  loader.load('obj/leeperrysmith/LeePerrySmith.js').then((geometry) => createScene(geometry, 100.0, material));

  //

  renderer = new WebGLRenderer(antialias: true)
    ..setClearColor(0x0a0a0a)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  renderer.shadowMap.enabled = true;
  renderer.shadowMap.cullFace = CullFaceBack;

  document.onMouseMove.listen((event) {
    mouseX = (event.client.x - windowHalfX);
    mouseY = (event.client.y - windowHalfY);
  });

  window.onResize.listen((_) {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);
  });
}

void createScene(Geometry geometry, double scale, Material material) {
  mesh = new Mesh(geometry, material);

  mesh.position.y = -50.0;
  mesh.scale.splat(scale);

  mesh.castShadow = true;
  mesh.receiveShadow = true;

  scene.add(mesh);

  loader.statusDomElement.style.display = 'none';
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  targetX = mouseX * .001;
  targetY = mouseY * .001;

  if (mesh != null) {
    mesh.rotation.y += 0.05 * (targetX - mesh.rotation.y);
    mesh.rotation.x += 0.05 * (targetY - mesh.rotation.x);
  }

  renderer.render(scene, camera);
}
