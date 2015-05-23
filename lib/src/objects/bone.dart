/*
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 * @author ikerr / http://verold.com
 *
 * based on r71
 */

part of three.objects;

/// A bone which is part of a SkinnedMesh.
class Bone extends Object3D {
  String type = 'Bone';

  /// The skin that contains this bone.
  SkinnedMesh skin;

  Map animationCache;

  Bone(this.skin);
}
