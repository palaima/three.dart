import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/three_math.dart' as three_math;

Element container;

OrthographicCamera camera;
Scene scene;
WebGLRenderer renderer;
Raycaster raycaster;

Vector2 mouse = new Vector2.zero();

Mesh intersected;

int currentHex;

double radius = 100.0;
double theta = 0.0;

void init() {
  camera = new OrthographicCamera(window.innerWidth / -2, window.innerWidth / 2, window.innerHeight / 2,
      window.innerHeight / -2, -500.0, 1000.0);
  scene = new Scene();

  var light = new DirectionalLight(0xffffff, 1.0);
  light.position.splat(1.0).normalize();
  scene.add(light);

  var random = new math.Random().nextDouble;

  var geometry = new BoxGeometry(20.0, 20.0, 20.0);

  for (var i = 0; i < 2000; i++) {
    scene.add(new Mesh(geometry, new MeshLambertMaterial(color: random() * 0xffffff))
      ..position.x = random() * 800 - 400
      ..position.y = random() * 800 - 400
      ..position.z = random() * 800 - 400
      ..rotation.x = random() * 2 * math.PI
      ..rotation.y = random() * 2 * math.PI
      ..rotation.z = random() * 2 * math.PI
      ..scale.x = random() + 0.5
      ..scale.y = random() + 0.5
      ..scale.z = random() + 0.5);
  }

  raycaster = new Raycaster();
  renderer = new WebGLRenderer()
    ..setClearColor(0xf0f0f0)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..sortObjects = false;
  document.body.append(renderer.domElement);

  document.onMouseMove.listen(onDocumentMouseMove);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.left = window.innerWidth / - 2;
  camera.right = window.innerWidth / 2;
  camera.top = window.innerHeight / 2;
  camera.bottom = window.innerHeight / - 2;

  camera.updateProjectionMatrix();

  renderer.setSize( window.innerWidth, window.innerHeight );
}

void onDocumentMouseMove(MouseEvent event) {
  event.preventDefault();

  mouse.x = (event.client.x / window.innerWidth) * 2 - 1;
  mouse.y = -(event.client.y / window.innerHeight) * 2 + 1;
}

void render() {
  theta += 0.1;

  camera.position.x = radius * math.sin(three_math.degToRad(theta));
  camera.position.y = radius * math.sin(three_math.degToRad(theta));
  camera.position.z = radius * math.cos(three_math.degToRad(theta));
  camera.lookAt(scene.position);

  camera.updateMatrixWorld();

  // find intersections
  raycaster.setFromCamera(mouse, camera);

  var intersects = raycaster.intersectObjects(scene.children);

  if (intersects.length > 0) {
    if (intersected != intersects[0].object) {
      if (intersected != null) {
        (intersected.material as MeshLambertMaterial).emissive.setHex(currentHex);
      }

      intersected = intersects[0].object;
      currentHex = (intersected.material as MeshLambertMaterial).emissive.getHex();
      (intersected.material as MeshLambertMaterial).emissive.setHex(0xff0000);
    }
  } else {
    if (intersected != null) {
      (intersected.material as MeshLambertMaterial).emissive.setHex(currentHex);
    }

    intersected = null;
  }

  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
