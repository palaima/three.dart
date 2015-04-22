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

  int  morphTargetBase = 0;
  List morphTargetForcedOrder;
  List morphTargetInfluences;
  Map  morphTargetDictionary;

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

  raycast(raycaster, intersects) {
    throw new UnimplementedError();
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
