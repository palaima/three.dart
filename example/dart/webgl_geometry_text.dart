import 'dart:html';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert' show JSON;
import 'package:three/three.dart';
import 'package:three/extras/postprocessing.dart';
import 'package:three/extras/shaders.dart' as shaders;
import 'package:three/extras/font_utils.dart' as font_utils;

PerspectiveCamera camera;
Vector3 cameraTarget;
Scene scene;
WebGLRenderer renderer;

EffectComposer composer;
ShaderPass effectFXAA;

Group group;
Mesh textMesh1, textMesh2;
TextGeometry textGeo;

MeshPhongMaterial material;

bool firstLetter = true;

String text = 'three.dart';
int height = 20;
int size = 70;
double hover = 30.0;

int curveSegments = 4;

double bevelThickness = 2.0;
double bevelSize = 1.5;
int bevelSegments = 3;
bool bevelEnabled = true;

String font = 'helvetiker'; // helvetiker, optimer, gentilis, droid sans, droid serif
String weight = 'normal'; // normal bold
String style = 'normal'; // normal italic

bool mirror = true;

double targetRotation = 0.0;
double targetRotationOnMouseDown = 0.0;

double mouseX = 0.0;
double mouseXOnMouseDown = 0.0;

double windowHalfX = window.innerWidth / 2;
double windowHalfY = window.innerHeight / 2;

Map postprocessing = {'enabled': false};

double glow = 0.9;

List<StreamSubscription> mouseSubs;

main() async {
  await loadFace();
  init();
  animate(0);
}

String capitalize(String txt) => txt.substring(0, 1).toUpperCase() + txt.substring(1);

Future loadFace() async {
  var f = font.contains('droid') ? 'droid/${font.split(' ').join('_')}' : font;
  var w = weight == 'normal' ? 'regular' : weight;

  var fontUrl = 'fonts/${f}_$w.typeface.json';
  font_utils.loadFace(JSON.decode(await HttpRequest.getString(fontUrl)));
}

void init() {
  // CAMERA
  camera = new PerspectiveCamera(30.0, window.innerWidth / window.innerHeight, 1.0, 1500.0)
    ..position.setValues(0.0, 400.0, 700.0);

  cameraTarget = new Vector3(0.0, 150.0, 0.0);

  // SCENE

  scene = new Scene()..fog = new FogLinear(0x000000, 250.0, 1400.0);

  // LIGHTS

  var dirLight = new DirectionalLight(0xffffff, 0.125);
  dirLight.position
    ..setValues(0.0, 0.0, 1.0)
    ..normalize();
  scene.add(dirLight);

  var pointLight = new PointLight(0xffffff, intensity: 1.5);
  pointLight.position.setValues(0.0, 100.0, 90.0);
  scene.add(pointLight);

  //text = capitalize( font ) + ' ' + capitalize( weight );
  //text = 'abcdefghijklmnopqrstuvwxyz0123456789';
  //text = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  pointLight.color.setHSL(new math.Random().nextDouble(), 1.0, 0.5);

  material = new MeshPhongMaterial(color: 0xffffff, shading: FlatShading);

  group = new Group()..position.y = 100.0;

  scene.add(group);

  createText();

  var plane = new Mesh(new PlaneBufferGeometry(10000.0, 10000.0),
      new MeshBasicMaterial(color: 0xffffff, opacity: 0.5, transparent: true))
    ..position.y = 100.0
    ..rotation.x = -math.PI / 2;
  scene.add(plane);

  // RENDERER

  renderer = new WebGLRenderer(antialias: true)
    ..setClearColor(scene.fog.color)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  document
    ..onMouseDown.listen(onDocumentMouseDown)
    ..onKeyPress.listen(onDocumentKeyPress)
    ..onKeyDown.listen(onDocumentKeyDown)
    ..onTouchStart.listen(onDocumentTouchStart)
    ..onTouchMove.listen(onDocumentTouchMove);

  querySelector('#color').onClick
      .listen((_) => pointLight.color.setHSL(new math.Random().nextDouble(), 1.0, 0.5));

  querySelector('#font').onClick.listen((_) async {
    if (font == 'helvetiker') {
      font = 'optimer';
    } else if (font == 'optimer') {
      font = 'gentilis';
    } else if (font == 'gentilis') {
      font = 'droid sans';
    } else if (font == 'droid sans') {
      font = 'droid serif';
    } else {
      font = 'helvetiker';
    }

    await loadFace();
    refreshText();
  });

  querySelector('#weight').onClick.listen((_) async {
    if (weight == 'bold') {
      weight = 'normal';
    } else {
      weight = 'bold';
    }

    await loadFace();
    refreshText();
  });

  querySelector('#bevel').onClick.listen((_) {
    bevelEnabled = !bevelEnabled;
    refreshText();
  });

  querySelector('#postprocessing').onClick.listen((_) =>
      postprocessing['enabled'] = !postprocessing['enabled']);

  // POSTPROCESSING

  renderer.autoClear = false;

  var renderModel = new RenderPass(scene, camera);
  var effectBloom = new BloomPass(strength: 0.25);
  var effectFilm = new FilmPass(0.5, 0.125, 2048.0, false);

  effectFXAA = new ShaderPass(shaders.fxaa);

  effectFXAA.uniforms['resolution'].value.setValues(1 / window.innerWidth, 1 / window.innerHeight);

  effectFilm.renderToScreen = true;

  composer = new EffectComposer(renderer);

  composer.addPass(renderModel);
  composer.addPass(effectFXAA);
  composer.addPass(effectBloom);
  composer.addPass(effectFilm);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  windowHalfX = window.innerWidth / 2;
  windowHalfY = window.innerHeight / 2;

  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void onDocumentMouseDown(MouseEvent event) {
  event.preventDefault();

  mouseSubs = [
    document.onMouseMove.listen(onDocumentMouseMove),
    document.onMouseUp.listen(onDocumentMouseUp),
    document.onMouseOut.listen(onDocumentMouseOut)
  ];

  mouseXOnMouseDown = event.client.x - windowHalfX;
  targetRotationOnMouseDown = targetRotation;
}

void onDocumentKeyPress(KeyEvent event) {
  var keyCode = event.keyCode;

  if (keyCode == KeyCode.BACKSPACE) {
    event.preventDefault();
  } else {
    text += new String.fromCharCode(keyCode);
    refreshText();
  }
}

void onDocumentKeyDown(KeyEvent event) {
  if (firstLetter) {
    firstLetter = false;
    text = '';
  }

  if (event.keyCode == KeyCode.BACKSPACE) {
    event.preventDefault();

    text = text.substring(0, text.length - 1);
    refreshText();
    return;
  }
}

void onDocumentTouchStart(TouchEvent event) {
  if (event.touches.length == 1) {
    event.preventDefault();

    mouseXOnMouseDown = event.touches[0].page.x - windowHalfX;
    targetRotationOnMouseDown = targetRotation;
  }
}

void onDocumentTouchMove(TouchEvent event) {
  if (event.touches.length == 1) {
    event.preventDefault();

    mouseX = event.touches[0].page.x - windowHalfX;
    targetRotation = targetRotationOnMouseDown + (mouseX - mouseXOnMouseDown) * 0.05;
  }
}

void onDocumentMouseMove(MouseEvent event) {
  mouseX = event.client.x - windowHalfX;
  targetRotation = targetRotationOnMouseDown + (mouseX - mouseXOnMouseDown) * 0.02;
}

void onDocumentMouseUp(_) {
  mouseSubs.forEach((s) => s.cancel());
}

void onDocumentMouseOut(_) {
  mouseSubs.forEach((s) => s.cancel());
}

void createText() {
  textGeo = new TextGeometry(text,
      size: size,
      height: height,
      curveSegments: curveSegments,
      font: font,
      weight: weight,
      style: style,
      bevelThickness: bevelThickness,
      bevelSize: bevelSize,
      bevelEnabled: bevelEnabled)
    ..computeBoundingBox()
    ..computeVertexNormals();

  var centerOffset = -0.5 * (textGeo.boundingBox.max.x - textGeo.boundingBox.min.x);

  textMesh1 = new Mesh(textGeo, material)
    ..position.x = centerOffset
    ..position.y = hover
    ..position.z = 0.0

    ..rotation.x = 0.0
    ..rotation.y = math.PI * 2;

  group.add(textMesh1);

  if (mirror) {
    textMesh2 = new Mesh(textGeo, material)
      ..position.x = centerOffset
      ..position.y = -hover
      ..position.z = height.toDouble()

      ..rotation.x = math.PI
      ..rotation.y = math.PI * 2;

    group.add(textMesh2);
  }
}

void refreshText() {
  group.remove(textMesh1);
  if (mirror) group.remove(textMesh2);

  if (text == null) return;

  createText();
}

void animate(num time) {
  window.animationFrame.then(animate);
  render();
}

void render() {
  group.rotation.y += (targetRotation - group.rotation.y) * 0.05;

  camera.lookAt(cameraTarget);

  renderer.clear();

  if (postprocessing['enabled']) {
    composer.render(0.05);
  } else {
    renderer.render(scene, camera);
  }
}
