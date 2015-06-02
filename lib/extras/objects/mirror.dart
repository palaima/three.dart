/*
 * @author Slayvin / http://slayvin.net
 */

library three.extras.objects.mirror;

import 'package:three/three.dart';
import 'package:three/extras/helpers.dart' show ArrowHelper;
import 'package:three/extras/uniforms_utils.dart' as uniforms_utils;

final Map mirrorShader = {
  'uniforms': {
    "mirrorColor": new Uniform.color(0x7f7f7f),
    "mirrorSampler": new Uniform.texture(),
    "textureMatrix": new Uniform.matrix4()
  },
  'vertexShader': '''
    uniform mat4 textureMatrix;
    varying vec4 mirrorCoord;
    void main() {
      vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
      vec4 worldPosition = modelMatrix * vec4(position, 1.0);
      mirrorCoord = textureMatrix * worldPosition;
      gl_Position = projectionMatrix * mvPosition;
    }
''',
  'fragmentShader': '''
    uniform vec3 mirrorColor;
    uniform sampler2D mirrorSampler;
    varying vec4 mirrorCoord;
    float blendOverlay(float base, float blend) {
      return(base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)));
    }
    void main() {
      vec4 color = texture2DProj(mirrorSampler, mirrorCoord);
      color = vec4(blendOverlay(mirrorColor.r, color.r), blendOverlay(mirrorColor.g, color.g), blendOverlay(mirrorColor.b, color.b), 1.0);
      gl_FragColor = color;
    }
'''
};

class Mirror extends Object3D {
  WebGLRenderer renderer;

  PerspectiveCamera camera;

  double clipBias;

  Plane mirrorPlane = new Plane();
  Vector3 normal = new Vector3(0.0, 0.0, 1.0);
  Vector3 mirrorWorldPosition = new Vector3.zero();
  Vector3 cameraWorldPosition = new Vector3.zero();
  Matrix4 rotationMatrix = new Matrix4.identity();
  Vector3 lookAtPosition = new Vector3(0.0, 0.0, -1.0);
  Vector4 clipPlane = new Vector4.zero();

  Matrix4 textureMatrix = new Matrix4.identity();

  PerspectiveCamera mirrorCamera;

  WebGLRenderTarget texture;
  WebGLRenderTarget tempTexture;

  ShaderMaterial material;

  bool matrixNeedsUpdate = true;

  Mirror(this.renderer, this.camera, {int textureWidth: 512,
      int textureHeight: 512, this.clipBias: 0.0, num color: 0x7f7f7f,
      bool debugMode: false}) {
    this.name = 'mirror_$id';

    var width = textureWidth;
    var height = textureHeight;

    var mirrorColor = new Color(color);

    // For debug only, show the normal and plane of the mirror
    if (debugMode) {
      var arrow = new ArrowHelper(
          new Vector3(0.0, 0.0, 1.0), new Vector3.zero(), 10.0, 0xffff80);
      var planeGeometry = new Geometry()
        ..vertices.add(new Vector3(-10.0, -10.0, 0.0))
        ..vertices.add(new Vector3(10.0, -10.0, 0.0))
        ..vertices.add(new Vector3(10.0, 10.0, 0.0))
        ..vertices.add(new Vector3(-10.0, 10.0, 0.0));
      planeGeometry.vertices.add(planeGeometry.vertices[0]);

      var plane =
          new Line(planeGeometry, new LineBasicMaterial(color: 0xffff80));

      add(arrow);
      add(plane);
    }

    mirrorCamera = camera.clone();
    mirrorCamera.matrixAutoUpdate = true;

    texture = new WebGLRenderTarget(width, height);
    tempTexture = new WebGLRenderTarget(width, height);

    var mirrorUniforms = uniforms_utils.clone(mirrorShader['uniforms']);

    material = new ShaderMaterial(
        fragmentShader: mirrorShader['fragmentShader'],
        vertexShader: mirrorShader['vertexShader'],
        uniforms: mirrorUniforms);

    material.uniforms['mirrorSampler'].value = texture;
    material.uniforms['mirrorColor'].value = mirrorColor;
    material.uniforms['textureMatrix'].value = textureMatrix;

    if (!isPowerOfTwo(width) || !isPowerOfTwo(height)) {
      texture.generateMipmaps = false;
      tempTexture.generateMipmaps = false;
    }

    updateTextureMatrix();
    render();
  }

  void renderWithMirror(Mirror otherMirror) {
    // update the mirror matrix to mirror the current view
    updateTextureMatrix();
    matrixNeedsUpdate = false;

    // set the camera of the other mirror so the mirrored view is the reference view
    var tempCamera = otherMirror.camera;
    otherMirror.camera = mirrorCamera;

    // render the other mirror in temp texture
    otherMirror.renderTemp();
    otherMirror.material.uniforms['mirrorSampler'].value =
        otherMirror.tempTexture;

    // render the current mirror
    render();
    matrixNeedsUpdate = true;

    // restore material and camera of other mirror
    otherMirror.material.uniforms['mirrorSampler'].value = otherMirror.texture;
    otherMirror.camera = tempCamera;

    // restore texture matrix of other mirror
    otherMirror.updateTextureMatrix();
  }

  void updateTextureMatrix() {
    updateMatrixWorld();
    camera.updateMatrixWorld();

    mirrorWorldPosition.setFromMatrixTranslation(matrixWorld);
    cameraWorldPosition.setFromMatrixTranslation(camera.matrixWorld);

    rotationMatrix.extractRotation(matrixWorld);

    normal.setValues(0.0, 0.0, 1.0);
    normal.applyMatrix4(rotationMatrix);

    var view = mirrorWorldPosition.clone().sub(cameraWorldPosition);
    view.reflect(normal).negate();
    view.add(mirrorWorldPosition);

    rotationMatrix.extractRotation(camera.matrixWorld);

    lookAtPosition.setValues(0.0, 0.0, -1.0);
    lookAtPosition.applyMatrix4(rotationMatrix);
    lookAtPosition.add(cameraWorldPosition);

    var target = mirrorWorldPosition.clone().sub(lookAtPosition);
    target.reflect(normal).negate();
    target.add(mirrorWorldPosition);

    up.setValues(0.0, -1.0, 0.0);
    up.applyMatrix4(rotationMatrix);
    up.reflect(normal).negate();

    mirrorCamera.position.setFrom(view);
    mirrorCamera.up = up;
    mirrorCamera.lookAt(target);

    mirrorCamera.updateProjectionMatrix();
    mirrorCamera.updateMatrixWorld();
    mirrorCamera.matrixWorldInverse.copyInverse(mirrorCamera.matrixWorld);

    // Update the texture matrix
    textureMatrix.setValues(0.5, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0,
        0.5, 0.0, 0.5, 0.5, 0.5, 1.0);
    textureMatrix.multiply(mirrorCamera.projectionMatrix);
    textureMatrix.multiply(mirrorCamera.matrixWorldInverse);

    // Now update projection matrix with new clip plane, implementing code from: http://www.terathon.com/code/oblique.html
    // Paper explaining this technique: http://www.terathon.com/lengyel/Lengyel-Oblique.pdf
    mirrorPlane.setFromNormalAndCoplanarPoint(normal, mirrorWorldPosition);
    mirrorPlane.applyMatrix4(mirrorCamera.matrixWorldInverse);

    clipPlane.setValues(mirrorPlane.normal.x, mirrorPlane.normal.y,
        mirrorPlane.normal.z, mirrorPlane.constant);

    var q = new Vector4.zero();
    var projectionMatrix = mirrorCamera.projectionMatrix;

    q.x = (clipPlane.x.sign + projectionMatrix.storage[8]) /
        projectionMatrix.storage[0];
    q.y = (clipPlane.y.sign + projectionMatrix.storage[9]) /
        projectionMatrix.storage[5];
    q.z = -1.0;
    q.w = (1.0 + projectionMatrix.storage[10]) / projectionMatrix.storage[14];

    // Calculate the scaled plane vector
    var c = new Vector4.zero();
    c = clipPlane.scale(2.0 / clipPlane.dot(q));

    // Replacing the third row of the projection matrix
    projectionMatrix.storage[2] = c.x;
    projectionMatrix.storage[6] = c.y;
    projectionMatrix.storage[10] = c.z + 1.0 - clipBias;
    projectionMatrix.storage[14] = c.w;
  }

  void render() {
    if (matrixNeedsUpdate) updateTextureMatrix();

    matrixNeedsUpdate = true;

    // Render the mirrored view of the current scene into the target texture
    var scene = this;

    while (scene.parent != null) {
      scene = scene.parent;
    }

    if (scene != null && scene is Scene) {
      renderer.render(scene, mirrorCamera,
          renderTarget: texture, forceClear: true);
    }
  }

  void renderTemp() {
    if (matrixNeedsUpdate) updateTextureMatrix();

    matrixNeedsUpdate = true;

    // Render the mirrored view of the current scene into the target texture
    var scene = this;

    while (scene.parent != null) {
      scene = scene.parent;
    }

    if (scene != null && scene is Scene) {
      renderer.render(scene, mirrorCamera,
          renderTarget: tempTexture, forceClear: true);
    }
  }
}
