/*
 * @author mikael emtinger / http://gomo.se/
 */

// FIXME

library three.extras.animation.animation_handler;

import 'package:three/three.dart';

int LINEAR = 0;
int CATMULLROM = 1;
int CATMULLROM_FORWARD = 2;

//

List animations = [];

init(data) {
  if (data.initialized == true) return data;

  // loop through all keys

  for (var h = 0; h < data.hierarchy.length; h++) {
    for (var k = 0; k < data.hierarchy[h].keys.length; k++) {

      // remove minus times

      if (data.hierarchy[h].keys[k].time < 0) {
        data.hierarchy[h].keys[k].time = 0;
      }

      // create quaternions

      if (data.hierarchy[h].keys[k].rot != null &&
          !(data.hierarchy[h].keys[k].rot is Quaternion)) {
        var quat = data.hierarchy[h].keys[k].rot;
        data.hierarchy[h].keys[k].rot = new Quaternion.fromFloat32List(quat);
      }
    }

    // prepare morph target keys

    if (data.hierarchy[h].keys.length &&
        data.hierarchy[h].keys[0].morphTargets != null) {

      // get all used

      var usedMorphTargets = {};

      for (var k = 0; k < data.hierarchy[h].keys.length; k++) {
        for (var m = 0;
            m < data.hierarchy[h].keys[k].morphTargets.length;
            m++) {
          var morphTargetName = data.hierarchy[h].keys[k].morphTargets[m];
          usedMorphTargets[morphTargetName] = -1;
        }
      }

      data.hierarchy[h].usedMorphTargets = usedMorphTargets;

      // set all used on all frames

      for (var k = 0; k < data.hierarchy[h].keys.length; k++) {
        var influences = {};

        var m;

        for (var morphTargetName in usedMorphTargets) {
          for (m = 0; m < data.hierarchy[h].keys[k].morphTargets.length; m++) {
            if (data.hierarchy[h].keys[k].morphTargets[m] == morphTargetName) {
              influences[morphTargetName] =
                  data.hierarchy[h].keys[k].morphTargetsInfluences[m];
              break;
            }
          }

          if (m == data.hierarchy[h].keys[k].morphTargets.length) {
            influences[morphTargetName] = 0;
          }
        }

        data.hierarchy[h].keys[k].morphTargetsInfluences = influences;
      }
    }

    // remove all keys that are on the same time

    for (var k = 1; k < data.hierarchy[h].keys.length; k++) {
      if (data.hierarchy[h].keys[k].time ==
          data.hierarchy[h].keys[k - 1].time) {
        data.hierarchy[h].keys.splice(k, 1);
        k--;
      }
    }

    // set index

    for (var k = 0; k < data.hierarchy[h].keys.length; k++) {
      data.hierarchy[h].keys[k].index = k;
    }
  }

  data.initialized = true;

  return data;
}

parse(root) {
  parseRecurseHierarchy(root, hierarchy) {
    hierarchy.push(root);

    for (var c = 0; c < root.children.length; c++) {
      parseRecurseHierarchy(root.children[c], hierarchy);
    }
  }

  // setup hierarchy

  var hierarchy = [];

  if (root is SkinnedMesh) {
    for (var b = 0; b < root.skeleton.bones.length; b++) {
      hierarchy.add(root.skeleton.bones[b]);
    }
  } else {
    parseRecurseHierarchy(root, hierarchy);
  }

  return hierarchy;
}

void play(animation) {
  if (animations.indexOf(animation) == -1) {
    animations.add(animation);
  }
}

void stop(animation) {
  var index = animations.indexOf(animation);

  if (index != -1) {
    animations.removeAt(index);
  }
}

void update(deltaTimeMS) {
  for (var i = 0; i < animations.length; i++) {
    animations[i].resetBlendWeights();
  }

  for (var i = 0; i < animations.length; i++) {
    animations[i].update(deltaTimeMS);
  }
}
