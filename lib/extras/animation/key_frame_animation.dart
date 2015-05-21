/*
 * @author mikael emtinger / http://gomo.se/
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 * @author khang duong
 * @author erik kitson
 */

part of three.extras.animation;

// FIXME
class KeyFrameAnimation {
  var root;
  var data;
  var hierarchy;
  var currentTime = 0;
  double timeScale = 0.001;
  bool isPlaying = false;
  bool isPaused = true;
  bool loop = true;

  KeyFrameAnimation(data) {
    this.root = data.node;
    this.data = animation_handler.init(data);
    this.hierarchy = animation_handler.parse(this.root);

    // initialize to first keyframes

    for (var h = 0, hl = this.hierarchy.length; h < hl; h++) {
      var keys = this.data.hierarchy[h].keys,
          sids = this.data.hierarchy[h].sids,
          obj = this.hierarchy[h];

      if (keys.length && sids) {
        for (var s = 0; s < sids.length; s++) {
          var sid = sids[s],
              next = this.getNextKeyWith(sid, h, 0);

          if (next) {
            next.apply(sid);
          }
        }

        obj.matrixAutoUpdate = false;
        this.data.hierarchy[h].node.updateMatrix();
        obj.matrixWorldNeedsUpdate = true;
      }
    }
  }

  play(startTime) {
    this.currentTime = startTime != null ? startTime : 0;

    if (this.isPlaying == false) {
      this.isPlaying = true;

      // reset key cache

      var h,
          hl = this.hierarchy.length,
          object,
          node;

      for (h = 0; h < hl; h++) {
        object = this.hierarchy[h];
        node = this.data.hierarchy[h];

        if (node.animationCache == null) {
          node.animationCache = {};
          node.animationCache.prevKey = null;
          node.animationCache.nextKey = null;
          node.animationCache.originalMatrix = object.matrix;
        }

        var keys = this.data.hierarchy[h].keys;

        if (keys.length) {
          node.animationCache.prevKey = keys[0];
          node.animationCache.nextKey = keys[1];

          this.startTime = math.min(keys[0].time, this.startTime);
          this.endTime = math.max(keys[keys.length - 1].time, this.endTime);
        }
      }

      this.update(0);
    }

    this.isPaused = false;

    animation_handler.play(this);
  }

  stop() {
    this.isPlaying = false;
    this.isPaused = false;

    animation_handler.stop(this);

    // reset JIT matrix and remove cache

    for (var h = 0; h < this.data.hierarchy.length; h++) {
      var obj = this.hierarchy[h];
      var node = this.data.hierarchy[h];

      if (node.animationCache != null) {
        var original = node.animationCache.originalMatrix;

        original.copy(obj.matrix);
        obj.matrix = original;

        node.animationCache = null;
      }
    }
  }

  update(delta) {
    if (this.isPlaying == false) return;

    this.currentTime += delta * this.timeScale;

    //

    var duration = this.data.length;

    if (this.loop == true && this.currentTime > duration) {
      this.currentTime %= duration;
    }

    this.currentTime = math.min(this.currentTime, duration);

    for (var h = 0, hl = this.hierarchy.length; h < hl; h++) {
      var object = this.hierarchy[h];
      var node = this.data.hierarchy[h];

      var keys = node.keys,
          animationCache = node.animationCache;

      if (keys.length) {
        var prevKey = animationCache.prevKey;
        var nextKey = animationCache.nextKey;

        if (nextKey.time <= this.currentTime) {
          while (nextKey.time < this.currentTime &&
              nextKey.index > prevKey.index) {
            prevKey = nextKey;
            nextKey = keys[prevKey.index + 1];
          }

          animationCache.prevKey = prevKey;
          animationCache.nextKey = nextKey;
        }

        if (nextKey.time >= this.currentTime) {
          prevKey.interpolate(nextKey, this.currentTime);
        } else {
          prevKey.interpolate(nextKey, nextKey.time);
        }

        this.data.hierarchy[h].node.updateMatrix();
        object.matrixWorldNeedsUpdate = true;
      }
    }
  }

  getNextKeyWith(sid, h, key) {
    var keys = this.data.hierarchy[h].keys;
    key = key % keys.length;

    for (; key < keys.length; key++) {
      if (keys[key].hasTarget(sid)) {
        return keys[key];
      }
    }

    return keys[0];
  }

  getPrevKeyWith(sid, h, key) {
    var keys = this.data.hierarchy[h].keys;
    key = key >= 0 ? key : key + keys.length;

    for (; key >= 0; key--) {
      if (keys[key].hasTarget(sid)) {
        return keys[key];
      }
    }

    return keys[keys.length - 1];
  }
}
