import 'dart:html';
import 'dart:math' as math;
import 'dart:convert' show JSON;
import 'package:three/three.dart';
import 'package:three/extras/font_utils.dart' as font_utils;

final String vertexShader = '''
uniform float amplitude;

attribute vec3 displacement;
attribute vec3 customColor;

varying vec3 vColor;

void main() {
  vec3 newPosition = position + amplitude * displacement;

  vColor = customColor;

  gl_Position = projectionMatrix * modelViewMatrix * vec4(newPosition, 1.0);
}
''';

final String fragmentShader = '''
uniform vec3 color;
uniform float opacity;

varying vec3 vColor;

void main() {
  gl_FragColor = vec4(vColor * color, opacity);
}
''';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Line object;
Map<String, Attribute> attributes;
Map<String, Uniform> uniforms;

String text = 'three.dart';
int height = 15;
int size = 50;

int curveSegments = 10;
int steps = 40;

double bevelThickness = 5.0;
double bevelSize = 1.5;
int bevelSegments = 10;
bool bevelEnabled = true;

String font = 'helvetiker'; // helvetiker, optimer, gentilis, droid sans, droid serif
String weight = 'bold'; // normal bold
String style = 'normal'; // normal italic

math.Random rnd = new math.Random();

main() async {
  font_utils.loadFace(JSON.decode(await HttpRequest.getString('fonts/helvetiker_bold.typeface.json')));
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(30.0, window.innerWidth / window.innerHeight, 1.0, 10000.00)
    ..position.z = 400.0;

  scene = new Scene();

  attributes = {
    'displacement': new Attribute.vector3(),
    'customColor': new Attribute.color()
  };

  uniforms = {
    'amplitude': new Uniform.float(5.0),
    'opacity': new Uniform.float(0.3),
    'color': new Uniform.color(0xff0000)
  };

  var shaderMaterial = new ShaderMaterial(
      uniforms: uniforms,
      attributes: attributes,
      vertexShader: vertexShader,
      fragmentShader: fragmentShader,
      blending: AdditiveBlending,
      depthTest: false,
      transparent: true);

  var geometry = new TextGeometry(text,
    size: size,
    height: height,
    curveSegments: curveSegments,

    font: font,
    weight: weight,
    style: style,

    bevelThickness: bevelThickness,
    bevelSize: bevelSize,
    bevelEnabled: bevelEnabled,
    bevelSegments: bevelSegments,

    steps: steps)
    ..center();

  object = new Line(geometry, shaderMaterial);

  var vertices = object.geometry.vertices;

  var displacement = attributes['displacement'].value;
  var color = attributes['customColor'].value;

  for(var v = 0; v < vertices.length; v++) {
    displacement.add(new Vector3.zero());

    color.add(new Color.white()..setHSL(v / vertices.length, 0.5, 0.5));
  }

  object.rotation.x = 0.2;

  scene.add(object);

  renderer = new WebGLRenderer(antialias: true)
    ..setClearColor(0x050505)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);

  document.body.append(renderer.domElement);

  window.onResize.listen((_) {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);
  });
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.001;

  object.rotation.y = 0.25 * time;

  uniforms['amplitude'].value = 0.5 * math.sin(0.5 * time);
  uniforms['color'].value.offsetHSL(0.0005, 0.0, 0.0);

  attributes['displacement'].value.forEach((value) {
    var nx = 0.3 * (0.5 - rnd.nextDouble());
    var ny = 0.3 * (0.5 - rnd.nextDouble());
    var nz = 0.3 * (0.5 - rnd.nextDouble());

    value.x += nx;
    value.y += ny;
    value.z += nz;
  });

  renderer.render(scene, camera);
}
