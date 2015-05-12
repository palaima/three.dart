/*
 * Camera for rendering cube maps
 *  - renders scene into axis-aligned cube
 *
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r72
 */

part of three.cameras;

class CubeCamera extends Object3D {
  String type = 'CubeCamera';

  WebGLRenderTargetCube renderTarget;

  PerspectiveCamera _cameraPX;
  PerspectiveCamera _cameraNX;
  PerspectiveCamera _cameraPY;
  PerspectiveCamera _cameraNY;
  PerspectiveCamera _cameraPZ;
  PerspectiveCamera _cameraNZ;

  CubeCamera(double near, double far, int cubeResolution) {
    var fov = 90.0, aspect = 1.0;

    _cameraPX = new PerspectiveCamera(fov, aspect, near, far)
      ..up.setValues(0.0, -1.0, 0.0)
      ..lookAt(new Vector3(1.0, 0.0, 0.0));
    add(_cameraPX);

    _cameraNX = new PerspectiveCamera(fov, aspect, near, far)
      ..up.setValues(0.0, -1.0, 0.0)
      ..lookAt(new Vector3(-1.0, 0.0, 0.0));
    add(_cameraNX);

    _cameraPY = new PerspectiveCamera(fov, aspect, near, far)
      ..up.setValues(0.0, 0.0, 1.0)
      ..lookAt(new Vector3(0.0, 1.0, 0.0));
    add(_cameraPY);

    _cameraNY = new PerspectiveCamera(fov, aspect, near, far)
      ..up.setValues(0.0, 0.0, -1.0)
      ..lookAt(new Vector3(0.0, - 1.0, 0.0));
    add(_cameraNY);

    _cameraPZ = new PerspectiveCamera(fov, aspect, near, far)
      ..up.setValues(0.0, -1.0, 0.0)
      ..lookAt(new Vector3(0.0, 0.0, 1.0));
    add(_cameraPZ);

    _cameraNZ = new PerspectiveCamera(fov, aspect, near, far)
      ..up.setValues(0.0, -1.0, 0.0)
      ..lookAt(new Vector3(0.0, 0.0, -1.0));
    add(_cameraNZ);

    renderTarget = new WebGLRenderTargetCube(cubeResolution, cubeResolution, format: RGBFormat, magFilter: LinearFilter, minFilter: LinearFilter);
  }

  void updateCubeMap(WebGLRenderer renderer, Scene scene) {
    if (parent == null) updateMatrixWorld();

    var generateMipmaps = renderTarget.generateMipmaps;

    renderTarget.generateMipmaps = false;

    renderTarget.activeCubeFace = 0;
    renderer.render(scene, _cameraPX, renderTarget: renderTarget);

    renderTarget.activeCubeFace = 1;
    renderer.render(scene, _cameraNX, renderTarget: renderTarget);

    renderTarget.activeCubeFace = 2;
    renderer.render(scene, _cameraPY, renderTarget: renderTarget);

    renderTarget.activeCubeFace = 3;
    renderer.render(scene, _cameraNY, renderTarget: renderTarget);

    renderTarget.activeCubeFace = 4;
    renderer.render(scene, _cameraPZ, renderTarget: renderTarget);

    renderTarget.generateMipmaps = generateMipmaps;

    renderTarget.activeCubeFace = 5;
    renderer.render(scene, _cameraNZ, renderTarget: renderTarget);

    renderer.setRenderTarget(null);
  }
}
