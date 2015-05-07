/**
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author nelson silva / http://www.inevo.pt/
 *
 * based on rev 5816003656
 **/
part of three.extras.controls;

class TrackballControls {

  State _state, _prevState;
  Object3D object;
  dynamic domElement;
  bool enabled;
  math.Rectangle screen;
  num rotateSpeed, zoomSpeed, panSpeed;
  bool noRotate, noZoom, noPan, noRoll;
  bool staticMoving;
  bool autoUpdate;
  // emit a change event automatically when something changes (without having to call update explicitly)
  num dynamicDampingFactor;
  num minDistance, maxDistance;
  List keys;
  Vector3 target;

  Vector3 _eye;

  Vector3 _rotateStart, _rotateEnd;
  Vector2 _zoomStart, _zoomEnd;
  double _touchZoomDistanceStart, _touchZoomDistanceEnd;
  Vector2 _panStart, _panEnd;
  Vector3 lastPosition;

  StreamSubscription<MouseEvent> mouseMoveStream;
  StreamSubscription<MouseEvent> mouseUpStream;
  StreamSubscription<KeyboardEvent> keydownStream, keyupStream;

  StreamController _onChangeController = new StreamController(sync: true);
  Stream get onChange => _onChangeController.stream;

  StreamController _onStartController = new StreamController(sync: true);
  Stream get onStart => _onStartController.stream;

  StreamController _onEndController = new StreamController(sync: true);
  Stream get onEnd => _onEndController.stream;

  TrackballControls(this.object, [Element domElement]) {

    this.domElement = (domElement != null) ? domElement : document;

    // API

    enabled = true;

    screen = new math.Rectangle(0, 0, 0, 0);

    rotateSpeed = 1.0;
    zoomSpeed = 1.2;
    panSpeed = 0.3;

    noRotate = false;
    noZoom = false;
    noPan = false;
    noRoll = false;

    staticMoving = false;
    autoUpdate = false;
    dynamicDampingFactor = 0.2;

    minDistance = 0;
    maxDistance = double.INFINITY;

    keys = [65 /*A*/, 83 /*S*/, 68 /*D*/ ];

    // internals

    target = new Vector3.zero();

    lastPosition = new Vector3.zero();

    _state = State.NONE;
    _prevState = State.NONE;

    _eye = new Vector3.zero();

    _rotateStart = new Vector3.zero();
    _rotateEnd = new Vector3.zero();

    _zoomStart = new Vector2.zero();
    _zoomEnd = new Vector2.zero();

    _touchZoomDistanceStart = 0.0;
    _touchZoomDistanceEnd = 0.0;

    _panStart = new Vector2.zero();
    _panEnd = new Vector2.zero();

    this.domElement
        ..onContextMenu.listen((event) => event.preventDefault())
        ..onMouseDown.listen(mousedown)
        ..onMouseWheel.listen(mousewheel)
        ..onTouchStart.listen(touchstart)
        ..onTouchEnd.listen(touchend)
        ..onTouchMove.listen(touchmove);

    //this.domElement.addEventListener( 'DOMMouseScroll', mousewheel, false ); // firefox

    keydownStream = window.onKeyDown.listen(keydown);
    keyupStream = window.onKeyUp.listen(keyup);


    handleResize();
  }


  // methods
  handleResize() {
    if (domElement == document) {
      screen = new math.Rectangle(0, 0, window.innerWidth, window.innerHeight);
    } else {
      screen = domElement.getBoundingClientRect();
    }
  }

  getMouseOnScreen(clientX, clientY) =>
      new Vector2((clientX - screen.left) / screen.width, (clientY - screen.top) / screen.height);

  getMouseProjectionOnBall(clientX, clientY) {

    var mouseOnBall = new Vector3(
        (clientX - screen.width * 0.5 - screen.left) / (screen.width * 0.5),
        (screen.height * 0.5 + screen.top - clientY) / (screen.height * 0.5),
        0.0);

    var length = mouseOnBall.length;

    if (noRoll) {

      if (length < math.SQRT1_2) {

        mouseOnBall.z = math.sqrt(1.0 - length * length);

      } else {

        mouseOnBall.z = 0.5 / length;

      }

    } else if (length > 1.0) {

      mouseOnBall.normalize();

    } else {

      mouseOnBall.z = math.sqrt(1.0 - length * length);

    }

    _eye.setFrom(object.position).sub(target);

    Vector3 projection = object.up.clone().normalize().scale(mouseOnBall.y);
    projection.add(object.up.cross(_eye).normalize().scale(mouseOnBall.x));
    projection.add(_eye.normalize().scale(mouseOnBall.z));

    return projection;

  }

  rotateCamera() {

    var angle = math.acos(_rotateStart.dot(_rotateEnd) / _rotateStart.length / _rotateEnd.length);

    if (!angle.isNaN && angle != 0) {

      Vector3 axis = _rotateStart.cross(_rotateEnd).normalize();
      Quaternion quaternion = new Quaternion.identity();

      angle *= rotateSpeed;

      quaternion.setAxisAngle(axis, angle);

      quaternion.rotate(_eye);
      quaternion.rotate(object.up);

      quaternion.rotate(_rotateEnd);

      if (staticMoving) {

        _rotateStart.setFrom(_rotateEnd);

      } else {

        quaternion.setAxisAngle(axis, -angle * (dynamicDampingFactor - 1.0));
        quaternion.rotate(_rotateStart);

      }

    }

  }

  zoomCamera() {

    if (_state == State.TOUCH_ZOOM_PAN) {

      var factor = _touchZoomDistanceStart / _touchZoomDistanceEnd;

      _touchZoomDistanceStart = _touchZoomDistanceEnd;

      _eye.scale(factor);

    } else {

      var factor = 1.0 + (_zoomEnd.y - _zoomStart.y) * zoomSpeed;

      if (factor != 1.0 && factor > 0.0) {

        _eye.scale(factor);

        if (staticMoving) {

          _zoomStart.setFrom(_zoomEnd);

        } else {

          _zoomStart.y += (_zoomEnd.y - _zoomStart.y) * this.dynamicDampingFactor;

        }

      }

    }

  }

  panCamera() {

    Vector2 mouseChange = _panEnd - _panStart;

    if (mouseChange.length != 0.0) {

      mouseChange.scale(_eye.length * panSpeed);

      Vector3 pan = _eye.cross(object.up).normalize().scale(mouseChange.x);
      pan += object.up.clone().normalize().scale(mouseChange.y);

      object.position.add(pan);
      target.add(pan);

      if (staticMoving) {

        _panStart.setFrom(_panEnd);

      } else {

        _panStart += (_panEnd - _panStart).scale(dynamicDampingFactor);

      }

    }

  }

  checkDistances() {

    if (!noZoom || !noPan) {

      if (object.position.length2 > maxDistance * maxDistance) {

        object.position.normalize().scale(maxDistance);

      }

      if (_eye.length2 < minDistance * minDistance) {

        object.position = target + _eye.normalize().scale(minDistance);

      }

    }

  }

  void triggerAutoUpdate() {
    if (autoUpdate) {
      update();
    }
  }

  update() {

    _eye.setFrom(object.position).sub(target);

    if (!noRotate) {
      rotateCamera();
    }

    if (!noZoom) {
      zoomCamera();
    }

    if (!noPan) {
      panCamera();
    }

    object.position = target + _eye;

    checkDistances();

    object.lookAt(target);

    // distanceToSquared
    if ((lastPosition - object.position).length2 > 0.0) {
      //
      _onChangeController.add(null);

      lastPosition.setFrom(object.position);

    }

  }

  // listeners

  keydown(KeyboardEvent event) {

    if (!enabled) return;

    keydownStream.cancel();

    _prevState = _state;

    if (_state != State.NONE) {

      return;

    } else if (event.keyCode == keys[State.ROTATE.index] && !noRotate) {

      _state = State.ROTATE;

    } else if (event.keyCode == keys[State.ZOOM.index] && !noZoom) {

      _state = State.ZOOM;

    } else if (event.keyCode == keys[State.PAN.index] && !noPan) {

      _state = State.PAN;

    }

  }

  keyup(KeyboardEvent event) {

    if (!enabled) {
      return;
    }

    _state = _prevState;

    keydownStream = window.onKeyDown.listen(keydown);

  }

  mousedown(MouseEvent event) {

    if (!enabled) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();

    if (_state == State.NONE) {

      _state = State.values[event.button];
    }

    if (_state == State.ROTATE && !noRotate) {

      _rotateStart = getMouseProjectionOnBall(event.client.x, event.client.y);
      _rotateEnd.setFrom(_rotateStart);

    } else if (_state == State.ZOOM && !noZoom) {

      _zoomStart = getMouseOnScreen(event.client.x, event.client.y);
      _zoomEnd.setFrom(_zoomStart);

    } else if (_state == State.PAN && !noPan) {

      _panStart = getMouseOnScreen(event.client.x, event.client.y);
      _panEnd.setFrom(_panStart);

    }

    mouseMoveStream = document.onMouseMove.listen(mousemove);
    mouseUpStream = document.onMouseUp.listen(mouseup);

    _onStartController.add(null);

  }

  mousemove(MouseEvent event) {

    if (!enabled) {
      return;
    }

    if (_state == State.ROTATE && !noRotate) {

      _rotateEnd = getMouseProjectionOnBall(event.client.x, event.client.y);

    } else if (_state == State.ZOOM && !noZoom) {

      _zoomEnd = getMouseOnScreen(event.client.x, event.client.y);

    } else if (_state == State.PAN && !noPan) {

      _panEnd = getMouseOnScreen(event.client.x, event.client.y);

    }

    triggerAutoUpdate();
  }

  mouseup(MouseEvent event) {

    if (!enabled) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();

    _state = State.NONE;

    mouseMoveStream.cancel();
    mouseUpStream.cancel();

    _onEndController.add(null);
  }

  mousewheel(WheelEvent event) {

    if (!enabled) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();

    var delta = 0;

    // TODO(nelsonsilva) - check this!
    if (event.deltaY != 0) { // WebKit / Opera / Explorer 9

      delta = event.deltaY / 40;

    } else if (event.detail != 0) { // Firefox

      delta = -event.detail / 3;

    }

    _zoomStart.y += (1 / delta) * 0.05;

    _onStartController.add(null);
    _onEndController.add(null);

    triggerAutoUpdate();
  }

  touchstart(TouchEvent event) {

    if (!enabled) {
      return;
    }

    event.preventDefault();

    switch (event.touches.length) {

      case 1:
        _state = State.TOUCH_ROTATE;
        _rotateStart = getMouseProjectionOnBall(event.touches[0].page.x, event.touches[0].page.y);
        _rotateEnd.setFrom(_rotateStart);
        break;
      case 2:
        _state = State.TOUCH_ZOOM_PAN;
        var dx = event.touches[0].page.x - event.touches[1].page.x;
        var dy = event.touches[0].page.y - event.touches[1].page.y;
        _touchZoomDistanceEnd = _touchZoomDistanceStart = math.sqrt(dx * dx + dy * dy);

        var x = (event.touches[0].page.x + event.touches[1].page.x) / 2;
        var y = (event.touches[0].page.y + event.touches[1].page.y) / 2;
        _panStart = getMouseOnScreen(x, y);
        _panEnd.setFrom(_panStart);
        break;
      default:
        _state = State.NONE;
        break;
    }

    _onStartController.add(null);
  }

  touchmove(TouchEvent event) {

    if (!enabled) {
      return;
    }

    event.preventDefault();

    switch (event.touches.length) {

      case 1:
        _rotateEnd = getMouseProjectionOnBall(event.touches[0].page.x, event.touches[0].page.y);
        break;
      case 2:
        var dx = event.touches[0].page.x - event.touches[1].page.x;
        var dy = event.touches[0].page.y - event.touches[1].page.y;
        _touchZoomDistanceEnd = math.sqrt(dx * dx + dy * dy);

        var x = (event.touches[0].page.x + event.touches[1].page.x) / 2;
        var y = (event.touches[0].page.y + event.touches[1].page.y) / 2;
        _panEnd = getMouseOnScreen(x, y);
        break;
      default:
        _state = State.NONE;
        break;

    }

    triggerAutoUpdate();
  }

  touchend(TouchEvent event) {

    if (!enabled) {
      return;
    }

    switch (event.touches.length) {

      case 1:
        _rotateEnd = getMouseProjectionOnBall(event.touches[0].page.x, event.touches[0].page.y);
        _rotateStart.setFrom(_rotateEnd);
        break;

      case 2:
        _touchZoomDistanceStart = _touchZoomDistanceEnd = 0.0;

        var x = (event.touches[0].page.x + event.touches[1].page.x) / 2;
        var y = (event.touches[0].page.y + event.touches[1].page.y) / 2;
        _panEnd = getMouseOnScreen(x, y);
        _panStart.setFrom(_panEnd);
        break;

    }

    _state = State.NONE;

    _onEndController.add(null);

  }

  void unlisten() {
    keydownStream.cancel();
    keyupStream.cancel();
  }
}
