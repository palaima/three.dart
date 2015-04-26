import 'dart:html' show window, document;
import 'dart:math' as Math;
import 'package:three/three.dart';

final fragmentShaderScreen = '''
varying vec2 vUv;
uniform sampler2D tDiffuse;

void main() {
  gl_FragColor = texture2D(tDiffuse, vUv);
}
''';

final fragmentShaderPass1 = '''
varying vec2 vUv;
uniform float time;

void main() {
  float r = vUv.x;
  if(vUv.y < 0.5) r = 0.0;
  float g = vUv.y;
  if(vUv.x < 0.5) g = 0.0;

  gl_FragColor = vec4(r, g, time, 1.0);
}
''';

final vertexShader = '''
varying vec2 vUv;

void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''';

OrthographicCamera cameraRTT;
PerspectiveCamera camera;

Scene sceneRTT, sceneScreen, scene;

WebGLRenderer renderer;

Mesh zmesh1, zmesh2;

num mouseX = 0, mouseY = 0;

num windowHalfX = window.innerWidth / 2;
num windowHalfY = window.innerHeight / 2;

Texture rtTexture;
ShaderMaterial material;
Mesh quad;

double delta = 0.01;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(30.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 100.0;

  cameraRTT = new OrthographicCamera(
      window.innerWidth / -2,
      window.innerWidth / 2,
      window.innerHeight / 2,
      window.innerHeight / -2, -10000.0, 10000.0)
    ..position.z = 100.0;

  //

  scene = new Scene();
  sceneRTT = new Scene();
  sceneScreen = new Scene();

  sceneRTT.add(new DirectionalLight(0xffffff)
    ..position.setValues(0.0, 0.0, 1.0).normalize());

  sceneRTT.add(new DirectionalLight(0xffaaaa, 1.5)
    ..position.setValues(0.0, 0.0, -1.0).normalize());

  rtTexture = new WebGLRenderTarget(window.innerWidth, window.innerHeight,
      minFilter: LinearFilter, magFilter: NearestFilter, format: RGBFormat);

  material = new ShaderMaterial(
      uniforms: {'time': new Uniform.float(0.0)},
      vertexShader: vertexShader,
      fragmentShader: fragmentShaderPass1);

  var materialScreen = new ShaderMaterial(
      uniforms: {'tDiffuse': new Uniform.texture(rtTexture)},
      vertexShader: vertexShader,
      fragmentShader: fragmentShaderScreen,
      depthWrite: false);

  var plane = new PlaneBufferGeometry(window.innerWidth.toDouble(), window.innerHeight.toDouble());

  quad = new Mesh(plane, material)
    ..position.z = -100.0;
  sceneRTT.add(quad);

  var geometry = new TorusGeometry(100.0, 25.0, 15, 30);

  var mat1 = new MeshPhongMaterial(color: 0x555555, specular: 0xffaa00, shininess: 5.0);
  var mat2 = new MeshPhongMaterial(color: 0x550000, specular: 0xff2200, shininess: 5.0);

  zmesh1 = new Mesh(geometry, mat1)
    ..position.setValues(0.0, 0.0, 100.0)
    ..scale.setValues(1.5, 1.5, 1.5);
  sceneRTT.add(zmesh1);

  zmesh2 = new Mesh(geometry, mat2)
    ..position.setValues(0.0, 150.0, 100.0)
    ..scale.setValues(0.75, 0.75, 0.75);
  sceneRTT.add(zmesh2);

  quad = new Mesh(plane, materialScreen)
    ..position.z = -100.0;
  sceneScreen.add(quad);

  var n = 5,
      geometry2 = new SphereGeometry(10.0, 64, 32),
      material2 = new MeshBasicMaterial(color: 0xffffff, map: rtTexture);

  for (var j = 0; j < n; j++) {
    for (var i = 0; i < n; i++) {
      var mesh = new Mesh(geometry2, material2)
        ..position.x = (i - (n - 1) / 2) * 20.0
        ..position.y = (j - (n - 1) / 2) * 20.0
        ..position.z = 0.0

        ..rotation.y = -Math.PI / 2;

      scene.add(mesh);
    }
  }

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..autoClear = false;
  document.body.append(renderer.domElement);

  window.onMouseMove.listen((event) {
    mouseX = (event.client.x - windowHalfX);
    mouseY = (event.client.y - windowHalfY);
  });
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.0015;

  camera.position.x += (mouseX - camera.position.x) * .05;
  camera.position.y += (-mouseY - camera.position.y) * .05;

  camera.lookAt(scene.position);

  if (zmesh1 != null && zmesh2 != null) {
    zmesh1.rotation.y = -time;
    zmesh2.rotation.y = -time + Math.PI / 2;
  }

  if (material.uniforms['time'].value > 1 || material.uniforms['time'].value < 0) {
    delta *= -1;
  }

  material.uniforms['time'].value += delta;

  renderer.clear();

  // Render first scene into texture

  renderer.render(sceneRTT, cameraRTT, renderTarget: rtTexture, forceClear: true);

  // Render full screen quad with generated texture

  renderer.render(sceneScreen, cameraRTT);

  // Render second scene to screen
  // (using first scene as regular texture)

  renderer.render(scene, camera);
}
