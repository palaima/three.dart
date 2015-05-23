/*
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 * @author ikerr / http://verold.com
 */

part of three.objects;

class SkinnedMesh extends Mesh {
  String type = 'SkinnedMesh';

  String bindMode = "attached";
  Matrix4 bindMatrix = new Matrix4.identity();
  Matrix4 bindMatrixInverse = new Matrix4.identity();

  bool useVertexTexture;

  Skeleton skeleton;

  SkinnedMesh(IGeometry geometry_, Material material,
      {this.useVertexTexture: true})
      : super(geometry_, material) {
    // init bones

    var bones = [];

    if (geometry != null && geometry.bones != null) {
      for (var b = 0; b < geometry.bones.length; ++b) {
        var gbone = geometry.bones[b];

        var p = gbone['pos'];
        var q = gbone['rotq'];
        var s = gbone['scl'];

        var bone = new Bone(this);
        bones.add(bone);

        bone.name = gbone['name'];
        bone.position.setValues(
            p[0].toDouble(), p[1].toDouble(), p[2].toDouble());
        bone.quaternion.setValues(
            q[0].toDouble(), q[1].toDouble(), q[2].toDouble(), q[3].toDouble());

        if (s != null) {
          bone.scale.setValues(
              s[0].toDouble(), s[1].toDouble(), s[2].toDouble());
        } else {
          bone.scale.splat(1.0);
        }
      }

      for (var b = 0; b < geometry.bones.length; ++b) {
        var gbone = geometry.bones[b];

        if (gbone['parent'] != -1) {
          bones[gbone['parent']].add(bones[b]);
        } else {
          add(bones[b]);
        }
      }
    }

    normalizeSkinWeights();

    updateMatrixWorld(force: true);
    bind(new Skeleton(bones, null, useVertexTexture: useVertexTexture));
  }

  void bind(Skeleton skeleton, [bindMatrix]) {
    this.skeleton = skeleton;

    if (bindMatrix == null) {
      updateMatrixWorld(force: true);

      bindMatrix = matrixWorld;
    }

    bindMatrix.setFrom(bindMatrix);
    bindMatrixInverse.copyInverse(bindMatrix);
  }

  void pose() {
    skeleton.pose();
  }

  void normalizeSkinWeights() {
    if (geometry is Geometry) {
      for (var i = 0; i < geometry.skinIndices.length; i++) {
        var sw = geometry.skinWeights[i];

        var scale = 1.0 / sw.lengthManhattan;

        if (scale != double.INFINITY) {
          sw.scale(scale);
        } else {
          //  TODO check if same as sw.set(1);
          sw.x = 1.0; // this will be normalized by the shader anyway

        }
      }
    } else {
      // skinning weights assumed to be normalized for THREE.BufferGeometry
    }
  }

  void updateMatrixWorld({bool force: false}) {
    super.updateMatrixWorld(force: true);

    if (bindMode == "attached") {
      bindMatrixInverse.copyInverse(matrixWorld);
    } else if (bindMode == "detached") {
      bindMatrixInverse.copyInverse(bindMatrix);
    } else {
      warn('SkinnedMesh unreckognized bindMode: $bindMode');
    }
  }

  SkinnedMesh clone([SkinnedMesh object, bool recursive = true]) {
    if (object == null) {
      object = new SkinnedMesh(this.geometry, this.material,
          useVertexTexture: useVertexTexture);
    }

    super.clone(object, recursive);

    return object;
  }
}
