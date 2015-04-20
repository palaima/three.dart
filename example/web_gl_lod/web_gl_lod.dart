import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/controls.dart';

DivElement container;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

FlyControls controls;
Clock clock = new Clock();

Math.Random rnd = new Math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  container = new DivElement();
  document.body.append(container);

  camera = new PerspectiveCamera(
     45.0, window.innerWidth / window.innerHeight, 1.0, 15000.0)
     ..position.z = 1000.0;

  controls = new FlyControls(camera)
    ..movementSpeed = 1000.0
    ..rollSpeed = Math.PI / 10;

  scene = new Scene()
    ..fog = new FogLinear(0x000000, 1.0, 15000.0)
    ..autoUpdate = false;

  scene.add(new PointLight(0xff2200));
  scene.add(new DirectionalLight(0xffffff)
    ..position = new Vector3(0.0, 0.0, 1.0).normalize());

  var geometry = [
    [new IcosahedronGeometry(100.0, 4), 50.0],
    [new IcosahedronGeometry(100.0, 3), 300.0],
    [new IcosahedronGeometry(100.0, 2), 1000.0],
    [new IcosahedronGeometry(100.0, 1), 2000.0],
    [new IcosahedronGeometry(100.0, 0), 8000.0]];

  var material = new MeshLambertMaterial(color: 0xffffff, wireframe: false);

  for (var j = 0; j < 1000; j++) {
    var lod = new LOD();

    for (var i = 0; i < geometry.length; i++) {
      var mesh = new Mesh(geometry[i][0], material)
        ..scale.splat(1.5)
        ..updateMatrix()
        ..matrixAutoUpdate = false;

      lod.addLevel(mesh, geometry[i][1]);
    }

    lod.position.x = 10000 * (0.5 - rnd.nextDouble());
    lod.position.y = 7500 * (0.5 - rnd.nextDouble());
    lod.position.z = 10000 * (0.5 - rnd.nextDouble());
    lod.updateMatrix();
    lod.matrixAutoUpdate = false;
    scene.add(lod);
  }

  renderer = new WebGLRenderer(antialias: true)
    ..setSize(window.innerWidth, window.innerHeight)
    ..sortObjects = false;
  container.append(renderer.domElement);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(Event e) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  controls.update(clock.getDelta());

  scene.updateMatrixWorld();
  scene.traverse((object) {
    if (object is LOD) {
      object.update(camera);
    }
  });

  renderer.render(scene, camera);
}