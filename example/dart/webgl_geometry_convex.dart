import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as ImageUtils;
import 'package:three/extras/scene_utils.dart' as SceneUtils;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Math.Random rnd = new Math.Random();

void main() {
  init();
  animate(0);
}

init() {
  camera = new PerspectiveCamera(45.0, window.innerWidth / window.innerHeight, 1.0, 2000.0)
    ..position.y = 400.0;

  scene = new Scene();

  var light, object, materials;

  scene.add(new AmbientLight(0x404040));

  light = new DirectionalLight(0xffffff)
    ..position.setValues(0.0, 1.0, 0.0);
  scene.add(light);

  var map = ImageUtils.loadTexture('textures/UV_Grid_Sm.jpg');
  map.wrapS = map.wrapT = RepeatWrapping;
  map.anisotropy = 16;

  materials = [
    new MeshLambertMaterial(map: map),
    new MeshBasicMaterial(color: 0xffffff, wireframe: true, transparent: true, opacity: 0.1)
  ];

  var points;

  // tetrahedron

  points = [
    new Vector3(100.0, 0.0, 0.0),
    new Vector3(0.0, 100.0, 0.0),
    new Vector3(0.0, 0.0, 100.0),
    new Vector3(0.0, 0.0, 0.0)
  ];

  object = SceneUtils.createMultiMaterialObject(new ConvexGeometry(points), materials)
    ..position.setValues(0.0, 0.0, 0.0);
  scene.add(object);

  // cube

  points = [
    new Vector3(50.0, 50.0, 50.0),
    new Vector3(50.0, 50.0, -50.0),
    new Vector3(-50.0, 50.0, -50.0),
    new Vector3(-50.0, 50.0, 50.0),
    new Vector3(50.0, -50.0, 50.0),
    new Vector3(50.0, -50.0, -50.0),
    new Vector3(-50.0, -50.0, -50.0),
    new Vector3(-50.0, -50.0, 50.0),
  ];

  object = SceneUtils.createMultiMaterialObject(new ConvexGeometry(points), materials)
    ..position.setValues(-200.0, 0.0, -200.0);
  scene.add(object);

  // random convex

  points = new List.generate(30, (_) => randomPointInSphere(50));

  object = SceneUtils.createMultiMaterialObject(new ConvexGeometry(points), materials);
  object.position.setValues(-200.0, 0.0, 200.0);
  scene.add(object);


  object = new AxisHelper(50.0);
  object.position.setValues(200.0, 0.0, -200.0);
  scene.add(object);

  object = new ArrowHelper(new Vector3(0.0, 1.0, 0.0), new Vector3(0.0, 0.0, 0.0), 50.0);
  object.position.setValues(200.0, 0.0, 400.0);
  scene.add(object);

  renderer = new WebGLRenderer(antialias: true)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  //

  window.onResize.listen(onWindowResize);
}

void onWindowResize(Event e) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

Vector3 randomPointInSphere(radius) {
  return new Vector3(
    (rnd.nextDouble() - 0.5) * 2 * radius,
    (rnd.nextDouble() - 0.5) * 2 * radius,
    (rnd.nextDouble() - 0.5) * 2 * radius
 );

}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var timer = new DateTime.now().millisecondsSinceEpoch * 0.0001;

  camera.position.x = Math.cos(timer) * 800;
  camera.position.z = Math.sin(timer) * 800;

  camera.lookAt(scene.position);

  scene.children.forEach((object) {
    object.rotation.x = timer * 5;
    object.rotation.y = timer * 2.5;
  });

  renderer.render(scene, camera);
}
