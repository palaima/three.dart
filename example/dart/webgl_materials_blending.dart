import 'dart:html';
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;

WebGLRenderer renderer;
PerspectiveCamera camera;
Scene scene;

Texture mapBg;

void init() {
  camera = new PerspectiveCamera(70.0, window.innerWidth / window.innerHeight, 1.0, 1000.0)
    ..position.z = 600.0;

  scene = new Scene();

  // BACKGROUND

  var x = new CanvasElement()
    ..width = 128
    ..height = 128;

  x.context2D
    ..fillStyle = "#ddd"
    ..fillRect(0, 0, 128, 128)
    ..fillStyle = "#555"
    ..fillRect(0, 0, 64, 64)
    ..fillStyle = "#999"
    ..fillRect(32, 32, 32, 32)
    ..fillStyle = "#555"
    ..fillRect(64, 64, 64, 64)
    ..fillStyle = "#777"
    ..fillRect(96, 96, 32, 32);

  mapBg = new Texture(x);
  mapBg.wrapS = mapBg.wrapT = RepeatWrapping;
  mapBg.repeat.setValues(128.0, 64.0);
  mapBg.needsUpdate = true;

  var materialBg = new MeshBasicMaterial(map: mapBg);

  var meshBg = new Mesh(new PlaneBufferGeometry(4000.0, 2000.0), materialBg);
  meshBg.position = new Vector3(0.0, 0.0, -1.0);
  scene.add(meshBg);

  // OBJECTS

  var blendings = [NoBlending, NormalBlending, AdditiveBlending, SubtractiveBlending, MultiplyBlending];

  var blendingNames = ["No", "Normal", "Additive", "Subtractive", "Multiply"];

  var map0 = image_utils.loadTexture('textures/UV_Grid_Sm.jpg');
  var map1 = image_utils.loadTexture('textures/sprite0.jpg');
  var map2 = image_utils.loadTexture('textures/sprite0.png');
  var map3 = image_utils.loadTexture('textures/lensflare/lensflare0.png');
  var map4 = image_utils.loadTexture('textures/lensflare/lensflare0_alpha.png');

  var geo1 = new PlaneBufferGeometry(100.0, 100.0);
  var geo2 = new PlaneBufferGeometry(100.0, 25.0);

  void addImageRow(map, y) {
    for (var i = 0; i < blendings.length; i++) {
      var material = new MeshBasicMaterial(map: map)
        ..transparent = true
        ..blending = blendings[i];

      var x = (i - blendings.length / 2) * 110;
      var z = 0.0;

      scene.add(new Mesh(geo1, material)
        ..position.setValues(x, y, z));

      scene.add(new Mesh(geo2, generateLabelMaterial(blendingNames[i]))
        ..position.setValues(x, y - 75, z));
    }
  }

  addImageRow(map0, 300.0);
  addImageRow(map1, 150.0);
  addImageRow(map2, 0.0);
  addImageRow(map3, -150.0);
  addImageRow(map4, -300.0);

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);

  document.body.append(renderer.domElement);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

MeshBasicMaterial generateLabelMaterial(String text) {
  var x = new CanvasElement()
    ..width = 128
    ..height = 32;

  x.context2D
    ..fillStyle = "rgba(0, 0, 0, 0.95)"
    ..fillRect(0, 0, 128, 32)
    ..fillStyle = "white"
    ..font = "12pt arial bold"
    ..fillText(text, 10, 22);

  var map = new Texture(x)..needsUpdate = true;

  return new MeshBasicMaterial(map: map, transparent: true);
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.00025;

  var ox = (time * -0.01 * mapBg.repeat.x) % 1;
  var oy = (time * -0.01 * mapBg.repeat.y) % 1;

  mapBg.offset.setValues(ox, oy);

  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
