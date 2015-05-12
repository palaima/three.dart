part of three.materials;

@Deprecated("ASAP")
class MeshFaceMaterial extends Material {
  /// Get or set the materials for the geometry.
  List materials = [];

  /// Creates a MeshFaceMaterial with the correct materials.
  MeshFaceMaterial([this.materials]) : super._();
}
