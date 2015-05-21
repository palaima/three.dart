/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on https://github.com/mrdoob/three.js/blob/bf573f30aff137d574365fe7a645cd3edc0ac739/src/renderers/webgl/WebGLGeometries.js
 */

part of three.renderers;

class WebGLGeometries {
  Map<String, BufferGeometry> geometries = {};

  gl.RenderingContext _gl;
  WebGLRendererInfo _info;

  WebGLGeometries(this._gl, this._info);

  BufferGeometry get(Object3D object) {
    var geometry = (object as GeometryObject).geometry;

    if (geometries[geometry.id] != null) {
      return geometries[geometry.id];
    }

    geometry['_onDisposeSubscription'] = geometry.onDispose.listen(onGeometryDispose);

    if (geometry is BufferGeometry) {
      geometries[geometry.id] = geometry;
    } else {
      geometries[geometry.id] = new BufferGeometry()
        ..setFromObject(object);
    }

    _info.memory.geometries++;

    return geometries[geometry.id];
  }

  void onGeometryDispose(IGeometry geometry) {
    geometry['_onDisposeSubscription'].cancel();

    var geo = geometries[geometry.id];

    for (var name in geo.attributes.keys) {
      var attribute = geo.attributes[name];

      if (attribute.buffer != null) {
        _gl.deleteBuffer(attribute.buffer.glbuffer);

        attribute.buffer = null;
      }
    }

    _info.memory.geometries--;
  }
}

