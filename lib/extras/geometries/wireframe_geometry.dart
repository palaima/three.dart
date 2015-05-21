/*
 * @author mrdoob / http://mrdoob.com/
 */

part of three.extras.geometries;

class WireframeGeometry extends BufferGeometry {
  WireframeGeometry(IGeometry geometry) {
    var edge = [0, 0], hash = {};

    var sortFunction = (a, b) => a - b;

    if (geometry is Geometry) {
      var vertices = geometry.vertices;
      var faces = geometry.faces;
      var numEdges = 0;

      // allocate maximal size
      var edges = new Uint32List(6 * faces.length);

      for (var i = 0, l = faces.length; i < l; i ++) {
        var face = faces[i];

        for (var j = 0; j < 3; j ++) {
          edge[0] = face.indices[j];
          edge[1] = face.indices[(j + 1) % 3];
          edge.sort(sortFunction);

          var key = edge.toString();

          if (hash[key] == null) {
            edges[2 * numEdges] = edge[0];
            edges[2 * numEdges + 1] = edge[1];
            hash[key] = true;
            numEdges++;
          }
        }
      }

      var coords = new Float32List(numEdges * 2 * 3);

      for (var i = 0; i < numEdges; i++) {
        for (var j = 0; j < 2; j ++) {
          var vertex = vertices[edges [2 * i + j]];

          var index = 6 * i + 3 * j;
          coords[index + 0] = vertex.x;
          coords[index + 1] = vertex.y;
          coords[index + 2] = vertex.z;
        }
      }

      addAttribute('position', new BufferAttribute(coords, 3));
    } else if (geometry is BufferGeometry) {
      if (geometry.aPosition != null) { // Indexed BufferGeometry
        var vertices = geometry.aPosition.array;
        var indices = geometry.aIndex.array;
        var drawcalls = geometry.drawcalls;
        var numEdges = 0;

        if (drawcalls.length == 0) {
          drawcalls = [new DrawCall(count: indices.length, index: 0, start: 0)];
        }

        // allocate maximal size
        var edges = new Uint32List(2 * indices.length);

        for (var o = 0; o < drawcalls.length; ++o) {
          var start = drawcalls[o].start;
          var count = drawcalls[o].count;
          var index = drawcalls[o].index;

          for (var i = start; i < start + count; i += 3) {
            for (var j = 0; j < 3; j ++) {
              edge[0] = index + indices[i + j];
              edge[1] = index + indices[i + (j + 1) % 3];
              edge.sort(sortFunction);

              var key = edge.toString();

              if (hash[key] == null) {
                edges[2 * numEdges] = edge[0];
                edges[2 * numEdges + 1] = edge[1];
                hash[key] = true;
                numEdges++;
              }
            }
          }
        }

        var coords = new Float32List(numEdges * 2 * 3);

        for (var i = 0; i < numEdges; i++) {
          for (var j = 0; j < 2; j ++) {
            var index = 6 * i + 3 * j;
            var index2 = 3 * edges[2 * i + j];
            coords[index + 0] = vertices[index2];
            coords[index + 1] = vertices[index2 + 1];
            coords[index + 2] = vertices[index2 + 2];
          }
        }

        addAttribute('position', new BufferAttribute(coords, 3));
      } else { // non-indexed BufferGeometry
        var vertices = geometry.aPosition.array;
        var numEdges = vertices.length ~/ 3;
        var numTris = numEdges ~/ 3;

        var coords = new Float32List(numEdges * 2 * 3);

        for (var i = 0; i < numTris; i++) {
          for (var j = 0; j < 3; j++) {
            var index = 18 * i + 6 * j;

            var index1 = 9 * i + 3 * j;
            coords[index + 0] = vertices[index1];
            coords[index + 1] = vertices[index1 + 1];
            coords[index + 2] = vertices[index1 + 2];

            var index2 = 9 * i + 3 * ((j + 1) % 3);
            coords[index + 3] = vertices[index2];
            coords[index + 4] = vertices[index2 + 1];
            coords[index + 5] = vertices[index2 + 2];
          }
        }

        addAttribute('position', new BufferAttribute(coords, 3));
      }
    }
  }

  noSuchMethod(Invocation invocation) {
    print("'${invocation.memberName}' not available in BufferGeometry");
  }
}
