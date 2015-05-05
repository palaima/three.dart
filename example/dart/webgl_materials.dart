import 'dart:html';
import 'dart:math' as Math;
import 'package:three/three.dart';

var container, stats;

var camera, scene, renderer, objects;
var particleLight;

var materials = [];

main() {
  init();
  animate(0);
}


init() {

  container = document.createElement( 'div' );
  document.body.append( container );

  camera = new PerspectiveCamera( 45.0, window.innerWidth / window.innerHeight, 1.0, 2000.0 );
  camera.position.setValues( 0.0, 200.0, 800.0 );

  scene = new Scene();

  // Grid

  var line_material = new LineBasicMaterial( color: 0x303030  ),
    geometry = new Geometry(),
    floor = -75.0, step = 25;

  for ( var i = 0; i <= 40; i ++ ) {

    geometry.vertices.add( new Vector3( - 500.0, floor, i * step - 500.0 ) );
    geometry.vertices.add( new Vector3(   500.0, floor, i * step - 500.0 ) );

    geometry.vertices.add( new Vector3( i * step - 500.0, floor, -500.0 ) );
    geometry.vertices.add( new Vector3( i * step - 500.0, floor,  500.0 ) );

  }

  var line = new LineSegments( geometry, line_material );
  scene.add( line );

  // Materials

  var texture = new Texture( generateTexture() );
  texture.needsUpdate = true;

  materials.add( new MeshLambertMaterial( map: texture, transparent: true  ) );
  materials.add( new MeshLambertMaterial(  color: 0xdddddd, shading: FlatShading  ) );
  materials.add( new MeshPhongMaterial(  color: 0xdddddd, specular: 0x009900, shininess: 30.0, shading: FlatShading  ) );
  materials.add( new MeshNormalMaterial( ) );
  materials.add( new MeshBasicMaterial(  color: 0xffaa00, transparent: true, blending: AdditiveBlending  ) );

  materials.add( new MeshLambertMaterial(  color: 0xdddddd, shading: SmoothShading  ) );
  materials.add( new MeshPhongMaterial(  color: 0xdddddd, specular: 0x009900, shininess: 30.0, shading: SmoothShading, map: texture, transparent: true  ) );
  materials.add( new MeshNormalMaterial()); // shading: SmoothShading  ) );
  materials.add( new MeshBasicMaterial(  color: 0xffaa00, wireframe: true  ) );

  materials.add( new MeshDepthMaterial() );

  materials.add( new MeshLambertMaterial(  color: 0x666666, emissive: 0xff0000, shading: SmoothShading  ) );
  materials.add( new MeshPhongMaterial(  color: 0x000000, specular: 0x666666, emissive: 0xff0000, shininess: 10.0, shading: SmoothShading, opacity: 0.9, transparent: true  ) );

  materials.add( new MeshBasicMaterial(  map: texture, transparent: true  ) );

  // Spheres geometry

  var geometry_smooth = new SphereGeometry( 70.0, 32, 16 );
  var geometry_flat = new SphereGeometry( 70.0, 32, 16 );

  objects = [];

  var sphere, material;

  var rnd = new Math.Random();

  for ( var i = 0, l = materials.length; i < l; i ++ ) {

    material = materials[ i ];

    geometry = material.shading == FlatShading ? geometry_flat : geometry_smooth;

    sphere = new Mesh( geometry, material );

    sphere.position.x = ( i % 4 ) * 200.0 - 400.0;
    sphere.position.z = ( i / 4 ).floor() * 200.0 - 200.0;

    sphere.rotation.x = rnd.nextDouble() * 200.0 - 100.0;
    sphere.rotation.y = rnd.nextDouble() * 200.0 - 100.0;
    sphere.rotation.z = rnd.nextDouble() * 200.0 - 100.0;

    objects.add( sphere );

    scene.add( sphere );

  }

  particleLight = new Mesh( new SphereGeometry( 4.0, 8, 8 ), new MeshBasicMaterial( color: 0xffffff  ) );
  scene.add( particleLight );

  // Lights

  scene.add( new AmbientLight( 0x111111 ) );

  var directionalLight = new DirectionalLight( /*Math.random() * */ 0xffffff, 0.125 );

  directionalLight.position.x = rnd.nextDouble() - 0.5;
  directionalLight.position.y = rnd.nextDouble() - 0.5;
  directionalLight.position.z = rnd.nextDouble() - 0.5;

  directionalLight.position.normalize();

  scene.add( directionalLight );

  var pointLight = new PointLight(0xffffff);
  particleLight.add( pointLight );

  //

  renderer = new WebGLRenderer( antialias: true );
  renderer.setPixelRatio( window.devicePixelRatio );
  renderer.setSize( window.innerWidth, window.innerHeight );
  container.append( renderer.domElement );

  //

//  stats = new Stats();
//  stats.domElement.style.position = 'absolute';
//  stats.domElement.style.top = '0px';
//
//  container.appendChild( stats.domElement );

  //

  window.addEventListener( 'resize', onWindowResize, false );

}

onWindowResize(Event e) {

  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();

  renderer.setSize( window.innerWidth, window.innerHeight );

}

generateTexture() {

  var canvas = new CanvasElement();
  canvas.width = 256;
  canvas.height = 256;

  var context = canvas.getContext( '2d' );
  var image = context.getImageData( 0, 0, 256, 256 );

  var x = 0, y = 0;

  for ( var i = 0, j = 0, l = image.data.length; i < l; i += 4, j ++ ) {

    x = j % 256;
    y = x == 0 ? y + 1 : y;

    image.data[ i ] = 255;
    image.data[ i + 1 ] = 255;
    image.data[ i + 2 ] = 255;
    image.data[ i + 3 ] = ( x ^ y ).floor();

  }

  context.putImageData( image, 0, 0 );

  return canvas;

}

//

animate(num time) {
  window.requestAnimationFrame( animate );

  render();
  //stats.update();
}

render() {

  var timer = 0.0001 * new DateTime.now().millisecondsSinceEpoch;

  camera.position.x = Math.cos( timer ) * 1000;
  camera.position.z = Math.sin( timer ) * 1000;

  camera.lookAt( scene.position );

  for ( var i = 0, l = objects.length; i < l; i ++ ) {

    var object = objects[ i ];

    object.rotation.x += 0.01;
    object.rotation.y += 0.005;

  }

  materials[ materials.length - 2 ].emissive.setHSL( 0.54, 1.0, 0.35 * ( 0.5 + 0.5 * Math.sin( 35 * timer ) ) );
  materials[ materials.length - 3 ].emissive.setHSL( 0.04, 1.0, 0.35 * ( 0.5 + 0.5 * Math.cos( 35 * timer ) ) );

  particleLight.position.x = Math.sin( timer * 7 ) * 300;
  particleLight.position.y = Math.cos( timer * 5 ) * 400;
  particleLight.position.z = Math.cos( timer * 3 ) * 300;

  renderer.render( scene, camera );

}