import 'dart:html';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three/three.dart';
import 'package:three/extras/helpers.dart' show BoxHelper;
import 'package:three/extras/controls.dart';

Group group;
List<Map> particlesData = [];

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Float32List positions, colors;

PointCloud pointCloud;

Float32List particlePositions;
LineSegments linesMesh;

int maxParticleCount = 1000;
int particleCount = 500;
double r = 800.0;
double rHalf = r / 2;

OrbitControls controls;

Map effectController = {
  'showDots': true,
  'showLines': true,
  'minDistance': 150,
  'limitConnections': false,
  'maxConnections': 20,
  'particleCount': 500
};

void init() {
  //initGUI() TODO

  camera = new PerspectiveCamera(45.0, window.innerWidth / window.innerHeight, 1.0, 4000.0);
  camera.position.z = 1750.0;

  controls = new OrbitControls(camera);

  scene = new Scene();

  group = new Group();
  scene.add(group);

  var helper = new BoxHelper(new Mesh(new BoxGeometry(r, r, r)));
  helper.material.color.setHex(0x080808);
  helper.material.blending = AdditiveBlending;
  helper.material.transparent = true;
  group.add(helper);

  var segments = maxParticleCount * maxParticleCount;

  positions = new Float32List(segments * 3);
  colors = new Float32List(segments * 3);

  var pMaterial = new PointCloudMaterial(
      color: 0xFFFFFF, size: 3.0, blending: AdditiveBlending, transparent: true, sizeAttenuation: false);

  var particles = new BufferGeometry();
  particlePositions = new Float32List(maxParticleCount * 3);

  var random = new math.Random().nextDouble;
  for (var i = 0; i < maxParticleCount; i++) {
    var x = random() * r - r / 2;
    var y = random() * r - r / 2;
    var z = random() * r - r / 2;

    particlePositions[i * 3] = x;
    particlePositions[i * 3 + 1] = y;
    particlePositions[i * 3 + 2] = z;

    // add it to the geometry
    particlesData.add({
      'velocity': new Vector3(-1 + random() * 2, -1 + random() * 2, -1 + random() * 2),
      'numConnections': 0
    });
  }

  particles.drawcalls.add(new DrawCall(start: 0, count: particleCount, index: 0));

  particles.addAttribute('position', new DynamicBufferAttribute(particlePositions, 3));

  // create the particle system
  pointCloud = new PointCloud(particles, pMaterial);
  group.add(pointCloud);

  var geometry = new BufferGeometry()
    ..addAttribute('position', new DynamicBufferAttribute(positions, 3))
    ..addAttribute('color', new DynamicBufferAttribute(colors, 3))
    ..computeBoundingSphere()
    ..drawcalls.add(new DrawCall(start: 0, count: 0, index: 0));

  var material =
      new LineBasicMaterial(vertexColors: VertexColors, blending: AdditiveBlending, transparent: true);

  linesMesh = new LineSegments(geometry, material);
  group.add(linesMesh);

  //

  renderer = new WebGLRenderer(antialias: true)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(window.innerWidth, window.innerHeight)
    ..gammaInput = true
    ..gammaOutput = true;

  document.body.append(renderer.domElement);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void animate(num time) {
  var vertexpos = 0;
  var colorpos = 0;
  var numConnected = 0;

  for (var i = 0; i < particleCount; i++) {
    particlesData[i]['numConnections'] = 0;
  }

  for (var i = 0; i < particleCount; i++) {

    // get the particle
    var particleData = particlesData[i];

    particlePositions[i * 3] += particleData['velocity'].x;
    particlePositions[i * 3 + 1] += particleData['velocity'].y;
    particlePositions[i * 3 + 2] += particleData['velocity'].z;

    if (particlePositions[i * 3 + 1] < -rHalf || particlePositions[i * 3 + 1] > rHalf) particleData[
        'velocity'].y = -particleData['velocity'].y;

    if (particlePositions[i * 3] < -rHalf || particlePositions[i * 3] > rHalf) particleData['velocity'].x =
        -particleData['velocity'].x;

    if (particlePositions[i * 3 + 2] < -rHalf || particlePositions[i * 3 + 2] > rHalf) particleData[
        'velocity'].z = -particleData['velocity'].z;

    if (effectController['limitConnections'] &&
        particleData['numConnections'] >= effectController['maxConnections']) {
      continue;
    }

    // Check collision
    for (var j = i + 1; j < particleCount; j++) {
      var particleDataB = particlesData[j];
      if (effectController['limitConnections'] &&
          particleDataB['numConnections'] >= effectController['maxConnections']) {
        continue;
      }

      var dx = particlePositions[i * 3] - particlePositions[j * 3];
      var dy = particlePositions[i * 3 + 1] - particlePositions[j * 3 + 1];
      var dz = particlePositions[i * 3 + 2] - particlePositions[j * 3 + 2];
      var dist = math.sqrt(dx * dx + dy * dy + dz * dz);

      if (dist < effectController['minDistance']) {
        particleData['numConnections']++;
        particleDataB['numConnections']++;

        var alpha = 1.0 - dist / effectController['minDistance'];

        positions[vertexpos++] = particlePositions[i * 3];
        positions[vertexpos++] = particlePositions[i * 3 + 1];
        positions[vertexpos++] = particlePositions[i * 3 + 2];

        positions[vertexpos++] = particlePositions[j * 3];
        positions[vertexpos++] = particlePositions[j * 3 + 1];
        positions[vertexpos++] = particlePositions[j * 3 + 2];

        colors[colorpos++] = alpha;
        colors[colorpos++] = alpha;
        colors[colorpos++] = alpha;

        colors[colorpos++] = alpha;
        colors[colorpos++] = alpha;
        colors[colorpos++] = alpha;

        numConnected++;
      }
    }
  }

  var linesGeo = linesMesh.geometry as BufferGeometry;

  linesGeo.drawcalls[0].count = numConnected * 2;
  linesGeo.attributes['position'].needsUpdate = true;
  linesGeo.attributes['color'].needsUpdate = true;

  var pointCloudGeo = pointCloud.geometry as BufferGeometry;

  pointCloudGeo.attributes['position'].needsUpdate = true;

  window.animationFrame.then(animate);

  render();
}

void render() {
  var time = new DateTime.now().millisecondsSinceEpoch * 0.001;

  group.rotation.y = time * 0.1;
  renderer.render(scene, camera);
}

void main() {
  init();
  animate(0);
}
