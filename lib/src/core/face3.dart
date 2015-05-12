part of three.core;

/// Triangle face.
class Face3 {
  Int32List indices;

  Vector3 normal;

  List<Vector3> vertexNormals;

  Color color;

  List<Color> vertexColors;

  List vertexTangents = [];

  // backwards compatibility
  var materialIndex;
  var centroid = new Vector3.zero();

  /// Vertex A index.
  int get a => indices[0];

  /// Set vertex A index.
  set a(int i) {
    indices[0] = i;
  }

  /// Vertex B index.
  int get b => indices[1];

  /// Set vertex B index.
  set b(int i) {
    indices[1] = i;
  }

  /// Vertex C index.
  int get c => indices[2];

  /// Set vertex C index.
  set c(int i) {
    indices[2] = i;
  }

  Face3(int a, int b, int c, {normal, color})
      : indices = new Int32List.fromList([a, b, c]) {
    this.normal = normal is Vector3 ? normal : new Vector3.zero();
    vertexNormals = normal is List ? normal : [];

    this.color = color is Color ? color : new Color.white();
    vertexColors = color is List ? color : [];
  }

  Face3 clone() {
    var face = new Face3(indices[0], indices[1], indices[2])
      ..normal.setFrom(normal)
      ..color.setFrom(color);

    for (var i = 0; i < vertexNormals.length; i++) {
      face.vertexNormals.add(vertexNormals[i].clone());
    }

    for (var i = 0; i < vertexColors.length; i++) {
      face.vertexColors.add(vertexColors[i].clone());
    }

    for (var i = 0; i < vertexTangents.length; i++) {
      face.vertexTangents.add(vertexTangents[i].clone());
    }

    return face;
  }
}
