import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as ImageUtils;

WebGLRenderer renderer;
PerspectiveCamera camera;

List objects = [];

Mesh particleLight;
PointLight pointLight;

Scene scene;

var rnd = new Math.Random().nextDouble;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(40.0, window.innerWidth / window.innerHeight, 1.0, 2000.0)
    ..position.y = 200.0;

  scene = new Scene();

  var imgTexture2 = ImageUtils.loadTexture("moon.jpg");
  imgTexture2.wrapS = imgTexture2.wrapT = RepeatWrapping;
  imgTexture2.anisotropy = 16;

  var imgTexture = ImageUtils.loadTexture("lava.jpg");
  imgTexture.repeat.setValues(4.0, 2.0);
  imgTexture.wrapS = imgTexture.wrapT = RepeatWrapping;
  imgTexture.anisotropy = 16;

  var shininess = 50.0, specular = 0x333333, bumpScale = 1.0, shading = SmoothShading;

  var materials = [];

  materials.add(new MeshPhongMaterial(map: imgTexture, bumpMap: imgTexture, bumpScale: bumpScale, color: 0xffffff, specular: specular, shininess: shininess, shading: shading));
  materials.add(new MeshPhongMaterial(map: imgTexture, bumpMap: imgTexture, bumpScale: bumpScale, color: 0x00ff00, specular: specular, shininess: shininess, shading: shading));
  materials.add(new MeshPhongMaterial(map: imgTexture, bumpMap: imgTexture, bumpScale: bumpScale, color: 0x00ff00, specular: specular, shininess: shininess, shading: shading));
  materials.add(new MeshPhongMaterial(map: imgTexture, bumpMap: imgTexture, bumpScale: bumpScale, color: 0x000000, specular: specular, shininess: shininess, shading: shading));

  materials.add(new MeshLambertMaterial(map: imgTexture, color: 0xffffff, shading: shading));
  materials.add(new MeshLambertMaterial(map: imgTexture, color: 0xff0000, shading: shading));
  materials.add(new MeshLambertMaterial(map: imgTexture, color: 0xff0000, shading: shading));
  materials.add(new MeshLambertMaterial(map: imgTexture, color: 0x000000, shading: shading));

  shininess = 15.0;

  materials.add(new MeshPhongMaterial(map: imgTexture2, bumpMap: imgTexture2, bumpScale: bumpScale, color: 0x000000, specular: 0xffaa00, shininess: shininess, metal: true, shading: shading));
  materials.add(new MeshPhongMaterial(map: imgTexture2, bumpMap: imgTexture2, bumpScale: bumpScale, color: 0x000000, specular: 0xaaff00, shininess: shininess, metal: true, shading: shading));
  materials.add(new MeshPhongMaterial(map: imgTexture2, bumpMap: imgTexture2, bumpScale: bumpScale, color: 0x000000, specular: 0x00ffaa, shininess: shininess, metal: true, shading: shading));
  materials.add(new MeshPhongMaterial(map: imgTexture2, bumpMap: imgTexture2, bumpScale: bumpScale, color: 0x000000, specular: 0x00aaff, shininess: shininess, metal: true, shading: shading));

  // Spheres geometry

  var geometry_smooth = new SphereGeometry(70.0, 32, 16);
  var geometry_flat = new SphereGeometry(70.0, 32, 16);

  objects = [];

  for (var i = 0; i < materials.length; i ++) {
    var material = materials[i];

    var geometry = material.shading == FlatShading ? geometry_flat : geometry_smooth;

    var sphere = new Mesh(geometry, material)
      ..position.x = (i % 4) * 200.0 - 200.0
      ..position.z = (i / 4).floor() * 200.0 - 200.0;

    objects.add(sphere);

    scene.add(sphere);
  }

  particleLight = new Mesh(new SphereGeometry(4.0, 8, 8), new MeshBasicMaterial(color: 0xffffff));
  scene.add(particleLight);

  // Lights

  scene.add(new AmbientLight(0x444444));

  var directionalLight = new DirectionalLight(0xffffff, 1.0)
    ..position.setValues(1.0, 1.0, 1.0).normalize();
  scene.add(directionalLight);

  var pointLight = new PointLight(0xffffff, intensity: 2.0, distance: 800.0);
  particleLight.add(pointLight);

  //

  renderer = new WebGLRenderer(antialias: true)
    ..setClearColor(0x0a0a0a)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..sortObjects = true;

  document.body.append(renderer.domElement);

  renderer.gammaInput = true;
  renderer.gammaOutput = true;

  window.onResize.listen(onWindowResize);
}

void onWindowResize(Event e) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var timer = new DateTime.now().millisecondsSinceEpoch * 0.00025;

  camera.position.x = Math.cos(timer) * 800;
  camera.position.z = Math.sin(timer) * 800;

  camera.lookAt(scene.position);

  objects.forEach((object) => object.rotation.y += 0.005);

  particleLight.position.x = Math.sin(timer * 7) * 300;
  particleLight.position.y = Math.cos(timer * 5) * 400;
  particleLight.position.z = Math.cos(timer * 3) * 300;

  renderer.render(scene, camera);
}
