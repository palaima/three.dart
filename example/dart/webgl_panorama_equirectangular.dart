import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

bool isUserInteracting = false;

int onMouseDownMouseX = 0;
int onMouseDownMouseY = 0;

double lon = 0.0;
double lat = 0.0;

double onMouseDownLon = 0.0;
double onMouseDownLat = 0.0;

double phi = 0.0;
double theta = 0.0;

Vector3 target = new Vector3.zero();

void init() {
  camera = new PerspectiveCamera(75.0, window.innerWidth / window.innerHeight, 1.0, 1100.0);

  scene = new Scene();

  var geometry = new SphereGeometry(500.0, 60, 40);

  var texture = image_utils.loadTexture('textures/2294472375_24a3b8ef46_o.jpg');

  var material = new MeshBasicMaterial(map: texture);

  var mesh = new Mesh(geometry, material)..scale.setValues(-1.0, 1.0, 1.0);

  scene.add(mesh);

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  document.onMouseDown.listen(onDocumentMouseDown);
  document.onMouseMove.listen(onDocumentMouseMove);
  document.onMouseUp.listen(onDocumentMouseUp);
  document.onMouseWheel.listen(onDocumentMouseWheel);

  //

  document.onDragOver.listen((event) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
  });

  document.onDragEnter.listen((_) => document.body.style.opacity = '0.5');

  document.onDragLeave.listen((_) => document.body.style.opacity = '1');

  document.onDrop.listen((event) {
    event.preventDefault();

    var reader = new FileReader();
    reader.onLoad.listen((event) {
      material.map.image.src = event.target.result;
      material.map.needsUpdate = true;
    });

    reader.readAsDataUrl(event.dataTransfer.files[0]);

    document.body.style.opacity = '1';
  });

  //

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void onDocumentMouseDown(MouseEvent event) {
  event.preventDefault();

  isUserInteracting = true;

  onMouseDownMouseX = event.client.x;
  onMouseDownMouseY = event.client.y;

  onMouseDownLon = lon;
  onMouseDownLat = lat;
}

void onDocumentMouseMove(MouseEvent event) {
  if (isUserInteracting) {
    lon = (onMouseDownMouseX - event.client.x) * 0.1 + onMouseDownLon;
    lat = (event.client.y - onMouseDownMouseY) * 0.1 + onMouseDownLat;
  }
}

void onDocumentMouseUp(_) {
  isUserInteracting = false;
}

void onDocumentMouseWheel(WheelEvent event) {
  // WebKit
  if (event.wheelDeltaY != null) {
    camera.fov -= event.wheelDeltaY * 0.05;
    // Firefox
  } else if (event.detail != null) {
    camera.fov += event.detail * 1.0;
  }

  camera.updateProjectionMatrix();
}

void render() {
  if (!isUserInteracting) {
    lon += 0.1;
  }

  lat = math.max(-85, math.min(85, lat));
  phi = degToRad(90 - lat);
  theta = degToRad(lon);

  target.x = 500 * math.sin(phi) * math.cos(theta);
  target.y = 500 * math.cos(phi);
  target.z = 500 * math.sin(phi) * math.sin(theta);

  camera.lookAt(target);

//  // Distortion
//  camera.position.setFrom(target).negate();

  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
