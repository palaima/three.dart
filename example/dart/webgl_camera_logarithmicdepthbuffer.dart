import 'dart:html';
import 'dart:convert' show JSON;
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/font_utils.dart' as font_utils;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Mesh mesh;

double near = 1e-6, far = 1e27;

double screensplit = .25, screensplit_right = 0.0;
List<double> mouse = [.5, .5];
double zoompos = -100.0, minzoomspeed = .015;
double zoomspeed = minzoomspeed;

DivElement container;
Map objsNormal;
Map objsLogzbuf;

Element border;

// Generate a number of text labels, from 1µm in size up to 100,000,000 light years
// Try to use some descriptive real-world examples of objects at each scale

var labeldata = [
//  {'size': .01,           'scale': .0001, 'label': "microscopic (1µm)"},
//  {'size': .01,           'scale': 0.1,  'label': "minuscule (1mm)"},
//  {'size': .01,           'scale': 1.0,  'label': "tiny (1cm)"},
  {'size': 1,             'scale': 1.0,  'label': "child-sized (1m)"},
  {'size': 10,            'scale': 1.0,  'label': "tree-sized (10m)"},
  {'size': 100,           'scale': 1.0,  'label': "building-sized (100m)"},
  {'size': 1000,          'scale': 1.0,  'label': "medium (1km)"},
  {'size': 10000,         'scale': 1.0,  'label': "city-sized (10km)"},
  {'size': 3400000,       'scale': 1.0,  'label': "moon-sized (3,400 Km)"},
  {'size': 12000000,      'scale': 1.0,  'label': "planet-sized (12,000 km)"},
  {'size': 1400000000,    'scale': 1.0,  'label': "sun-sized (1,400,000 km)"},
  {'size': 7.47e12,       'scale': 1.0,  'label': "solar system-sized (50Au)"},
  {'size': 9.4605284e15,  'scale': 1.0,  'label': "gargantuan (1 light year)"},
  {'size': 3.08567758e16, 'scale': 1.0,  'label': "ludicrous (1 parsec)"},
  {'size': 1e19,          'scale': 1.0,  'label': "mind boggling (1000 light years)"},
  {'size': 1.135e21,      'scale': 1.0,  'label': "galaxy-sized (120,000 light years)"},
  {'size': 9.46e23,       'scale': 1.0,  'label': "... (100,000,000 light years)"}
];

main() async {
  font_utils.loadFace(JSON.decode(await HttpRequest.getString('fonts/helvetiker_regular.typeface.json')));
  init();
  animate(0);
}

void init() {
  container = querySelector('#container');

  // Initialize two copies of the same scene, one with normal z-buffer and one with logarithmic z-buffer
  objsNormal = initScene('normal', false);
  objsLogzbuf = initScene('logzbuf', true);

  // Resize border allows the user to easily compare effects of logarithmic depth buffer over the whole scene
  border = querySelector('#renderer_border');
  border.onMouseDown.listen(onBorderMouseDown);

  window.onResize.listen((_) => updateRendererSizes());
  window.onMouseWheel.listen(onMouseWheel);
  window.onMouseMove.listen(onMouseMove);

  render();
}

var mouseMoveSub;
var mouseUpSub;

void onBorderMouseDown(MouseEvent ev) {
  // activate draggable window resizing bar
  mouseMoveSub = window.onMouseMove.listen(onBorderMouseMove);
  mouseUpSub = window.onMouseUp.listen(onBorderMouseUp);
  ev.stopPropagation();
  ev.preventDefault();
}

void onBorderMouseMove(MouseEvent ev) {
  screensplit = math.max(0, math.min(1, ev.client.x / window.innerWidth));
  ev.stopPropagation();
}

void onBorderMouseUp(MouseEvent ev) {
  mouseMoveSub.cancel();
  mouseUpSub.cancel();
}

void onMouseMove(MouseEvent ev) {
  mouse[0] = ev.client.x / window.innerWidth;
  mouse[1] = ev.client.y / window.innerHeight;
}

void onMouseWheel(WheelEvent ev) {
  var amount = -ev.wheelDeltaY;
  if (amount == 0) amount = ev.detail;
  var dir = amount / amount.abs();
  zoomspeed = dir / 10;

  // Slow down default zoom speed after user starts zooming, to give them more control
  minzoomspeed = 0.001;
}

Map initScene(String name, bool logDepthBuf) {
  var scene = new Scene();
  var framecontainer = querySelector('#container_$name');

  var camera = new PerspectiveCamera(50.0, screensplit * window.innerHeight / window.innerHeight, near, far);
  scene.add(camera);

  scene.add(new DirectionalLight(0xffffff, 1.0)
    ..position.splat(100.0));

  var coloroffset = 0;
  var colorskip = new Set.from([Colors.black, Colors.antiqueWhite, Colors.bisque, Colors.beige, Colors.blanchedAlmond, Colors.darkBlue, Colors.darkCyan]);

  // Exclude dark colors, because it looks bad.
  var colors = Colors.toList().toSet().difference(colorskip).toList();

  for (var i = 0; i < labeldata.length; i++) {
    var scale = labeldata[i]['scale'];

    var labelgeo = new TextGeometry(labeldata[i]['label'],
      size: labeldata[i]['size'].toInt(),
      height: labeldata[i]['size'] ~/ 2,
      font: 'helvetiker')
      ..computeBoundingSphere();

    // center text
    var geomtransform = new Matrix4.translationValues(-labelgeo.boundingSphere.radius, 0.0, 0.0);
    labelgeo.applyMatrix(geomtransform);

    var color = colors[coloroffset++];

    var material = new MeshPhongMaterial(color: color, specular: 0xffaa00, shininess: 50.0, shading: SmoothShading, emissive: 0x000000);

    var textmesh = new Mesh(labelgeo, material)
      ..scale.setValues(scale, scale, scale)
      ..position.z = -labeldata[i]['size'] * scale
      ..position.y = labeldata[i]['size'] / 4 * scale
      ..updateMatrix();

    var dotmesh = new Mesh(new SphereGeometry(labeldata[i]['size'] * scale / 2, 24, 12), material)
      ..position.y = -labeldata[i]['size'] / 4 * scale
      ..updateMatrix();

    var merged = new Geometry()
      ..merge(textmesh.geometry, matrix: textmesh.matrix)
      ..merge(dotmesh.geometry, matrix: dotmesh.matrix);

    var mesh = new Mesh(merged, material)
      ..position.z = -labeldata[i]['size'] * 1 * scale;

    scene.add(mesh);
  }

  var renderer = new WebGLRenderer(antialias: true, logarithmicDepthBuffer: logDepthBuf)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth ~/ 2, window.innerHeight)
    ..domElement.style.position = "relative"
    ..domElement.id = 'renderer_$name';
  framecontainer.append(renderer.domElement);

  return {'container': framecontainer, 'renderer': renderer, 'scene': scene, 'camera': camera};
}

// Recalculate size for both renderers when screen size or split location changes
void updateRendererSizes() {
  var screenWidth = window.innerWidth.toDouble();
  var screenHeight = window.innerHeight.toDouble();

  screensplit_right = 1 - screensplit;

  var width = (screensplit * screenWidth).toInt();
  objsNormal['renderer'].setSize(width, screenHeight.toInt());
  objsNormal['camera'].aspect = screensplit * screenWidth / screenHeight;
  objsNormal['camera'].updateProjectionMatrix();
  objsNormal['camera'].setViewOffset(screenWidth, screenHeight, 0.0, 0.0, screenWidth * screensplit, screenHeight);
  objsNormal['container'].style.width = '${(screensplit * 100)}%';

  width = (screensplit_right * screenWidth).toInt();
  objsLogzbuf['renderer'].setSize(width, screenHeight.toInt());
  objsLogzbuf['camera'].aspect = screensplit_right * screenWidth / screenHeight;
  objsLogzbuf['camera'].updateProjectionMatrix();
  objsLogzbuf['camera'].setViewOffset(screenWidth, screenHeight, screenWidth * screensplit, 0.0, screenWidth * screensplit_right, screenHeight);
  objsLogzbuf['container'].style.width = '${(screensplit_right * 100)}%';

  border.style.left = '${(screensplit * 100)}%';
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  // Put some limits on zooming
  var minzoom = labeldata[0]['size'] * labeldata[0]['scale'] * 1;
  var maxzoom = labeldata[labeldata.length - 1]['size'] * labeldata[labeldata.length-1]['scale'] * 100;
  var damping = (zoomspeed.abs() > minzoomspeed ? .95 : 1.0);

  // Zoom out faster the further out you go
  var zoom = math.pow(math.E, zoompos).clamp(minzoom, maxzoom);
  zoompos = math.log(zoom);

  // Slow down quickly at the zoom limits
  if ((zoom == minzoom && zoomspeed < 0) || (zoom == maxzoom && zoomspeed > 0)) {
    damping = .85;
  }

  zoompos += zoomspeed;
  zoomspeed *= damping;

  objsNormal['camera'].position.x = math.sin(.5 * math.PI * (mouse[0] - .5)) * zoom;
  objsNormal['camera'].position.y = math.sin(.25 * math.PI * (mouse[1] - .5)) * zoom;
  objsNormal['camera'].position.z = math.cos(.5 * math.PI * (mouse[0] - .5)) * zoom;
  objsNormal['camera'].lookAt(objsNormal['scene'].position);

  // Clone camera settings across both scenes
  objsLogzbuf['camera'].position.setFrom(objsNormal['camera'].position);
  objsLogzbuf['camera'].quaternion.setFrom(objsNormal['camera'].quaternion);

  // Update renderer sizes if the split has changed
  if (screensplit_right != 1 - screensplit) {
    updateRendererSizes();
  }

  objsNormal['renderer'].render(objsNormal['scene'], objsNormal['camera']);
  objsLogzbuf['renderer'].render(objsLogzbuf['scene'], objsLogzbuf['camera']);
}
