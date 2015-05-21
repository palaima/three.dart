import 'dart:html';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;

final vertexShader = '''
uniform float amplitude;

attribute float displacement;

varying vec3 vNormal;
varying vec2 vUv;

void main() {
  vNormal = normal;
  vUv = ( 0.5 + amplitude ) * uv + vec2( amplitude );

  vec3 newPosition = position + amplitude * normal * vec3( displacement );
  gl_Position = projectionMatrix * modelViewMatrix * vec4( newPosition, 1.0 );
}
''';

final fragmentShader = '''
varying vec3 vNormal;
varying vec2 vUv;

uniform vec3 color;
uniform sampler2D texture;

void main() {
  vec3 light = vec3( 0.5, 0.2, 1.0 );
  light = normalize( light );

  float dProd = dot( vNormal, light ) * 0.5 + 0.5;

  vec4 tcolor = texture2D( texture, vUv );
  vec4 gray = vec4( vec3( tcolor.r * 0.3 + tcolor.g * 0.59 + tcolor.b * 0.11 ), 1.0 );

  gl_FragColor = gray * vec4( vec3( dProd ) * vec3( color ), 1.0 );
}
''';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Map<String, Uniform> uniforms;

Mesh sphere;

List<double> noise = [];
Float32List displacement;
DynamicBufferAttribute displacementAttribute;

Function random = new math.Random().nextDouble;

void init() {
  camera = new PerspectiveCamera(30.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 300.0;

  scene = new Scene();

  uniforms = {
    'amplitude': new Uniform.float(1.0),
    'color': new Uniform.color(0xff2200),
    'texture': new Uniform.texture(image_utils.loadTexture('textures/water.jpg'))
  };

  uniforms['texture'].value.wrapS = uniforms['texture'].value.wrapT = RepeatWrapping;

  var shaderMaterial = new ShaderMaterial(
      uniforms: uniforms, attributes: ['displacement'], vertexShader: vertexShader, fragmentShader: fragmentShader);

  var radius = 50.0,
      segments = 128,
      rings = 64;

  var geometry = new SphereBufferGeometry(radius, segments, rings);

  var positions = geometry.aPosition;
  var vertexCount = positions.count;

  displacement = new Float32List(vertexCount);
  noise = new Float32List(vertexCount);

  for (var v = 0; v < displacement.length; v++) {
    displacement[v] = 0.0;
    noise[v] = random() * 5;
  }

  displacementAttribute = new DynamicBufferAttribute(displacement, 1);

  geometry.addAttribute('displacement', displacementAttribute);

  sphere = new Mesh(geometry, shaderMaterial);

  scene.add(sphere);

  renderer = new WebGLRenderer()
    ..setClearColor(0x050505)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.01;

  sphere.rotation.y = sphere.rotation.z = 0.01 * time;

  uniforms['amplitude'].value = 2.5 * math.sin(sphere.rotation.y * 0.125);
  uniforms['color'].value.offsetHSL(0.0005, 0.0, 0.0);

  for (var i = 0; i < displacement.length; i++) {
    displacement[i] = math.sin(0.1 * i + time);

    noise[i] += 0.5 * (0.5 - random());
    noise[i] = noise[i].clamp(-5.0, 5.0);

    displacement[i] += noise[i];
  }

  displacementAttribute.needsUpdate = true;

  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
