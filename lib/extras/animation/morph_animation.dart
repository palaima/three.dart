/*
 * @author mrdoob / http://mrdoob.com
 * @author willy-vvu / http://willy-vvu.github.io
 */

part of three.extras.animation;

class MorphAnimation {
  Mesh mesh;
  int frames;

  int currentTime = 0;
  int duration = 1000;
  bool loop = true;
  int lastFrame = 0;
  int currentFrame = 0;

  bool isPlaying = false;

  MorphAnimation(this.mesh) {
    frames = mesh.morphTargetInfluences.length;
  }

  void play() {
    isPlaying = true;
  }

  void pause() {
    isPlaying = false;
  }

  void update(int delta) {
    if (!isPlaying) return;

    currentTime += delta;

    if (loop && currentTime > duration) {
      currentTime %= duration;
    }

    currentTime = math.min(currentTime, duration);

    var interpolation = duration / frames;
    var frame = (currentTime / interpolation).floor();

    var influences = mesh.morphTargetInfluences;

    if (frame != currentFrame) {
      influences[lastFrame] = 0.0;
      influences[currentFrame] = 1.0;
      influences[frame] = 0.0;

      lastFrame = currentFrame;
      currentFrame = frame;
    }

    influences[frame] = (currentTime % interpolation) / interpolation;
    influences[lastFrame] = 1.0 - influences[frame];
  }
}
