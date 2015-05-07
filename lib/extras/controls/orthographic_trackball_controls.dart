/**
 * @author Eberhard Graether / http://egraether.com/
 * @author Patrick Fuller / http://patrick-fuller.com
 *
 * Ported to Dart from JS by:
 * @author Adam Joseph Cook / https://github.com/adamjcook
 *
 **/
part of controls;

class OrthographicTrackballControls {

  State _state, _prevState;
  Object3D object;
  dynamic domElement;
  bool enabled;
  Map<String, num> screen;
  num radius;
  num rotateSpeed, zoomSpeed, panSpeed;
  bool noRotate, noZoom, noPan;
  bool staticMoving;
  num dynamicDampingFactor;
  num minDistance, maxDistance;
  List keys;
  Vector3 target;

  Vector3 _eye;

  Vector3 _rotateStart, _rotateEnd;
  Vector2 _zoomStart, _zoomEnd;
  num _zoomFactor;
  num _touchZoomDistanceStart, _touchZoomDistanceEnd;
  Vector2 _panStart, _panEnd;
  Vector3 lastPosition;

  Vector3 target0, position0, up0;
  Vector2 center0;
  double left0, right0, top0, bottom0;

  StreamSubscription<MouseEvent> mouseMoveStream;
  StreamSubscription<MouseEvent> mouseUpStream;
  StreamSubscription<KeyboardEvent> keydownStream;

  StreamController _onChangeController = new StreamController(sync: true);
  Stream get onChange => _onChangeController.stream;

  OrthographicTrackballControls(this.object, [Element domElement]) {

    assert(this.object is OrthographicCamera);

    this.domElement = (domElement != null) ? domElement : document;

    // API

    enabled = true;

    screen = {
      'width': 0,
      'height': 0,
      'offsetLeft': 0,
      'offsetTop': 0
    };
    radius = (screen['width'] + screen['height']) / 4;

    rotateSpeed = 1.0;
    zoomSpeed = 1.2;
    panSpeed = 0.3;

    noRotate = false;
    noZoom = false;
    noPan = false;

    staticMoving = false;
    dynamicDampingFactor = 0.2;

    keys = [65 /*A*/, 83 /*S*/, 68 /*D*/ ];

    // Internals

    target = new Vector3.zero();

    lastPosition = new Vector3.zero();

    _state = State.NONE;
    _prevState = State.NONE;

    _eye = new Vector3.zero();

    _rotateStart = new Vector3.zero();
    _rotateEnd = new Vector3.zero();

    _zoomStart = new Vector2.zero();
    _zoomEnd = new Vector2.zero();
    _zoomFactor = 1;

    _touchZoomDistanceStart = 0;
    _touchZoomDistanceEnd = 0;

    _panStart = new Vector2.zero();
    _panEnd = new Vector2.zero();

    // For reset

    target0 = target.clone();
    position0 = this.object.position.clone();
    up0 = this.object.up.clone();

    left0 = (this.object as OrthographicCamera).left;
    right0 = (this.object as OrthographicCamera).right;
    top0 = (this.object as OrthographicCamera).top;
    bottom0 = (this.object as OrthographicCamera).bottom;
    center0 = new Vector2((left0 + right0) / 2.0, (top0 + bottom0) / 2.0);

    this.domElement
        ..onContextMenu.listen((event) => event.preventDefault())
        ..onMouseDown.listen(mousedown)
        ..onMouseWheel.listen(mousewheel)
        ..onTouchStart.listen(touchstart)
        ..onTouchEnd.listen(touchend)
        ..onTouchMove.listen(touchmove);

    //this.domElement.addEventListener( 'DOMMouseScroll', mousewheel, false ); // firefox

    keydownStream = window.onKeyDown.listen(keydown);
    window.onKeyUp.listen(keyup);


    handleResize();
  }


  // methods

  handleResize() {
    screen['width'] = window.innerWidth;
    screen['height'] = window.innerHeight;

    screen['offsetLeft'] = 0;
    screen['offsetTop'] = 0;

    radius = (screen['width'] + screen['height'] / 4);
  }

  getMouseOnScreen(clientX, clientY) =>
      new Vector2((clientX - screen['offsetLeft']) / radius, (clientY - screen['offsetTop']) / radius);

  getMouseProjectionOnBall(clientX, clientY) {

    var mouseOnBall = new Vector3(
        (clientX - screen['width'] * 0.5 - screen['offsetLeft']) / radius,
        (screen['height'] * 0.5 + screen['offsetTop'] - clientY) / radius,
        0.0);

    var length = mouseOnBall.length;

    if (length > 1.0) {

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

    if (_state == State.TOUCH_ZOOM) {

      double factor = _touchZoomDistanceStart / _touchZoomDistanceEnd;
      _touchZoomDistanceStart = _touchZoomDistanceEnd;
      _zoomFactor *= factor;

      (object as OrthographicCamera).left = _zoomFactor * left0 + (1 - _zoomFactor) * center0.x;
      (object as OrthographicCamera).right = _zoomFactor * right0 + (1 - _zoomFactor) * center0.x;
      (object as OrthographicCamera).top = _zoomFactor * top0 + (1 - _zoomFactor) * center0.y;
      (object as OrthographicCamera).bottom = _zoomFactor * bottom0 + (1 - _zoomFactor) * center0.y;

    } else {

      var factor = 1.0 + (_zoomEnd.y - _zoomStart.y) * zoomSpeed;

      if (factor != 1.0 && factor > 0.0) {

        _zoomFactor *= factor;

        (object as OrthographicCamera).left = _zoomFactor * left0 + (1 - _zoomFactor) * center0.x;
        (object as OrthographicCamera).right = _zoomFactor * right0 + (1 - _zoomFactor) * center0.x;
        (object as OrthographicCamera).top = _zoomFactor * top0 + (1 - _zoomFactor) * center0.y;
        (object as OrthographicCamera).bottom = _zoomFactor * bottom0 + (1 - _zoomFactor) * center0.y;

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

        _panStart = _panEnd;

      } else {

        _panStart += (_panEnd - _panStart).scale(dynamicDampingFactor);

      }

    }

  }

  update() {

    _eye.setFrom(object.position).sub(target);

    if (!noRotate) {
      rotateCamera();
    }

    if (!noZoom) {
      zoomCamera();
      (object as OrthographicCamera).updateProjectionMatrix();
    }

    if (!noPan) {
      panCamera();
    }

    object.position = target + _eye;

    object.lookAt(target);

    // distanceToSquared
    if ((lastPosition - object.position).length2 > 0.0) {

      _onChangeController.add(null);

      lastPosition.setFrom(object.position);

    }

  }

  reset() {

    _state = State.NONE;
    _prevState = State.NONE;

    target = target0;
    object.position = position0;
    object.up = up0;

    _eye.setFrom(object.position).sub(target);

    (object as OrthographicCamera).left = left0;
    (object as OrthographicCamera).right = right0;
    (object as OrthographicCamera).top = top0;
    (object as OrthographicCamera).bottom = bottom0;

    object.lookAt(target);

    _onChangeController.add(null);

  }

  // Listeners

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
      _rotateEnd = _rotateStart;

    } else if (_state == State.ZOOM && !noZoom) {

      _zoomStart = getMouseOnScreen(event.client.x, event.client.y);
      _zoomEnd = _zoomStart;

    } else if (_state == State.PAN && !noPan) {

      _panStart = getMouseOnScreen(event.client.x, event.client.y);
      _panEnd = _panStart;

    }

    mouseMoveStream = document.onMouseMove.listen(mousemove);
    mouseUpStream = document.onMouseUp.listen(mouseup);

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

  }

  touchstart(TouchEvent event) {

    if (!enabled) {
      return;
    }

    event.preventDefault();

    switch (event.touches.length) {

      case 1:
        _state = State.TOUCH_ROTATE;
        _rotateStart = _rotateEnd = getMouseProjectionOnBall(event.touches[0].page.x, event.touches[0].page.y);
        break;
      case 2:
        _state = State.TOUCH_ZOOM;
        _zoomStart = _zoomEnd = getMouseOnScreen(event.touches[0].page.x, event.touches[0].page.y);
        break;
      case 3:
        _state = State.TOUCH_PAN;
        _panStart = _panEnd = getMouseOnScreen(event.touches[0].page.x, event.touches[0].page.y);
        break;
      default:
        _state = State.NONE;

    }

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
        _zoomEnd = getMouseOnScreen(event.touches[0].page.x, event.touches[0].page.y);
        break;
      case 3:
        _panEnd = getMouseOnScreen(event.touches[0].page.x, event.touches[0].page.y);
        break;
      default:
        _state = State.NONE;

    }

  }

  touchend(TouchEvent event) {

    if (!enabled) {
      return;
    }

    switch (event.touches.length) {

      case 1:
        _rotateStart = _rotateEnd = getMouseProjectionOnBall(event.touches[0].page.x, event.touches[0].page.y);
        break;
      case 2:
        _touchZoomDistanceStart = _touchZoomDistanceEnd = 0;
        break;
      case 3:
        _panStart = _panEnd = getMouseOnScreen(event.touches[0].page.x, event.touches[0].page.y);

    }

    _state = State.NONE;

  }
}
