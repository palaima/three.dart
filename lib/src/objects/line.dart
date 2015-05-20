/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author adam smith / http://financecoding.wordpress.com/
 *
 * based on r71
 */

part of three.objects;

/// A line or a series of lines.
///
/// Example
///
///     var material = new LineBasicMaterial(color: 0x0000ff);
///     var geometry = new THREE.Geometry();
///
///     geometry.vertices.add(
///       new Vector3(-10.0, 0.0, 0.0), new Vector3(0.0, 10.0, 0.0), new Vector3(10.0, 0.0, 0.0));
///
///     var line = new Line(geometry, material);
///     scene.add(line);
///
class Line extends Object3D implements GeometryMaterialObject {
  String type = 'Line';

  IGeometry geometry;
  Material material;

  /// Creates a new [Line].
  Line([IGeometry geometry, LineMaterial material]) : super() {
    this.geometry = geometry != null ? geometry : new Geometry();
    this.material = material != null ? (material as Material) : new LineBasicMaterial(color: new math.Random().nextInt(0xffffff));
  }

  /// Returns intersections between a casted ray and this Line.
  /// Raycaster.intersectObject will call this method.
  raycast(raycaster, intersects) {
    throw new UnimplementedError();
  }

  /// Returns a clone of [this].
  Line clone([Object3D object, bool recursive = true]) {
    if (object == null) object = new Line(geometry, material as LineMaterial);

    super.clone(object, recursive);

    return object;
  }
}
