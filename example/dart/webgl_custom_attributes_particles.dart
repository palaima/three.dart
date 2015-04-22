import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as ImageUtils;

final vertexShader = r'''
uniform float amplitude;
attribute float size;
attribute vec3 customColor;

varying vec3 vColor;

void main() {
  vColor = customColor;

  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);

  //gl_PointSize = size;
  gl_PointSize = size * (300.0 / length(mvPosition.xyz));

  gl_Position = projectionMatrix * mvPosition;
}
''';

final fragmentShader = r'''
uniform vec3 color;
uniform sampler2D texture;

varying vec3 vColor;

void main() {
  gl_FragColor = vec4(color * vColor, 1.0);
  gl_FragColor = gl_FragColor * texture2D(texture, gl_PointCoord);
}
''';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

PointCloud sphere;

Map<String, Uniform> uniforms;
Uniform amplitude, color;

Map<String, Attribute> attributes;
Attribute size, customColor;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(40.0, window.innerWidth / window.innerHeight, 1.0, 10000.00)
    ..position.z = 300.0;

  scene = new Scene();

  size = new Attribute.float();
  customColor = new Attribute.color();

  attributes = {
    "size": size,
    "customColor": customColor
  };

  amplitude = new Uniform.float(1.0);
  color = new Uniform.color(0xffffff);

  uniforms = {
    "amplitude": amplitude,
    "color": color,
    "texture": new Uniform.texture(ImageUtils.loadTexture("textures/sprites/spark1.png"))
  };

  var shaderMaterial = new ShaderMaterial(
      uniforms: uniforms,
      attributes: attributes,
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
      blending: AdditiveBlending,
      depthTest: false,
      transparent: true);

  var radius = 200.0;
  var geometry = new Geometry();

  var rnd = new Math.Random();

  for (var i = 0; i < 100000; i++) {
    var vertex = new Vector3.zero()
      ..x = rnd.nextDouble() * 2 - 1
      ..y = rnd.nextDouble() * 2 - 1
      ..z = rnd.nextDouble() * 2 - 1
      ..scale(radius);

    geometry.vertices.add(vertex);
  }

  sphere = new PointCloud(geometry, shaderMaterial);

  var vertices = (sphere.geometry as Geometry).vertices;

  for (var v = 0; v < vertices.length; v++) {

    size.value.add(10.0);
    customColor.value.add(new Color(0xffaa00));

    if (vertices[v].x < 0) {
      customColor.value[v].setHSL(0.5 + 0.1 * (v / vertices.length), 0.7, 0.5);
    } else {
      customColor.value[v].setHSL(0.0 + 0.1 * (v / vertices.length), 0.9, 0.5);
    }
  }

  scene.add(sphere);

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);

  document.body.append(renderer.domElement);

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
  var time = new DateTime.now().millisecondsSinceEpoch * 0.005;

  sphere.rotation.z = 0.01 * time;

  for (var i = 0; i < size.value.length; i++) {
    size.value[i] = 14 + 13 * Math.sin(0.1 * i + time);
  }

  size.needsUpdate = true;

  renderer.render(scene, camera);
}
