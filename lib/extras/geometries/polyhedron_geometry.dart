/*
 * @author clockworkgeek / https://github.com/clockworkgeek
 * @author timothypratley / https://github.com/timothypratley
 * @author WestLangley / http://github.com/WestLangley
 *
 * based on r71
 */

part of three.extras.geometries;

class PolyhedronGeometry extends Geometry {
  List<UVIndexVector> _vertices = [];

  PolyhedronGeometry(List<int> verticesInt, List<int> indices, [double radius = 1.0, int detail = 0])
      : super() {
    var verticesDouble = verticesInt.map((v) => v.toDouble()).toList();

    for (var i = 0; i < verticesDouble.length; i += 3) {
      _prepare(new Vector3.array(verticesDouble, i));
    }

    var faces = [];

    for (var i = 0, j = 0; i < indices.length; i += 3, j++) {
      var v1 = _vertices[indices[i]];
      var v2 = _vertices[indices[i + 1]];
      var v3 = _vertices[indices[i + 2]];

      faces.add(new Face3(v1.index, v2.index, v3.index, normal: [v1.clone(), v2.clone(), v3.clone()]));
    }

    faces.forEach((face) => _subdivide(face, detail));

    // Handle case when face straddles the seam
    faceVertexUvs[0].forEach((uvs) {
      var x0 = uvs[0].x;
      var x1 = uvs[1].x;
      var x2 = uvs[2].x;

      var max = math.max(x0, math.max(x1, x2));
      var min = math.min(x0, math.min(x1, x2));

      if (max > 0.9 && min < 0.1) {
        // 0.9 is somewhat arbitrary
        if (x0 < 0.2) uvs[0].x += 1;
        if (x1 < 0.2) uvs[1].x += 1;
        if (x2 < 0.2) uvs[2].x += 1;
      }
    });

    for (var i = 0; i < _vertices.length; i++) {
      this.vertices.add(_vertices[i]);
    }


    // Apply radius
    this.vertices.forEach((vertex) => vertex.scale(radius));

    // Merge vertices
    mergeVertices();

    computeFaceNormals();
    computeCentroids();

    boundingSphere = new Sphere.centerRadius(new Vector3.zero(), radius);
  }

  // Project vector onto sphere's surface
  Vector3 _prepare(Vector3 vector) {
    var vertex = new UVIndexVector.copy(vector.normalize());
    _vertices.add(vertex);
    vertex.index = _vertices.length - 1;

    // Texture coords are equivalent to map coords, calculate angle and convert to fraction of a circle.

    var u = _azimuth(vector) / 2 / math.PI + 0.5;
    var v = _inclination(vector) / math.PI + 0.5;
    vertex.uv = new Vector2(u, 1.0 - v);

    return vertex;
  }

  // Approximate a curved face with recursively sub-divided triangles.
  void _make(UVIndexVector v1, UVIndexVector v2, UVIndexVector v3) {
    var face = new Face3(v1.index, v2.index, v3.index, normal: [v1.clone(), v2.clone(), v3.clone()]);
    faces.add(face);

    var centroid = (v1 + v2 + v3) * (1 / 3);

    var azi = _azimuth(centroid);

    faceVertexUvs[0]
        .add([_correctUV(v1.uv, v1, azi), _correctUV(v2.uv, v2, azi), _correctUV(v3.uv, v3, azi)]);
  }

  // Analytically subdivide a face to the required detail level.
  void _subdivide(Face3 face, int detail) {
    var cols = math.pow(2, detail);
    var a = _prepare(_vertices[face.a]);
    var b = _prepare(_vertices[face.b]);
    var c = _prepare(_vertices[face.c]);
    var v = [];

    // Construct all of the vertices for this subdivision.

    for (var i = 0; i <= cols; i++) {
      v.add([]);

      var result = new Vector3.zero();
      Vector3.mix(a, c, i / cols, result);
      var aj = _prepare(result);
      Vector3.mix(b, c, i / cols, result);
      var bj = _prepare(result);
      var rows = cols - i;

      for (var j = 0; j <= rows; j++) {
        if (j == 0 && i == cols) {
          v[i].add(aj);
        } else {
          Vector3.mix(aj, bj, j / rows, result);
          v[i].add(_prepare(result));
        }
      }
    }

    // Construct all of the faces.

    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < 2 * (cols - i) - 1; j++) {
        var k = (j / 2).floor();

        if (j % 2 == 0) {
          _make(v[i][k + 1], v[i + 1][k], v[i][k]);
        } else {
          _make(v[i][k + 1], v[i + 1][k + 1], v[i + 1][k]);
        }
      }
    }
  }

  /// Angle around the Y axis, counter-clockwise when looking from above.
  double _azimuth(Vector3 vector) => math.atan2(vector.z, -vector.x);

  /// Angle above the XZ plane.
  double _inclination(Vector3 vector) {
    return math.atan2(-vector.y, math.sqrt(vector.x * vector.x + vector.z * vector.z));
  }

  /// Texture fixing helper. Spheres have some odd behaviours.
  Vector2 _correctUV(Vector2 uv, Vector3 vector, double azimuth) {
    if (azimuth < 0 && uv.x == 1.0) {
      uv = new Vector2(uv.x - 1.0, uv.y);
    }
    if (vector.x == 0.0 && vector.z == 0.0) {
      uv = new Vector2(azimuth / 2 / math.PI + 0.5, uv.y);
    }

    return uv.clone();
  }
}

class UVIndexVector extends Vector3 {
  Vector2 uv;
  int index;
  UVIndexVector._() : super.zero();
  factory UVIndexVector(double x, double y, double z) => new UVIndexVector._()..setValues(x, y, z);
  factory UVIndexVector.copy(Vector3 arg) => new UVIndexVector._()..setFrom(arg);
}
