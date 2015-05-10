import 'dart:html';
import 'package:three/three.dart';
import 'package:three/extras/image_utils.dart' as image_utils;
import 'package:three/extras/uniforms_utils.dart' as uniforms_utils;
import 'package:three/extras/postprocessing.dart';

JSONLoader loader;

WebGLRenderer renderer;
PerspectiveCamera camera;
Scene scene;

Mesh mesh, mesh2;

DirectionalLight directionalLight, directionalLight2;
PointLight pointLight;
SpotLight spotLight;

double mouseX = 0.0,
    mouseY = 0.0;

double targetX = 0.0,
    targetY = 0.0;

double windowHalfX = window.innerWidth / 2;
double windowHalfY = window.innerHeight / 2;

bool firstPass = true;

EffectComposer composer, composerBeckmann;

void main() {
  init();
  animate(0);
}

void init() {
  camera = new PerspectiveCamera(
      27.0, window.innerWidth / window.innerHeight, 1.0, 10000.0)
    ..position.z = 1200.0;

  scene = new Scene();

  // LIGHTS
  scene.add(new AmbientLight(0x555555));

  //

  pointLight = new PointLight(0xffffff, intensity: 1.5, distance: 1000.0);
  pointLight.position.setValues(0.0, 0.0, 600.0);

  scene.add(pointLight);

  // shadow for PointLight

  spotLight = new SpotLight(0xffffff, intensity: 1.0);
  spotLight.position.setValues(0.05, 0.05, 1.0);
  scene.add(spotLight);

  spotLight.position.scale(700.0);

  spotLight.castShadow = true;
  spotLight.onlyShadow = true;
  //spotLight.shadowCameraVisible = true;

  spotLight.shadowMapWidth = 2048;
  spotLight.shadowMapHeight = 2048;

  spotLight.shadowCameraNear = 200.0;
  spotLight.shadowCameraFar = 1500.0;

  spotLight.shadowCameraFov = 40.0;

  spotLight.shadowBias = -0.005;
  spotLight.shadowDarkness = 0.15;

  //

  directionalLight = new DirectionalLight(0xffffff, 0.85);
  directionalLight.position.setValues(1.0, -0.5, 1.0);
  directionalLight.color.setHSL(0.6, 1.0, 0.85);
  scene.add(directionalLight);

  directionalLight.position.scale(500.0);

  directionalLight.castShadow = true;
  //directionalLight.shadowCameraVisible = true;

  directionalLight.shadowMapWidth = 2048;
  directionalLight.shadowMapHeight = 2048;

  directionalLight.shadowCameraNear = 200.0;
  directionalLight.shadowCameraFar = 1500.0;

  directionalLight.shadowCameraLeft = -500.0;
  directionalLight.shadowCameraRight = 500.0;
  directionalLight.shadowCameraTop = 500.0;
  directionalLight.shadowCameraBottom = -500.0;

  directionalLight.shadowBias = -0.005;
  directionalLight.shadowDarkness = 0.15;

  //

  directionalLight2 = new DirectionalLight(0xffffff, 0.85);
  directionalLight2.position.setValues(1.0, -0.5, -1.0);
  scene.add(directionalLight2);

  //

  loader = new JSONLoader();

  loader.load('obj/leeperrysmith/LeePerrySmith.js').then((geometry) {
    createScene(geometry, 100.0);
  });

  //

  renderer = new WebGLRenderer(antialias: false);
  renderer.setClearColor(0x444a54);
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.append(renderer.domElement);

  renderer.shadowMap.enabled = true;
  renderer.shadowMap.cullFace = CullFaceBack;

  renderer.autoClear = false;

  //

  renderer.gammaInput = true;
  renderer.gammaOutput = true;

  renderer.shadowMap.enabled = true;
  renderer.shadowMap.cullFace = CullFaceBack;

  // COMPOSER

  renderer.autoClear = false;

  // BECKMANN

  var effectBeckmann = new ShaderPass(ShaderSkin['beckmann']);
  var effectCopy = new ShaderPass(copyShader);

  effectCopy.renderToScreen = true;

  var rtwidth = 512,
      rtheight = 512;

  composerBeckmann = new EffectComposer(renderer, new WebGLRenderTarget(
      rtwidth, rtheight,
      minFilter: LinearFilter,
      magFilter: LinearFilter,
      format: RGBFormat,
      stencilBuffer: false));

  composerBeckmann.addPass(effectBeckmann);
  composerBeckmann.addPass(effectCopy);

  document.onMouseMove.listen(onDocumentMouseMove);

  window.onResize.listen(onWindowResize);
}

void onWindowResize(_) {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize(window.innerWidth, window.innerHeight);
}

void onDocumentMouseMove(MouseEvent event) {
  mouseX = (event.client.x - windowHalfX);
  mouseY = (event.client.y - windowHalfY);
}

void createScene(Geometry geometry, double scale) {
  var mapHeight = image_utils.loadTexture(
      'obj/leeperrysmith/Infinite-Level_02_Disp_NoSmoothUV-4096.jpg')
    ..anisotropy = 4
    ..repeat.setValues(0.998, 0.998)
    ..offset.setValues(0.001, 0.001)
    ..wrapS = RepeatWrapping
    ..wrapT = RepeatWrapping
    ..format = RGBFormat;

  var mapSpecular = image_utils.loadTexture('obj/leeperrysmith/Map-SPEC.jpg')
    ..anisotropy = 4
    ..repeat.setValues(0.998, 0.998)
    ..offset.setValues(0.001, 0.001)
    ..wrapS = RepeatWrapping
    ..wrapT = RepeatWrapping
    ..format = RGBFormat;

  var mapColor = image_utils.loadTexture('obj/leeperrysmith/Map-COL.jpg')
    ..anisotropy = 4
    ..repeat.setValues(0.998, 0.998)
    ..offset.setValues(0.001, 0.001)
    ..wrapS = RepeatWrapping
    ..wrapT = RepeatWrapping
    ..format = RGBFormat;

  var shader = ShaderSkin['skinSimple'];

  var fragmentShader = shader['fragmentShader'];
  var vertexShader = shader['vertexShader'];

  var uniforms = uniforms_utils.clone(shader['uniforms']);

  uniforms['enableBump'].value = 1;
  uniforms['enableSpecular'].value = 1;

  uniforms['tBeckmann'].value = composerBeckmann.renderTarget1;
  uniforms['tDiffuse'].value = mapColor;

  uniforms['bumpMap'].value = mapHeight;
  uniforms['specularMap'].value = mapSpecular;

  uniforms['diffuse'].value.setHex(0xa0a0a0);
  uniforms['specular'].value.setHex(0xa0a0a0);

  uniforms['uRoughness'].value = 0.145;
  uniforms['uSpecularBrightness'].value = 0.75;

  uniforms['bumpScale'].value = 16;

  uniforms['offsetRepeat'].value.setValues(0.001, 0.001, 0.998, 0.998);

  var material = new ShaderMaterial(
      fragmentShader: fragmentShader,
      vertexShader: vertexShader,
      uniforms: uniforms,
      lights: true,
      derivatives: true);

  mesh = new Mesh(geometry, material);

  mesh.position.y = -50.0;
  mesh.scale.splat(scale);

  mesh.castShadow = true;
  mesh.receiveShadow = true;

  scene.add(mesh);
}

void animate(num time) {
  window.requestAnimationFrame(animate);
  render();
}

void render() {
  targetX = mouseX * .001;
  targetY = mouseY * .001;

  if (mesh != null) {
    mesh.rotation.y += 0.05 * (targetX - mesh.rotation.y);
    mesh.rotation.x += 0.05 * (targetY - mesh.rotation.x);
  }

  if (firstPass) {
    composerBeckmann.render();
    firstPass = false;
  }

  renderer.clear();
  renderer.render(scene, camera);
}

/*
 * @author alteredq / http://alteredqualia.com/
 *
 */

final Map ShaderSkin = {

  /* ------------------------------------------------------------------------------------------
  //  Simple skin shader
  //    - per-pixel Blinn-Phong diffuse term mixed with half-Lambert wrap-around term (per color component)
  //    - physically based specular term (Kelemen/Szirmay-Kalos specular reflectance)
  //
  //    - diffuse map
  //    - bump map
  //    - specular map
  //    - point, directional and hemisphere lights (use with 'lights: true' material option)
  //    - fog (use with 'fog: true' material option)
  //    - shadow maps
  //
  // ------------------------------------------------------------------------------------------ */

  'skinSimple': {
    'uniforms': uniforms_utils.merge([
      UniformsLib['fog'],
      UniformsLib['lights'],
      UniformsLib['shadowmap'],
      {
        'enableBump': new Uniform.int(0),
        'enableSpecular': new Uniform.int(0),
        'tDiffuse': new Uniform.texture(),
        'tBeckmann': new Uniform.texture(),
        'diffuse': new Uniform.color(0xeeeeee),
        'specular': new Uniform.color(0x111111),
        'opacity': new Uniform.float(1.0),
        'uRoughness': new Uniform.float(0.15),
        'uSpecularBrightness': new Uniform.float(0.75),
        'bumpMap': new Uniform.texture(),
        'bumpScale': new Uniform.float(1.0),
        'specularMap': new Uniform.texture(),
        'offsetRepeat': new Uniform.vector4(0.0, 0.0, 1.0, 1.0),
        'uWrapRGB': new Uniform.vector3(0.75, 0.375, 0.1875)
      }
    ]),
    'fragmentShader': [
      '#define USE_BUMPMAP',
      'uniform bool enableBump;',
      'uniform bool enableSpecular;',
      'uniform vec3 diffuse;',
      'uniform vec3 specular;',
      'uniform float opacity;',
      'uniform float uRoughness;',
      'uniform float uSpecularBrightness;',
      'uniform vec3 uWrapRGB;',
      'uniform sampler2D tDiffuse;',
      'uniform sampler2D tBeckmann;',
      'uniform sampler2D specularMap;',
      'varying vec3 vNormal;',
      'varying vec2 vUv;',
      'uniform vec3 ambientLightColor;',
      '#if MAX_DIR_LIGHTS > 0',
      'uniform vec3 directionalLightColor[ MAX_DIR_LIGHTS ];',
      'uniform vec3 directionalLightDirection[ MAX_DIR_LIGHTS ];',
      '#endif',
      '#if MAX_HEMI_LIGHTS > 0',
      'uniform vec3 hemisphereLightSkyColor[ MAX_HEMI_LIGHTS ];',
      'uniform vec3 hemisphereLightGroundColor[ MAX_HEMI_LIGHTS ];',
      'uniform vec3 hemisphereLightDirection[ MAX_HEMI_LIGHTS ];',
      '#endif',
      '#if MAX_POINT_LIGHTS > 0',
      'uniform vec3 pointLightColor[ MAX_POINT_LIGHTS ];',
      'uniform vec3 pointLightPosition[ MAX_POINT_LIGHTS ];',
      'uniform float pointLightDistance[ MAX_POINT_LIGHTS ];',
      'uniform float pointLightDecay[ MAX_POINT_LIGHTS ];',
      '#endif',
      'varying vec3 vViewPosition;',
      ShaderChunk['common'],
      ShaderChunk['shadowmap_pars_fragment'],
      ShaderChunk['fog_pars_fragment'],
      ShaderChunk['bumpmap_pars_fragment'],

      // Fresnel term

      'float fresnelReflectance( vec3 H, vec3 V, float F0 ) {',
      'float base = 1.0 - dot( V, H );',
      'float exponential = pow( base, 5.0 );',
      'return exponential + F0 * ( 1.0 - exponential );',
      '}',

      // Kelemen/Szirmay-Kalos specular BRDF

      'float KS_Skin_Specular( vec3 N,', // Bumped surface normal
      'vec3 L,', // Points to light
      'vec3 V,', // Points to eye
      'float m,', // Roughness
      'float rho_s', // Specular brightness
      ') {',
      'float result = 0.0;',
      'float ndotl = dot( N, L );',
      'if( ndotl > 0.0 ) {',
      'vec3 h = L + V;', // Unnormalized half-way vector
      'vec3 H = normalize( h );',
      'float ndoth = dot( N, H );',
      'float PH = pow( 2.0 * texture2D( tBeckmann, vec2( ndoth, m ) ).x, 10.0 );',
      'float F = fresnelReflectance( H, V, 0.028 );',
      'float frSpec = max( PH * F / dot( h, h ), 0.0 );',
      'result = ndotl * rho_s * frSpec;', // BRDF * dot(N,L) * rho_s

      '}',
      'return result;',
      '}',
      'void main() {',
      'vec3 outgoingLight = vec3( 0.0 );', // outgoing light does not have an alpha, the surface does
      'vec4 diffuseColor = vec4( diffuse, opacity );',
      'vec4 colDiffuse = texture2D( tDiffuse, vUv );',
      'colDiffuse.rgb *= colDiffuse.rgb;',
      'diffuseColor = diffuseColor * colDiffuse;',
      'vec3 normal = normalize( vNormal );',
      'vec3 viewPosition = normalize( vViewPosition );',
      'float specularStrength;',
      'if ( enableSpecular ) {',
      'vec4 texelSpecular = texture2D( specularMap, vUv );',
      'specularStrength = texelSpecular.r;',
      '} else {',
      'specularStrength = 1.0;',
      '}',
      '#ifdef USE_BUMPMAP',
      'if ( enableBump ) normal = perturbNormalArb( -vViewPosition, normal, dHdxy_fwd() );',
      '#endif',

      // point lights

      'vec3 totalSpecularLight = vec3( 0.0 );',
      'vec3 totalDiffuseLight = vec3( 0.0 );',
      '#if MAX_POINT_LIGHTS > 0',
      'for ( int i = 0; i < MAX_POINT_LIGHTS; i ++ ) {',
      'vec4 lPosition = viewMatrix * vec4( pointLightPosition[ i ], 1.0 );',
      'vec3 lVector = lPosition.xyz + vViewPosition.xyz;',
      'float attenuation = calcLightAttenuation( length( lVector ), pointLightDistance[ i ], pointLightDecay[i] );',
      'lVector = normalize( lVector );',
      'float pointDiffuseWeightFull = max( dot( normal, lVector ), 0.0 );',
      'float pointDiffuseWeightHalf = max( 0.5 * dot( normal, lVector ) + 0.5, 0.0 );',
      'vec3 pointDiffuseWeight = mix( vec3 ( pointDiffuseWeightFull ), vec3( pointDiffuseWeightHalf ), uWrapRGB );',
      'float pointSpecularWeight = KS_Skin_Specular( normal, lVector, viewPosition, uRoughness, uSpecularBrightness );',
      'totalDiffuseLight += attenuation * pointLightColor[ i ] * pointDiffuseWeight;',
      'totalSpecularLight += attenuation * specular * pointLightColor[ i ] * pointSpecularWeight * specularStrength;',
      '}',
      '#endif',

      // directional lights

      '#if MAX_DIR_LIGHTS > 0',
      'for( int i = 0; i < MAX_DIR_LIGHTS; i++ ) {',
      'vec3 dirVector = transformDirection( directionalLightDirection[ i ], viewMatrix );',
      'float dirDiffuseWeightFull = max( dot( normal, dirVector ), 0.0 );',
      'float dirDiffuseWeightHalf = max( 0.5 * dot( normal, dirVector ) + 0.5, 0.0 );',
      'vec3 dirDiffuseWeight = mix( vec3 ( dirDiffuseWeightFull ), vec3( dirDiffuseWeightHalf ), uWrapRGB );',
      'float dirSpecularWeight = KS_Skin_Specular( normal, dirVector, viewPosition, uRoughness, uSpecularBrightness );',
      'totalDiffuseLight += directionalLightColor[ i ] * dirDiffuseWeight;',
      'totalSpecularLight += specular * directionalLightColor[ i ] * dirSpecularWeight * specularStrength;',
      '}',
      '#endif',

      // hemisphere lights

      '#if MAX_HEMI_LIGHTS > 0',
      'for ( int i = 0; i < MAX_HEMI_LIGHTS; i ++ ) {',
      'vec3 lVector = transformDirection( hemisphereLightDirection[ i ], viewMatrix );',
      'float dotProduct = dot( normal, lVector );',
      'float hemiDiffuseWeight = 0.5 * dotProduct + 0.5;',
      'totalDiffuseLight += mix( hemisphereLightGroundColor[ i ], hemisphereLightSkyColor[ i ], hemiDiffuseWeight );',

      // specular (sky light)

      'float hemiSpecularWeight = 0.0;',
      'hemiSpecularWeight += KS_Skin_Specular( normal, lVector, viewPosition, uRoughness, uSpecularBrightness );',

      // specular (ground light)

      'vec3 lVectorGround = -lVector;',
      'hemiSpecularWeight += KS_Skin_Specular( normal, lVectorGround, viewPosition, uRoughness, uSpecularBrightness );',
      'totalSpecularLight += specular * mix( hemisphereLightGroundColor[ i ], hemisphereLightSkyColor[ i ], hemiDiffuseWeight ) * hemiSpecularWeight * specularStrength;',
      '}',
      '#endif',
      'outgoingLight += diffuseColor.xyz * ( totalDiffuseLight + ambientLightColor * diffuse ) + totalSpecularLight;',
      ShaderChunk['shadowmap_fragment'],
      ShaderChunk['linear_to_gamma_fragment'],
      ShaderChunk['fog_fragment'],
      'gl_FragColor = vec4( outgoingLight, diffuseColor.a );', // TODO, this should be pre-multiplied to allow for bright highlights on very transparent objects

      '}'
    ].join('\n'),
    'vertexShader': [
      'uniform vec4 offsetRepeat;',
      'varying vec3 vNormal;',
      'varying vec2 vUv;',
      'varying vec3 vViewPosition;',
      ShaderChunk['common'],
      ShaderChunk['shadowmap_pars_vertex'],
      'void main() {',
      'vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );',
      'vec4 worldPosition = modelMatrix * vec4( position, 1.0 );',
      'vViewPosition = -mvPosition.xyz;',
      'vNormal = normalize( normalMatrix * normal );',
      'vUv = uv * offsetRepeat.zw + offsetRepeat.xy;',
      'gl_Position = projectionMatrix * mvPosition;',
      ShaderChunk['shadowmap_vertex'],
      '}'
    ].join('\n')
  },

  /* ------------------------------------------------------------------------------------------
  //  Skin shader
  //    - Blinn-Phong diffuse term (using normal + diffuse maps)
  //    - subsurface scattering approximation by four blur layers
  //    - physically based specular term (Kelemen/Szirmay-Kalos specular reflectance)
  //
  //    - point and directional lights (use with 'lights: true' material option)
  //
  //    - based on Nvidia Advanced Skin Rendering GDC 2007 presentation
  //      and GPU Gems 3 Chapter 14. Advanced Techniques for Realistic Real-Time Skin Rendering
  //
  //      http://developer.download.nvidia.com/presentations/2007/gdc/Advanced_Skin.pdf
  //      http://http.developer.nvidia.com/GPUGems3/gpugems3_ch14.html
  // ------------------------------------------------------------------------------------------ */

  'skin': {
    'uniforms': uniforms_utils.merge([
      UniformsLib['fog'],
      UniformsLib['lights'],
      {
        'passID': new Uniform.int(0),
        'tDiffuse': new Uniform.texture(),
        'tNormal': new Uniform.texture(),
        'tBlur1': new Uniform.texture(),
        'tBlur2': new Uniform.texture(),
        'tBlur3': new Uniform.texture(),
        'tBlur4': new Uniform.texture(),
        'tBeckmann': new Uniform.texture(),
        'uNormalScale': new Uniform.float(1.0),
        'diffuse': new Uniform.color(0xeeeeee),
        'specular': new Uniform.color(0x111111),
        'opacity': new Uniform.float(1.0),
        'uRoughness': new Uniform.float(0.15),
        'uSpecularBrightness': new Uniform.float(0.75)
      }
    ]),
    'fragmentShader': [
      'uniform vec3 diffuse;',
      'uniform vec3 specular;',
      'uniform float opacity;',
      'uniform float uRoughness;',
      'uniform float uSpecularBrightness;',
      'uniform int passID;',
      'uniform sampler2D tDiffuse;',
      'uniform sampler2D tNormal;',
      'uniform sampler2D tBlur1;',
      'uniform sampler2D tBlur2;',
      'uniform sampler2D tBlur3;',
      'uniform sampler2D tBlur4;',
      'uniform sampler2D tBeckmann;',
      'uniform float uNormalScale;',
      'varying vec3 vTangent;',
      'varying vec3 vBinormal;',
      'varying vec3 vNormal;',
      'varying vec2 vUv;',
      'uniform vec3 ambientLightColor;',
      '#if MAX_DIR_LIGHTS > 0',
      'uniform vec3 directionalLightColor[ MAX_DIR_LIGHTS ];',
      'uniform vec3 directionalLightDirection[ MAX_DIR_LIGHTS ];',
      '#endif',
      '#if MAX_POINT_LIGHTS > 0',
      'uniform vec3 pointLightColor[ MAX_POINT_LIGHTS ];',
      'varying vec4 vPointLight[ MAX_POINT_LIGHTS ];',
      '#endif',
      'varying vec3 vViewPosition;',
      ShaderChunk['common'],
      ShaderChunk['fog_pars_fragment'],
      'float fresnelReflectance( vec3 H, vec3 V, float F0 ) {',
      'float base = 1.0 - dot( V, H );',
      'float exponential = pow( base, 5.0 );',
      'return exponential + F0 * ( 1.0 - exponential );',
      '}',

      // Kelemen/Szirmay-Kalos specular BRDF

      'float KS_Skin_Specular( vec3 N,', // Bumped surface normal
      'vec3 L,', // Points to light
      'vec3 V,', // Points to eye
      'float m,', // Roughness
      'float rho_s', // Specular brightness
      ') {',
      'float result = 0.0;',
      'float ndotl = dot( N, L );',
      'if( ndotl > 0.0 ) {',
      'vec3 h = L + V;', // Unnormalized half-way vector
      'vec3 H = normalize( h );',
      'float ndoth = dot( N, H );',
      'float PH = pow( 2.0 * texture2D( tBeckmann, vec2( ndoth, m ) ).x, 10.0 );',
      'float F = fresnelReflectance( H, V, 0.028 );',
      'float frSpec = max( PH * F / dot( h, h ), 0.0 );',
      'result = ndotl * rho_s * frSpec;', // BRDF * dot(N,L) * rho_s

      '}',
      'return result;',
      '}',
      'void main() {',
      'vec3 outgoingLight = vec3( 0.0 );', // outgoing light does not have an alpha, the surface does
      'vec4 diffuseColor = vec4( diffuse, opacity );',
      'vec4 mSpecular = vec4( specular, opacity );',
      'vec3 normalTex = texture2D( tNormal, vUv ).xyz * 2.0 - 1.0;',
      'normalTex.xy *= uNormalScale;',
      'normalTex = normalize( normalTex );',
      'vec4 colDiffuse = texture2D( tDiffuse, vUv );',
      'colDiffuse *= colDiffuse;',
      'diffuseColor *= colDiffuse;',
      'mat3 tsb = mat3( vTangent, vBinormal, vNormal );',
      'vec3 finalNormal = tsb * normalTex;',
      'vec3 normal = normalize( finalNormal );',
      'vec3 viewPosition = normalize( vViewPosition );',

      // point lights

      'vec3 totalDiffuseLight = vec3( 0.0 );',
      'vec3 totalSpecularLight = vec3( 0.0 );',
      '#if MAX_POINT_LIGHTS > 0',
      'for ( int i = 0; i < MAX_POINT_LIGHTS; i ++ ) {',
      'vec3 pointVector = normalize( vPointLight[ i ].xyz );',
      'float pointDistance = vPointLight[ i ].w;',
      'float pointDiffuseWeight = max( dot( normal, pointVector ), 0.0 );',
      'totalDiffuseLight += pointDistance * pointLightColor[ i ] * pointDiffuseWeight;',
      'if ( passID == 1 )',
      'totalSpecularLight += pointDistance * mSpecular.xyz * pointLightColor[ i ] * KS_Skin_Specular( normal, pointVector, viewPosition, uRoughness, uSpecularBrightness );',
      '}',
      '#endif',

      // directional lights

      '#if MAX_DIR_LIGHTS > 0',
      'for( int i = 0; i < MAX_DIR_LIGHTS; i++ ) {',
      'vec3 dirVector = transformDirection( directionalLightDirection[ i ], viewMatrix );',
      'float dirDiffuseWeight = max( dot( normal, dirVector ), 0.0 );',
      'totalDiffuseLight += directionalLightColor[ i ] * dirDiffuseWeight;',
      'if ( passID == 1 )',
      'totalSpecularLight += mSpecular.xyz * directionalLightColor[ i ] * KS_Skin_Specular( normal, dirVector, viewPosition, uRoughness, uSpecularBrightness );',
      '}',
      '#endif',
      'outgoingLight += diffuseColor.rgb * ( totalDiffuseLight + totalSpecularLight );',
      'if ( passID == 0 ) {',
      'outgoingLight = sqrt( outgoingLight );',
      '} else if ( passID == 1 ) {',

      //'#define VERSION1',

      '#ifdef VERSION1',
      'vec3 nonblurColor = sqrt(outgoingLight );',
      '#else',
      'vec3 nonblurColor = outgoingLight;',
      '#endif',
      'vec3 blur1Color = texture2D( tBlur1, vUv ).xyz;',
      'vec3 blur2Color = texture2D( tBlur2, vUv ).xyz;',
      'vec3 blur3Color = texture2D( tBlur3, vUv ).xyz;',
      'vec3 blur4Color = texture2D( tBlur4, vUv ).xyz;',

      //'gl_FragColor = vec4( blur1Color, gl_FragColor.w );',

      //'gl_FragColor = vec4( vec3( 0.22, 0.5, 0.7 ) * nonblurColor + vec3( 0.2, 0.5, 0.3 ) * blur1Color + vec3( 0.58, 0.0, 0.0 ) * blur2Color, gl_FragColor.w );',

      //'gl_FragColor = vec4( vec3( 0.25, 0.6, 0.8 ) * nonblurColor + vec3( 0.15, 0.25, 0.2 ) * blur1Color + vec3( 0.15, 0.15, 0.0 ) * blur2Color + vec3( 0.45, 0.0, 0.0 ) * blur3Color, gl_FragColor.w );',

      'outgoingLight = vec3( vec3( 0.22,  0.437, 0.635 ) * nonblurColor + ',
      'vec3( 0.101, 0.355, 0.365 ) * blur1Color + ',
      'vec3( 0.119, 0.208, 0.0 )   * blur2Color + ',
      'vec3( 0.114, 0.0,   0.0 )   * blur3Color + ',
      'vec3( 0.444, 0.0,   0.0 )   * blur4Color );',
      'outgoingLight *= sqrt( colDiffuse.xyz );',
      'outgoingLight += ambientLightColor * diffuse * colDiffuse.xyz + totalSpecularLight;',
      '#ifndef VERSION1',
      'outgoingLight = sqrt( outgoingLight );',
      '#endif',
      '}',
      ShaderChunk['fog_fragment'],
      'gl_FragColor = vec4( outgoingLight, diffuseColor.a );', // TODO, this should be pre-multiplied to allow for bright highlights on very transparent objects

      '}'
    ].join('\n'),
    'vertexShader': [
      'attribute vec4 tangent;',
      '#ifdef VERTEX_TEXTURES',
      'uniform sampler2D tDisplacement;',
      'uniform float uDisplacementScale;',
      'uniform float uDisplacementBias;',
      '#endif',
      'varying vec3 vTangent;',
      'varying vec3 vBinormal;',
      'varying vec3 vNormal;',
      'varying vec2 vUv;',
      '#if MAX_POINT_LIGHTS > 0',
      'uniform vec3 pointLightPosition[ MAX_POINT_LIGHTS ];',
      'uniform float pointLightDistance[ MAX_POINT_LIGHTS ];',
      'uniform float pointLightDecay[ MAX_POINT_LIGHTS ];',
      'varying vec4 vPointLight[ MAX_POINT_LIGHTS ];',
      '#endif',
      'varying vec3 vViewPosition;',
      ShaderChunk['common'],
      'void main() {',
      'vec4 worldPosition = modelMatrix * vec4( position, 1.0 );',
      'vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );',
      'vViewPosition = -mvPosition.xyz;',
      'vNormal = normalize( normalMatrix * normal );',

      // tangent and binormal vectors

      'vTangent = normalize( normalMatrix * tangent.xyz );',
      'vBinormal = cross( vNormal, vTangent ) * tangent.w;',
      'vBinormal = normalize( vBinormal );',
      'vUv = uv;',

      // point lights

      '#if MAX_POINT_LIGHTS > 0',
      'for( int i = 0; i < MAX_POINT_LIGHTS; i++ ) {',
      'vec4 lPosition = viewMatrix * vec4( pointLightPosition[ i ], 1.0 );',
      'vec3 lVector = lPosition.xyz - mvPosition.xyz;',
      'float attenuation = calcLightAttenuation( length( lVector ), pointLightDistance[ i ], pointLightDecay[i] );',
      'lVector = normalize( lVector );',
      'vPointLight[ i ] = vec4( lVector, attenuation );',
      '}',
      '#endif',

      // displacement mapping

      '#ifdef VERTEX_TEXTURES',
      'vec3 dv = texture2D( tDisplacement, uv ).xyz;',
      'float df = uDisplacementScale * dv.x + uDisplacementBias;',
      'vec4 displacedPosition = vec4( vNormal.xyz * df, 0.0 ) + mvPosition;',
      'gl_Position = projectionMatrix * displacedPosition;',
      '#else',
      'gl_Position = projectionMatrix * mvPosition;',
      '#endif',
      '}'
    ].join('\n'),
    'vertexShaderUV': [
      'attribute vec4 tangent;',
      '#ifdef VERTEX_TEXTURES',
      'uniform sampler2D tDisplacement;',
      'uniform float uDisplacementScale;',
      'uniform float uDisplacementBias;',
      '#endif',
      'varying vec3 vTangent;',
      'varying vec3 vBinormal;',
      'varying vec3 vNormal;',
      'varying vec2 vUv;',
      '#if MAX_POINT_LIGHTS > 0',
      'uniform vec3 pointLightPosition[ MAX_POINT_LIGHTS ];',
      'uniform float pointLightDistance[ MAX_POINT_LIGHTS ];',
      'uniform float pointLightDecay[ MAX_POINT_LIGHTS ];',
      'varying vec4 vPointLight[ MAX_POINT_LIGHTS ];',
      '#endif',
      'varying vec3 vViewPosition;',
      ShaderChunk['common'],
      'void main() {',
      'vec4 worldPosition = modelMatrix * vec4( position, 1.0 );',
      'vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );',
      'vViewPosition = -mvPosition.xyz;',
      'vNormal = normalize( normalMatrix * normal );',

      // tangent and binormal vectors

      'vTangent = normalize( normalMatrix * tangent.xyz );',
      'vBinormal = cross( vNormal, vTangent ) * tangent.w;',
      'vBinormal = normalize( vBinormal );',
      'vUv = uv;',

      // point lights

      '#if MAX_POINT_LIGHTS > 0',
      'for( int i = 0; i < MAX_POINT_LIGHTS; i++ ) {',
      'vec4 lPosition = viewMatrix * vec4( pointLightPosition[ i ], 1.0 );',
      'vec3 lVector = lPosition.xyz - mvPosition.xyz;',
      'float attenuation = calcLightAttenuation( length( lVector ), pointLightDistance[ i ], pointLightDecay[i] );',
      'lVector = normalize( lVector );',
      'vPointLight[ i ] = vec4( lVector, attenuation );',
      '}',
      '#endif',
      'gl_Position = vec4( uv.x * 2.0 - 1.0, uv.y * 2.0 - 1.0, 0.0, 1.0 );',
      '}'
    ].join('\n')
  },

  /* ------------------------------------------------------------------------------------------
  // Beckmann distribution function
  //  - to be used in specular term of skin shader
  //  - render a screen-aligned quad to precompute a 512 x 512 texture
  //
  //    - from http://developer.nvidia.com/node/171
   ------------------------------------------------------------------------------------------ */

  'beckmann': {
    'uniforms': {},
    'vertexShader': [
      'varying vec2 vUv;',
      'void main() {',
      'vUv = uv;',
      'gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
      '}'
    ].join('\n'),
    'fragmentShader': [
      'varying vec2 vUv;',
      'float PHBeckmann( float ndoth, float m ) {',
      'float alpha = acos( ndoth );',
      'float ta = tan( alpha );',
      'float val = 1.0 / ( m * m * pow( ndoth, 4.0 ) ) * exp( -( ta * ta ) / ( m * m ) );',
      'return val;',
      '}',
      'float KSTextureCompute( vec2 tex ) {',

      // Scale the value to fit within [0,1]  invert upon lookup.

      'return 0.5 * pow( PHBeckmann( tex.x, tex.y ), 0.1 );',
      '}',
      'void main() {',
      'float x = KSTextureCompute( vUv );',
      'gl_FragColor = vec4( x, x, x, 1.0 );',
      '}'
    ].join('\n')
  }
};
