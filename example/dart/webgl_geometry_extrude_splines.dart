import 'dart:html';
import 'dart:async';
import 'package:three/three.dart';
import 'package:three/extras/helpers.dart' show CameraHelper;
import 'package:three/extras/curve_extras.dart' as curves;
import 'package:three/extras/scene_utils.dart' as scene_utils;

DivElement container;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

PerspectiveCamera splineCamera;
CameraHelper cameraHelper;
Mesh cameraEye;

double targetRotation = 0.0;
double targetRotationOnMouseDown = 0.0;

double mouseX = 0.0;
double mouseXOnMouseDown = 0.0;

double windowHalfX = window.innerWidth / 2;
double windowHalfY = window.innerHeight / 2;

Vector3 binormal = new Vector3.zero();
Vector3 normal = new Vector3.zero();

CatmullRomCurve3 pipeSpline = new CatmullRomCurve3([
  new Vector3(0.0, 10.0, -10.0),
  new Vector3(10.0, 0.0, -10.0),
  new Vector3(20.0, 0.0, 0.0),
  new Vector3(30.0, 0.0, 10.0),
  new Vector3(30.0, 0.0, 20.0),
  new Vector3(20.0, 0.0, 30.0),
  new Vector3(10.0, 0.0, 30.0),
  new Vector3(0.0, 0.0, 30.0),
  new Vector3(-10.0, 10.0, 30.0),
  new Vector3(-10.0, 20.0, 30.0),
  new Vector3(0.0, 30.0, 30.0),
  new Vector3(10.0, 30.0, 30.0),
  new Vector3(20.0, 30.0, 15.0),
  new Vector3(10.0, 30.0, 10.0),
  new Vector3(0.0, 30.0, 10.0),
  new Vector3(-10.0, 20.0, 10.0),
  new Vector3(-10.0, 10.0, 10.0),
  new Vector3(0.0, 0.0, 10.0),
  new Vector3(10.0, -10.0, 10.0),
  new Vector3(20.0, -15.0, 10.0),
  new Vector3(30.0, -15.0, 10.0),
  new Vector3(40.0, -15.0, 10.0),
  new Vector3(50.0, -15.0, 10.0),
  new Vector3(60.0, 0.0, 10.0),
  new Vector3(70.0, 0.0, 0.0),
  new Vector3(80.0, 0.0, 0.0),
  new Vector3(90.0, 0.0, 0.0),
  new Vector3(100.0, 0.0, 0.0)
]);

ClosedSplineCurve3 sampleClosedSpline = new ClosedSplineCurve3([
  new Vector3(0.0, -40.0, -40.0),
  new Vector3(0.0, 40.0, -40.0),
  new Vector3(0.0, 140.0, -40.0),
  new Vector3(0.0, 40.0, 40.0),
  new Vector3(0.0, -40.0, 40.0),
]);

// Keep a dictionary of Curve instances
Map splines = {
  'GrannyKnot': new curves.GrannyKnot(),
  'HeartCurve': new curves.HeartCurve(3.5),
  'VivianiCurve': new curves.VivianiCurve(70.0),
  'KnotCurve': new curves.KnotCurve(),
  'HelixCurve': new curves.HelixCurve(),
  'TrefoilKnot': new curves.TrefoilKnot(),
  'TorusKnot': new curves.TorusKnot(20.0),
  'CinquefoilKnot': new curves.CinquefoilKnot(20.0),
  'TrefoilPolynomialKnot': new curves.TrefoilPolynomialKnot(14.0),
  'FigureEightPolynomialKnot': new curves.FigureEightPolynomialKnot(),
  'DecoratedTorusKnot4a': new curves.DecoratedTorusKnot4a(),
  'DecoratedTorusKnot4b': new curves.DecoratedTorusKnot4b(),
  'DecoratedTorusKnot5a': new curves.DecoratedTorusKnot5a(),
  'DecoratedTorusKnot5c': new curves.DecoratedTorusKnot5c(),
  'PipeSpline': pipeSpline,
  'SampleClosedSpline': sampleClosedSpline
};

var extrudePath = new curves.TrefoilKnot();

bool closed2 = true;

Object3D parent;

TubeGeometry tube;
Object3D tubeMesh;

bool animation = false,
    lookAhead = false;

double scale;
bool showCameraHelper = false;

List<StreamSubscription> mouseSubs;

void addTube() {
  var value = dropdownSelect.value;

  var segments = int.parse(segmentsSelect.value);
  closed2 = closedCheckbox.checked;

  var radiusSegments = int.parse(radiusSegmentsSelect.value);

  print('adding tube $value $closed2 $radiusSegments');

  if (tubeMesh != null) parent.remove(tubeMesh);

  extrudePath = splines[value];

  tube = new TubeGeometry(extrudePath, segments, 2.0, radiusSegments, closed2);

  addGeometry(tube, 0xff00ff);
  setScale();
}

void setScale() {
  scale = double.parse(scaleSelect.value);
  tubeMesh.scale.splat(scale);
}

void addGeometry(Geometry geometry, int color) {
  // 3d shape

  tubeMesh = scene_utils.createMultiMaterialObject(geometry, [
    new MeshLambertMaterial(color: color),
    new MeshBasicMaterial(color: 0x000000, opacity: 0.3, wireframe: true, transparent: true)
  ]);

  parent.add(tubeMesh);
}

void animateCamera([bool toggle = false]) {
  if (toggle) {
    animation = !animation;
    animationButton.text =
        'Camera Spline Animation View: ' + (animation ? 'ON' : 'OFF');
  }

  lookAhead = lookAheadCheckbox.checked;

  showCameraHelper = cameraHelperCheckbox.checked;

  cameraHelper.visible = showCameraHelper;
  cameraEye.visible = showCameraHelper;
}

SelectElement dropdownSelect;
SelectElement scaleSelect;

SelectElement segmentsSelect;
SelectElement radiusSegmentsSelect;
CheckboxInputElement closedCheckbox;

ButtonInputElement animationButton;
CheckboxInputElement lookAheadCheckbox;
CheckboxInputElement cameraHelperCheckbox;

List scales = ['1', '2', '4', '6', '10'];
List segments = ['50', '100', '200', '400'];
List radiusSegments = ['1', '2', '3', '4', '5', '6', '8', '12'];

void addInfo() {
  dropdownSelect = new SelectElement()..onChange.listen((_) => addTube());
  for (var s in splines.keys) {
    dropdownSelect.children.add(new OptionElement(value: s, data: s));
  }

  scaleSelect = new SelectElement()..onChange.listen((_) => setScale());
  for (var v in scales) {
    scaleSelect.append(new OptionElement(value: v, data: v));
  }

  segmentsSelect = new SelectElement()..onChange.listen((_) => addTube());
  for (var v in segments) {
    segmentsSelect.append(new OptionElement(value: v, data: v));
  }

  radiusSegmentsSelect = new SelectElement()..onChange.listen((_) => addTube());
  for (var v in radiusSegments) {
    radiusSegmentsSelect.append(new OptionElement(value: v, data: v));
  }

  closedCheckbox = new CheckboxInputElement()
    ..checked = true
    ..onChange.listen((_) => addTube());

  animationButton = new ButtonInputElement()
    ..value = "Camera Spline Animation View: OFF"
    ..onClick.listen((_) => animateCamera(true));

  lookAheadCheckbox = new CheckboxInputElement()..onChange.listen((_) => animateCamera());

  cameraHelperCheckbox = new CheckboxInputElement()..onChange.listen((_) => animateCamera());

  var info = new DivElement()
    ..style.position = 'absolute'
    ..style.top = '10px'
    ..style.width = '100%'
    ..style.textAlign = 'center';

  info.appendHtml('Spline Extrusion Examples by <a href="http://www.lab4games.net/zz85/blog">zz85</a><br/>');

  info..appendHtml('Select spline: ')..append(dropdownSelect);
  info..appendHtml('<br/>Scale: ')..append(scaleSelect);
  info..appendHtml('<br/>Extrusion Segments: ')..append(segmentsSelect);
  info..appendHtml('<br/>Radius segments: ')..append(radiusSegmentsSelect);
  info..appendHtml('<br/>Closed: ')..append(closedCheckbox);
  info..appendHtml('<br/>')..append(animationButton);
  info..appendHtml('<br/>Look Ahead:')..append(lookAheadCheckbox)..appendHtml('   Camera Helper:')..append(cameraHelperCheckbox);

  container.append(info);
}

void init() {
  container = new DivElement();
  document.body.append(container);

  addInfo();

  camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 0.01, 1000.0)
    ..position.setValues(0.0, 50.0, 500.0);

  scene = new Scene();

  var light = new DirectionalLight(0xffffff)..position.setValues(0.0, 0.0, 1.0);
  scene.add(light);

  parent = new Object3D()..position.y = 100.0;
  scene.add(parent);

  splineCamera = new PerspectiveCamera(84.0, window.innerWidth / window.innerHeight, 0.01, 1000.0);
  parent.add(splineCamera);

  cameraHelper = new CameraHelper(splineCamera);
  scene.add(cameraHelper);

  addTube();

  // Debug point

  cameraEye = new Mesh(new SphereGeometry(5.0), new MeshBasicMaterial(color: 0xdddddd));
  parent.add(cameraEye);

  cameraHelper.visible = showCameraHelper;
  cameraEye.visible = showCameraHelper;

  //

  renderer = new WebGLRenderer(antialias: true)
    ..setClearColor(0xf0f0f0)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  container.append(renderer.domElement);

  document.onMouseDown.listen(onDocumentMouseDown);
  document.onTouchStart.listen(onDocumentTouchStart);
  document.onTouchMove.listen(onDocumentTouchMove);

  //

  window..onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  windowHalfX = window.innerWidth / 2;
  windowHalfY = window.innerHeight / 2;

  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void onDocumentMouseDown(MouseEvent event) {
  //event.preventDefault();

  mouseSubs = [
    document.onMouseMove.listen(onDocumentMouseMove),
    document.onMouseUp.listen(onDocumentMouseUp),
    document.onMouseOut.listen(onDocumentMouseOut)
  ];

  mouseXOnMouseDown = event.client.x - windowHalfX;
  targetRotationOnMouseDown = targetRotation;
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

void render() {
  // Try Animate Camera Along Spline
  var time = new DateTime.now().millisecondsSinceEpoch;
  var looptime = 20 * 1000;
  var t = (time % looptime) / looptime;

  var pos = tube.path.getPointAt(t)..scale(scale);

  // interpolation
  var segments = tube.tangents.length;
  var pickt = t * segments;
  var pick = pickt.floor();
  var pickNext = (pick + 1) % segments;

  binormal.subVectors(tube.binormals[pickNext], tube.binormals[pick]);
  binormal.scale(pickt - pick).add(tube.binormals[pick]);

  var dir = tube.path.getTangentAt(t);

  var offset = 15.0;

  normal.setFrom(binormal);
  normal.crossVectors(normal, dir);

  // We move on a offset on its binormal
  pos.add(normal
    ..clone()
    ..scale(offset));

  splineCamera.position.setFrom(pos);
  cameraEye.position.setFrom(pos);

  // Camera Orientation 1 - default look at
  // splineCamera.lookAt( lookAt );

  // Using arclength for stablization in look ahead.
  Vector3 lookAt = tube.path.getPointAt((t + 30 / tube.path.length) % 1).scale(scale);

  // Camera Orientation 2 - up orientation via normal
  if (!lookAhead) {
    lookAt.setFrom(pos);
    lookAt.add(dir);
  }

  splineCamera.matrix.lookAt(splineCamera.position, lookAt, normal);
  splineCamera.rotation.setFromRotationMatrix(splineCamera.matrix,
      order: splineCamera.rotation.order);

  cameraHelper.update();

  parent.rotation.y += (targetRotation - parent.rotation.y) * 0.05;

  renderer.render(scene, animation ? splineCamera : camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
