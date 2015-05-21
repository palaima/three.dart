import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

int mouseX = 0,
    mouseY = 0;

Mesh mesh;
int windowHalfX = window.innerWidth ~/ 2;
int windowHalfY = window.innerHeight ~/ 2;

void init() {
  var inputs = querySelectorAll("input[type='range']");

  for (var i = 0; i < inputs.length; i++) {
    inputs[i].onChange.listen(
        (_) => mesh.morphTargetInfluences[i] = inputs[i].valueAsNumber / 100);
  }

  camera = new PerspectiveCamera(
      45.0, window.innerWidth / window.innerHeight, 1.0, 15000.0)
    ..position.z = 500.0;

  scene = new Scene()..fog = new FogLinear(0x000000, 1.0, 15000.0);

  scene.add(new PointLight(0xff2200)..position.splat(100.0));

  scene.add(new AmbientLight(0x111111));

  var geometry = new BoxGeometry(100.0, 100.0, 100.0);
  var material = new MeshPhongMaterial(
      color: 0xffffff, shading: FlatShading, morphTargets: true);

  // construct 8 blend shapes

  for (var i = 0; i < geometry.vertices.length; i++) {
    var vertices = [];

    for (var v = 0; v < geometry.vertices.length; v++) {
      vertices.add(geometry.vertices[v].clone());

      if (v == i) {
        vertices.last.scale(2.0);
      }
    }

    geometry.morphTargets
        .add(new MorphTarget(name: "target$i", vertices: vertices));
  }

  mesh = new Mesh(geometry, material);

  scene.add(mesh);

  //

  renderer = new WebGLRenderer()
    ..setClearColor(0x222222)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..sortObjects = false;
  document.body.append(renderer.domElement);

  //

  document.onMouseMove.listen(onDocumentMouseMove);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  windowHalfX = window.innerWidth ~/ 2;
  windowHalfY = window.innerHeight ~/ 2;

  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void onDocumentMouseMove(MouseEvent event) {
  mouseX = (event.client.x - windowHalfX);
  mouseY = (event.client.y - windowHalfY) * 2;
}

void render() {
  mesh.rotation.y += 0.01;

//  mesh.morphTargetInfluences[0] = math.sin(mesh.rotation.y) * 0.5 + 0.5;

//  camera.position.x += (mouseX - camera.position.x) * .005;
  camera.position.y += (-mouseY - camera.position.y) * .01;

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
