import 'dart:html';
import 'dart:math' as math;

import 'package:three/three.dart';

import 'package:three/extras/marching_cubes.dart';

import 'package:three/extras/postprocessing.dart';
import 'package:three/extras/controls.dart';
import 'package:three/extras/shaders.dart' show toonShader;

import 'package:three/extras/image_utils.dart' as image_utils;
import 'package:three/extras/uniforms_utils.dart' as uniforms_utils;

int MARGIN = 0;

int screenWidth = window.innerWidth;
int screenHeight = window.innerHeight - 2 * MARGIN;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Map materials;
String current_material;

DirectionalLight light;
PointLight pointLight;
AmbientLight ambientLight;

MarchingCubes effect;
int resolution, numBlobs;

EffectComposer composer;

ShaderPass effectFXAA, hblur, vblur;

Map effectController;

OrbitControls controls;

double time = 0.0;

Clock clock = new Clock();

void init() {
  camera = new PerspectiveCamera(45.0, screenWidth / screenHeight, 1.0, 10000.0)
    ..position.setValues(-500.0, 500.0, 1500.0);

  //

  scene = new Scene();

  //

  light = new DirectionalLight(0xffffff)..position.setValues(0.5, 0.5, 1.0);
  scene.add(light);

  pointLight = new PointLight(0xff3300)..position.setValues(0.0, 0.0, 100.0);
  scene.add(pointLight);

  ambientLight = new AmbientLight(0x080808);
  scene.add(ambientLight);

  //

  materials = generateMaterials();
  current_material = 'shiny';

  //

  resolution = 28;
  numBlobs = 10;

  effect = new MarchingCubes(resolution, materials[current_material]['m'],
      enableUvs: true, enableColors: true)
    ..position.setValues(0.0, 0.0, 0.0)
    ..scale.setValues(700.0, 700.0, 700.0)
    ..enableUvs = false
    ..enableColors = false;

  scene.add(effect);

  //

  renderer = new WebGLRenderer()
    ..setClearColor(0x050505)
    ..setPixelRatio(window.devicePixelRatio)
    ..setSize(screenWidth, screenHeight)
    ..domElement.style.position = 'absolute'
    ..domElement.style.top = '${MARGIN}px'
    ..domElement.style.left = '0px';

  querySelector('#container').append(renderer.domElement);

  //

  renderer.gammaInput = true;
  renderer.gammaOutput = true;

  //

  controls = new OrbitControls(camera, renderer.domElement);

  //

  renderer.autoClear = false;

  var renderTarget = new WebGLRenderTarget(screenWidth, screenHeight,
      minFilter: LinearFilter, magFilter: LinearFilter, format: RGBFormat, stencilBuffer: false);

  effectFXAA = new ShaderPass(fxaaShader);

  hblur = new ShaderPass(horizontalTiltShiftShader);
  vblur = new ShaderPass(verticalTiltShiftShader);

  var bluriness = 8;

  hblur.uniforms['h'].value = bluriness / screenWidth;
  vblur.uniforms['v'].value = bluriness / screenHeight;

  hblur.uniforms['r'].value = vblur.uniforms['r'].value = 0.5;

  effectFXAA.uniforms['resolution'].value.setValues(1 / screenWidth, 1 / screenHeight);

  var renderModel = new RenderPass(scene, camera);

  vblur.renderToScreen = true;
  //effectFXAA.renderToScreen = true;

  composer = new EffectComposer(renderer, renderTarget)
    ..addPass(renderModel)
    ..addPass(effectFXAA)
    ..addPass(hblur)
    ..addPass(vblur);

  //

  setupGui();

  //

  window.onResize.listen(onWindowResize);
}

//

void onWindowResize(_) {
  screenWidth = window.innerWidth;
  screenHeight = window.innerHeight - 2 * MARGIN;

  camera.aspect = screenWidth / screenHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(screenWidth, screenHeight);
  composer.setSize(screenWidth, screenHeight);

  hblur.uniforms['h'].value = 4 / screenWidth;
  vblur.uniforms['v'].value = 4 / screenHeight;

  effectFXAA.uniforms['resolution'].value.setValues(1 / screenWidth, 1 / screenHeight);
}

Map generateMaterials() {
  // environment map

  var urls = new List.generate(
      6, (i) => 'textures/cube/SwedishRoyalCastle/${['px', 'nx', 'py', 'ny', 'pz', 'nz'][i]}.jpg');

  var reflectionCube = image_utils.loadTextureCube(urls);
  reflectionCube.format = RGBFormat;

  var refractionCube = new Texture(reflectionCube.image, CubeRefractionMapping);
  reflectionCube.format = RGBFormat;

  // toons

  var toonMaterial1 = createShaderMaterial('toon1', light, ambientLight),
      toonMaterial2 = createShaderMaterial('toon2', light, ambientLight),
      hatchingMaterial = createShaderMaterial('hatching', light, ambientLight),
      hatchingMaterial2 = createShaderMaterial('hatching', light, ambientLight),
      dottedMaterial = createShaderMaterial('dotted', light, ambientLight),
      dottedMaterial2 = createShaderMaterial('dotted', light, ambientLight);

  hatchingMaterial2.uniforms['uBaseColor'].value.setRGB(0.0, 0.0, 0.0);
  hatchingMaterial2.uniforms['uLineColor1'].value.setHSL(0.0, 0.8, 0.5);
  hatchingMaterial2.uniforms['uLineColor2'].value.setHSL(0.0, 0.8, 0.5);
  hatchingMaterial2.uniforms['uLineColor3'].value.setHSL(0.0, 0.8, 0.5);
  hatchingMaterial2.uniforms['uLineColor4'].value.setHSL(0.1, 0.8, 0.5);

  dottedMaterial2.uniforms['uBaseColor'].value.setRGB(0.0, 0.0, 0.0);
  dottedMaterial2.uniforms['uLineColor1'].value.setHSL(0.05, 1.0, 0.5);

  var texture = image_utils.loadTexture('textures/UV_Grid_Sm.jpg');
  texture.wrapS = texture.wrapT = RepeatWrapping;

  var materials = {
    'chrome': {
      'm': new MeshLambertMaterial(color: 0xffffff, envMap: reflectionCube),
      'h': 0.0,
      's': 0.0,
      'l': 1.0
    },
    'liquid': {
      'm': new MeshLambertMaterial(color: 0xffffff, envMap: refractionCube, refractionRatio: 0.85),
      'h': 0.0,
      's': 0.0,
      'l': 1.0
    },
    'shiny': {
      'm': new MeshPhongMaterial(
          color: 0x550000,
          specular: 0x440000,
          envMap: reflectionCube,
          combine: MixOperation,
          reflectivity: 0.3,
          metal: true),
      'h': 0.0,
      's': 0.8,
      'l': 0.2
    },
    'matte': {
      'm': new MeshPhongMaterial(color: 0x000000, specular: 0x111111, shininess: 1.0),
      'h': 0.0,
      's': 0.0,
      'l': 1.0
    },
    'flat': {
      'm': new MeshPhongMaterial(
          color: 0x000000, specular: 0x111111, shininess: 1.0, shading: FlatShading),
      'h': 0.0,
      's': 0.0,
      'l': 1.0
    },
    'textured': {
      'm': new MeshPhongMaterial(color: 0xffffff, specular: 0x111111, shininess: 1.0, map: texture),
      'h': 0.0,
      's': 0.0,
      'l': 1.0
    },
    'colors': {
      'm': new MeshPhongMaterial(
          color: 0xffffff, specular: 0xffffff, shininess: 2.0, vertexColors: VertexColors),
      'h': 0.0,
      's': 0.0,
      'l': 1.0
    },
    'plastic': {
      'm': new MeshPhongMaterial(color: 0x000000, specular: 0x888888, shininess: 250.0),
      'h': 0.6,
      's': 0.8,
      'l': 0.1
    },
    'toon1': {'m': toonMaterial1, 'h': 0.2, 's': 1.0, 'l': 0.75},
    'toon2': {'m': toonMaterial2, 'h': 0.4, 's': 1.0, 'l': 0.75},
    'hatching': {'m': hatchingMaterial, 'h': 0.2, 's': 1.0, 'l': 0.9},
    'hatching2': {'m': hatchingMaterial2, 'h': 0.0, 's': 0.8, 'l': 0.5},
    'dotted': {'m': dottedMaterial, 'h': 0.2, 's': 1.0, 'l': 0.9},
    'dotted2': {'m': dottedMaterial2, 'h': 0.1, 's': 1.0, 'l': 0.5}
  };

  return materials;
}

ShaderMaterial createShaderMaterial(String id, DirectionalLight light, AmbientLight ambientLight) {
  var shader = toonShader[id];

  var u = uniforms_utils.clone(shader['uniforms']);

  var vs = shader['vertexShader'];
  var fs = shader['fragmentShader'];

  var material = new ShaderMaterial(uniforms: u, vertexShader: vs, fragmentShader: fs);

  material.uniforms['uDirLightPos'].value = light.position;
  material.uniforms['uDirLightColor'].value = light.color;

  material.uniforms['uAmbientLightColor'].value = ambientLight.color;

  return material;
}

//

void setupGui() {
  var h, m_h, m_s, m_l;

  var createHandler = (id) {
    return () {
      var mat_old = materials[current_material];
      mat_old.h = m_h.getValue();
      mat_old.s = m_s.getValue();
      mat_old.l = m_l.getValue();

      current_material = id;

      var mat = materials[id];
      effect.material = mat.m;

      m_h.setValue(mat.h);
      m_s.setValue(mat.s);
      m_l.setValue(mat.l);

      if (current_material == 'textured') {
        effect.enableUvs = true;
      } else {
        effect.enableUvs = false;
      }

      if (current_material == 'colors') {
        effect.enableColors = true;
      } else {
        effect.enableColors = false;
      }
    };
  };

  effectController = {
    'material': 'shiny',
    'speed': 1.0,
    'numBlobs': 10,
    'resolution': 28,
    'isolation': 80,
    'floor': true,
    'wallx': false,
    'wallz': false,
    'hue': 0.0,
    'saturation': 0.8,
    'lightness': 0.1,
    'lhue': 0.04,
    'lsaturation': 1.0,
    'llightness': 0.5,
    'lx': 0.5,
    'ly': 0.5,
    'lz': 1.0,
    'postprocessing': false,
    'dummy': () {}
  };

  // TODO

//  var gui = new dat.GUI();
//
//  // material (type)
//
//  h = gui.addFolder('Materials');
//
//  for (var m in materials) {
//    effectController[m] = createHandler(m);
//    h.add(effectController, m).name(m);
//  }
//
//  // material (color)
//
//  h = gui.addFolder('Material color');
//
//  m_h = h.add(effectController, 'hue', 0.0, 1.0, 0.025);
//  m_s = h.add(effectController, 'saturation', 0.0, 1.0, 0.025);
//  m_l = h.add(effectController, 'lightness', 0.0, 1.0, 0.025);
//
//  // light (point)
//
//  h = gui.addFolder('Point light color');
//
//  h.add(effectController, 'lhue', 0.0, 1.0, 0.025).name('hue');
//  h.add(effectController, 'lsaturation', 0.0, 1.0, 0.025).name('saturation');
//  h.add(effectController, 'llightness', 0.0, 1.0, 0.025).name('lightness');
//
//  // light (directional)
//
//  h = gui.addFolder('Directional light orientation');
//
//  h.add(effectController, 'lx', -1.0, 1.0, 0.025).name('x');
//  h.add(effectController, 'ly', -1.0, 1.0, 0.025).name('y');
//  h.add(effectController, 'lz', -1.0, 1.0, 0.025).name('z');
//
//  // simulation
//
//  h = gui.addFolder('Simulation');
//
//  h.add(effectController, 'speed', 0.1, 8.0, 0.05);
//  h.add(effectController, 'numBlobs', 1, 50, 1);
//  h.add(effectController, 'resolution', 14, 40, 1);
//  h.add(effectController, 'isolation', 10, 300, 1);
//
//  h.add(effectController, 'floor');
//  h.add(effectController, 'wallx');
//  h.add(effectController, 'wallz');
//
//  // rendering
//
//  h = gui.addFolder('Rendering');
//  h.add(effectController, 'postprocessing');
}

// this controls content of marching cubes voxel field

void updateCubes(
    MarchingCubes object, double time, int numblobs, bool floor, bool wallx, bool wallz) {
  object.reset();

  // fill the field with some metaballs

  var subtract = 12;
  var strength = 1.2 / ((math.sqrt(numblobs) - 1) / 4 + 1);

  for (var i = 0; i < numblobs; i++) {
    var ballx =
        math.sin(i + 1.26 * time * (1.03 + 0.5 * math.cos(0.21 * i))) *
                0.27 +
            0.5;
    var bally =
        math.cos(i + 1.12 * time * math.cos(1.22 + 0.1424 * i)).abs() * 0.77; // dip into the floor
    var ballz =
        math.cos(i + 1.32 * time * 0.1 * math.sin((0.92 + 0.53 * i))) * 0.27 +
            0.5;

    object.addBall(ballx, bally, ballz, strength, subtract);
  }

  if (floor) object.addPlaneY(2.0, 12);
  if (wallz) object.addPlaneZ(2.0, 12);
  if (wallx) object.addPlaneX(2.0, 12);
}

void render() {
  var delta = clock.getDelta();

  time += delta * effectController['speed'] * 0.5;

  controls.update(); // delta);

  // marching cubes

  if (effectController['resolution'] != resolution) {
    resolution = effectController['resolution'];
    effect.init(resolution);
  }

  if (effectController['isolation'] != effect.isolation) {
    effect.isolation = effectController['isolation'];
  }

  updateCubes(effect, time, effectController['numBlobs'], effectController['floor'],
      effectController['wallx'], effectController['wallz']);

  // materials

  var mat = effect.material;

  if (mat is ShaderMaterial) {
    if (current_material == 'dotted2') {
      mat.uniforms['uLineColor1'].value.setHSL(
          effectController['hue'], effectController['saturation'], effectController['lightness']);
    } else if (current_material == 'hatching2') {
      var u = mat.uniforms;

      u['uLineColor1'].value.setHSL(
          effectController['hue'], effectController['saturation'], effectController['lightness']);
      u['uLineColor2'].value.setHSL(
          effectController['hue'], effectController['saturation'], effectController['lightness']);
      u['uLineColor3'].value.setHSL(
          effectController['hue'], effectController['saturation'], effectController['lightness']);
      u['uLineColor4'].value.setHSL((effectController['hue'] + 0.2 % 1.0),
          effectController['saturation'], effectController['lightness']);
    } else {
      mat.uniforms['uBaseColor'].value.setHSL(
          effectController['hue'], effectController['saturation'], effectController['lightness']);
    }
  } else {
    effect.material.color.setHSL(
        effectController['hue'], effectController['saturation'], effectController['lightness']);
  }

  // lights

  light.position.setValues(effectController['lx'], effectController['ly'], effectController['lz']);
  light.position.normalize();

  pointLight.color.setHSL(
      effectController['lhue'], effectController['lsaturation'], effectController['llightness']);

  // render

  if (effectController['postprocessing']) {
    composer.render(delta);
  } else {
    renderer.clear();
    renderer.render(scene, camera);
  }
}

main() async {
  init();

  while (true) {
    await window.animationFrame;
    render();
  }
}
