/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three;

/// Class for keeping track of time.
class Clock {
  bool _autoStart;
  double _startTime = 0.0;
  double _oldTime = 0.0;
  double _elapsedTime = 0.0;
  bool _running = false;

  /// Creates a new clock object. If [autoStart] is set, the clock starts
  /// automatically when [getDelta] is first called.
  Clock([this._autoStart = true]);

  /// Whether the clock is running.
  bool get running => _running;

  /// Time when clock was started.
  double get startTime => _startTime;

  /// Elapsed seconds since [start] was called.
  double get elapsedTime {
    getDelta();
    return _elapsedTime;
  }

  /// Starts the clock.
  void start() {
    _startTime = window.performance.now();
    _oldTime = _startTime;
    _running = true;
  }

  /// Stops the clock.
  void stop() {
    getDelta();
    _running = false;
  }

  /// Returns seconds passed a since the last call to this method.
  double getDelta() {
    var diff;

    if (_autoStart && !_running) start();

    if (_running) {
      var newTime = window.performance.now();
      diff = 0.001 * (newTime - _oldTime);
      _oldTime = newTime;
      _elapsedTime += diff;
    }

    return diff;
  }
}