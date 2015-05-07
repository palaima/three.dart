import 'dart:html' show window, document;
import 'package:three/three.dart';
import 'package:three/extras/postprocessing.dart';
import 'package:three/extras/image_utils.dart' as image_utils;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

EffectComposer composer;
BokehPass bokehPass;

List<Material> materials = [];
List<Mesh> objects = [];

int mouseX = 0, mouseY = 0;

int windowHalfX = window.innerWidth ~/ 2;
int windowHalfY = window.innerHeight ~/ 2;

int width = window.innerWidth;
int height = window.innerHeight;

bool singleMaterial;

int nobjects;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(70.0, width / height, 1.0, 3000.0)
    ..position.z = 200.0;

  scene = new Scene();

  renderer = new WebGLRenderer(antialias: false)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(width, height);
  document.body.append(renderer.domElement);

  renderer.sortObjects = false;

  var urls = new List.generate(6, (i) =>
      'textures/cube/SwedishRoyalCastle/${['px', 'nx', 'py', 'ny', 'pz', 'nz'][i]}.jpg');

  var textureCube = image_utils.loadTextureCube(urls);

  var cubeMaterial = new MeshBasicMaterial(color: 0xff1100, envMap: textureCube, shading: FlatShading);

  singleMaterial = false;

  var zmaterial;
  if (singleMaterial) zmaterial = [cubeMaterial];

  var geo = new SphereGeometry(1.0, 20, 10);

  var xgrid = 14, ygrid = 9, zgrid = 14;

  nobjects = xgrid * ygrid * zgrid;

  var s = 60.0;

  Mesh mesh;

  for (var i = 0; i < xgrid; i++)
  for (var j = 0; j < ygrid; j++)
  for (var k = 0; k < zgrid; k++) {
    if (singleMaterial) {
      mesh = new Mesh(geo, zmaterial);
    } else {
      materials.add(new MeshBasicMaterial(color: 0xff1100, envMap: textureCube, shading: FlatShading));
      mesh = new Mesh(geo, materials.last);
    }

    var x = 200 * (i - xgrid / 2);
    var y = 200 * (j - ygrid / 2);
    var z = 200 * (k - zgrid / 2);

    mesh.position.setValues(x, y, z);
    mesh.scale.splat(s);

    mesh.matrixAutoUpdate = false;
    mesh.updateMatrix();

    scene.add(mesh);
    objects.add(mesh);
  }

  scene.matrixAutoUpdate = false;

  initPostprocessing();

  renderer.autoClear = false;

  document.onMouseMove.listen((event) {
    mouseX = event.client.x - windowHalfX;
    mouseY = event.client.y - windowHalfY;
  });

  document.onTouchStart.listen((event) {
    if (event.touches.length == 1) {
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
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);
  });

  var effectController = {
    'focus':    1.0,
    'aperture': 0.025,
    'maxblur':  1.0
  };

  //matChanger() {}

  bokehPass.uniforms['focus'].value = effectController['focus'];
  bokehPass.uniforms['aperture'].value = effectController['aperture'];
  bokehPass.uniforms['maxblur'].value = effectController['maxblur'];
}

void initPostprocessing() {
  var renderPass = new RenderPass(scene, camera);

  bokehPass = new BokehPass(scene, camera,
      focus: 1.0,
      aperture: 0.025,
      maxblur:  1.0,
      width: width,
      height: height)
    ..renderToScreen = true;

  composer = new EffectComposer(renderer)
    ..addPass(renderPass)
    ..addPass(bokehPass);
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.00005;

  camera.position.x += (mouseX - camera.position.x) * 0.036;
  camera.position.y += (-(mouseY) - camera.position.y) * 0.036;

  camera.lookAt(scene.position);

  if (!singleMaterial) {
    for (var i = 0; i < nobjects; i ++) {
      var h = (360 * (i / nobjects + time) % 360) / 360;
      materials[i].color.setHSL(h, 1.0, 0.5);
    }
  }

  composer.render(0.1);
}
