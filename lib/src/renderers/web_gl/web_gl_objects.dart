/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

class WebGLObjects {
  Map objects = {};
  List objectsImmediate = [];

  WebGLGeometries geometries;

  var geometryGroups = {};
  var geometryGroupCounter = 0;

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
    } else if (object is ImmediateRenderObject || object.immediateRenderCallback) {
      removeInstances(objectsImmediate, object);
    }

    object.__webglInit = false;
    object._modelViewMatrix = null;
    object._normalMatrix = null;

    object.__webglActive = false;
  }

  void removeInstances(List objlist, object) {
    for (var o = objlist.length - 1; o >= 0; o--) {
      if (objlist[o].object == object){
        objlist.removeAt(o);
      }
    }
  }

  void init(Object3D object) {
    if (object.__webglInit == null){
      object.__webglInit = true;
      object._modelViewMatrix = new Matrix4.identity();
      object._normalMatrix = new Matrix3.identity();

      object._objectRemovedSubscription = object.onObjectRemoved.listen(onObjectRemoved);
    }

    if (object.__webglActive == null) {
      object.__webglActive = true;

      if (object is Mesh || object is Line || object is PointCloud) {
        objects[object.id] =
            new WebGLObject(id: object.id, object: object, material: null, z: 0);

      } else if (object is ImmediateRenderObject || object.immediateRenderCallback) {
        objectsImmediate.add(
            new WebGLObject(id: null, object: object, opaque: null, transparent: null, z: 0));
      }
    }
  }

  void update(GeometryMaterialObject object) {
    var geometry = geometries.get(object);

    if (object.geometry is DynamicGeometry) {
      geometry.updateFromObject(object);
    }

    geometry.updateFromMaterial(object.material);

    if (geometry is BufferGeometry) {
      var attributes = geometry.attributes;

      attributes.keys.forEach((key) {
        var attribute = attributes[key];
        var bufferType = (key == 'index') ? gl.ELEMENT_ARRAY_BUFFER : gl.ARRAY_BUFFER;

        var data = (attribute is InterleavedBufferAttribute) ? attribute.data : attribute;

        if (data.buffer == null) {
          data.buffer = _gl.createBuffer();
          _gl.bindBuffer(bufferType, data.buffer);

          var usage = gl.STATIC_DRAW;

          if (data is DynamicBufferAttribute ||
              (data is InstancedBufferAttribute && data.dynamic) ||
              (data is InterleavedBuffer && data.dynamic)) {
            usage = gl.DYNAMIC_DRAW;
          }

          _gl.bufferData(bufferType, data.array, usage);

          data.needsUpdate = false;

        } else if (data.needsUpdate) {
          _gl.bindBuffer(bufferType, data.buffer);

          if (data.updateRange == null || data.updateRange.count == -1) { // Not using update ranges
            _gl.bufferSubData(bufferType, 0, data.array);
          } else if (data.updateRange.count == 0){
            error('WebGLRenderer.updateObject: using updateRange for DynamicBufferAttribute and marked' +
                  'as needsUpdate but count is 0, ensure you are using set methods or updating manually.');
          } else {
            _gl.bufferSubData(bufferType, data.updateRange.offset * data.array.BYTES_PER_ELEMENT,
                data.array.subarray(data.updateRange.offset, data.updateRange.offset + data.updateRange.count));

            data.updateRange.count = 0; // reset range
          }

          data.needsUpdate = false;
        }
      });
    }
  }
}
