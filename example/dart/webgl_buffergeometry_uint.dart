import 'dart:html';
import 'dart:typed_data' show Float32List, Uint32List;
import 'dart:math' as math;
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Mesh mesh;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(27.0, window.innerWidth / window.innerHeight, 1.0, 3500.0);
  camera.position.z = 2750.0;

  scene = new Scene();
  scene.fog = new FogLinear(0x050505, 2000.0, 3500.0);

  //

  scene.add(new AmbientLight(0x444444));

  scene.add(new DirectionalLight(0xffffff, 0.5)
    ..position.splat(1.0));

  scene.add(new DirectionalLight(0xffffff, 1.5)
    ..position.setValues(0.0, -1.0, 0.0));

  //

  var triangles = 160000;

  var geometry = new BufferGeometry();

  var indices = new Uint32List(triangles * 3);

  for (var i = 0; i < indices.length; i++) {
    indices[i] = i;
  }

  var positions = new Float32List(triangles * 3 * 3);
  var normals = new Float32List(triangles * 3 * 3);
  var colors = new Float32List(triangles * 3 * 3);

  var color = new Color.white();

  var n = 800, n2 = n / 2;  // triangles spread in the cube
  var d = 12, d2 = d / 2; // individual triangle size

  var pA = new Vector3.zero();
  var pB = new Vector3.zero();
  var pC = new Vector3.zero();

  var random = new math.Random().nextDouble;

  for (var i = 0; i < positions.length; i += 9) {
    // positions
    var x = random() * n - n2;
    var y = random() * n - n2;
    var z = random() * n - n2;

    var ax = x + random() * d - d2;
    var ay = y + random() * d - d2;
    var az = z + random() * d - d2;

    var bx = x + random() * d - d2;
    var by = y + random() * d - d2;
    var bz = z + random() * d - d2;

    var cx = x + random() * d - d2;
    var cy = y + random() * d - d2;
    var cz = z + random() * d - d2;

    positions[i]     = ax;
    positions[i + 1] = ay;
    positions[i + 2] = az;

    positions[i + 3] = bx;
    positions[i + 4] = by;
    positions[i + 5] = bz;

    positions[i + 6] = cx;
    positions[i + 7] = cy;
    positions[i + 8] = cz;

    // flat face normals

    pA.setValues(ax, ay, az);
    pB.setValues(bx, by, bz);
    pC.setValues(cx, cy, cz);

    var cb = pC - pB;
    var ab = pA - pB;
    cb = cb.cross(ab);

    cb.normalize();

    var nx = cb.x;
    var ny = cb.y;
    var nz = cb.z;

    normals[i]     = nx;
    normals[i + 1] = ny;
    normals[i + 2] = nz;

    normals[i + 3] = nx;
    normals[i + 4] = ny;
    normals[i + 5] = nz;

    normals[i + 6] = nx;
    normals[i + 7] = ny;
    normals[i + 8] = nz;

    // colors

    var vx = (x / n) + 0.5;
    var vy = (y / n) + 0.5;
    var vz = (z / n) + 0.5;

    color.setRGB(vx, vy, vz);

    colors[i]     = color.r;
    colors[i + 1] = color.g;
    colors[i + 2] = color.b;

    colors[i + 3] = color.r;
    colors[i + 4] = color.g;
    colors[i + 5] = color.b;

    colors[i + 6] = color.r;
    colors[i + 7] = color.g;
    colors[i + 8] = color.b;
  }

  geometry.addAttribute('index', new BufferAttribute(indices, 1));
  geometry.addAttribute('position', new BufferAttribute(positions, 3));
  geometry.addAttribute('normal', new BufferAttribute(normals, 3));
  geometry.addAttribute('color', new BufferAttribute(colors, 3));

  geometry.computeBoundingSphere();

  var material = new MeshPhongMaterial(
    color: 0xaaaaaa, specular: 0xffffff, shininess: 250.0,
    side: DoubleSide, vertexColors: VertexColors
 );

  mesh = new Mesh(geometry, material);
  scene.add(mesh);

  renderer = new WebGLRenderer()
    ..setClearColor(0x101010)
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

  mesh.rotation.x = time * 0.25;
  mesh.rotation.y = time * 0.5;

  renderer.render(scene, camera);
}
