/*
 * @author Dylan Grafmyre
 * Based on work by:
 * @author Thomas Diewald
 * @link http://www.openprocessing.org/visuals/?visualID=15599
 */

part of three;

// Hilbert Curve: Generates 2D-Coordinates in a very fast way.
class HilbertGeometry extends Geometry {
  /// @param center     Center of Hilbert curve.
  /// @param size       Total width of Hilbert curve.
  /// @param iterations Number of subdivisions.
  /// @param v0         Corner index -X, -Z.
  /// @param v1         Corner index -X, +Z.
  /// @param v2         Corner index +X, +Z.
  /// @param v3         Corner index +X, -Z.
  HilbertGeometry.D2([Vector3 center, double size = 10.0, int iterations = 1, int v0 = 0, int v1 = 1, int v2 = 2, int v3 = 3]) {
    center = center != null ? center : new Vector3.zero();
    vertices.addAll(_hilbert2D(center, size, iterations, v0, v1, v2, v3));
  }

  /// @param center     Center of Hilbert curve.
  /// @param size       Total width of Hilbert curve.
  /// @param iterations Number of subdivisions.
  /// @param v0         Corner index -X, +Y, -Z.
  /// @param v1         Corner index -X, +Y, +Z.
  /// @param v2         Corner index -X, -Y, +Z.
  /// @param v3         Corner index -X, -Y, -Z.
  /// @param v4         Corner index +X, -Y, -Z.
  /// @param v5         Corner index +X, -Y, +Z.
  /// @param v6         Corner index +X, +Y, +Z.
  /// @param v7         Corner index +X, +Y, -Z.
  HilbertGeometry.D3([Vector3 center, double size = 10.0, int iterations = 1, int v0 = 0, int v1 = 1, int v2 = 2, int v3 = 3,
      int v4 = 4, int v5 = 5, int v6 = 6, int v7 = 7]) {
    center = center != null ? center : new Vector3.zero();
    vertices.addAll(_hilbert3D(center, size, iterations, v0, v1, v2, v3, v4, v5, v6, v7));
  }

  List<Vector3> _hilbert2D(Vector3 center, double size, int iterations, int v0, int v1, int v2, int v3) {
    var half  = size / 2;

    var vec_s = [
      new Vector3(center.x - half, center.y, center.z - half),
      new Vector3(center.x - half, center.y, center.z + half),
      new Vector3(center.x + half, center.y, center.z + half),
      new Vector3(center.x + half, center.y, center.z - half)
    ];

    var vec = [vec_s[v0], vec_s[v1], vec_s[v2], vec_s[v3]];

    // Recurse iterations
    if (0 <= --iterations) {
      var tmp = []
        ..addAll(_hilbert2D (vec[0], half, iterations, v0, v3, v2, v1))
        ..addAll(_hilbert2D (vec[1], half, iterations, v0, v1, v2, v3))
        ..addAll(_hilbert2D (vec[2], half, iterations, v0, v1, v2, v3))
        ..addAll(_hilbert2D (vec[3], half, iterations, v2, v1, v0, v3));

      // Return recursive call
      return tmp;
    }

    // Return complete Hilbert Curve.
    return vec;
  }

  List<Vector3> _hilbert3D(Vector3 center, double size, int iterations, int v0, int v1, int v2, int v3,
      int v4, int v5, int v6, int v7) {
    var half = size / 2;

    var vec_s = [
      new Vector3(center.x - half, center.y + half, center.z - half),
      new Vector3(center.x - half, center.y + half, center.z + half),
      new Vector3(center.x - half, center.y - half, center.z + half),
      new Vector3(center.x - half, center.y - half, center.z - half),
      new Vector3(center.x + half, center.y - half, center.z - half),
      new Vector3(center.x + half, center.y - half, center.z + half),
      new Vector3(center.x + half, center.y + half, center.z + half),
      new Vector3(center.x + half, center.y + half, center.z - half)
    ];

    var vec = [vec_s[v0], vec_s[v1], vec_s[v2], vec_s[v3], vec_s[v4], vec_s[v5], vec_s[v6], vec_s[v7]];

    // Recurse iterations
    if (--iterations >= 0) {
      var tmp = []
        ..addAll(_hilbert3D(vec[0], half, iterations, v0, v3, v4, v7, v6, v5, v2, v1))
        ..addAll(_hilbert3D(vec[1], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3))
        ..addAll(_hilbert3D(vec[2], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3))
        ..addAll(_hilbert3D(vec[3], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5))
        ..addAll(_hilbert3D(vec[4], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5))
        ..addAll(_hilbert3D(vec[5], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7))
        ..addAll(_hilbert3D(vec[6], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7))
        ..addAll(_hilbert3D(vec[7], half, iterations, v6, v5, v2, v1, v0, v3, v4, v7));

      // Return recursive call
      return tmp;
    }

    // Return complete Hilbert Curve.
    return vec;
  }
}
