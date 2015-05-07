import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;

final String vertexShader= """
attribute float size;
attribute vec4 ca;

varying vec4 vColor;

void main() {

  vColor = ca;

  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);

  gl_PointSize = size * (150.0 / length(mvPosition.xyz));

  gl_Position = projectionMatrix * mvPosition;

}
""";

final String fragmentShader = """
uniform vec3 color;
uniform sampler2D texture;

varying vec4 vColor;

void main() {
  vec4 outColor = texture2D(texture, gl_PointCoord);

  if (outColor.a < 0.5) discard;

  gl_FragColor = outColor * vec4(color * vColor.xyz, 1.0);

  float depth = gl_FragCoord.z / gl_FragCoord.w;
  const vec3 fogColor = vec3(0.0);

  float fogFactor = smoothstep(200.0, 600.0, depth);
  gl_FragColor = mix(gl_FragColor, vec4(fogColor, gl_FragColor.w), fogFactor);
}
""";

Renderer renderer;
Scene scene;
PerspectiveCamera camera;

PointCloud object;

Map<String, Uniform> uniforms;
Map<String, Attribute> attributes;

int vc1;

math.Random rnd = new math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(40.0, window.innerWidth / window.innerHeight, 1.0, 1000.0);
  camera.position.z = 500.0;

  scene = new Scene();

  attributes = {
    'size': new Attribute.float(),
    'ca': new Attribute.color()
  };

  uniforms = {
    'amplitude': new Uniform.float(1.0),
    'color': new Uniform.color(0xffffff),
    'texture': new Uniform.texture(image_utils.loadTexture("textures/sprites/ball.png")),
  };

  uniforms['texture'].value.wrapS = uniforms['texture'].value.wrapT = RepeatWrapping;

  var shaderMaterial = new ShaderMaterial(
      uniforms: uniforms,
      attributes: attributes,
      vertexShader: vertexShader,
      fragmentShader: fragmentShader);

  var radius = 100.0, inner = 0.6 * radius;
  var geometry = new Geometry();

  for (var i = 0; i < 100000; i ++) {
    var vertex = new Vector3.zero()
      ..x = rnd.nextDouble() * 2 - 1
      ..y = rnd.nextDouble() * 2 - 1
      ..z = rnd.nextDouble() * 2 - 1
      ..scale(radius);

    if ((vertex.x > inner || vertex.x < -inner) ||
         (vertex.y > inner || vertex.y < -inner) ||
         (vertex.z > inner || vertex.z < -inner)) {
      geometry.vertices.add(vertex);
    }

  }

  vc1 = geometry.vertices.length;

  radius = 200.0;
  var geometry2 = new BoxGeometry(radius, 0.1 * radius, 0.1 * radius, 50, 5, 5);

  addGeo(geo, x, y, z, ry) {
    var mesh = new Mesh(geo);
    mesh.position.setValues(x.toDouble(), y.toDouble(), z.toDouble());
    mesh.rotation.y = ry.toDouble();
    mesh.updateMatrix();

    geometry.merge(mesh.geometry, matrix: mesh.matrix);
  }

  // side 1

  addGeo(geometry2, 0,  110,  110, 0);
  addGeo(geometry2, 0,  110, -110, 0);
  addGeo(geometry2, 0, -110,  110, 0);
  addGeo(geometry2, 0, -110, -110, 0);

  // side 2

  addGeo(geometry2,  110,  110, 0, math.PI/2);
  addGeo(geometry2,  110, -110, 0, math.PI/2);
  addGeo(geometry2, -110,  110, 0, math.PI/2);
  addGeo(geometry2, -110, -110, 0, math.PI/2);

  // corner edges

  var geometry3 = new BoxGeometry(0.1 * radius, radius * 1.2, 0.1 * radius, 5, 60, 5);

  addGeo(geometry3,  110, 0,  110, 0);
  addGeo(geometry3,  110, 0, -110, 0);
  addGeo(geometry3, -110, 0,  110, 0);
  addGeo(geometry3, -110, 0, -110, 0);

  // particle system

  object = new PointCloud(geometry, shaderMaterial);

  // custom attributes

  var vertices = object.geometry.vertices;

  var values_size = attributes['size'].value;
  var values_color = attributes['ca'].value;

  values_size.length = values_color.length = vertices.length;

  for (var v = 0; v < vertices.length; v ++) {
    values_size[v] = 10.0;
    values_color[v] = new Color(0xffffff);

    if (v < vc1) {
      values_color[v].setHSL(0.5 + 0.2 * (v / vc1), 1.0, 0.5);
    } else {
      values_size[v] = 55.0;
      values_color[v].setHSL(0.1, 1.0, 0.5);
    }
  }

  scene.add(object);

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
  var time = new DateTime.now().millisecondsSinceEpoch * 0.01;

  object.rotation.y = object.rotation.z = 0.02 * time;

  for(var i = 0; i < attributes['size'].value.length; i ++) {
    if (i < vc1) {
      attributes['size'].value[i] = math.max(0.0, 26.0 + 32.0 * math.sin(0.1 * i + 0.6 * time));
    }
  }

  renderer.render(scene, camera);
}
