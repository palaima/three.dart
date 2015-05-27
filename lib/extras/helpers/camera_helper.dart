/*
 * @author alteredq / http://alteredqualia.com/
 *
 *  - shows frustum, line of sight and up of the camera
 *  - suitable for fast updates
 *  - based on frustum visualization in lightgl.js shadowmap example
 *    http://evanw.github.com/lightgl.js/tests/shadowmap.html
 */

part of three.extras.helpers;

class CameraHelper extends LineSegments {
  Camera camera;

  Map<String, List> pointMap = {};

  CameraHelper(this.camera)
      : super(new Geometry()..dynamic = true, new LineBasicMaterial(color: 0xffffff, vertexColors: FaceColors)) {
    matrix = camera.matrixWorld;
    matrixAutoUpdate = false;

    // colors

    var hexFrustum = 0xffaa00;
    var hexCone = 0xff0000;
    var hexUp = 0x00aaff;
    var hexTarget = 0xffffff;
    var hexCross = 0x333333;

    // near

    _addLine('n1', 'n2', hexFrustum);
    _addLine('n2', 'n4', hexFrustum);
    _addLine('n4', 'n3', hexFrustum);
    _addLine('n3', 'n1', hexFrustum);

    // far

    _addLine('f1', 'f2', hexFrustum);
    _addLine('f2', 'f4', hexFrustum);
    _addLine('f4', 'f3', hexFrustum);
    _addLine('f3', 'f1', hexFrustum);

    // sides

    _addLine('n1', 'f1', hexFrustum);
    _addLine('n2', 'f2', hexFrustum);
    _addLine('n3', 'f3', hexFrustum);
    _addLine('n4', 'f4', hexFrustum);

    // cone

    _addLine('p', 'n1', hexCone);
    _addLine('p', 'n2', hexCone);
    _addLine('p', 'n3', hexCone);
    _addLine('p', 'n4', hexCone);

    // up

    _addLine('u1', 'u2', hexUp);
    _addLine('u2', 'u3', hexUp);
    _addLine('u3', 'u1', hexUp);

    // target

    _addLine('c', 't', hexTarget);
    _addLine('p', 'c', hexCross);

    // cross

    _addLine('cn1', 'cn2', hexCross);
    _addLine('cn3', 'cn4', hexCross);

    _addLine('cf1', 'cf2', hexCross);
    _addLine('cf3', 'cf4', hexCross);

    update();
  }

  void _addLine(String a, String b, int hex) {
    _addPoint(a, hex);
    _addPoint(b, hex);
  }

  void _addPoint(String id, int hex) {
    var geo = geometry as Geometry;
    geo.vertices.add(new Vector3.zero());
    geo.colors.add(new Color(hex));

    if (!pointMap.containsKey(id)) {
      pointMap[id] = [];
    }

    pointMap[id].add(geo.vertices.length - 1);
  }

  Vector3 _vector = new Vector3.zero();
  Camera _camera = new Camera();

  void _setPoint(String point, double x, double y, double z) {
    _vector.setValues(x, y, z).unproject(_camera);

    var points = pointMap[point];

    if (points != null) {
      for (var i = 0; i < points.length; i++) {
        (geometry as Geometry).vertices[points[i]].setFrom(_vector);
      }
    }
  }

  void update() {
    var w = 1.0,
        h = 1.0;

    // we need just camera projection matrix
    // world matrix must be identity

    _camera.projectionMatrix.setFrom(camera.projectionMatrix);

    // center / target

    _setPoint('c', 0.0, 0.0, -1.0);
    _setPoint('t', 0.0, 0.0, 1.0);

    // near

    _setPoint('n1', -w, -h, -1.0);
    _setPoint('n2', w, -h, -1.0);
    _setPoint('n3', -w, h, -1.0);
    _setPoint('n4', w, h, -1.0);

    // far

    _setPoint('f1', -w, -h, 1.0);
    _setPoint('f2', w, -h, 1.0);
    _setPoint('f3', -w, h, 1.0);
    _setPoint('f4', w, h, 1.0);

    // up

    _setPoint('u1', w * 0.7, h * 1.1, -1.0);
    _setPoint('u2', -w * 0.7, h * 1.1, -1.0);
    _setPoint('u3', 0.0, h * 2.0, -1.0);

    // cross

    _setPoint('cf1', -w, 0.0, 1.0);
    _setPoint('cf2', w, 0.0, 1.0);
    _setPoint('cf3', 0.0, -h, 1.0);
    _setPoint('cf4', 0.0, h, 1.0);

    _setPoint('cn1', -w, 0.0, -1.0);
    _setPoint('cn2', w, 0.0, -1.0);
    _setPoint('cn3', 0.0, -h, -1.0);
    _setPoint('cn4', 0.0, h, -1.0);

    (geometry as Geometry).verticesNeedUpdate = true;
  }
}
