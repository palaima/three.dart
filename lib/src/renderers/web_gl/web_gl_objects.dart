/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on https://github.com/mrdoob/three.js/blob/01ccd8df7916ad4883044621fd091d06057682db/src/renderers/webgl/WebGLObjects.js
 */

part of three;

class WebGLObjects {
  Map<int, WebGLObject> objects = {};
  List<WebGLObject> objectsImmediate = [];

  WebGLGeometries geometries;

  Map geometryGroups = {};
  int geometryGroupCounter = 0;

  gl.RenderingContext _gl;
  WebGLRendererInfo _info;

  WebGLObjects(this._gl, this._info) {
    geometries = new WebGLGeometries(_gl, _info);
  }

  void onObjectRemoved(Object3D object) {
    object.traverse((child) {
      child._objectRemovedSubscription.cancel();
      removeObject(child);
    });
  }

  void removeObject(Object3D object) {
    if (object is Mesh || object is PointCloud || object is Line) {
      objects[object.id] = null;
    } else if (object is ImmediateRenderObject || object.immediateRenderCallback != null) {
      removeInstances(objectsImmediate, object);
    }

    object.__webglInit = false;
    object._modelViewMatrix = null;
    object._normalMatrix = null;

    object.__webglActive = false;
  }

  void removeInstances(List<WebGLObject> objlist, Object3D object) {
    for (var o = objlist.length - 1; o >= 0; o--) {
      if (objlist[o].object == object){
        objlist.removeAt(o);
      }
    }
  }

  void init(Object3D object) {
    if (!object.__webglInit) {
      object.__webglInit = true;
      object._modelViewMatrix = new Matrix4.identity();
      object._normalMatrix = new Matrix3.identity();

      object._objectRemovedSubscription = object.onObjectRemoved.listen(onObjectRemoved);
    }

    if (!object.__webglActive) {
      object.__webglActive = true;

      if (object is Mesh || object is Line || object is PointCloud) {
        objects[object.id] =
            new WebGLObject(id: object.id, object: object, material: null, z: 0);

      } else if (object is ImmediateRenderObject || object.immediateRenderCallback != null) {
        objectsImmediate.add(
            new WebGLObject(id: null, object: object, opaque: null, transparent: null, z: 0));
      }
    }
  }

  void _update(Object3D object) {
    var obj = object;
    var geometry = geometries.get(object);

    if (obj is GeometryObject && obj.geometry is DynamicGeometry) {
      geometry.updateFromObject(object);
    }

    if (obj is MaterialObject && obj.material is ShaderMaterial) {
      geometry.updateFromMaterial(obj.material);
    }

    if (geometry is BufferGeometry) {
      for (var key in geometry.attributes.keys) {
        var attribute = geometry.attributes[key];
        var bufferType = (key == 'index') ? gl.ELEMENT_ARRAY_BUFFER : gl.ARRAY_BUFFER;

        var data = (attribute is InterleavedBufferAttribute) ? attribute.data : attribute;

        if (data.buffer == null) {
          data.buffer = new Buffer(_gl);
          data.buffer.bind(bufferType);

          var usage = gl.STATIC_DRAW;

          if (data is DynamicBufferAttribute ||
              (data is InstancedBufferAttribute && data.dynamic) ||
              (data is InterleavedBuffer && data.dynamic)) {
            usage = gl.DYNAMIC_DRAW;
          }

          _gl.bufferDataTyped(bufferType, data.array as TypedData, usage);

          data.needsUpdate = false;
        } else if (data.needsUpdate) {
          data.buffer.bind(bufferType);

          if (data.updateRange == null || (data.updateRange != null && data.updateRange.count == -1)) { // Not using update ranges
            _gl.bufferSubDataTyped(bufferType, 0, data.array as TypedData);
          } else if (data.updateRange.count == 0) {
            error('WebGLRenderer.updateObject: using updateRange for DynamicBufferAttribute and marked' +
                  'as needsUpdate but count is 0, ensure you are using set methods or updating manually.');
          } else {

            _gl.bufferSubData(bufferType, data.updateRange['offset'] * data.bytesPerElement,
                data.array.getRange(data.updateRange['offset'], data.updateRange['offset'] + data.updateRange['count']));

            data.updateRange['count'] = 0; // reset range
          }

          data.needsUpdate = false;
        }
      }
    }
  }

  void update(List<WebGLObject> renderList) {
    for (var i = 0; i < renderList.length; i++) {
      var object = renderList[i].object;
      if (object.material.visible) _update(object);
    }
  }
}
