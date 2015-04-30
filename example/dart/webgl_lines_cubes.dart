import 'dart:html';
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

num mouseX = 0, mouseY = 0,

windowHalfX = window.innerWidth / 2,
windowHalfY = window.innerHeight / 2;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(33.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 700.0;

  scene = new Scene();

  renderer = new WebGLRenderer(antialias: false)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);

  document.body.append(renderer.domElement);

  var geometry = new HilbertGeometry.D3(new Vector3.zero(), 200.0, 4, 0, 1, 2, 3, 4, 5, 6, 7);

  // lines

  var scale = 0.3, d = 125, c1 = 0x553300, c2 = 0x555555, c3 = 0x992800, g1 = geometry;

  var m1 = new LineBasicMaterial(color: c1, opacity: 1.0, blending: AdditiveBlending, transparent: true),
      m2 = new LineBasicMaterial(color: c2, opacity: 1.0, blending: AdditiveBlending, transparent: true),
      m3 = new LineBasicMaterial(color: c3, opacity: 1.0, blending: AdditiveBlending, transparent: true);

  var parameters = [
      [m3, scale * 0.5, [0, 0, 0], g1], [m2, scale * 0.5, [d, 0, 0],  g1], [m2, scale * 0.5, [-d, 0, 0],  g1],
      [m2, scale * 0.5, [0, d, 0], g1], [m2, scale * 0.5, [d, d, 0],  g1], [m2, scale * 0.5, [-d, d, 0],  g1],
      [m2, scale * 0.5, [0,-d, 0], g1], [m2, scale * 0.5, [d, -d, 0], g1], [m2, scale * 0.5, [-d, -d, 0], g1],

      [m1, scale * 0.5, [2 * d, 0, 0],  g1], [m1, scale * 0.5, [-2 * d, 0, 0],  g1],
      [m1, scale * 0.5, [2 * d, d, 0],  g1], [m1, scale * 0.5, [-2 * d, d, 0],  g1],
      [m1, scale * 0.5, [2 * d, -d, 0], g1], [m1, scale * 0.5, [-2 * d, -d, 0], g1]];

  parameters.forEach((p) {
    scene.add(new Line(p[3], p[0])
      ..scale.splat(p[1])
      ..position.x = p[2][0].toDouble()
      ..position.y = p[2][1].toDouble()
      ..position.z = p[2][2].toDouble());
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

  var time = new DateTime.now().millisecondsSinceEpoch * 0.0015;

  for (var i = 0; i < scene.children.length; i++) {
    var object = scene.children[i];
    if (object is Line) {
      object.rotation.y = time * (i % 2 != 0 ? 1 : -1);
    }
  }

  renderer.render(scene, camera);
}