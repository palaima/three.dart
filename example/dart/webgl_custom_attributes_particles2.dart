import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as ImageUtils;

final String vertexShader= """
attribute float size;
attribute vec3 ca;

varying vec3 vColor;

void main() {
  vColor = ca;

  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);

  //gl_PointSize = size;
  gl_PointSize = size * (300.0 / length(mvPosition.xyz));

  gl_Position = projectionMatrix * mvPosition;
}

""";

final String fragmentShader = """
uniform vec3 color;
uniform sampler2D texture;

varying vec3 vColor;

void main() {
  vec4 color = vec4(color * vColor, 1.0) * texture2D(texture, gl_PointCoord);

  if (color.w < 0.5) discard;

  gl_FragColor = color;
}

""";

Renderer renderer;
PerspectiveCamera camera;

Map<String, Attribute> attributes;
Map<String, Uniform> uniforms;

PointCloud sphere;

int vc1;

Scene scene = new Scene();

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(45.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 300.0;

  scene = new Scene();

  attributes = {'size': new Attribute.float(), 'ca': new Attribute.color()};

  uniforms = {
    'amplitude': new Uniform.float(1.0),
    'color': new Uniform.color(0xffffff),
    'texture': new Uniform.texture(ImageUtils.loadTexture("textures/sprites/disc.png"))
  };

  uniforms['texture'].value.wrapS = uniforms['texture'].value.wrapT = RepeatWrapping;

  var shaderMaterial = new ShaderMaterial(
      uniforms: uniforms,
      attributes: attributes,
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
      transparent: true
 );


  var radius = 100.0, segments = 68, rings = 38;
  var geometry = new SphereGeometry(radius, segments, rings);

  vc1 = geometry.vertices.length;

  var geometry2 = new BoxGeometry(0.8 * radius, 0.8 * radius, 0.8 * radius, 10, 10, 10);
  geometry.merge(geometry2);

  sphere = new PointCloud(geometry, shaderMaterial);

  var vertices = sphere.geometry.vertices;
  var values_size = attributes['size'].value;
  var values_color = attributes['ca'].value;

  values_size.length = values_color.length = vertices.length;

  for (var v = 0; v < vertices.length; v ++) {
    values_size[v] = 10.0;
    values_color[v] = new Color(0xffffff);

    if (v < vc1) {
      values_color[v].setHSL(0.01 + 0.1 * (v / vc1), 0.99, (vertices[v].y + radius) / (4 * radius));
    } else {
      values_size[v] = 40.0;
      values_color[v].setHSL(0.6, 0.75, 0.25 + vertices[v].y / (2 * radius));
    }
  }

  scene.add(sphere);

  renderer = new WebGLRenderer()
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);


  window.onResize.listen(onWindowResize);
}

void onWindowResize(event) {
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

  sphere.rotation.y = 0.02 * time;
  sphere.rotation.z = 0.02 * time;

  for(var i = 0; i < attributes['size'].value.length; i ++) {
    if (i < vc1) {
      attributes['size'].value[i] = 16 + 12 * Math.sin(0.1 * i + time);
    }
  }

  renderer.render(scene, camera);
}
