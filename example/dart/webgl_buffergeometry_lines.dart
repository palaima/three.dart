import 'dart:html';
import 'dart:typed_data';
import 'dart:math' show Random;
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Line mesh;

Random rnd = new Random();

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(27.0, window.innerWidth / window.innerHeight, 1.0, 4000.0)
    ..position.z = 2750.0;

  scene = new Scene();


  var segments = 10000;

  var geometry = new BufferGeometry();
  var material = new LineBasicMaterial(vertexColors: VertexColors);

  var positions = new Float32List(segments * 3);
  var colors = new Float32List(segments * 3);

  var r = 800;

  for (var i = 0; i < segments; i ++) {
    var x = rnd.nextDouble() * r - r / 2;
    var y = rnd.nextDouble() * r - r / 2;
    var z = rnd.nextDouble() * r - r / 2;

    // positions

    positions[i * 3] = x;
    positions[i * 3 + 1] = y;
    positions[i * 3 + 2] = z;

    // colors

    colors[i * 3] = (x / r) + 0.5;
    colors[i * 3 + 1] = (y / r) + 0.5;
    colors[i * 3 + 2] = (z / r) + 0.5;
  }

  geometry.addAttribute('position', new BufferAttribute(positions, 3));
  geometry.addAttribute('color', new BufferAttribute(colors, 3));

  geometry.computeBoundingSphere();

  mesh = new Line(geometry, material);
  scene.add(mesh);

  //

  renderer = new WebGLRenderer(antialias: false)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)

    ..gammaInput = true
    ..gammaOutput = true;

  document.body.append(renderer.domElement);

  window.onResize.listen((event) {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);
  });
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.001;

  mesh.rotation.x = time * 0.25;
  mesh.rotation.y = time * 0.5;

  renderer.render(scene, camera);
}
