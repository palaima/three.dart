import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/helpers.dart' show CameraHelper;
import 'package:three/extras/three_math.dart' as three_math;

Scene scene;
WebGLRenderer renderer;
Line mesh;

PerspectiveCamera camera;
PerspectiveCamera cameraPerspective;
OrthographicCamera cameraOrtho;

CameraHelper cameraPerspectiveHelper;
CameraHelper cameraOrthoHelper;

Camera activeCamera;
CameraHelper activeHelper;

Object3D cameraRig;

int screenWidth = window.innerWidth;
int screenHeight = window.innerHeight;

void init() {
  scene = new Scene();

  //

  camera = new PerspectiveCamera(50.0, 0.5 * screenWidth / screenHeight, 1.0, 10000.0);
  camera.position.z = 2500.0;

  cameraPerspective = new PerspectiveCamera(50.0, 0.5 * screenWidth / screenHeight, 150.0, 1000.0);

  cameraPerspectiveHelper = new CameraHelper(cameraPerspective);
  scene.add(cameraPerspectiveHelper);

  //

  cameraOrtho = new OrthographicCamera(
      0.5 * screenWidth / -2, 0.5 * screenWidth / 2, screenHeight / 2, screenHeight / -2, 150.0, 1000.0);

  cameraOrthoHelper = new CameraHelper(cameraOrtho);
  scene.add(cameraOrthoHelper);

  //

  activeCamera = cameraPerspective;
  activeHelper = cameraPerspectiveHelper;

  // counteract different front orientation of cameras vs rig

  cameraOrtho.rotation.y = math.PI;
  cameraPerspective.rotation.y = math.PI;

  cameraRig = new Group();

  cameraRig.add(cameraPerspective);
  cameraRig.add(cameraOrtho);

  scene.add(cameraRig);

  //

  mesh = new LineSegments(
      new WireframeGeometry(new SphereBufferGeometry(100.0, 16, 8)), new LineBasicMaterial(color: 0xffffff));
  scene.add(mesh);

  mesh.add(new LineSegments(
      new WireframeGeometry(new SphereBufferGeometry(50.0, 16, 8)), new LineBasicMaterial(color: 0x00ff00))
    ..position.y = 150.0);

  cameraRig.add(new LineSegments(
      new WireframeGeometry(new SphereBufferGeometry(5.0, 16, 8)), new LineBasicMaterial(color: 0x0000ff))
    ..position.z = 150.0);

  //

  var geometry = new Geometry();

  for (var i = 0; i < 10000; i++) {
    geometry.vertices.add(new Vector3.zero()
      ..x = three_math.randFloatSpread(2000.0)
      ..y = three_math.randFloatSpread(2000.0)
      ..z = three_math.randFloatSpread(2000.0));
  }

  var particles = new PointCloud(geometry, new PointCloudMaterial(color: 0x888888));
  scene.add(particles);

  //

  renderer = new WebGLRenderer(antialias: true)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(screenWidth, screenHeight)
    ..domElement.style.position = "relative";
  document.body.append(renderer.domElement);

  renderer.autoClear = false;

  window.onResize.listen(onWindowResize);
  document.onKeyDown.listen(onDocumentKeyDown);
}

void onDocumentKeyDown(KeyboardEvent event) {
  switch (event.keyCode) {
    case KeyCode.O:
      activeCamera = cameraOrtho;
      activeHelper = cameraOrthoHelper;
      break;
    case KeyCode.P:
      activeCamera = cameraPerspective;
      activeHelper = cameraPerspectiveHelper;
      break;
  }
}

onWindowResize(event) {
  screenWidth = window.innerWidth;
  screenHeight = window.innerHeight;

  renderer.setSize(screenWidth, screenHeight);

  camera.aspect = 0.5 * screenWidth / screenHeight;
  camera.updateProjectionMatrix();

  cameraPerspective.aspect = 0.5 * screenWidth / screenHeight;
  cameraPerspective.updateProjectionMatrix();

  cameraOrtho.left = -0.5 * screenWidth / 2;
  cameraOrtho.right = 0.5 * screenWidth / 2;
  cameraOrtho.top = screenHeight / 2;
  cameraOrtho.bottom = -screenHeight / 2;
  cameraOrtho.updateProjectionMatrix();
}

void render() {
  var r = new DateTime.now().millisecondsSinceEpoch * 0.0005;

  mesh.position.x = 700 * math.cos(r);
  mesh.position.z = 700 * math.sin(r);
  mesh.position.y = 700 * math.sin(r);

  mesh.children[0].position.x = 70 * math.cos(2 * r);
  mesh.children[0].position.z = 70 * math.sin(r);

  if (activeCamera == cameraPerspective) {
    cameraPerspective.fov = 35 + 30 * math.sin(0.5 * r);
    cameraPerspective.far = mesh.position.length;
    cameraPerspective.updateProjectionMatrix();

    cameraPerspectiveHelper.update();
    cameraPerspectiveHelper.visible = true;

    cameraOrthoHelper.visible = false;
  } else {
    cameraOrtho.far = mesh.position.length;
    cameraOrtho.updateProjectionMatrix();

    cameraOrthoHelper.update();
    cameraOrthoHelper.visible = true;

    cameraPerspectiveHelper.visible = false;
  }

  cameraRig.lookAt(mesh.position);

  renderer.clear();

  activeHelper.visible = false;

  renderer.setViewport(0, 0, screenWidth ~/ 2, screenHeight);
  renderer.render(scene, activeCamera);

  activeHelper.visible = true;

  renderer.setViewport(screenWidth ~/ 2, 0, screenWidth ~/ 2, screenHeight);
  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
