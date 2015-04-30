import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

LineBasicMaterial material;

num mouseX = 0,
    mouseY = 0,
    windowHalfX = window.innerWidth / 2,
    windowHalfY = window.innerHeight / 2;

Function random = new math.Random().nextDouble;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(33.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 700.0;

  scene = new Scene();

  renderer = new WebGLRenderer(antialias: true)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  var geometry = new Geometry(),
      geometry2 = new Geometry(),
      geometry3 = new Geometry();

  var points = new HilbertGeometry.D3(new Vector3.zero(), 200.0, 1, 0, 1, 2, 3, 4, 5, 6, 7).vertices;

  var colors = [],
      colors2 = [],
      colors3 = [];

  var n_sub = 6;

  var spline = new Spline(points);

  for (var i = 0; i < points.length * n_sub; i++) {
    var index = i / (points.length * n_sub);
    var position = spline.getPoint(index);

    geometry.vertices.add(new Vector3(position.x, position.y, position.z));

    colors.add(new Color(0xffffff)
      ..setHSL(0.6, 1.0, math.max(0, -position.x / 200) + 0.5));

    colors2.add(new Color(0xffffff)
      ..setHSL(0.9, 1.0, math.max(0, -position.y / 200) + 0.5));

    colors3.add(new Color(0xffffff)
      ..setHSL(i / (points.length * n_sub), 1.0, 0.5));
  }

  geometry2.vertices = geometry3.vertices = geometry.vertices;

  geometry.colors = colors;
  geometry2.colors = colors2;
  geometry3.colors = colors3;

  // lines

  material = new LineBasicMaterial(color: 0xffffff, opacity: 1.0, linewidth: 3.0, vertexColors: VertexColors);

  var scale = 0.3,
      d = 225.0;

  var parameters = [
    [material, scale * 1.5, [-d, 0.0, 0.0], geometry],
    [material, scale * 1.5, [0.0, 0.0, 0.0], geometry2],
    [material, scale * 1.5, [d, 0.0, 0.0], geometry3]
  ];

  parameters.forEach((p) {
    scene.add(new Line(p[3], p[0])
      ..scale.splat(p[1])
      ..position.x = p[2][0]
      ..position.y = p[2][1]
      ..position.z = p[2][2]);
  });

  // Events

  document.onMouseMove.listen((event) {
    mouseX = event.client.x - windowHalfX;
    mouseY = event.client.y - windowHalfY;
  });

  document.onTouchStart.listen((event) {
    if (event.touches.length > 1) {
      event.preventDefault();

      mouseX = event.touches[0].page.x - windowHalfX;
      mouseY = event.touches[0].page.y - windowHalfY;
    }
  });

  document.onTouchMove.listen((event) {
    if (event.touches.length == 1) {
      event.preventDefault();

      mouseX = event.touches[0].page.x - windowHalfX;
      mouseY = event.touches[0].page.y - windowHalfY;
    }
  });

  window.onResize.listen((event) {
    windowHalfX = window.innerWidth / 2;
    windowHalfY = window.innerHeight / 2;

    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);
  });

  document.onMouseMove.listen((event) {
    mouseX = event.client.x - windowHalfX;
    mouseY = event.client.y - windowHalfY;
  });

  document.onTouchStart.listen((event) {
    if (event.touches.length > 1) {
      event.preventDefault();

      mouseX = event.touches[0].page.x - windowHalfX;
      mouseY = event.touches[0].page.y - windowHalfY;
    }
  });

  document.onTouchMove.listen((event) {
    if (event.touches.length == 1) {
      event.preventDefault();

      mouseX = event.touches[0].page.x - windowHalfX;
      mouseY = event.touches[0].page.y - windowHalfY;
    }
  });
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  camera.position.x += (mouseX - camera.position.x) * .05;
  camera.position.y += (-mouseY + 200 - camera.position.y) * .05;

  camera.lookAt(scene.position);

  var time = new DateTime.now().millisecondsSinceEpoch * 0.0005;

  for (var i = 0; i < scene.children.length; i++) {
    var object = scene.children[i];

    if (object is Line) {
      object.rotation.y = time * (i % 2 != 0 ? 1 : -1);
    }
  }

  renderer.render(scene, camera);
}
