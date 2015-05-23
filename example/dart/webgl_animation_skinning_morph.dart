import 'dart:html' hide Animation;
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/loaders.dart' show JSONLoader;
import 'package:three/extras/animation.dart';
import 'package:three/extras/animation_handler.dart' as animation_handler;
import 'package:three/extras/image_utils.dart' as image_utils;

// TODO
// - add SkeletonHelper
// - investigate why there is a break between animations
// - investigate why loading model is taking so long.

int screenWidth = window.innerWidth;
int screenHeight = window.innerHeight;
double floor = -250.0;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

SkinnedMesh mesh;
// SkeletonHelper helper;

double mouseX = 0.0,
    mouseY = 0.0;

double windowHalfX = window.innerWidth / 2;
double windowHalfY = window.innerHeight / 2;

Clock clock = new Clock();

void init() {
  camera = new PerspectiveCamera(30.0, screenWidth / screenHeight, 1.0, 10000.0)
    ..position.z = 2200.0;

  scene = new Scene();

  scene.fog = new FogLinear(0xffffff, 2000.0, 10000.0);

  scene.add(camera);

  // GROUND

  var geometry = new PlaneBufferGeometry(16000.0, 16000.0);
  var material = new MeshPhongMaterial(emissive: 0xbbbbbb);

  var ground = new Mesh(geometry, material);
  ground.position.setValues(0.0, floor, 0.0);
  ground.rotation.x = -math.PI / 2;
  scene.add(ground);

  ground.receiveShadow = true;

  // LIGHTS

  var ambient = new AmbientLight(0x222222);
  scene.add(ambient);

  var light = new DirectionalLight(0xebf3ff, 1.6);
  light.position.setValues(0.0, 140.0, 500.0).scale(1.1);
  scene.add(light);

  light.castShadow = true;

  light.shadowMapWidth = 1024;
  light.shadowMapHeight = 2048;

  var d = 390.0;

  light.shadowCameraLeft = -d;
  light.shadowCameraRight = d;
  light.shadowCameraTop = d * 1.5;
  light.shadowCameraBottom = -d;

  light.shadowCameraFar = 3500.0;
  //light.shadowCameraVisible = true;

  //

  scene.add(
      new DirectionalLight(0x493f13, 1.0)..position.setValues(0.0, -1.0, 0.0));

  // RENDERER

  renderer = new WebGLRenderer(antialias: true)
    ..setClearColor(scene.fog.color)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(screenWidth, screenHeight);
  renderer.domElement.style.position = "relative";

  document.body.append(renderer.domElement);

  renderer.gammaInput = true;
  renderer.gammaOutput = true;

  renderer.shadowMap.enabled = true;

  //

  var loader = new JSONLoader();
  loader.load("models/skinned/knight.js").then((result) {
    createScene(result.geometry, result.materials, 0.0, floor, -300.0, 60.0);
  });

  // GUI

  //initGUI();

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

void ensureLoop(Map animation) {
  for (var i = 0; i < animation['hierarchy'].length; i++) {
    var bone = animation['hierarchy'][i];

    var first = bone['keys'].first;
    var last = bone['keys'].last;

    last['pos'] = first['pos'];
    last['rot'] = first['rot'];
    last['scl'] = first['scl'];
  }
}

void createScene(Geometry geometry, List<Material> materials, double x,
    double y, double z, double s) {
  ensureLoop(geometry.animation);

  geometry.computeBoundingBox();
  var bb = geometry.boundingBox;

  var path = "textures/cube/Park2/";
  var format = '.jpg';
  var urls = [
    path + 'posx' + format,
    path + 'negx' + format,
    path + 'posy' + format,
    path + 'negy' + format,
    path + 'posz' + format,
    path + 'negz' + format
  ];

  //var envMap = image_utils.loadTextureCube( urls );

  //var map = image_utils.loadTexture( "textures/UV_Grid_Sm.jpg" );

  //var bumpMap = image_utils.generateDataTexture( 1, 1, new Color.white() );
  //var bumpMap = image_utils.loadTexture( "textures/water.jpg" );

  for (var i = 0; i < materials.length; i++) {
    var m = materials[i];
    m.skinning = true;
    m.morphTargets = true;

    m.specular.setHSL(0.0, 0.0, 0.1);

    m.color.setHSL(0.6, 0.0, 0.6);

    //m.map = map;
    //m.envMap = envMap;
    //m.bumpMap = bumpMap;
    //m.bumpScale = 2;

    //m.combine = MixOperation;
    //m.reflectivity = 0.75;
  }

  mesh = new SkinnedMesh(geometry, materials[0])
    ..position.setValues(x, y - bb.min.y * s, z)
    ..scale.splat(s);
  scene.add(mesh);

  mesh.castShadow = true;
  mesh.receiveShadow = true;

//  helper = new SkeletonHelper(mesh);
//  helper.material.linewidth = 3;
//  helper.visible = false;
//  scene.add(helper);

  new Animation(mesh, geometry.animation)..play();
}

void initGUI() {
//  var API = {'show model': true, 'show skeleton': false};
//
//  var gui = new dat.GUI();
//
//  gui.add(API, 'show model').onChange(() {
//    mesh.visible = API['show model'];
//  });
//
//  gui.add(API, 'show skeleton').onChange(() {
//    helper.visible = API['show skeleton'];
//  });
}

void onDocumentMouseMove(MouseEvent event) {
  mouseX = (event.client.x - windowHalfX);
  mouseY = (event.client.y - windowHalfY);
}

//

void animate(num time) {
  window.animationFrame.then(animate);

  render();
}

void render() {
  var delta = 0.75 * clock.getDelta();

  camera.position.x += (mouseX - camera.position.x) * .05;
  camera.position.y = (camera.position.y + (-mouseY - camera.position.y) * .05)
      .clamp(0.0, 1000.0);

  camera.lookAt(scene.position);

  // update skinning

  animation_handler.update(delta);

  //if (helper != null) helper.update();

  // update morphs

  if (mesh != null) {
    var time = new DateTime.now().millisecondsSinceEpoch * 0.001;

    // mouth
    mesh.morphTargetInfluences[1] = (1 + math.sin(4 * time)) / 2;

    // frown ?
    mesh.morphTargetInfluences[2] = (1 + math.sin(2 * time)) / 2;

    // eyes
    mesh.morphTargetInfluences[3] = (1 + math.cos(4 * time)) / 2;
  }

  renderer.render(scene, camera);
}

void main() {
  init();
  animate(0);
}
