/*
 * @author mrdoob / http://mrdoob.com/
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three.extras.geometries;

class PlaneBufferGeometry extends BufferGeometry {
  String type = 'PlaneBufferGeometry';

  PlaneBufferGeometry(double width, double height, [int widthSegments = 1, int heightSegments = 1]) {
    var width_half = width / 2;
    var height_half = height / 2;

    var gridX = widthSegments;
    var gridY = heightSegments;

    var gridX1 = gridX + 1;
    var gridY1 = gridY + 1;

    var segment_width = width / gridX;
    var segment_height = height / gridY;

    var vertices = new Float32List(gridX1 * gridY1 * 3);
    var normals = new Float32List(gridX1 * gridY1 * 3);
    var uvs = new Float32List(gridX1 * gridY1 * 2);

    var offset = 0;
    var offset2 = 0;

    for (var iy = 0; iy < gridY1; iy ++) {
      var y = iy * segment_height - height_half;

      for (var ix = 0; ix < gridX1; ix ++) {
        var x = ix * segment_width - width_half;

        vertices[offset    ] = x;
        vertices[offset + 1] = - y;

        normals[offset + 2] = 1.0;

        uvs[offset2    ] = ix / gridX;
        uvs[offset2 + 1] = 1.0 - (iy / gridY);

        offset += 3;
        offset2 += 2;
      }
    }

    offset = 0;

    var indices;

    if ((vertices.length / 3) > 65535) {
      indices = new Uint32List(gridX * gridY * 6);
    } else {
      indices = new Uint16List(gridX * gridY * 6);
    }

    for (var iy = 0; iy < gridY; iy ++) {
      for (var ix = 0; ix < gridX; ix ++) {
        var a = ix + gridX1 * iy;
        var b = ix + gridX1 * (iy + 1);
        var c = (ix + 1) + gridX1 * (iy + 1);
        var d = (ix + 1) + gridX1 * iy;

        indices[offset    ] = a;
        indices[offset + 1] = b;
        indices[offset + 2] = d;

        indices[offset + 3] = b;
        indices[offset + 4] = c;
        indices[offset + 5] = d;

        offset += 6;
      }
    }

    aIndex = new BufferAttribute(indices, 1);
    aPosition = new BufferAttribute(vertices, 3);
    aNormal = new BufferAttribute(normals, 3);
    aUV = new BufferAttribute(uvs, 2);
  }

  noSuchMethod(Invocation invocation) {
    print("'${invocation.memberName}' not available in BufferGeometry");
  }
}