import 'dart:html';
import 'dart:typed_data' show Float32List;
import 'dart:math' as math;
import 'package:three/three.dart';

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Raycaster raycaster = new Raycaster();

Vector2 mouse = new Vector2.zero();

Mesh mesh;
Line line;

void init() {
  camera = new PerspectiveCamera(27.0, window.innerWidth / window.innerHeight, 1.0, 3500.0);
  camera.position.z = 2750.0;

  scene = new Scene()..fog = new FogLinear(0x050505, 2000.0, 3500.0);

  //

  scene.add(new AmbientLight(0x444444));

  scene.add(new DirectionalLight(0xffffff, 0.5)
    ..position.splat(1.0));

  scene.add(new DirectionalLight(0xffffff, 1.5)
    ..position.setValues(0.0, -1.0, 0.0));

  //

  var triangles = 5000;

  var geometry = new BufferGeometry();

  var positions = new Float32List(triangles * 3 * 3);
  var normals = new Float32List(triangles * 3 * 3);
  var colors = new Float32List(triangles * 3 * 3);

  var color = new Color.white();

  var n = 800,
      n2 = n / 2; // triangles spread in the cube
  var d = 120,
      d2 = d / 2; // individual triangle size

  var pA = new Vector3.zero();
  var pB = new Vector3.zero();
  var pC = new Vector3.zero();

  var cb = new Vector3.zero();
  var ab = new Vector3.zero();

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

    positions[i] = ax;
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

    cb.subVectors(pC, pB);
    ab.subVectors(pA, pB);
    cb.crossVectors(cb, ab);

    cb.normalize();

    var nx = cb.x;
    var ny = cb.y;
    var nz = cb.z;

    normals[i] = nx;
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

    colors[i] = color.r;
    colors[i + 1] = color.g;
    colors[i + 2] = color.b;

    colors[i + 3] = color.r;
    colors[i + 4] = color.g;
    colors[i + 5] = color.b;

    colors[i + 6] = color.r;
    colors[i + 7] = color.g;
    colors[i + 8] = color.b;
  }

  geometry.addAttribute('position', new BufferAttribute(positions, 3));
  geometry.addAttribute('normal', new BufferAttribute(normals, 3));
  geometry.addAttribute('color', new BufferAttribute(colors, 3));

  geometry.computeBoundingSphere();

  var material = new MeshPhongMaterial(
      color: 0xaaaaaa, specular: 0xffffff, shininess: 250.0, side: DoubleSide, vertexColors: VertexColors);

  mesh = new Mesh(geometry, material);
  scene.add(mesh);

  //

  var geometry2 = new BufferGeometry()
    ..addAttribute('position', new BufferAttribute(new Float32List(4 * 3), 3));

  var material2 = new LineBasicMaterial(color: 0xffffff, linewidth: 2.0, transparent: true);

  line = new Line(geometry2, material2);
  scene.add(line);

  //

  renderer = new WebGLRenderer(antialias: false)
    ..setClearColor(scene.fog.color)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  window.onResize.listen(onWindowResize);
  document.onMouseMove.listen(onDocumentMouseMove);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void onDocumentMouseMove(MouseEvent event) {
  event.preventDefault();

  mouse.x = (event.client.x / window.innerWidth) * 2 - 1;
  mouse.y = -(event.client.y / window.innerHeight) * 2 + 1;
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.001;

  mesh.rotation.x = time * 0.15;
  mesh.rotation.y = time * 0.25;

  raycaster.setFromCamera(mouse, camera);

  var intersects = raycaster.intersectObject(mesh);

  if (intersects.length > 0) {
    var intersect = intersects[0];
    var face = intersect.face;

    var linePosition = (line.geometry as BufferGeometry).attributes['position'];
    var meshPosition = (mesh.geometry as BufferGeometry).attributes['position'];

    linePosition.copyAt(0, meshPosition, face.a);
    linePosition.copyAt(1, meshPosition, face.b);
    linePosition.copyAt(2, meshPosition, face.c);
    linePosition.copyAt(3, meshPosition, face.a);

    mesh.updateMatrix();

    line.geometry.applyMatrix(mesh.matrix);

    line.visible = true;
  } else {
    line.visible = false;
  }

  renderer.render(scene, camera);
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
