import 'dart:html';
import 'package:three/three.dart';

WebGLRenderer renderer;
Scene scene;
PerspectiveCamera camera;

List<Line> objects = [];

void init() {
  camera = new PerspectiveCamera(60.0, window.innerWidth / window.innerHeight, 1.0, 200.0)
    ..position.z = 150.0;

  scene = new Scene();

  scene.fog = new FogLinear(0x111111, 150.0, 200.0);

  var subdivisions = 6;
  var recursion = 1;

  var hilbertGeo = new HilbertGeometry.D3(new Vector3.zero(), 25.0, recursion, 0, 1, 2, 3, 4, 5, 6, 7);

  var points = hilbertGeo.vertices;

  var spline = new Spline(points);
  var geometrySpline = new Geometry();

  for (var i = 0; i < points.length * subdivisions; i++) {
    var index = i / (points.length * subdivisions);
    var position = spline.getPoint(index);

    geometrySpline.vertices.add(position.clone());
  }

  var geometryCube = cube(50.0);

  geometryCube.computeLineDistances();
  geometrySpline.computeLineDistances();

  var object = new LineSegments(
      geometrySpline, new LineDashedMaterial(color: 0xffffff, dashSize: 1.0, gapSize: 0.5));

  objects.add(object);
  scene.add(object);

  var object2 = new LineSegments(geometryCube,
      new LineDashedMaterial(color: 0xffaa00, dashSize: 3.0, gapSize: 1.0, linewidth: 2.0));

  objects.add(object2);
  scene.add(object2);

  renderer = new WebGLRenderer(antialias: true)
    ..setClearColor(0x111111)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);

  document.body.append(renderer.domElement);

  //

  window.onResize.listen(onWindowResize);
}

Geometry cube(double size) {
  var h = size * 0.5;

  var geometry = new Geometry();

  geometry.vertices.addAll([new Vector3(-h, -h, -h), new Vector3(-h, h, -h), new Vector3(-h, h, -h),
      new Vector3(h, h, -h), new Vector3(h, h, -h), new Vector3(h, -h, -h), new Vector3(h, -h, -h),
      new Vector3(-h, -h, -h), new Vector3(-h, -h, h), new Vector3(-h, h, h), new Vector3(-h, h, h),
      new Vector3(h, h, h), new Vector3(h, h, h), new Vector3(h, -h, h), new Vector3(h, -h, h),
      new Vector3(-h, -h, h), new Vector3(-h, -h, -h), new Vector3(-h, -h, h),
      new Vector3(-h, h, -h), new Vector3(-h, h, h), new Vector3(h, h, -h), new Vector3(h, h, h),
      new Vector3(h, -h, -h), new Vector3(h, -h, h)]);

  return geometry;
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void animate(num time) {
  window.requestAnimationFrame(animate);

  render();
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.001;

  for (var i = 0; i < objects.length; i++) {
    var object = objects[i];

    //object.rotation.x = 0.25 * time * ( i%2 == 1 ? 1 : -1);
    object.rotation.x = 0.25 * time;
    object.rotation.y = 0.25 * time;
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
