import 'dart:html';
import 'dart:math' as math;
import 'package:three/extras/helpers.dart';
import 'package:three/three.dart';
import 'package:three/extras/loaders.dart' show JSONLoader;

Scene scene;
WebGLRenderer renderer;
PerspectiveCamera camera;
PointLight light;

void init() {
  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  camera = new PerspectiveCamera(70.0, window.innerWidth / window.innerHeight, 1.0, 1000.0)
    ..position.z = 400.0;

  scene = new Scene();

  light = new PointLight(0xffffff)
    ..position.setValues(200.0, 100.0, 150.0);
  scene.add(light);

  scene.add(new PointLightHelper(light, 5.0));

  scene.add(new GridHelper(200.0, 10.0)
    ..setColors(0x0000ff, 0x808080)
    ..position.y = -150.0);

  var loader = new JSONLoader();
  loader.load('obj/leeperrysmith/LeePerrySmith.js').then((geometry) {
    var material = new MeshLambertMaterial();

    var group = new Group()..scale.scale(50.0);
    scene.add(group);

    var mesh = new Mesh(geometry, material);
    group.add(mesh);

    group.add(new FaceNormalsHelper(mesh, size: 0.1));
    group.add(new VertexNormalsHelper(mesh, size: 0.1));

    group.add(new BoxHelper(mesh));

    var wireframe = new WireframeGeometry(geometry);
    group.add(new LineSegments(wireframe)
      ..material.depthTest = false
      ..material.opacity = 0.25
      ..material.transparent = true
      ..position.x = 4.0);

    var edges = new EdgesGeometry(geometry);
    group.add(new LineSegments(edges)
      ..material.depthTest = false
      ..material.opacity = 0.25
      ..material.transparent = true
      ..position.x = -4.0);
  });

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void render() {
  var time = -window.performance.now() * 0.0003;

  camera.position.x = 400 * math.cos(time);
  camera.position.z = 400 * math.sin(time);
  camera.lookAt(scene.position);

  light.position.x = math.sin(time * 1.7) * 300;
  light.position.y = math.cos(time * 1.5) * 400;
  light.position.z = math.cos(time * 1.3) * 300;

  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
