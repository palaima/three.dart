/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three;

/// Class for keeping track of time.
class Clock {
  /// Whether the clock starts automatically on first update.
  bool autoStart;

  /// Returns the time when the clock was started.
  double startTime = 0.0;

  /// The time when [getDelta] was last called.
  double oldTime = 0.0;

  /// Elapsed seconds since [start] was called.
  double elapsedTime = 0.0;

  /// Whether the clock is running.
  bool running = false;

  /// Creates a new clock object. If [autoStart] is set, the clock starts
  /// automatically when [getDelta] is first called.
  Clock([this.autoStart = true]);

  /// Starts the clock.
  void start() {
    startTime = window.performance.now();
    oldTime = startTime;
    running = true;
  }

  /// Stops the clock.
  void stop() {
    getDelta();
    running = false;
  }

  /// Returns seconds passed a since the last call to this method.
  double getDelta() {
    var diff;

    if (autoStart && !running) start();

    if (running) {
      var newTime = window.performance.now();
      diff = 0.001 * (newTime - oldTime);
      oldTime = newTime;
      elapsedTime += diff;
    }

    return diff;
  }
}