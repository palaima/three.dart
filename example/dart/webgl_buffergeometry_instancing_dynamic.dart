import 'dart:html';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;

final vertexShader = '''
precision highp float;

uniform mat4 modelViewMatrix; 
uniform mat4 projectionMatrix; 
attribute vec3 position;
attribute vec3 offset;
attribute vec2 uv;
attribute vec4 orientation;
varying vec2 vUv;
void main() {
vec3 vPosition = position;
vec3 vcV = cross(orientation.xyz, vPosition);
vPosition = vcV * (2.0 * orientation.w) + (cross(orientation.xyz, vcV) * 2.0 + vPosition);
vUv = uv;
gl_Position = projectionMatrix * modelViewMatrix * vec4(offset + vPosition, 1.0);
}
''';

final fragmentShader = '''
precision highp float;
uniform sampler2D map;
varying vec2 vUv;
void main() {
gl_FragColor = texture2D(map, vUv);
}
''';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

InstancedBufferAttribute orientations;

math.Random rnd = new math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 1000.0);
  //camera.position.z = 20;

  renderer = new WebGLRenderer();
  scene = new Scene();

  // geometry
  var instances = 5000;
  var geometry = new InstancedBufferGeometry();

  // per mesh data
  var vertices = new Float32List.fromList([
    // Front
    -1, 1, 1,
    1, 1, 1,
    -1, -1, 1,
    1, -1, 1,
    // Back
    1, 1, -1,
    -1, 1, -1,
    1, -1, -1,
    -1, -1, -1,
    // Left
    -1, 1, -1,
    -1, 1, 1,
    -1, -1, -1,
    -1, -1, 1,
    // Right
    1, 1, 1,
    1, 1, -1,
    1, -1, 1,
    1, -1, -1,
    // Top
    -1, 1, 1,
    1, 1, 1,
    -1, 1, -1,
    1, 1, -1,
    // Bottom
    1, -1, 1,
    -1, -1, 1,
    1, -1, -1,
    -1, -1, -1
  ].map((e) => e.toDouble()).toList());

  geometry.addAttribute('position', new BufferAttribute(vertices, 3));

  var uvs = new Float32List.fromList([
    //x    y    z
    // Front
    0, 0,
    1, 0,
    0, 1,
    1, 1,
    // Back
    1, 0,
    0, 0,
    1, 1,
    0, 1,
    // Left
    1, 1,
    1, 0,
    0, 1,
    0, 0,
    // Right
    1, 0,
    1, 1,
    0, 0,
    0, 1,
    // Top
    0, 0,
    1, 0,
    0, 1,
    1, 1,
    // Bottom
    1, 0,
    0, 0,
    1, 1,
    0, 1
  ].map((e) => e.toDouble()).toList());

  geometry.addAttribute('uv', new BufferAttribute(uvs, 2));

  var indices = new Uint16List.fromList([
    0, 1, 2,
    2, 1, 3,
    4, 5, 6,
    6, 5, 7,
    8, 9, 10,
    10, 9, 11,
    12, 13, 14,
    14, 13, 15,
    16, 17, 18,
    18, 17, 19,
    20, 21, 22,
    22, 21, 23
  ]);

  geometry.addAttribute('index', new BufferAttribute(indices, 1));

  // per instance data
  var offsets = new InstancedBufferAttribute(new Float32List(instances * 3), 3);

  var vector = new Vector4.zero();

  for (var i = 0; i < offsets.count; i++) {
      var x = rnd.nextDouble() * 100 - 50;
      var y = rnd.nextDouble() * 100 - 50;
      var z = rnd.nextDouble() * 100 - 50;

      vector.setValues(x, y, z, 0.0);
      vector.normalize();

      // move out at least 5 units from center in current direction
      offsets.setXYZ(i, x + vector.x * 5, y + vector.y * 5, z + vector.z * 5);
  }

  geometry.addAttribute('offset', offsets); // per mesh translation

  orientations = new InstancedBufferAttribute(new Float32List(instances * 4), 4, dynamic: true);

  for (var i = 0, ul = orientations.count; i < ul; i++) {
    vector.setValues(rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1);
    vector.normalize();
    orientations.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
  }

  geometry.addAttribute('orientation', orientations); // per mesh orientation

  // material
  var texture = image_utils.loadTexture('textures/crate.gif')
    ..anisotropy = renderer.getMaxAnisotropy();

  var material = new RawShaderMaterial(
      uniforms: {
        'map': new Uniform.texture(texture)
      },
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
      side: DoubleSide,
      transparent: false,
      attributes: ['position', 'offset', 'orientation', 'uv']
 );

  var mesh = new Mesh(geometry, material);
  scene.add(mesh);

  if (!renderer.supportsInstancedArrays) {
    document.getElementById("notSupported").style.display = "";
    return;
  }

  renderer.setClearColor(0x101010);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(Event event) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

//

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

double lastTime = 0.0;

Quaternion moveQ = new Quaternion(.5, .5, .5, 0.0)..normalize();
Quaternion tmpQ = new Quaternion.identity();
Quaternion currentQ = new Quaternion.identity();

void render() {
  var time = window.performance.now();

  var object = scene.children[0];
  object.rotation.y = time * 0.00005;

  renderer.render(scene, camera);

  var delta = (time - lastTime) / 5000;

  tmpQ.setValues(moveQ.x * delta, moveQ.y * delta, moveQ.z * delta, 1.0);
  tmpQ.normalize();

  for (var i = 0; i < orientations.length; i++) {
    var index = i * 4;
    currentQ.setValues(orientations.array[index], orientations.array[index + 1], orientations.array[index + 2], orientations.array[index + 3]);
    currentQ.multiply(tmpQ);

    orientations.setXYZW(i, currentQ.x, currentQ.y, currentQ.z, currentQ.w);
  }

  orientations.needsUpdate = true;
  lastTime = time;
}
