/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

class WebGLGeometries {
  Map geometries = {};

  gl.RenderingContext _gl;
  WebGLRendererInfo _info;

  StreamSubscription _disposeSubscription;

  WebGLGeometries(this._gl, this._info);

  Geometry get(GeometryObject object) {
    var geometry = object.geometry;

    if (geometries[geometry.id] != null) {
      return geometries[geometry.id];
    }

    _disposeSubscription = geometry.onDispose.listen(onGeometryDispose);

    if (geometry is BufferGeometry) {
      geometries[geometry.id] = geometry;
    } else {
      geometries[geometry.id] = new BufferGeometry()
        ..setFromObject(object as Object3D);
    }

    _info.memory.geometries++;

    return geometries[geometry.id];
  }

  void onGeometryDispose(Geometry geometry) {
    _disposeSubscription.cancel();

    var geo = geometries[geometry.id];

    for (var name in geo.attributes) {
      var attribute = geo.attributes[name];

      if (attribute.buffer != null) {
        _gl.deleteBuffer(attribute.buffer);

        attribute.buffer = null;
      }
    }

    _info.memory.geometries--;
  }
}

