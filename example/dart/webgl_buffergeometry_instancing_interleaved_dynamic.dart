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

InterleavedBufferAttribute orientations;
InstancedInterleavedBuffer instanceBuffer;

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

  // per mesh data x,y,z,w,u,v,s,t for 4-element alignment
  // only use x,y,z and u,v; but x, y, z, nx, ny, nz, u, v would be a good layout
  var vertexBuffer = new InterleavedBuffer(new Float32List.fromList([
    // Front
    -1, 1, 1, 0, 0, 0, 0, 0,
    1, 1, 1, 0, 1, 0, 0, 0,
    -1, -1, 1, 0, 0, 1, 0, 0,
    1, -1, 1, 0, 1, 1, 0, 0,
    // Back
    1, 1, -1, 0, 1, 0, 0, 0,
    -1, 1, -1, 0, 0, 0, 0, 0,
    1, -1, -1, 0, 1, 1, 0, 0,
    -1, -1, -1, 0, 0, 1, 0, 0,
    // Left
    -1, 1, -1, 0, 1, 1, 0, 0,
    -1, 1, 1, 0, 1, 0, 0, 0,
    -1, -1, -1, 0, 0, 1, 0, 0,
    -1, -1, 1, 0, 0, 0, 0, 0,
    // Right
    1, 1, 1, 0, 1, 0, 0, 0,
    1, 1, -1, 0, 1, 1, 0, 0,
    1, -1, 1, 0, 0, 0, 0, 0,
    1, -1, -1, 0, 0, 1, 0, 0,
    // Top
    -1, 1, 1, 0, 0, 0, 0, 0,
    1, 1, 1, 0, 1, 0, 0, 0,
    -1, 1, -1, 0, 0, 1, 0, 0,
    1, 1, -1, 0, 1, 1, 0, 0,
    // Bottom
    1, -1, 1, 0, 1, 0, 0, 0,
    -1, -1, 1, 0, 0, 0, 0, 0,
    1, -1, -1, 0, 1, 1, 0, 0,
    -1, -1, -1, 0, 0, 1, 0, 0,
  ].map((e) => e.toDouble()).toList()), 8);

  // Use vertexBuffer, starting at offset 0, 3 items in position attribute
  var positions = new InterleavedBufferAttribute(vertexBuffer, 3, 0);
  geometry.addAttribute('position', positions);

  // Use vertexBuffer, starting at offset 4, 2 items in uv attribute
  var uvs = new InterleavedBufferAttribute(vertexBuffer, 2, 4);
  geometry.addAttribute('uv', uvs);

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
  instanceBuffer = new InstancedInterleavedBuffer(new Float32List(instances * 8), 8, dynamic: true);
  var offsets = new InterleavedBufferAttribute(instanceBuffer, 3, 0);

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

  orientations = new InterleavedBufferAttribute(instanceBuffer, 4, 4);

  for (var i = 0; i < orientations.count; i++) {
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
      attributes: ['position', 'offset', 'orientation', 'uv']);

  var mesh = new Mesh(geometry, material)
    ..frustumCulled = false;
  scene.add(mesh);

  if (!renderer.supportsInstancedArrays) {
    document.getElementById("notSupported").style.display = "";
    return;
  }

  renderer.setClearColor(0x101010);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  window.onResize.listen((event) {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);
  });
}

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

  for (var i = 0; i < orientations.count; i++) {
    var index = i * instanceBuffer.stride + orientations.offset;
    currentQ.setValues(instanceBuffer.array[index], instanceBuffer.array[index + 1], instanceBuffer.array[index + 2], instanceBuffer.array[index + 3]);
    currentQ.multiply(tmpQ);

    orientations.setXYZW(i, currentQ.x, currentQ.y, currentQ.z, currentQ.w);
  }

  instanceBuffer.needsUpdate = true;
  lastTime = time;
}
