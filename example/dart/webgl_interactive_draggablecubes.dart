import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/controls.dart';

PerspectiveCamera camera;
TrackballControls controls;
Scene scene;

WebGLRenderer renderer;
List<Mesh> objects = [];
Mesh plane;

Raycaster raycaster = new Raycaster();
Vector2 mouse = new Vector2.zero();
Vector3 offset = new Vector3.zero();
Mesh intersected, selected;
int currentHex;

void init() {
  camera = new PerspectiveCamera(70.0, window.innerWidth / window.innerHeight, 1.0, 10000.0);
  camera.position.z = 1000.0;

  controls = new TrackballControls(camera)
    ..rotateSpeed = 1.0
    ..zoomSpeed = 1.2
    ..panSpeed = 0.8
    ..noZoom = false
    ..noPan = false
    ..staticMoving = true
    ..dynamicDampingFactor = 0.3;

  scene = new Scene();

  scene.add(new AmbientLight(0x505050));

  var light = new SpotLight(0xffffff, intensity: 1.5)
    ..position.setValues(0.0, 500.0, 2000.0)
    ..castShadow = true

    ..shadowCameraNear = 200.0
    ..shadowCameraFar = camera.far
    ..shadowCameraFov = 50.0

    ..shadowBias = -0.00022
    ..shadowDarkness = 0.5

    ..shadowMapWidth = 2048
    ..shadowMapHeight = 2048;

  scene.add(light);

  var geometry = new BoxGeometry(40.0, 40.0, 40.0);

  var random = new math.Random().nextDouble;

  for (var i = 0; i < 200; i++) {
    var object = new Mesh(geometry, new MeshLambertMaterial(color: random() * 0xffffff))
      ..position.x = random() * 1000 - 500
      ..position.y = random() * 600 - 300
      ..position.z = random() * 800 - 400

      ..rotation.x = random() * 2 * math.PI
      ..rotation.y = random() * 2 * math.PI
      ..rotation.z = random() * 2 * math.PI

      ..scale.x = random() * 2 + 1
      ..scale.y = random() * 2 + 1
      ..scale.z = random() * 2 + 1

      ..castShadow = true
      ..receiveShadow = true;

    scene.add(object);

    objects.add(object);
  }

  plane = new Mesh(new PlaneGeometry(2000.0, 2000.0, 8, 8),
      new MeshBasicMaterial(color: 0x000000, opacity: 0.25, transparent: true))
    ..visible = false;
  scene.add(plane);

  renderer = new WebGLRenderer(antialias: true)
    ..setClearColor(0xf0f0f0)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..sortObjects = false

    ..shadowMap.enabled = true
    ..shadowMap.type = PCFShadowMap;

  document.body.append(renderer.domElement);

  var info = new DivElement()
    ..style.position = 'absolute'
    ..style.top = '10px'
    ..style.width = '100%'
    ..style.textAlign = 'center'
    ..innerHtml = '<a href="http://threejs.org" target="_blank">three.js</a> webgl - draggable cubes';
  document.body.append(info);

  document.onMouseMove.listen(onDocumentMouseMove);
  document.onMouseDown.listen(onDocumentMouseDown);
  document.onMouseUp.listen(onDocumentMouseUp);

  //

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}


void onDocumentMouseMove(MouseEvent event) {
  event.preventDefault();

  mouse.x = (event.client.x / window.innerWidth) * 2 - 1;
  mouse.y = -(event.client.y / window.innerHeight) * 2 + 1;

  //

  raycaster.setFromCamera(mouse, camera);

  if (selected != null) {
    var intersects = raycaster.intersectObject(plane);
    selected.position.setFrom(intersects[0].point.sub(offset));
    return;
  }

  var intersects = raycaster.intersectObjects(objects);

  if (intersects.length > 0) {
    if (intersected != intersects[0].object) {
      if (intersected != null) intersected.material.color.setHex(currentHex);

      intersected = intersects[0].object;
      currentHex = intersected.material.color.getHex();

      plane.position.setFrom(intersected.position);
      plane.lookAt(camera.position);
    }

    document.body.style.cursor = 'pointer';
  } else {
    if (intersected != null) intersected.material.color.setHex(currentHex);

    intersected = null;

    document.body.style.cursor = 'auto';
  }
}

void onDocumentMouseDown(MouseEvent event) {
  event.preventDefault();

  var vector = new Vector3(mouse.x, mouse.y, 0.5).unproject(camera);

  var raycaster = new Raycaster(camera.position, vector.sub(camera.position).normalize());

  var intersects = raycaster.intersectObjects(objects);

  if (intersects.length > 0) {
    controls.enabled = false;

    selected = intersects[0].object;

    {
      var intersects = raycaster.intersectObject(plane);
      offset.setFrom(intersects[0].point).sub(plane.position);

      document.body.style.cursor = 'move';
    }
  }
}

void onDocumentMouseUp(MouseEvent event) {
  event.preventDefault();

  controls.enabled = true;

  if (intersected != null) {
    plane.position.setFrom(intersected.position);

    selected = null;
  }

  document.body.style.cursor = 'auto';
}

void render() {
  controls.update();
  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
