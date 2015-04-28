/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on 82b4f9dda28b7df74023db6bb21d6df249a30158
 */

part of three;

class WebGLShadowMap {
  gl.RenderingContext _gl;

  Frustum _frustum = new Frustum();
  Matrix4 _projScreenMatrix = new Matrix4.identity();

  Vector3 _min = new Vector3.zero();
  Vector3 _max = new Vector3.zero();

  ShaderMaterial _depthMaterial, _depthMaterialMorph, _depthMaterialSkin, _depthMaterialMorphSkin;

  Vector3 _matrixPosition = new Vector3.zero();

  List<WebGLObject> _renderList = [];

  bool enabled = false;

  int type = PCFShadowMap;
  int cullFace = CullFaceFront;

  bool debug = false;
  bool cascade = false;

  WebGLRenderer _renderer;
  List<Light> _lights;
  WebGLObjects _objects;

  WebGLShadowMap(this._renderer, this._lights, this._objects) {
    _gl = _renderer.context;

    var depthShader = ShaderLib['depthRGBA'];
    var depthUniforms = UniformsUtils.clone(depthShader['uniforms']);

    _depthMaterial = new ShaderMaterial(
      uniforms: depthUniforms,
      vertexShader: depthShader['vertexShader'],
      fragmentShader: depthShader['fragmentShader']);

    _depthMaterialMorph = new ShaderMaterial(
      uniforms: depthUniforms,
      vertexShader: depthShader['vertexShader'],
      fragmentShader: depthShader['fragmentShader'],
      morphTargets: true);

    _depthMaterialSkin = new ShaderMaterial(
      uniforms: depthUniforms,
      vertexShader: depthShader['vertexShader'],
      fragmentShader: depthShader['fragmentShader'],
      skinning: true);

    _depthMaterialMorphSkin = new ShaderMaterial(
      uniforms: depthUniforms,
      vertexShader: depthShader['vertexShader'],
      fragmentShader: depthShader['fragmentShader'],
      morphTargets: true,
      skinning: true);

    _depthMaterial._shadowPass = true;
    _depthMaterialMorph._shadowPass = true;
    _depthMaterialSkin._shadowPass = true;
    _depthMaterialMorphSkin._shadowPass = true;
  }

  void render(Scene scene, Camera camera) {
    if (!enabled) return;

    // set GL state for depth map

    _gl.clearColor(1, 1, 1, 1);
    _gl.disable(gl.BLEND);

    _gl.enable(gl.CULL_FACE);
    _gl.frontFace(gl.CCW);

    if (cullFace == CullFaceFront) {
      _gl.cullFace(gl.FRONT);
    } else {
      _gl.cullFace(gl.BACK);
    }

    _renderer.state.setDepthTest(true);

    // preprocess lights
    //  - skip lights that are not casting shadows
    //  - create virtual lights for cascaded shadow maps

    List<VirtualLight> lights = new List(_lights.length);
    var virtualLight;
    var k = 0;

    for (var i = 0; i < _lights.length; i++) {
      var light = _lights[i];

      if (!light.castShadow) continue;

      if (light is DirectionalLight && light.shadowCascade) {
        for (var n = 0; n < light.shadowCascadeCount; n++) {
          if (!light.shadowCascadeArray[n]) {
            virtualLight = createVirtualLight(light, n);
            virtualLight.originalCamera = camera;

            var gyro = new Gyroscope()
              ..position.setFrom(light.shadowCascadeOffset);

            gyro.add(virtualLight);
            gyro.add(virtualLight.target);

            camera.add(gyro);

            light.shadowCascadeArray[n] = virtualLight;
          } else {
            virtualLight = light.shadowCascadeArray[n];
          }

          updateVirtualLight(light, n);

          lights[k] = virtualLight;
          k++;
        }
      } else {
        lights[k] = light;
        k++;
      }
    }

    // render depth map

    for (var i = 0; i < lights.length; i++) {
      var light = lights[i];

      if (light.shadowMap == null) {
        var shadowFilter = LinearFilter;

        if (type == PCFSoftShadowMap) {
          shadowFilter = NearestFilter;
        }

        light.shadowMap = new WebGLRenderTarget(light.shadowMapWidth, light.shadowMapHeight,
            minFilter: shadowFilter, magFilter: shadowFilter, format: RGBAFormat);

        light.shadowMapSize = new Vector2(light.shadowMapWidth.toDouble(), light.shadowMapHeight.toDouble());

        light.shadowMatrix = new Matrix4.identity();
      }

      if (light.shadowCamera == null) {
        if (light is SpotLight) {
          light.shadowCamera = new PerspectiveCamera(light.shadowCameraFov,
              light.shadowMapWidth / light.shadowMapHeight, light.shadowCameraNear, light.shadowCameraFar);
        } else if (light is DirectionalLight) {
          light.shadowCamera = new OrthographicCamera(light.shadowCameraLeft, light.shadowCameraRight,
              light.shadowCameraTop, light.shadowCameraBottom, light.shadowCameraNear, light.shadowCameraFar);
        } else {
          error('ShadowMapPlugin: Unsupported light type for shadow $light');
          continue;
        }

        scene.add(light.shadowCamera);

        if (scene.autoUpdate) scene.updateMatrixWorld();
      }

      if (light.shadowCameraVisible && light._cameraHelper == null) {
        light._cameraHelper = new CameraHelper(light.shadowCamera);
        scene.add(light.cameraHelper);
      }

      if (light is VirtualLight && light.originalCamera == camera) {
        updateShadowCamera(camera, light);
      }


      var shadowMap = light.shadowMap;
      var shadowMatrix = light.shadowMatrix;
      var shadowCamera = light.shadowCamera;

      //

      shadowCamera.position.setFromMatrixTranslation(light.matrixWorld);
      _matrixPosition.setFromMatrixTranslation(light.target.matrixWorld);
      shadowCamera.lookAt(_matrixPosition);
      shadowCamera.updateMatrixWorld();

      shadowCamera.matrixWorldInverse.copyInverse(shadowCamera.matrixWorld);

      //

      if (light._cameraHelper != null) light.cameraHelper.visible = light.shadowCameraVisible;
      if (light.shadowCameraVisible) light.cameraHelper.update();

      // compute shadow matrix

      shadowMatrix.setValues(
        0.5, 0.0, 0.0, 0.5,
        0.0, 0.5, 0.0, 0.5,
        0.0, 0.0, 0.5, 0.5,
        0.0, 0.0, 0.0, 1.0);

      shadowMatrix.multiply(shadowCamera.projectionMatrix);
      shadowMatrix.multiply(shadowCamera.matrixWorldInverse);

      // update camera matrices and frustum

      _projScreenMatrix.multiplyMatrices(shadowCamera.projectionMatrix, shadowCamera.matrixWorldInverse);
      _frustum.setFromMatrix(_projScreenMatrix);

      // render shadow map

      _renderer.setRenderTarget(shadowMap);
      _renderer.clear();

      // set object matrices & frustum culling

      _renderList.length = 0;

      projectObject(scene, scene, shadowCamera);


      // render regular objects

      var objectMaterial, useMorphing, useSkinning;
      var material;

      _renderList.forEach((webglObject) {
        var object = webglObject.object;
        var buffer = _objects.geometries.get(object);

        // culling is overriden globally for all objects
        // while rendering depth map

        // need to deal with MeshFaceMaterial somehow
        // in that case just use the first of material.materials for now
        // (proper solution would require to break objects by materials
        //  similarly to regular rendering and then set corresponding
        //  depth materials per each chunk instead of just once per object)

        objectMaterial = object.material;

        useMorphing = object.geometry.morphTargets != null &&
                      object.geometry.morphTargets.length > 0 &&
                      objectMaterial.morphTargets;

        useSkinning = object is SkinnedMesh && objectMaterial.skinning;

        if (object.customDepthMaterial != null) {
          material = object.customDepthMaterial;
        } else if (useSkinning) {
          material = useMorphing ? _depthMaterialMorphSkin : _depthMaterialSkin;
        } else if (useMorphing) {
          material = _depthMaterialMorph;
        } else {
          material = _depthMaterial;
        }

        _renderer.setMaterialFaces(objectMaterial);

        _renderer.renderBufferDirect(shadowCamera, _lights, null, material, buffer, object);
      });

      // set matrices and render immediate objects

      _objects.objectsImmediate.forEach((webglObject) {
        var object = webglObject.object;

        if (object.visible && object.castShadow) {
          object._modelViewMatrix = shadowCamera.matrixWorldInverse * object.matrixWorld;

          _renderer.renderImmediateObject(shadowCamera, _lights, null, _depthMaterial, object);
        }
      });
    }

    // restore GL state

    var clearColor = _renderer.getClearColor(),
    clearAlpha = _renderer.getClearAlpha();

    _gl.clearColor(clearColor.r, clearColor.g, clearColor.b, clearAlpha);
    _gl.enable(gl.BLEND);

    if (cullFace == CullFaceFront) {
      _gl.cullFace(gl.BACK);
    }

    _renderer.resetGLState();
  }

  void projectObject(Scene scene, Object3D object, Camera shadowCamera) {
    if (object.visible) {
      var webglObject = _objects.objects[object.id];

      if (webglObject != null && object.castShadow && (!object.frustumCulled || _frustum.intersectsWithObject(object))) {
        object._modelViewMatrix = shadowCamera.matrixWorldInverse * object.matrixWorld;
        _renderList.add(webglObject);
      }

      object.children.forEach((child) => projectObject(scene, child, shadowCamera));
    }
  }

  VirtualLight createVirtualLight(ShadowCaster light, int cascade) {
    var virtualLight = new VirtualLight();

    virtualLight.onlyShadow = true;
    virtualLight.castShadow = true;

    virtualLight.shadowCameraNear = light.shadowCameraNear;
    virtualLight.shadowCameraFar = light.shadowCameraFar;

    virtualLight.shadowCameraLeft = light.shadowCameraLeft;
    virtualLight.shadowCameraRight = light.shadowCameraRight;
    virtualLight.shadowCameraBottom = light.shadowCameraBottom;
    virtualLight.shadowCameraTop = light.shadowCameraTop;

    virtualLight.shadowCameraVisible = light.shadowCameraVisible;

    virtualLight.shadowDarkness = light.shadowDarkness;

    virtualLight.shadowBias = light.shadowCascadeBias[cascade];
    virtualLight.shadowMapWidth = light.shadowCascadeWidth[cascade];
    virtualLight.shadowMapHeight = light.shadowCascadeHeight[cascade];

    var pointsWorld = virtualLight.pointsWorld,
        pointsFrustum = virtualLight.pointsFrustum;

    for (var i = 0; i < 8; i++) {
      pointsWorld.add(new Vector3.zero());
      pointsFrustum.add(new Vector3.zero());
    }

    var nearZ = light.shadowCascadeNearZ[cascade];
    var farZ = light.shadowCascadeFarZ[cascade];

    pointsFrustum[0].setValues(-1.0, -1.0, nearZ);
    pointsFrustum[1].setValues(1.0, -1.0, nearZ);
    pointsFrustum[2].setValues(-1.0, 1.0, nearZ);
    pointsFrustum[3].setValues(1.0, 1.0, nearZ);

    pointsFrustum[4].setValues(-1.0, -1.0, farZ);
    pointsFrustum[5].setValues(1.0, -1.0, farZ);
    pointsFrustum[6].setValues(-1.0, 1.0, farZ);
    pointsFrustum[7].setValues(1.0, 1.0, farZ);

    return virtualLight;
  }

  // Synchronize virtual light with the original light

  void updateVirtualLight(VirtualLight light, int cascade) {
    var virtualLight = light.shadowCascadeArray[cascade];

    virtualLight.position.setFrom(light.position);
    virtualLight.target.position.setFrom(light.target.position);
    virtualLight.lookAt(virtualLight.target.position);

    virtualLight.shadowCameraVisible = light.shadowCameraVisible;
    virtualLight.shadowDarkness = light.shadowDarkness;

    virtualLight.shadowBias = light.shadowCascadeBias[cascade];

    var nearZ = light.shadowCascadeNearZ[cascade];
    var farZ = light.shadowCascadeFarZ[cascade];

    var pointsFrustum = virtualLight.pointsFrustum;

    pointsFrustum[0].z = nearZ;
    pointsFrustum[1].z = nearZ;
    pointsFrustum[2].z = nearZ;
    pointsFrustum[3].z = nearZ;

    pointsFrustum[4].z = farZ;
    pointsFrustum[5].z = farZ;
    pointsFrustum[6].z = farZ;
    pointsFrustum[7].z = farZ;
  }

  // Fit shadow camera's ortho frustum to camera frustum

  void updateShadowCamera(Camera camera, VirtualLight light) {
    var shadowCamera = light.shadowCamera,
        pointsFrustum = light.pointsFrustum,
        pointsWorld = light.pointsWorld;

    _min.splat(double.INFINITY);
    _max.splat(-double.INFINITY);

    for (var i = 0; i < 8; i ++) {
      var p = pointsWorld[i];

      p.setFrom(pointsFrustum[i]);
      p.unproject(camera);

      p.applyMatrix4(shadowCamera.matrixWorldInverse);

      if (p.x < _min.x) _min.x = p.x;
      if (p.x > _max.x) _max.x = p.x;

      if (p.y < _min.y) _min.y = p.y;
      if (p.y > _max.y) _max.y = p.y;

      if (p.z < _min.z) _min.z = p.z;
      if (p.z > _max.z) _max.z = p.z;
    }

    shadowCamera.left = _min.x;
    shadowCamera.right = _max.x;
    shadowCamera.top = _max.y;
    shadowCamera.bottom = _min.y;

    shadowCamera.updateProjectionMatrix();
  }
}


class VirtualLight extends DirectionalLight {
  //bool isVirtual = true;
  List<Vector3> pointsWorld = [];
  List<Vector3> pointsFrustum = [];
  Camera originalCamera;
  VirtualLight() : super(0);
}

