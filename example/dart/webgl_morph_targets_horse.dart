import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/loaders.dart' show JSONLoader;
import 'package:three/extras/animation.dart' show MorphAnimation;

PerspectiveCamera camera;
Vector3 cameraTarget;

Scene scene;
WebGLRenderer renderer;

Mesh mesh;
MorphAnimation animation;

void init() {
  var info = new DivElement()
    ..style.position = 'absolute'
    ..style.top = '10px'
    ..style.width = '100%'
    ..style.textAlign = 'center'
    ..innerHtml =
      '<a href="http://threejs.org" target="_blank">three.js</a> webgl - morph targets - horse. model by <a href="http://mirada.com/">mirada</a> from <a href="http://ro.me">rome</a>';
  document.body.append(info);

  //

  camera = new PerspectiveCamera(
      50.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.y = 300.0;

  cameraTarget = new Vector3(0.0, 150.0, 0.0);

  scene = new Scene();

  //

  var light = new DirectionalLight(0xefefff, 2.0);
  light.position
    ..splat(1.0)
    ..normalize();
  scene.add(light);

  var light2 = new DirectionalLight(0xffefef, 2.0);
  light2.position
    ..splat(-1.0)
    ..normalize();
  scene.add(light2);

  var loader = new JSONLoader(showStatus: true);
  loader.load("models/animated/horse.js").then((geometry) {
    var material = new MeshPhongMaterial(
        color: 0x606060, shading: FlatShading, morphTargets: true);

    mesh = new Mesh(geometry, material)..scale.splat(1.5);

    scene.add(mesh);

    animation = new MorphAnimation(mesh)..play();
  });

  //

  renderer = new WebGLRenderer()
    ..setClearColor(0xf0f0f0)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  //

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

double radius = 600.0;
double theta = 0.0;

int prevTime = new DateTime.now().millisecondsSinceEpoch;

void render() {
  theta += 0.1;

  camera.position.x = radius * math.sin(degToRad(theta));
  camera.position.z = radius * math.cos(degToRad(theta));

  camera.lookAt(cameraTarget);

  if (animation != null) {
    var time = new DateTime.now().millisecondsSinceEpoch;

    animation.update(time - prevTime);

    prevTime = time;
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
