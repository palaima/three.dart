import 'dart:math' show Random;
import 'dart:html';
import 'package:three/three.dart';
import 'package:three/extras/shaders.dart' as Shaders;
import 'package:three/extras/postprocessing.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;
EffectComposer composer;

Object3D object;
GlitchPass glitchPass;

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

  var geometry = new SphereGeometry(1.0, 4, 4 );

  var rnd = new Random().nextDouble;

  for (var i = 0; i < 100; i++) {
    var material = new MeshPhongMaterial(color: 0xffffff * rnd(), shading: FlatShading);

    var mesh = new Mesh(geometry, material)
      ..position.setValues(rnd() - 0.5, rnd() - 0.5, rnd() - 0.5).normalize()
      ..position.scale(rnd() * 400 )
      ..rotation.setValues(rnd() * 2, rnd() * 2, rnd() * 2);

    mesh.scale.x = mesh.scale.y = mesh.scale.z = rnd() * 50;
    object.add(mesh);
  }

  scene.add(new AmbientLight(0x222222));

  scene.add(new DirectionalLight(0xffffff)
    ..position.splat(1.0));

  // postprocessing

  composer = new EffectComposer(renderer);
  composer.addPass(new RenderPass(scene, camera));

  glitchPass = new GlitchPass()
    ..renderToScreen = true;
  composer.addPass(glitchPass);

  querySelector('#wildGlitch').onClick.listen((e) =>
      glitchPass.goWild = (e.target as InputElement).checked);

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
