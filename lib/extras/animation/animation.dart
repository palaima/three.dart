/*
 * @author mikael emtinger / http://gomo.se/
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 */

part of three.extras.animation;

class Animation {
  Object3D root;
  Map data;
  List<Bone> hierarchy;

  double currentTime = 0.0;
  double timeScale = 1.0;

  bool isPlaying = false;
  bool loop = true;
  double weight = 0.0;

  int interpolationType = animation_handler.LINEAR;

  List<String> keyTypes = ['pos', 'rot', 'scl'];

  Animation(this.root, data) {
    this.data = animation_handler.init(data);
    this.hierarchy = animation_handler.parse(root);
  }

  void play([double startTime = 0.0, double weight = 1.0]) {
    currentTime = startTime;
    this.weight = weight;

    isPlaying = true;

    reset();

    animation_handler.play(this);
  }

  void stop() {
    isPlaying = false;

    animation_handler.stop(this);
  }

  void reset() {
    for (var h = 0; h < hierarchy.length; h++) {
      var object = hierarchy[h];

      if (object.animationCache == null) {
        object.animationCache = {
          'animations': {},
          'blending': {
            'positionWeight': 0.0,
            'quaternionWeight': 0.0,
            'scaleWeight': 0.0
          }
        };
      }

      var name = data['name'];
      var animations = object.animationCache['animations'];
      var animationCache = animations[name];

      if (animationCache == null) {
        animationCache = {
          'prevKey': {'pos': 0, 'rot': 0, 'scl': 0},
          'nextKey': {'pos': 0, 'rot': 0, 'scl': 0},
          'originalMatrix': object.matrix
        };

        animations[name] = animationCache;
      }

      // Get keys to match our current time

      for (var t = 0; t < 3; t++) {
        var type = keyTypes[t];

        var prevKey = data['hierarchy'][h]['keys'][0];
        var nextKey = getNextKeyWith(type, h, 1);

        while (nextKey['time'] < currentTime &&
            nextKey['index'] > prevKey['index']) {
          prevKey = nextKey;
          nextKey = getNextKeyWith(type, h, nextKey['index'] + 1);
        }

        animationCache['prevKey'][type] = prevKey;
        animationCache['nextKey'][type] = nextKey;
      }
    }
  }

  void resetBlendWeights() {
    for (var h = 0; h < hierarchy.length; h++) {
      var object = hierarchy[h];
      var animationCache = object.animationCache;

      if (animationCache != null) {
        var blending = animationCache['blending'];

        blending['positionWeight'] = 0.0;
        blending['quaternionWeight'] = 0.0;
        blending['scaleWeight'] = 0.0;
      }
    }
  }

  List<Vector3> points = [];
  Vector3 target = new Vector3.zero();
  Vector3 newVector = new Vector3.zero();
  Quaternion newQuat = new Quaternion.identity();

  // Catmull-Rom spline

  Vector3 interpolateCatmullRom(List<Vector3> points, double scale) {
    var c = [],
        v3 = [];

    var point = (points.length - 1) * scale;
    var intPoint = point.floor();
    var weight = point - intPoint;

    c[0] = intPoint == 0 ? intPoint : intPoint - 1;
    c[1] = intPoint;
    c[2] = intPoint > points.length - 2 ? intPoint : intPoint + 1;
    c[3] = intPoint > points.length - 3 ? intPoint : intPoint + 2;

    var pa = points[c[0]];
    var pb = points[c[1]];
    var pc = points[c[2]];
    var pd = points[c[3]];

    var w2 = weight * weight;
    var w3 = weight * w2;

    v3[0] = interpolate(pa[0], pb[0], pc[0], pd[0], weight, w2, w3);
    v3[1] = interpolate(pa[1], pb[1], pc[1], pd[1], weight, w2, w3);
    v3[2] = interpolate(pa[2], pb[2], pc[2], pd[2], weight, w2, w3);

    return v3;
  }

  interpolate(p0, p1, p2, p3, t, t2, t3) {
    var v0 = (p2 - p0) * 0.5,
        v1 = (p3 - p1) * 0.5;

    return (2 * (p1 - p2) + v0 + v1) * t3 +
        (-3 * (p1 - p2) - 2 * v0 - v1) * t2 +
        v0 * t +
        p1;
  }

  bool update(double delta) {
    if (!isPlaying) return false;

    currentTime += delta * timeScale;

    if (weight == 0) return false;

    //

    var duration = data.length;

    if (currentTime > duration || currentTime < 0) {
      if (loop) {
        currentTime %= duration;

        if (currentTime < 0) {
          currentTime += duration;
        }

        reset();
      } else {
        stop();
      }
    }

    for (var h = 0; h < hierarchy.length; h++) {
      var object = hierarchy[h];
      Map animationCache = object.animationCache['animations'][data['name']];
      Map blending = object.animationCache['blending'];

      // loop through pos/rot/scl

      for (var t = 0; t < 3; t++) {
        // get keys

        var type = keyTypes[t];
        var prevKey = animationCache['prevKey'][type];
        var nextKey = animationCache['nextKey'][type];

        if ((timeScale > 0 && nextKey['time'] <= currentTime) ||
            (timeScale < 0 && prevKey['time'] >= currentTime)) {
          prevKey = data['hierarchy'][h]['keys'][0];
          nextKey = getNextKeyWith(type, h, 1);

          while (nextKey['time'] < currentTime &&
              nextKey['index'] > prevKey['index']) {
            prevKey = nextKey;
            nextKey = getNextKeyWith(type, h, nextKey['index'] + 1);
          }

          animationCache['prevKey'][type] = prevKey;
          animationCache['nextKey'][type] = nextKey;
        }

        var scale = (currentTime - prevKey['time']) /
            (nextKey['time'] - prevKey['time']);

        var prevXYZ = prevKey[type];
        var nextXYZ = nextKey[type];

        if (scale < 0.0) scale = 0.0;
        if (scale > 1.0) scale = 1.0;

        // interpolate

        if (type == 'pos') {
          if (interpolationType == animation_handler.LINEAR) {
            newVector.x = prevXYZ[0] + (nextXYZ[0] - prevXYZ[0]) * scale;
            newVector.y = prevXYZ[1] + (nextXYZ[1] - prevXYZ[1]) * scale;
            newVector.z = prevXYZ[2] + (nextXYZ[2] - prevXYZ[2]) * scale;

            // blend
            var proportionalWeight =
                weight / (weight + blending['positionWeight']);
            Vector3.mix(object.position, newVector, proportionalWeight,
                object.position);
            blending['positionWeight'] += weight;
          } else if (interpolationType == animation_handler.CATMULLROM ||
              interpolationType == animation_handler.CATMULLROM_FORWARD) {
            points[0] = getPrevKeyWith('pos', h, prevKey['index'] - 1)['pos'];
            points[1] = prevXYZ;
            points[2] = nextXYZ;
            points[3] = getNextKeyWith('pos', h, nextKey['index'] + 1)['pos'];

            scale = scale * 0.33 + 0.33;

            var currentPoint = interpolateCatmullRom(points, scale);
            var proportionalWeight =
                weight / (weight + blending['positionWeight']);
            blending['positionWeight'] += weight;

            // blend

            var vector = object.position;

            vector.x =
                vector.x + (currentPoint[0] - vector.x) * proportionalWeight;
            vector.y =
                vector.y + (currentPoint[1] - vector.y) * proportionalWeight;
            vector.z =
                vector.z + (currentPoint[2] - vector.z) * proportionalWeight;

            if (interpolationType == animation_handler.CATMULLROM_FORWARD) {
              var forwardPoint = interpolateCatmullRom(points, scale * 1.01);

              target.setValues(
                  forwardPoint[0], forwardPoint[1], forwardPoint[2]);
              target.sub(vector);
              target.y = 0.0;
              target.normalize();

              var angle = math.atan2(target.x, target.z);
              object.rotation.setValues(0.0, angle, 0.0);
            }
          }
        } else if (type == 'rot') {
          var q = prevXYZ is List
              ? new Quaternion.array(prevXYZ.map((v) => v.toDouble()).toList())
              : prevXYZ;

          var q2 = nextXYZ is List
              ? new Quaternion.array(nextXYZ.map((v) => v.toDouble()).toList())
              : nextXYZ;

          Quaternion.slerp(q, q2, newQuat, scale);

          // Avoid paying the cost of an additional slerp if we don't have to
          if (blending['quaternionWeight'] == 0) {
            object.quaternion.setFrom(newQuat);
            blending['quaternionWeight'] = weight;
          } else {
            var proportionalWeight =
                weight / (weight + blending['quaternionWeight']);
            Quaternion.slerp(object.quaternion, newQuat, object.quaternion,
                proportionalWeight);
            blending['quaternionWeight'] += weight;
          }
        } else if (type == 'scl') {
          newVector.x = prevXYZ[0] + (nextXYZ[0] - prevXYZ[0]) * scale;
          newVector.y = prevXYZ[1] + (nextXYZ[1] - prevXYZ[1]) * scale;
          newVector.z = prevXYZ[2] + (nextXYZ[2] - prevXYZ[2]) * scale;

          var proportionalWeight = weight / (weight + blending['scaleWeight']);
          Vector3.mix(
              object.scale, newVector, proportionalWeight, object.scale);
          blending['scaleWeight'] += weight;
        }
      }
    }

    return true;
  }

  Map getNextKeyWith(String type, int h, int key) {
    var keys = data['hierarchy'][h]['keys'];

    if (interpolationType == animation_handler.CATMULLROM ||
        interpolationType == animation_handler.CATMULLROM_FORWARD) {
      key = key < keys.length - 1 ? key : keys.length - 1;
    } else {
      key = key % keys.length;
    }

    for (; key < keys.length; key++) {
      if (keys[key][type] != null) {
        return keys[key];
      }
    }

    return data['hierarchy'][h]['keys'][0];
  }

  Map getPrevKeyWith(String type, int h, int key) {
    var keys = data['hierarchy'][h]['keys'];

    if (interpolationType == animation_handler.CATMULLROM ||
        interpolationType == animation_handler.CATMULLROM_FORWARD) {
      key = key > 0 ? key : 0;
    } else {
      key = key >= 0 ? key : key + keys.length;
    }

    for (; key >= 0; key--) {
      if (keys[key][type] != null) {
        return keys[key];
      }
    }

    return data['hierarchy'][h]['keys'][keys.length - 1];
  }
}
