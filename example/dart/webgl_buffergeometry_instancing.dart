import 'dart:html';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'package:three/three.dart';

final vertexShader = '''
precision highp float;

uniform float sineTime;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

attribute vec3 position;
attribute vec3 offset;
attribute vec4 color;
attribute vec4 orientationStart;
attribute vec4 orientationEnd;

varying vec3 vPosition;
varying vec4 vColor;

void main() {
  vPosition = offset * max(abs(sineTime * 2.0 + 1.0), 0.5) + position;
  vec4 orientation = normalize(mix(orientationStart, orientationEnd, sineTime));
  vec3 vcV = cross(orientation.xyz, vPosition);
  vPosition = vcV * (2.0 * orientation.w) + (cross(orientation.xyz, vcV) * 2.0 + vPosition);
  
  vColor = color;
  
  gl_Position = projectionMatrix * modelViewMatrix * vec4(vPosition, 1.0);
}
''';

final fragmentShader = '''
precision highp float;

uniform float time;

varying vec3 vPosition;
varying vec4 vColor;

void main() {
  vec4 color = vec4(vColor);
  color.r += sin(vPosition.x * 10.0 + time) * 0.5;
  
  gl_FragColor = color;
}
''';

var container, stats;

var camera, scene, renderer;

Math.Random rnd = new Math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(50.0, window.innerWidth / window.innerHeight, 1.0, 10.0)
    ..position.z = 2.0;

  scene = new Scene();

  // geometry

  var triangles = 1;
  var instances = 20000; // 65000

  var geometry = new InstancedBufferGeometry();

  geometry.maxInstancedCount = instances; // set so its initalized for dat.GUI, will be set in first draw otherwise

//  var gui = new dat.GUI();
//  gui.add(geometry, "maxInstancedCount", 0, 65000);

  var vertices = new BufferAttribute.float32(triangles * 3 * 3 , 3);

  vertices.setXYZ(0, 0.025, -0.025, 0.0);
  vertices.setXYZ(1, -0.025, 0.025, 0.0);
  vertices.setXYZ(2, 0.0, 0.0, 0.025);

  geometry.addAttribute('position', vertices);

  var offsets = new InstancedBufferAttribute(new Float32List(instances * 3), 3);

  for (var i = 0; i < offsets.length; i++) {
    offsets.setXYZ(i, rnd.nextDouble() - 0.5, rnd.nextDouble() - 0.5, rnd.nextDouble() - 0.5);
  }

  geometry.addAttribute('offset', offsets);

  var colors = new InstancedBufferAttribute(new Float32List(instances * 4), 4);

  for (var i = 0; i <  colors.length; i++) {
    colors.setXYZW(i, rnd.nextDouble(), rnd.nextDouble(), rnd.nextDouble(), rnd.nextDouble());
  }

  geometry.aColor = colors;

  var vector = new Vector4.zero();

  var orientationsStart = new InstancedBufferAttribute(new Float32List(instances * 4), 4);

  for (var i = 0; i < orientationsStart.length; i++) {
    vector.setValues(rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1,
        rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1);
    vector.normalize();

    orientationsStart.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
  }

  geometry.addAttribute('orientationStart', orientationsStart);

  var orientationsEnd = new InstancedBufferAttribute(new Float32List(instances * 4), 4);

  for (var i = 0; i < orientationsEnd.length; i++) {
    vector.setValues(rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1, rnd.nextDouble() * 2 - 1);
    vector.normalize();

    orientationsEnd.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
  }

  geometry.addAttribute('orientationEnd', orientationsEnd);

  // material

  var material = new RawShaderMaterial(
      uniforms: {
        'time': new Uniform.float(1.0),
        'sineTime': new Uniform.float(1.0)
      },
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
      side: DoubleSide,
      transparent: true,
      attributes: {'position': 0, 'offset': 1, 'color': 2, 'orientationStart': 3, 'orientationEnd': 4}
  );

  var mesh = new Mesh(geometry, material);
  scene.add(mesh);

  renderer = new WebGLRenderer();

//  if (!renderer.supportsInstancedArrays) {
//      document.getElementById("notSupported").style.display = "";
//      return;
//  }

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

var lastTime = 0;

void render() {
  var time = window.performance.now();

  var object = scene.children[0];

  object.rotation.y = time * 0.0005;
  object.material.uniforms['time'].value = time * 0.005;
  object.material.uniforms['sineTime'].value = Math.sin(object.material.uniforms['time'].value * 0.05);

  renderer.render(scene, camera);

  lastTime = time;
}
