import 'dart:html';
import 'dart:typed_data' show Uint8List;
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/controls.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

TrackballControls controls;

List pickingData = [];
WebGLRenderTarget pickingTexture;
Scene pickingScene;
Mesh highlightBox;

Vector2 mouse = new Vector2.zero();
Vector3 offset = new Vector3(10.0, 10.0, 10.0);

void init() {
  camera = new PerspectiveCamera(70.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 1000.0;

  controls = new TrackballControls(camera)
    ..rotateSpeed = 1.0
    ..zoomSpeed = 1.2
    ..panSpeed = 0.8
    ..noZoom = false
    ..noPan = false
    ..staticMoving = true
    ..dynamicDampingFactor = 0.3;

  scene = new Scene();

  pickingScene = new Scene();
  pickingTexture = new WebGLRenderTarget(window.innerWidth, window.innerHeight)
    ..minFilter = LinearFilter
    ..generateMipmaps = false;

  scene.add(new AmbientLight(0x555555));

  scene.add(new SpotLight(0xffffff, intensity: 1.5)
    ..position.setValues(0.0, 500.0, 2000.0));

  var geometry = new Geometry(),
      pickingGeometry = new Geometry();

  var pickingMaterial = new MeshBasicMaterial(vertexColors: VertexColors);
  var defaultMaterial =
    new MeshLambertMaterial(color: 0xffffff, shading: FlatShading, vertexColors: VertexColors);

  applyVertexColors(Geometry g, Color c) {
    g.faces.forEach((f) {
      for (var j = 0; j < 3; j++) {
        f.vertexColors.add(c);
      }
    });
  }

  var geom = new BoxGeometry(1.0, 1.0, 1.0);
  var color = new Color.white();

  var matrix = new Matrix4.identity();
  var quaternion = new Quaternion.identity();

  var random = new math.Random().nextDouble;

  // TODO investigate why this is taking up an obscene amount of ram...
  for (var i = 0; i < 500; i++) {
    var position = new Vector3.zero()
      ..x = random() * 10000 - 5000
      ..y = random() * 6000 - 3000
      ..z = random() * 8000 - 4000;

    var rotation = new Euler()
      ..x = random() * 2 * math.PI
      ..y = random() * 2 * math.PI
      ..z = random() * 2 * math.PI;

    var scale = new Vector3.zero()
      ..x = random() * 200 + 100
      ..y = random() * 200 + 100
      ..z = random() * 200 + 100;

    quaternion.setFromEuler(rotation, update: false);
    matrix.setFromTranslationRotationScale(position, quaternion, scale);

    // give the geom's vertices a random color, to be displayed

    applyVertexColors(geom, color.setHex(random() * 0xffffff));

    geometry.merge(geom, matrix: matrix);

    // give the geom's vertices a color corresponding to the "id"

    applyVertexColors(geom, color.setHex(i));

    pickingGeometry.merge(geom, matrix: matrix);

    pickingData.add({'position': position, 'rotation': rotation, 'scale': scale});
  }

  var drawnObject = new Mesh(geometry, defaultMaterial);
  scene.add(drawnObject);

  pickingScene.add(new Mesh(pickingGeometry, pickingMaterial));

  highlightBox = new Mesh(new BoxGeometry(1.0, 1.0, 1.0), new MeshLambertMaterial(color: 0xffff00));
  scene.add(highlightBox);

  renderer = new WebGLRenderer(antialias: true)
    ..setClearColor(0xffffff)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..sortObjects = false;
  document.body.append(renderer.domElement);

  document.onMouseMove.listen((e) {
    mouse.x = e.client.x.toDouble();
    mouse.y = e.client.y.toDouble();
  });
}

//create buffer for reading single pixel
Uint8List pixelBuffer = new Uint8List(4);

void pick() {
  //render the picking scene off-screen

  renderer.render(pickingScene, camera, renderTarget: pickingTexture);

  //read the pixel under the mouse from the texture
  renderer.readRenderTargetPixels(
      pickingTexture, mouse.x.toInt(), (pickingTexture.height - mouse.y).toInt(), 1, 1, pixelBuffer);

  //interpret the pixel as an ID
  var id = (pixelBuffer[0] << 16) | (pixelBuffer[1] << 8) | (pixelBuffer[2]);

  if (id < pickingData.length) {
    //move our highlightBox so that it surrounds the picked object
    var data = pickingData[id];
    if (data['position'] != null && data['rotation'] != null && data['scale'] != null) {
      highlightBox.position.setFrom(data['position']);
      highlightBox.rotation.setFrom(data['rotation']);
      highlightBox.scale.setFrom(data['scale']).add(offset);
      highlightBox.visible = true;
    }
  } else {
    highlightBox.visible = false;
  }
}

void render() {
  controls.update();
  pick();
  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
