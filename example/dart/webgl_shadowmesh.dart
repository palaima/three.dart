import 'dart:html';
import 'dart:math' as math;
import 'package:three/three.dart';

int screenWidth = window.innerWidth;
int screenHeight = window.innerHeight;

Clock clock = new Clock();

Scene scene;
PerspectiveCamera camera;
WebGLRenderer renderer;

DirectionalLight sunLight;
bool useDirectionalLight = true;
ArrowHelper arrowHelper1, arrowHelper2, arrowHelper3;

Vector3 arrowDirection = new Vector3.zero();
Vector3 arrowPosition1 = new Vector3.zero();
Vector3 arrowPosition2 = new Vector3.zero();
Vector3 arrowPosition3 = new Vector3.zero();

Mesh groundMesh;
Mesh lightSphere, lightHolder;

Mesh pyramid, sphere, box, cube, cylinder, torus;
ShadowMesh pyramidShadow, sphereShadow, boxShadow, cubeShadow, cylinderShadow, torusShadow;

Vector3 normalVector = new Vector3(0.0, 1.0, 0.0);
double planeConstant = 0.01; // this value must be slightly higher than the groundMesh's y position of 0.0
Plane groundPlane = new Plane.normalconstant(normalVector, planeConstant);
Vector4 lightPosition4D = new Vector4.identity();

double verticalAngle = 0.0;
double horizontalAngle = 0.0;
double frameTime = 0.0;
double TWO_PI = math.PI * 2;

void init() {
  scene = new Scene();

  renderer = new WebGLRenderer()
    ..setClearColor(0x0096FF)
    ..setSize(screenWidth, screenHeight);
  document.body.append(renderer.domElement);

  camera = new PerspectiveCamera(55.0, screenWidth / screenHeight, 1.0, 3000.0)
    ..position.setValues(0.0, 2.5, 10.0);
  scene.add(camera);
  onWindowResize(null);

  sunLight = new DirectionalLight(0xffffff, 1.0)
    ..position.setValues(5.0, 7.0, -1.0)
    ..lookAt(scene.position);
  scene.add(sunLight);

  lightPosition4D.x = sunLight.position.x;
  lightPosition4D.y = sunLight.position.y;
  lightPosition4D.z = sunLight.position.z;
  // amount of light-ray divergence. Ranging from:
  // 0.001 = sunlight(min divergence) to 1.0 = pointlight(max divergence)
  lightPosition4D.w = 0.001; // must be slightly greater than 0, due to 0 causing matrixInverse errors

  // YELLOW ARROW HELPERS
  arrowDirection.subVectors(scene.position, sunLight.position).normalize();

  arrowPosition1.setFrom(sunLight.position);
  arrowHelper1 = new ArrowHelper(arrowDirection, arrowPosition1, 0.9, 0xffff00, 0.25, 0.08);
  scene.add(arrowHelper1);

  arrowPosition2.setFrom(sunLight.position).add(new Vector3(0.0, 0.2, 0.0));
  arrowHelper2 = new ArrowHelper(arrowDirection, arrowPosition2, 0.9, 0xffff00, 0.25, 0.08);
  scene.add(arrowHelper2);

  arrowPosition3.setFrom(sunLight.position).add(new Vector3(0.0, -0.2, 0.0));
  arrowHelper3 = new ArrowHelper(arrowDirection, arrowPosition3, 0.9, 0xffff00, 0.25, 0.08);
  scene.add(arrowHelper3);

  // LIGHTBULB
  var lightSphereGeometry = new SphereGeometry(0.09);
  var lightSphereMaterial = new MeshBasicMaterial(color: 0xffffff);
  lightSphere = new Mesh(lightSphereGeometry, lightSphereMaterial);
  scene.add(lightSphere);
  lightSphere.visible = false;

  var lightHolderGeometry = new CylinderGeometry(0.05, 0.05, 0.13);
  var lightHolderMaterial = new MeshBasicMaterial(color: 0x4B4B4B);
  lightHolder = new Mesh(lightHolderGeometry, lightHolderMaterial);
  scene.add(lightHolder);
  lightHolder.visible = false;

  // GROUND
  var groundGeometry = new BoxGeometry(30.0, 0.01, 40.0);
  var groundMaterial = new MeshLambertMaterial(color: 0x008200);
  groundMesh = new Mesh(groundGeometry, groundMaterial)
    ..position.y = 0.0; //this value must be slightly lower than the planeConstant (0.01) parameter above
  scene.add(groundMesh);

  // RED CUBE and CUBE's SHADOW
  var cubeGeometry = new BoxGeometry(1.0, 1.0, 1.0);
  var cubeMaterial = new MeshLambertMaterial(color: 0xFF0000, emissive: 0x200000);
  cube = new Mesh(cubeGeometry, cubeMaterial)
    ..position.z = -1.0;
  scene.add(cube);

  cubeShadow = new ShadowMesh(cube);
  scene.add(cubeShadow);

  // BLUE CYLINDER and CYLINDER's SHADOW
  var cylinderGeometry = new CylinderGeometry(0.3, 0.3, 2.0);
  var cylinderMaterial = new MeshPhongMaterial(color: 0x0000ff, emissive: 0x000020);
  cylinder = new Mesh(cylinderGeometry, cylinderMaterial)
    ..position.z = -2.5;
  scene.add(cylinder);

  cylinderShadow = new ShadowMesh(cylinder);
  scene.add(cylinderShadow);

  // MAGENTA TORUS and TORUS' SHADOW
  var torusGeometry = new TorusGeometry(1.0, 0.2, 10, 16, TWO_PI);
  var torusMaterial = new MeshPhongMaterial(color: 0xff00ff, emissive: 0x200020);
  torus = new Mesh(torusGeometry, torusMaterial)
    ..position.z = -6.0;
  scene.add(torus);

  torusShadow = new ShadowMesh(torus);
  scene.add(torusShadow);

  // WHITE SPHERE and SPHERE'S SHADOW
  var sphereGeometry = new SphereGeometry(0.5, 20, 10);
  var sphereMaterial = new MeshPhongMaterial(color: 0xffffff, emissive: 0x222222);
  sphere = new Mesh(sphereGeometry, sphereMaterial)
    ..position.setValues(4.0, 0.5, 2.0);
  scene.add(sphere);

  sphereShadow = new ShadowMesh(sphere);
  scene.add(sphereShadow);

  // YELLOW PYRAMID and PYRAMID'S SHADOW
  var pyramidGeometry = new CylinderGeometry(0.0, 0.5, 2.0, 4);
  var pyramidMaterial = new MeshLambertMaterial(color: 0xffff00, emissive: 0x440000, shading: FlatShading);
  pyramid = new Mesh(pyramidGeometry, pyramidMaterial)
    ..position.setValues(-4.0, 1.0, 2.0);
  scene.add(pyramid);

  pyramidShadow = new ShadowMesh(pyramid);
  scene.add(pyramidShadow);

  querySelector('#lightButton').onClick.listen(lightButtonHandler);
  window.onResize.listen(onWindowResize);
}

void animate(num time) {
  window.animationFrame.then(animate);

  frameTime = clock.getDelta();

  cube.rotation.x += 1.0 * frameTime;
  cube.rotation.y += 1.0 * frameTime;

  cylinder.rotation.y += 1.0 * frameTime;
  cylinder.rotation.z -= 1.0 * frameTime;

  torus.rotation.x -= 1.0 * frameTime;
  torus.rotation.y -= 1.0 * frameTime;

  pyramid.rotation.y += 0.5 * frameTime;

  horizontalAngle += 0.5 * frameTime;
  if (horizontalAngle > TWO_PI) horizontalAngle -= TWO_PI;
  cube.position.x = math.sin(horizontalAngle) * 4;
  cylinder.position.x = math.sin(horizontalAngle) * -4;
  torus.position.x = math.cos(horizontalAngle) * 4;

  verticalAngle += 1.5 * frameTime;
  if (verticalAngle > TWO_PI) verticalAngle -= TWO_PI;
  cube.position.y = math.sin(verticalAngle) * 2 + 2.9;
  cylinder.position.y = math.sin(verticalAngle) * 2 + 3.1;
  torus.position.y = math.cos(verticalAngle) * 2 + 3.3;

  // update the ShadowMeshes to follow their shadow-casting objects
  cubeShadow.update(groundPlane, lightPosition4D);
  cylinderShadow.update(groundPlane, lightPosition4D);
  torusShadow.update(groundPlane, lightPosition4D);
  sphereShadow.update(groundPlane, lightPosition4D);
  pyramidShadow.update(groundPlane, lightPosition4D);

  renderer.render(scene, camera);
}

void onWindowResize(_) {
  screenWidth = window.innerWidth;
  screenHeight = window.innerHeight;

  renderer.setSize(screenWidth, screenHeight);

  camera.aspect = screenWidth / screenHeight;
  camera.updateProjectionMatrix();
}

void lightButtonHandler(_) {
  useDirectionalLight = !useDirectionalLight;

  if (useDirectionalLight) {
    renderer.setClearColor(0x0096FF);
    groundMesh.material.color.setRGB(0.0, 130.0, 0.0);
    sunLight.position.setValues(5.0, 7.0, -1.0);
    sunLight.lookAt(scene.position);

    lightPosition4D.x = sunLight.position.x;
    lightPosition4D.y = sunLight.position.y;
    lightPosition4D.z = sunLight.position.z;
    lightPosition4D.w = 0.001; // more of a directional Light value

    arrowHelper1.visible = true;
    arrowHelper2.visible = true;
    arrowHelper3.visible = true;

    lightSphere.visible = false;
    lightHolder.visible = false;

    querySelector('#lightButton').text = 'Switch to PointLight';
  } else {
    renderer.setClearColor(0x000000);
    groundMesh.material.color.setRGB(150.0, 150.0, 150.0);

    sunLight.position.setValues(0.0, 6.0, -2.0);
    sunLight.lookAt(scene.position);
    lightSphere.position.setFrom(sunLight.position);
    lightHolder.position.setFrom(lightSphere.position);
    lightHolder.position.y += 0.12;

    lightPosition4D.x = sunLight.position.x;
    lightPosition4D.y = sunLight.position.y;
    lightPosition4D.z = sunLight.position.z;
    lightPosition4D.w = 0.9; // more of a point Light value

    arrowHelper1.visible = false;
    arrowHelper2.visible = false;
    arrowHelper3.visible = false;

    lightSphere.visible = true;
    lightHolder.visible = true;

    querySelector('#lightButton').text = 'Switch to DirectionalLight';
  }
}

void main() {
  init();
  animate(0);
}

class ShadowMesh extends Mesh {
  Matrix4 meshMatrix;

  ShadowMesh(Mesh mesh) : super(mesh.geometry,
          new MeshBasicMaterial(color: 0x000000, transparent: true, opacity: 0.6, depthWrite: false)) {
    meshMatrix = mesh.matrixWorld;

    frustumCulled = false;
    matrixAutoUpdate = false;
  }

  void update(Plane plane, Vector4 lightPosition4D) {
    // based on https://www.opengl.org/archives/resources/features/StencilTalk/tsld021.htm

    var dot = plane.normal.x * lightPosition4D.x +
        plane.normal.y * lightPosition4D.y +
        plane.normal.z * lightPosition4D.z +
        -plane.constant * lightPosition4D.w;

    var sme = _shadowMatrix.storage;

    sme[0] = dot - lightPosition4D.x * plane.normal.x;
    sme[4] = -lightPosition4D.x * plane.normal.y;
    sme[8] = -lightPosition4D.x * plane.normal.z;
    sme[12] = -lightPosition4D.x * -plane.constant;

    sme[1] = -lightPosition4D.y * plane.normal.x;
    sme[5] = dot - lightPosition4D.y * plane.normal.y;
    sme[9] = -lightPosition4D.y * plane.normal.z;
    sme[13] = -lightPosition4D.y * -plane.constant;

    sme[2] = -lightPosition4D.z * plane.normal.x;
    sme[6] = -lightPosition4D.z * plane.normal.y;
    sme[10] = dot - lightPosition4D.z * plane.normal.z;
    sme[14] = -lightPosition4D.z * -plane.constant;

    sme[3] = -lightPosition4D.w * plane.normal.x;
    sme[7] = -lightPosition4D.w * plane.normal.y;
    sme[11] = -lightPosition4D.w * plane.normal.z;
    sme[15] = dot - lightPosition4D.w * -plane.constant;

    this.matrix.multiplyMatrices(_shadowMatrix, meshMatrix);
  }

  static final Matrix4 _shadowMatrix = new Matrix4.zero();
}
