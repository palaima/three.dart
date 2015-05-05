import 'dart:html';
import 'dart:typed_data';
import 'dart:math' as Math;
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Line mesh;

Object3D parentNode;

Math.Random rnd = new Math.Random();

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(27.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 9000.0;

  scene = new Scene();

  var geometry = new BufferGeometry();
  var material = new LineBasicMaterial(vertexColors: VertexColors);

  var positions = [];
  var nextPositionsIndex = 0;
  var colors = [];
  var indicesArray = [];

  //

  var iterationCount = 4;
  var rangle = 60 * Math.PI / 180.0;

  add_vertex(v) {
    if (nextPositionsIndex == 0xffff) throw new Exception("Too many points");

    positions.addAll([v.x, v.y, v.z]);
    colors.addAll([rnd.nextDouble() * 0.5 + 0.5, rnd.nextDouble() * 0.5 + 0.5, 1.0]);
    return nextPositionsIndex++;
  }

  // simple Koch curve
  snowflake_iteration(p0, p4, depth) {
    if (--depth < 0) {
      var i = nextPositionsIndex - 1; // p0 already there
      add_vertex(p4);
      indicesArray.addAll([i, i + 1]);
      return;
    }

    var v = p4 - p0;
    var vTier = v * (1.0 / 3.0);
    var p1 = p0 + vTier;

    var angle = Math.atan2(v.y, v.x) + rangle;
    var length = vTier.length;
    var p2 = p1.clone();

    p2.x += Math.cos(angle) * length;
    p2.y += Math.sin(angle) * length;

    var p3 = p0 + vTier + vTier;

    snowflake_iteration(p0, p1, depth);
    snowflake_iteration(p1, p2, depth);
    snowflake_iteration(p2, p3, depth);
    snowflake_iteration(p3, p4, depth);
  }

  snowflake(points, {loop, xOffset}) {
    for (var iteration = 0; iteration != iterationCount; ++iteration) {

      add_vertex(points[0]);

      for (var pIndex = 0; pIndex != points.length - 1; ++pIndex) {
        snowflake_iteration(points[pIndex], points[pIndex + 1], iteration);
      }

      if (loop) {
        snowflake_iteration(points[points.length - 1], points[0], iteration);
      }

      // translate input curve for next iteration
      for (var pIndex = 0; pIndex != points.length; ++pIndex) {
        points[pIndex].x += xOffset;
      }

    }
  }

  var y = 0.0;
  snowflake([
    new Vector3(0.0  , y + 0.0, 0.0),
    new Vector3(500.0, y + 0.0, 0.0)],
    loop: false, xOffset: 600);

  y += 600;
  snowflake([
    new Vector3(0.0  , y + 0.0  , 0.0),
    new Vector3(250.0, y + 400.0, 0.0),
    new Vector3(500.0, y + 0.0  , 0.0)],
    loop: true, xOffset: 600);

  y += 600;
  snowflake([
    new Vector3(0.0  , y + 0  , 0.0),
    new Vector3(500.0, y      , 0.0),
    new Vector3(500.0, y + 500, 0.0),
    new Vector3(0.0  , y + 500, 0.0)],
    loop: true, xOffset: 600);

  y += 1000;
  snowflake([
    new Vector3(250.0, y + 0  , 0.0),
    new Vector3(500.0, y + 0  , 0.0),
    new Vector3(250.0, y + 0  , 0.0),
    new Vector3(250.0, y + 250, 0.0),
    new Vector3(250.0, y + 0  , 0.0),
    new Vector3(0.0  , y      , 0.0),
    new Vector3(250.0, y + 0  , 0.0),
    new Vector3(250.0, y - 250, 0.0),
    new Vector3(250.0, y + 0  , 0.0)],
    loop: false, xOffset: 600);
  // --------------------------------

  geometry.aIndex = new BufferAttribute(new Uint16List.fromList(indicesArray), 1);
  geometry.aPosition = new BufferAttribute(new Float32List.fromList(positions), 3);
  geometry.aColor = new BufferAttribute(new Float32List.fromList(colors), 3);
  geometry.computeBoundingSphere();

  mesh = new LineSegments(geometry, material)
    ..position.x -= 1200.0
    ..position.y -= 1200.0;

  parentNode = new Object3D();
  parentNode.add(mesh);

  scene.add(parentNode);

  //

  renderer = new WebGLRenderer(antialias: false)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)

    ..gammaInput = true
    ..gammaOutput = true;

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

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.001;

  //mesh.rotation.x = time * 0.25;
  //mesh.rotation.y = time * 0.5;
  parentNode.rotation.z = time * 0.5;

  renderer.render(scene, camera);
}
