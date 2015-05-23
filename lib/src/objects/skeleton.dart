/*
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 * @author michael guerrero / http://realitymeltdown.com
 * @author ikerr / http://verold.com
 */

part of three.objects;

class Skeleton {
  List<Bone> bones;

  bool useVertexTexture;
  Matrix4 identityMatrix = new Matrix4.identity();

  int boneTextureWidth;
  int boneTextureHeight;

  Float32List boneMatrices;
  DataTexture boneTexture;

  List<Matrix4> boneInverses;

  Skeleton(List bones_, List boneInverses_, {this.useVertexTexture: true}) {
    // copy the bone array

    if (bones_ == null) bones_ = [];

    bones = bones_.toList();

    // create a bone texture or an array of floats

    if (useVertexTexture) {
      // layout (1 matrix = 4 pixels)
      //      RGBA RGBA RGBA RGBA (=> column1, column2, column3, column4)
      //  with  8x8  pixel texture max   16 bones  (8 * 8  / 4)
      //       16x16 pixel texture max   64 bones (16 * 16 / 4)
      //       32x32 pixel texture max  256 bones (32 * 32 / 4)
      //       64x64 pixel texture max 1024 bones (64 * 64 / 4)

      var size;

      if (bones.length > 256) {
        size = 64;
      } else if (bones.length > 64) {
        size = 32;
      } else if (bones.length > 16) {
        size = 16;
      } else {
        size = 8;
      }

      boneTextureWidth = size;
      boneTextureHeight = size;

      boneMatrices = // 4 floats per RGBA pixel
          new Float32List(this.boneTextureWidth * boneTextureHeight * 4);
      boneTexture = new DataTexture(
          boneMatrices, boneTextureWidth, boneTextureHeight,
          format: RGBAFormat, type: FloatType);
      boneTexture.minFilter = NearestFilter;
      boneTexture.magFilter = NearestFilter;
      boneTexture.generateMipmaps = false;
      boneTexture.flipY = false;
    } else {
      boneMatrices = new Float32List(16 * bones.length);
    }

    // use the supplied bone inverses or calculate the inverses

    if (boneInverses_ == null) {
      calculateInverses();
    } else {
      if (bones.length == boneInverses.length) {
        boneInverses = boneInverses.toList();
      } else {
        warn('Skeleton bonInverses is the wrong length.');

        boneInverses = [];

        for (var b = 0; b < bones.length; b++) {
          boneInverses.add(new Matrix4.identity());
        }
      }
    }
  }

  void calculateInverses() {
    boneInverses = [];

    for (var b = 0; b < bones.length; b++) {
      var inverse = new Matrix4.identity();

      if (bones.length > b) {
        inverse.copyInverse(bones[b].matrixWorld);
      }

      boneInverses.add(inverse);
    }
  }

  void pose() {
    // recover the bind-time world matrices
    for (var b = 0; b < bones.length; b++) {
      var bone = bones[b];

      if (bone) {
        bone.matrixWorld.copyInverse(boneInverses[b]);
      }
    }

    // compute the local matrices, positions, rotations and scales
    for (var b = 0; b < bones.length; b++) {
      var bone = bones[b];

      if (bone) {
        if (bone.parent) {
          bone.matrix.copyInverse(bone.parent.matrixWorld);
          bone.matrix.multiply(bone.matrixWorld);
        } else {
          bone.matrix.setFrom(bone.matrixWorld);
        }

        bone.matrix.decompose(bone.position, bone.quaternion, bone.scale);
      }
    }
  }

  static final Matrix4 _offsetMatrix = new Matrix4.identity();

  void update() {
    // flatten bone matrices to array

    for (var b = 0; b < bones.length; b++) {
      // compute the offset between the current and the original transform

      var matrix = bones.length > b ? bones[b].matrixWorld : identityMatrix;

      _offsetMatrix.multiplyMatrices(matrix, boneInverses[b]);
      _offsetMatrix.copyIntoArray(boneMatrices, b * 16);
    }

    if (useVertexTexture) {
      boneTexture.needsUpdate = true;
    }
  }
}
