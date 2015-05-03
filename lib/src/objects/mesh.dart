part of three;

/*
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 * @author mikael emtinger / http://gomo.se/
 * @author jonobr1 / http://jonobr1.com/
 *
 * based on r71
 */

/// Base class for Mesh objects, such as MorphAnimMesh and SkinnedMesh.
class Mesh extends Object3D implements GeometryMaterialObject {
  String type = 'Mesh';

  IGeometry geometry;

  /// Defines the object's appearance.
  /// Default is a MeshBasicMaterial with wireframe mode enabled and randomised colour.
  Material material;

  int morphTargetBase = 0;
  List morphTargetForcedOrder;
  List morphTargetInfluences;
  Map morphTargetDictionary;

  Mesh([IGeometry geometry, Material material]) : super() {
    this.geometry = geometry != null ? geometry : new Geometry();
    this.material = material != null
        ? material
        : new MeshBasicMaterial(color: new Math.Random().nextInt(0xffffff));

    updateMorphTargets();
  }

  void updateMorphTargets() {
    if (geometry.morphTargets != null && geometry.morphTargets.length > 0) {
      morphTargetBase = -1;
      morphTargetForcedOrder = [];
      morphTargetInfluences = [];
      morphTargetDictionary = {};

      for (var m = 0; m < geometry.morphTargets.length; m++) {
        morphTargetInfluences.add(0);
        morphTargetDictionary[geometry.morphTargets[m].name] = m;
      }
    }
  }

  /// Returns the index of a morph target defined by name.
  int getMorphTargetIndexByName(String name) {
    if (morphTargetDictionary[name] != null) {
      return morphTargetDictionary[name];
    }

    warn("Mesh.getMorphTargetIndexByName: morph target $name does not exist. Returning 0.");
    return 0;
  }

  static final _inverseMatrix = new Matrix4.identity();
  static final _ray = new Ray();
  static final _sphere = new Sphere();

  static final _vA = new Vector3.zero();
  static final _vB = new Vector3.zero();
  static final _vC = new Vector3.zero();

  void raycast(Raycaster raycaster, List<RayIntersection> intersects) {
    // Checking boundingSphere distance to ray

    if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

    _sphere.copyFrom(geometry.boundingSphere);
    _sphere.applyMatrix4(matrixWorld);

    if (raycaster.ray.intersectsWithSphere(_sphere) == null) {
      return;
    }

    // Check boundingBox before continuing

    _inverseMatrix.copyInverse(matrixWorld);
    _ray.copyFrom(raycaster.ray);
    _ray.applyMatrix4(_inverseMatrix);

    if (geometry.boundingBox != null) {
      if (_ray.intersectsWithAabb3(geometry.boundingBox) == null) {
        return;
      }
    }

    var geo = geometry;

    if (geo is BufferGeometry) {
      if (material == null) return;

      var attributes = geo.attributes;

      var a, b, c;
      var precision = raycaster.precision;

      if (attributes['index'] != null) {
        var indices = attributes['index'].array;
        var positions = attributes['position'].array;
        var offsets = attributes['offsets'];

        if (offsets.length == 0) {
          offsets = [new DrawCall(start: 0, count: indices.length, index: 0)];
        }

        for (var oi = 0, ol = offsets.length; oi < ol; ++oi) {
          var start = offsets[oi].start;
          var count = offsets[oi].count;
          var index = offsets[oi].index;

          for (var i = start, il = start + count; i < il; i += 3) {
            a = index + indices[i];
            b = index + indices[i + 1];
            c = index + indices[i + 2];

            _vA.copyFromArray(positions, a * 3);
            _vB.copyFromArray(positions, b * 3);
            _vC.copyFromArray(positions, c * 3);

            var intersectionPoint = material.side == BackSide
                ? _ray.intersectsWithTriangle(_vC, _vB, _vA, backfaceCulling: true)
                : _ray.intersectsWithTriangle(_vA, _vB, _vC, backfaceCulling: material.side != DoubleSide);

            if (intersectionPoint == null) continue;

            intersectionPoint.applyMatrix4(this.matrixWorld);

            var distance = raycaster.ray.origin.distanceTo(intersectionPoint);

            if (distance < precision || distance < raycaster.near || distance > raycaster.far) continue;

            intersects.add(new RayIntersection(
                distance: distance,
                point: intersectionPoint,
                face: new Face3(a, b, c, normal: Triangle.normal(_vA, _vB, _vC)),
                faceIndex: null,
                object: this));
          }
        }
      } else {
        var positions = attributes['position'].array;

        for (var i = 0, j = 0; i < positions.length / 3; i += 3, j += 9) {
          a = i;
          b = i + 1;
          c = i + 2;

          _vA.copyFromArray(positions, j);
          _vB.copyFromArray(positions, j + 3);
          _vC.copyFromArray(positions, j + 6);

          var intersectionPoint = material.side == BackSide
              ? _ray.intersectsWithTriangle(_vC, _vB, _vA, backfaceCulling: true)
              : _ray.intersectsWithTriangle(_vA, _vB, _vC, backfaceCulling: material.side != DoubleSide);

          if (intersectionPoint == null) continue;

          intersectionPoint.applyMatrix4(this.matrixWorld);

          var distance = raycaster.ray.origin.distanceTo(intersectionPoint);

          if (distance < precision || distance < raycaster.near || distance > raycaster.far) continue;

          intersects.add(new RayIntersection(
              distance: distance,
              point: intersectionPoint,
              face: new Face3(a, b, c, normal: Triangle.normal(_vA, _vB, _vC)),
              faceIndex: null,
              object: this));
        }
      }
    } else if (geo is Geometry) {
      var precision = raycaster.precision;

      var vertices = geo.vertices;

      for (var f = 0; f < geo.faces.length; f++) {
        var face = geo.faces[f];

        if (material == null) continue;

        var a = vertices[face.a];
        var b = vertices[face.b];
        var c = vertices[face.c];

        var m = material;

        if (m is Morphing && m.morphTargets) {
          var morphTargets = geo.morphTargets;
          var morphInfluences = morphTargetInfluences;

          _vA.setZero();
          _vB.setZero();
          _vC.setZero();

          for (var t = 0, tl = morphTargets.length; t < tl; t++) {
            var influence = morphInfluences[t];

            if (influence == 0) continue;

            var targets = morphTargets[t].vertices;

            _vA.x += (targets[face.a].x - a.x) * influence;
            _vA.y += (targets[face.a].y - a.y) * influence;
            _vA.z += (targets[face.a].z - a.z) * influence;

            _vB.x += (targets[face.b].x - b.x) * influence;
            _vB.y += (targets[face.b].y - b.y) * influence;
            _vB.z += (targets[face.b].z - b.z) * influence;

            _vC.x += (targets[face.c].x - c.x) * influence;
            _vC.y += (targets[face.c].y - c.y) * influence;
            _vC.z += (targets[face.c].z - c.z) * influence;
          }

          _vA.add(a);
          _vB.add(b);
          _vC.add(c);

          a = _vA;
          b = _vB;
          c = _vC;
        }

        var intersectionPoint = material.side == BackSide
            ? _ray.intersectsWithTriangle(c, b, a, backfaceCulling: true)
            : _ray.intersectsWithTriangle(a, b, c, backfaceCulling: material.side != DoubleSide);

        if (intersectionPoint == null) continue;

        intersectionPoint.applyMatrix4(matrixWorld);

        var distance = raycaster.ray.origin.distanceTo(intersectionPoint);

        if (distance < precision || distance < raycaster.near || distance > raycaster.far) continue;

        intersects.add(new RayIntersection(
            distance: distance, point: intersectionPoint, face: face, faceIndex: f, object: this));
      }
    }
  }

  /// Returns clone of [this].
  Mesh clone([Mesh object, bool recursive = true]) {
    if (object == null) object = new Mesh(geometry, material);
    super.clone(object, recursive);
    return object;
  }

  toJSON() {
    throw new UnimplementedError();
  }
}