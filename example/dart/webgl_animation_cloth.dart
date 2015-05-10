import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;
import 'package:three/extras/cloth.dart';

final String fragmentShaderDepth = '''
uniform sampler2D texture;
varying vec2 vUV;

vec4 pack_depth(const in float depth) {
  const vec4 bit_shift = vec4(256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0, 1.0);
  const vec4 bit_mask  = vec4(0.0, 1.0 / 256.0, 1.0 / 256.0, 1.0 / 256.0);
  vec4 res = fract(depth * bit_shift);
  res -= res.xxyz * bit_mask;
  return res;
}

void main() {
  vec4 pixel = texture2D(texture, vUV);
  if (pixel.a < 0.5) discard;
  gl_FragData[ 0 ] = pack_depth(gl_FragCoord.z);
}
''';

final String vertexShaderDepth = '''
varying vec2 vUV;

void main() {
  vUV = 0.75 * uv;
  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  gl_Position = projectionMatrix * mvPosition;
}
''';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Mesh sphere;
Cloth cloth;

bool rotate = true;

const clothWidthSegments = 10;
const clothHeightSegments = 10;

List<List<int>> pinsFormation = []
  ..add([6])
  ..add([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  ..add([0])
  ..add([])
  ..add([0, clothWidthSegments]);

Function random = new math.Random().nextDouble;

void togglePins() {
  cloth.pins = pinsFormation[(random() * pinsFormation.length).toInt()];
}

void init() {
  scene = new Scene()..fog = new FogLinear(0xcce0ff, 500.0, 10000.0);

  camera = new PerspectiveCamera(30.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.y = 50.0
    ..position.z = 1500.0;
  scene.add(camera);

  scene.add(new AmbientLight(0x666666));

  var d = 300.0;

  scene.add(new DirectionalLight(0xdfebff, 1.75)
    ..position.setValues(50.0, 200.0, 100.0)
    ..position.scale(1.3)

    ..castShadow = true

    ..shadowMapWidth = 1024
    ..shadowMapHeight = 1024

    ..shadowCameraLeft = -d
    ..shadowCameraRight = d
    ..shadowCameraTop = d
    ..shadowCameraBottom = -d

    ..shadowCameraFar = 1000.0
    ..shadowDarkness = 0.5);

  // Cloth material

  var clothTexture = image_utils.loadTexture('textures/patterns/circuit_pattern.png');
  clothTexture.wrapS = clothTexture.wrapT = RepeatWrapping;
  clothTexture.anisotropy = 16;

  var clothMaterial = new MeshPhongMaterial(
      alphaTest: 0.5,
      color: 0xffffff,
      specular: 0x030303,
      emissive: 0x111111,
      shininess: 10.0,
      map: clothTexture,
      side: DoubleSide);

  // Cloth mesh

  cloth = new Cloth(clothMaterial, clothWidthSegments, clothHeightSegments)
    ..castShadow = true
    ..receiveShadow = true
    ..sphereVisible = false
    ..customDepthMaterial = new ShaderMaterial(
        uniforms: {'texture': new Uniform.texture(clothTexture)},
        vertexShader: vertexShaderDepth,
        fragmentShader: fragmentShaderDepth);

  scene.add(cloth);

  cloth.pins = pinsFormation[1];

  // Sphere

  var ballGeo = new SphereGeometry(cloth.ballSize, 20, 20);
  var ballMaterial = new MeshPhongMaterial(color: 0xffffff);

  sphere = new Mesh(ballGeo, ballMaterial)
    ..castShadow = true
    ..receiveShadow = true;
  scene.add(sphere);

  cloth.sphereVisible = sphere.visible = false;

  // Ground

  var groundTexture = image_utils.loadTexture("textures/terrain/grasslight-big.jpg");
  groundTexture.wrapS = groundTexture.wrapT = RepeatWrapping;
  groundTexture.repeat.splat(25.0);
  groundTexture.anisotropy = 16;

  var groundMaterial =
      new MeshPhongMaterial(color: 0xffffff, specular: 0x111111, map: groundTexture);

  var mesh = new Mesh(new PlaneBufferGeometry(20000.0, 20000.0), groundMaterial)
    ..position.y = -250.0
    ..rotation.x = -math.PI / 2
    ..receiveShadow = true;
  scene.add(mesh);

  // Poles

  var poleGeo = new BoxGeometry(5.0, 375.0, 5.0);
  var poleMat = new MeshPhongMaterial(color: 0xffffff, specular: 0x111111, shininess: 100.0);

  scene.add(new Mesh(poleGeo, poleMat)
    ..position.x = -125.0
    ..position.y = -62.0
    ..receiveShadow = true
    ..castShadow = true);

  scene.add(new Mesh(poleGeo, poleMat)
    ..position.x = 125.0
    ..position.y = -62.0
    ..receiveShadow = true
    ..castShadow = true);

  scene.add(new Mesh(new BoxGeometry(255.0, 5.0, 5.0), poleMat)
    ..position.y = -250 + 750 / 2
    ..position.x = 0.0
    ..receiveShadow = true
    ..castShadow = true);

  scene.add(new Mesh(new BoxGeometry(10.0, 10.0, 10.0), poleMat)
    ..position.y = -250.0
    ..position.x = 125.0
    ..receiveShadow = true
    ..castShadow = true);

  scene.add(new Mesh(new BoxGeometry(10.0, 10.0, 10.0), poleMat)
    ..position.y = -250.0
    ..position.x = -125.0
    ..receiveShadow = true
    ..castShadow = true);

  //

  renderer = new WebGLRenderer(antialias: true)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..setClearColor(scene.fog.color);
  document.body.append(renderer.domElement);

  renderer.gammaInput = true;
  renderer.gammaOutput = true;

  renderer.shadowMap.enabled = true;

  //

  querySelector('#camera').onClick.listen((_) => rotate = !rotate);

  querySelector('#wind').onClick.listen((_) => cloth.wind = !cloth.wind);

  querySelector('#ball').onClick
      .listen((_) => cloth.sphereVisible = sphere.visible = !sphere.visible);

  querySelector('#pins').onClick.listen((_) => togglePins());

  //

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void animate(num time) {
  window.animationFrame.then(animate);

  var time = new DateTime.now().millisecondsSinceEpoch;

  cloth.windStrength = math.cos(time / 7000) * 20 + 40;
  cloth.windForce
    ..setValues(math.sin(time / 2000), math.cos(time / 3000), math.sin(time / 1000))
    ..normalize()
    ..scale(cloth.windStrength);

  cloth.simulate(time);
  render();
}

void render() {
  var timer = new DateTime.now().millisecondsSinceEpoch * 0.0002;

  var p = cloth.particles;

  for (var i = 0; i < p.length; i++) {
    cloth.geometry.vertices[i].setFrom(p[i].position);
  }

  cloth.geometry.normalsNeedUpdate = true;
  cloth.geometry.verticesNeedUpdate = true;

  sphere.position.setFrom(cloth.ballPosition);

  if (rotate) {
    camera.position.x = math.cos(timer) * 1500;
    camera.position.z = math.sin(timer) * 1500;
  }

  camera.lookAt(scene.position);

  renderer.render(scene, camera);
}

void main() {
  init();
  animate(0);
}
