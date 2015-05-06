import 'dart:math' show Random;
import 'dart:html' show window, document;
import 'package:three/three.dart';
import 'package:three/extras/postprocessing.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;
EffectComposer composer;

Object3D object;

Random rnd = new Random();

void main() {
  init();
  animate(0);
}

void init() {
  var renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  //

  camera = new PerspectiveCamera(70.0, window.innerWidth / window.innerHeight, 1.0, 1000.0)
    ..position.z = 400.0;

  scene = new Scene()
    ..fog = new FogLinear(0x000000, 1.0, 1000.0);

  object = new Object3D();
  scene.add(object);

  var geometry = new SphereGeometry(1.0, 4, 4);
  var material = new MeshPhongMaterial(color: 0xffffff, shading: FlatShading);

  for (var i = 0; i < 100; i ++) {
    var mesh = new Mesh(geometry, material)
      ..position.setValues(rnd.nextDouble() - 0.5, rnd.nextDouble() - 0.5, rnd.nextDouble() - 0.5).normalize()
      ..position.scale(rnd.nextDouble() * 400)
      ..rotation.setValues(rnd.nextDouble() * 2, rnd.nextDouble() * 2, rnd.nextDouble() * 2);
    mesh.scale.x = mesh.scale.y = mesh.scale.z = rnd.nextDouble() * 50;
    object.add(mesh);
  }

  scene.add(new AmbientLight(0x222222));

  scene.add(new DirectionalLight(0xffffff)
    ..position.splat(1.0));

  // postprocessing

  composer = new EffectComposer(renderer);
  composer.addPass(new RenderPass(scene, camera));

  composer.addPass(new ShaderPass(dotScreenShader)
    ..uniforms['scale'].value = 4);

  composer.addPass(new ShaderPass(rgbShiftShader)
    ..uniforms['amount'].value = 0.0015
    ..renderToScreen = true);

  window.onResize.listen((event) {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);
  });
}

void animate(num time) {
  window.requestAnimationFrame(animate);

  object.rotation.x += 0.005;
  object.rotation.y += 0.01;

  composer.render();
}
