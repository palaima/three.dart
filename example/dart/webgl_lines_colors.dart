import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';
import 'package:three/extras/postprocessing.dart';
import 'package:three/extras/shaders.dart' as shaders;

ShaderPass effectFXAA;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;
LineBasicMaterial material;
EffectComposer composer;

num mouseX = 0, mouseY = 0,

windowHalfX = window.innerWidth / 2,
windowHalfY = window.innerHeight / 2;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(33.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 700.0;

  scene = new Scene();

  renderer = new WebGLRenderer(antialias: false)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..autoClear = false;

  document.body.append(renderer.domElement);

  var geometry = new Geometry(),
      geometry2 = new Geometry(),
      geometry3 = new Geometry(),
      points = hilbert3D(new Vector3.zero(), 200.0, 2, 0, 1, 2, 3, 4, 5, 6, 7),
      colors = [], colors2 = [], colors3 = [];

  for (var i = 0; i < points.length; i ++) {
    geometry.vertices.add(points[i]);

    colors.add(new Color.fromHSL(0.6, 1.0, math.max(0, (200 - points[i].x) / 400) * 0.5 + 0.5));
    colors2.add(new Color.fromHSL(0.3, 1.0, math.max(0, (200 + points[i].x) / 400) * 0.5));
    colors3.add(new Color.fromHSL(i / points.length, 1.0, 0.5));
  }

  geometry2.vertices = geometry3.vertices = geometry.vertices;

  geometry.colors = colors;
  geometry2.colors = colors2;
  geometry3.colors = colors3;

  // lines

  material = new LineBasicMaterial(color: 0xffffff, opacity: 1.0, linewidth: 3.0, vertexColors: VertexColors);

  var line, scale = 0.3, d = 225.0;
  var parameters = [
    [material, scale * 1.5, [-d, 0.0, 0.0], geometry],
    [material, scale * 1.5, [0.0, 0.0, 0.0], geometry2],
    [material, scale * 1.5, [d, 0.0, 0.0], geometry3]
  ];

  parameters.forEach((p) {
    scene.add(new Line(p[3],  p[0])
      ..scale.splat(p[1])
      ..position.x = p[2][0]
      ..position.y = p[2][1]
      ..position.z = p[2][2]);
  });

  var renderModel = new RenderPass(scene, camera);
  var effectBloom = new BloomPass(strength: 1.3);
  var effectCopy = new ShaderPass(shaders.copy);

  effectFXAA = new ShaderPass(shaders.fxaa);

  var width = window.innerWidth; // || 2
  var height = window.innerHeight; // || 2

  effectFXAA.uniforms['resolution'].value.setValues(1 / width, 1 / height);

  effectCopy.renderToScreen = true;

  composer = new EffectComposer(renderer);

  composer.addPass(renderModel);
  composer.addPass(effectFXAA);
  composer.addPass(effectBloom);
  composer.addPass(effectCopy);

  window.onResize.listen((event) {
    windowHalfX = window.innerWidth / 2;
    windowHalfY = window.innerHeight / 2;

    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);

    effectFXAA.uniforms['resolution'].value.setValues(1 / window.innerWidth, 1 / window.innerHeight);

    composer.reset();
  });

  document.onMouseMove.listen((event) {
    mouseX = event.client.x - windowHalfX;
    mouseY = event.client.y - windowHalfY;
  });

  document.onTouchStart.listen((event) {
    if (event.touches.length > 1) {
      event.preventDefault();

      mouseX = event.touches[0].page.x - windowHalfX;
      mouseY = event.touches[0].page.y - windowHalfY;
    }
  });

  document.onTouchMove.listen((event) {
    if (event.touches.length == 1) {
      event.preventDefault();

      mouseX = event.touches[0].page.x - windowHalfX;
      mouseY = event.touches[0].page.y - windowHalfY;
    }
  });
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  camera.position.x += (mouseX - camera.position.x) * .05;
  camera.position.y += (-mouseY + 200 - camera.position.y) * .05;

  camera.lookAt(scene.position);

  var time = new DateTime.now().millisecondsSinceEpoch * 0.0005;

  for (var i = 0; i < scene.children.length; i ++) {
    var object = scene.children[i];

    if (object is Line) {
      object.rotation.y = time * (i % 2 != 0 ? 1.0 : -1.0);
    }
  }

  renderer.clear();
  composer.render();
}


/**
 * Hilbert Curve: Generates 2D-Coordinates in a very fast way.
 *
 * @author Dylan Grafmyre
 *
 * Based on work by:
 * @author Thomas Diewald
 * @link http://www.openprocessing.org/visuals/?visualID=15599
 *
 * Based on `examples/canvas_lines_colors.html`:
 * @author OpenShift guest
 * @link https://github.com/mrdoob/three.js/blob/8413a860aa95ed29c79cbb7f857c97d7880d260f/examples/canvas_lines_colors.html
 * @see  Line 149 - 186
 *
 * @param center     Center of Hilbert curve.
 * @param size       Total width of Hilbert curve.
 * @param iterations Number of subdivisions.
 * @param v0         Corner index -X, +Y, -Z.
 * @param v1         Corner index -X, +Y, +Z.
 * @param v2         Corner index -X, -Y, +Z.
 * @param v3         Corner index -X, -Y, -Z.
 * @param v4         Corner index +X, -Y, -Z.
 * @param v5         Corner index +X, -Y, +Z.
 * @param v6         Corner index +X, +Y, +Z.
 * @param v7         Corner index +X, +Y, -Z.
 */
List<Vector> hilbert3D(Vector3 center, [size = 10, iterations = 1, v0 = 0, v1 = 1, v2 = 2, v3 = 3, v4 = 4, v5 = 5, v6 = 6, v7 = 7]) {
  center = center != null ? center : new Vector3.zero();
  var half = size / 2;

  var vec_s = [
    new Vector3(center.x - half, center.y + half, center.z - half),
    new Vector3(center.x - half, center.y + half, center.z + half),
    new Vector3(center.x - half, center.y - half, center.z + half),
    new Vector3(center.x - half, center.y - half, center.z - half),
    new Vector3(center.x + half, center.y - half, center.z - half),
    new Vector3(center.x + half, center.y - half, center.z + half),
    new Vector3(center.x + half, center.y + half, center.z + half),
    new Vector3(center.x + half, center.y + half, center.z - half)
 ];

  var vec = [
    vec_s[v0],
    vec_s[v1],
    vec_s[v2],
    vec_s[v3],
    vec_s[v4],
    vec_s[v5],
    vec_s[v6],
    vec_s[v7]
  ];

  // Recurse iterations
  if (--iterations >= 0) {
    var tmp = []
      ..addAll(hilbert3D(vec[0], half, iterations, v0, v3, v4, v7, v6, v5, v2, v1))
      ..addAll(hilbert3D(vec[1], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3))
      ..addAll(hilbert3D(vec[2], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3))
      ..addAll(hilbert3D(vec[3], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5))
      ..addAll(hilbert3D(vec[4], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5))
      ..addAll(hilbert3D(vec[5], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7))
      ..addAll(hilbert3D(vec[6], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7))
      ..addAll(hilbert3D(vec[7], half, iterations, v6, v5, v2, v1, v0, v3, v4, v7));

    // Return recursive call
    return tmp;
  }

  // Return complete Hilbert Curve.
  return vec;
}
