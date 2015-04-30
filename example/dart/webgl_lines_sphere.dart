import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

num mouseX = 0, mouseY = 0,

windowHalfX = window.innerWidth / 2,
windowHalfY = window.innerHeight / 2;

double r = 450.0;

Function random = new math.Random().nextDouble;

Map originalScale = {};

void main() {
  init();
  animate(0);
}

createGeometry() {
  var geometry = new Geometry();

  for (var i = 0; i < 1500; i++) {
    var vertex1 = new Vector3.zero()
      ..x = random() * 2 - 1
      ..y = random() * 2 - 1
      ..z = random() * 2 - 1
      ..normalize()
      ..scale(r);

    var vertex2 = vertex1.clone()
      ..scale(random() * 0.09 + 1);

    geometry.vertices.add(vertex1);
    geometry.vertices.add(vertex2);
  }

  return geometry;
}

void init() {
  camera = new PerspectiveCamera(80.0, window.innerWidth / window.innerHeight, 1.0, 3000.0)
    ..position.z = 1000.0;

  scene = new Scene();

  var parameters = [
    [0.25, 0xff7700, 1, 2], [0.5, 0xff9900, 1, 1], [0.75, 0xffaa00, 0.75, 1], [1, 0xffaa00, 0.5, 1], [1.25, 0x000833, 0.8, 1],
    [3.0, 0xaaaaaa, 0.75, 2], [3.5, 0xffffff, 0.5, 1], [4.5, 0xffffff, 0.25, 1], [5.5, 0xffffff, 0.125, 1]];

  var geometry = createGeometry();

  parameters.forEach((p) {
    var material = new LineBasicMaterial(color: p[1], opacity: p[2].toDouble(), linewidth: p[3].toDouble());

    var line = new Line(geometry, material, LinePieces)
      ..scale.splat(p[0].toDouble())
      ..rotation.y = random() * math.PI
      ..updateMatrix();
    scene.add(line);

    originalScale[line.id] = p[0]; // TODO use expando instead?
  });

  renderer = new WebGLRenderer(antialias: true)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

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
  camera.position.y += (-mouseY + 200 - camera.position.y) * .05;
  camera.lookAt(scene.position);

  renderer.render(scene, camera);

  var time = new DateTime.now().millisecondsSinceEpoch * 0.0001;

  for (var i = 0; i < scene.children.length; i ++) {
    var object = scene.children[i];

    if (object is Line) {
      object.rotation.y = time * (i < 4 ? (i + 1) : -(i + 1));

      if (i < 5) {
        object.scale.splat(originalScale[object.id] * (i / 5 + 1) * (1 + 0.5 * math.sin(7 * time)));
      }
    }
  }
}
