/*
 * @author WestLangley / http://github.com/WestLangley
 */

part of three;

class EdgesGeometry extends BufferGeometry {
  EdgesGeometry(IGeometry geometry, [double thresholdAngle = 1.0]) {
    var thresholdDot = math.cos(degToRad(thresholdAngle));

    var edge = [0, 0],
        hash = {};

    var sortFunction = (a, b) => a - b;

    Geometry geometry2;

    if (geometry is BufferGeometry) {
      geometry2 = new Geometry();
      geometry2.fromBufferGeometry(geometry);
    } else {
      geometry2 = geometry.clone();
    }

    geometry2.mergeVertices();
    geometry2.computeFaceNormals();

    var vertices = geometry2.vertices;
    var faces = geometry2.faces;

    for (var i = 0; i < faces.length; i++) {
      var face = faces[i];

      for (var j = 0; j < 3; j++) {
        edge[0] = face.indices[j];
        edge[1] = face.indices[(j + 1) % 3];
        edge.sort(sortFunction);

        var key = edge.toString();

        if (hash[key] == null) {
          hash[key] = {'vert1': edge[0], 'vert2': edge[1], 'face1': i, 'face2': null};
        } else {
          hash[key]['face2'] = i;
        }
      }
    }

    var coords = [];

    for (var key in hash.keys) {
      var h = hash[key];

      if (h['face2'] == null || faces[h['face1']].normal.dot(faces[h['face2']].normal) <= thresholdDot) {
        var vertex = vertices[h['vert1']];
        coords.add(vertex.x);
        coords.add(vertex.y);
        coords.add(vertex.z);

        vertex = vertices[h['vert2']];
        coords.add(vertex.x);
        coords.add(vertex.y);
        coords.add(vertex.z);
      }
    }

    aPosition = new BufferAttribute(new Float32List.fromList(coords), 3);
  }
}
