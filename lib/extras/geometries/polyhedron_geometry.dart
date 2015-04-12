part of three;

class PolyhedronGeometry extends Geometry {
  List _midpoints;

  // nelsonsilva - We're using a PolyhedronGeometryVertex decorator to allow adding index and uv properties
  List<Vector3> _p = [];

  PolyhedronGeometry(List<List<num>> lvertices, List<List<num>> lfaces, [double radius = 1.0, num detail = 0])
      : super() {
    _midpoints = [];

    lvertices.forEach((vertex) {
      _prepare(new Vector3(vertex[0].toDouble(), vertex[1].toDouble(), vertex[2].toDouble()));
    });

    lfaces.forEach((face) => _make(_p[face[0]], _p[face[1]], _p[face[2]], detail));

    // TODO No need to unwrap ? (now unwrapp and add the original Vector3 to the vertices)
    _p.forEach((v) => this.vertices.add(v));

    mergeVertices();

    // Apply radius

    this.vertices.forEach((Vector3 vertex) => vertex.scale(radius));

    computeCentroids();

    boundingSphere = new Sphere.centerRadius(new Vector3.zero(), radius);
  }

  // Project vector onto sphere's surface
  Vector3 _prepare(Vector3 vertex) {
    vertex.normalize();
    _p.add(vertex);
    vertex._index = _p.length - 1;

    // Texture coords are equivalent to map coords, calculate angle and convert to fraction of a circle.

    var u = _azimuth(vertex) / 2 / Math.PI + 0.5;
    var v = _inclination(vertex) / Math.PI + 0.5;
    vertex._uv = new Vector2(u, 1 - v);

    return vertex;
  }

  // Approximate a curved face with recursively sub-divided triangles.
  _make(Vector3 v1, Vector3 v2, Vector3 v3, num detail) {
    if (detail < 1) {
      var face = new Face3(v1._index, v2._index, v3._index, normal: [v1.clone(), v2.clone(), v3.clone()]);
      face.centroid.add(v1).add(v2).add(v3).scale(1.0 / 3.0);
      face.normal = face.centroid.clone().normalize();
      this.faces.add(face);

      var azi = _azimuth(face.centroid);
      this.faceVertexUvs[0].add([_correctUV(v1._uv, v1, azi), _correctUV(v2._uv, v2, azi), _correctUV(v3._uv, v3, azi)]);
    } else {
      detail -= 1;

      // split triangle into 4 smaller triangles

      _make(v1, _midpoint(v1, v2), _midpoint(v1, v3), detail); // top quadrant
      _make(_midpoint(v1, v2), v2, _midpoint(v2, v3), detail); // left quadrant
      _make(_midpoint(v1, v3), _midpoint(v2, v3), v3, detail); // right quadrant
      _make(_midpoint(v1, v2), _midpoint(v2, v3), _midpoint(v1, v3), detail); // center quadrant
    }
  }

  _midpoint(Vector3 v1, Vector3 v2) {
    // TODO - nelsonsilva - refactor this code
    // arrays don't "automagically" grow in Dart!
    if (_midpoints.length < v1._index + 1) {
      _midpoints.length = v1._index + 1;
      _midpoints[v1._index] = [];
    }
    if (_midpoints.length < v2._index + 1) {
      _midpoints.length = v2._index + 1;
      _midpoints[v2._index] = [];
    }

    // prepare _midpoints[ v1.index ][ v2.index ]
    if (_midpoints[v1._index] == null) {
      _midpoints[v1._index] = [];
    }

    if (_midpoints[v1._index].length < v2._index + 1) {
      _midpoints[v1._index].length = v2._index + 1;
    }

    // prepare _midpoints[ v2.index ][ v1.index ]
    if (_midpoints[v2._index] == null) {
      _midpoints[v2._index] = [];
    }

    if (_midpoints[v2._index].length < v1._index + 1) {
      _midpoints[v2._index].length = v1._index + 1;
    }

    var mid = _midpoints[v1._index][v2._index];

    if (mid == null) {

      // generate mean point and project to surface with prepare()
      mid = _prepare(new Vector3.copy((v1 + v2).scale(0.5)));
      _midpoints[v1._index][v2._index] = mid;
      _midpoints[v2._index][v1._index] = mid;
    }

    return mid;
  }

  /// Angle around the Y axis, counter-clockwise when looking from above.
  double _azimuth(Vector3 vector) => Math.atan2(vector.z, -vector.x);

  /// Angle above the XZ plane.
  double _inclination(Vector3 vector) =>
      Math.atan2(-vector.y, Math.sqrt((vector.x * vector.x) + (vector.z * vector.z)));

  /// Texture fixing helper. Spheres have some odd behaviours.
  Vector2 _correctUV(Vector2 uv, Vector3 vector, double azimuth) {
    if ((azimuth < 0) && (uv.x == 1)) uv = new Vector2(uv.x - 1, uv.y);
    if ((vector.x == 0) && (vector.z == 0)) uv = new Vector2(azimuth / 2 / Math.PI + 0.5, uv.y);
    return uv;
  }
}