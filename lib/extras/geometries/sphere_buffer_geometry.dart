/*
 * @author benaadams / https://twitter.com/ben_a_adams
 *
 * based on r72
 */

part of three.extras.geometries;

class SphereBufferGeometry extends BufferGeometry {
  String type = 'SphereBufferGeometry';

  SphereBufferGeometry([double radius = 50.0, int widthSegments, int heightSegments, double phiStart = 0.0,
      double phiLength = math.PI * 2.0, double thetaStart = 0.0, double thetaLength = math.PI]) {
    widthSegments = widthSegments != null ? math.max(3, widthSegments) : 8;
    heightSegments = heightSegments != null ? math.max(2, heightSegments) : 6;
    var vertexCount = ((widthSegments + 1) * (heightSegments + 1));

    var positions = new BufferAttribute.float32(vertexCount * 3, 3);
    var normals = new BufferAttribute.float32(vertexCount * 3, 3);
    var uvs = new BufferAttribute.float32(vertexCount * 2, 2);

    addAttribute('position', positions);
    addAttribute('normal', normals);
    addAttribute('uv', uvs);

    var index = 0,
        vertices = [];

    for (var y = 0; y <= heightSegments; y++) {
      var verticesRow = [];

      var v = y / heightSegments;

      for (var x = 0; x <= widthSegments; x++) {
        var u = x / widthSegments;

        var px = -radius * math.cos(phiStart + u * phiLength) * math.sin(thetaStart + v * thetaLength);
        var py = radius * math.cos(thetaStart + v * thetaLength);
        var pz = radius * math.sin(phiStart + u * phiLength) * math.sin(thetaStart + v * thetaLength);

        var normal = new Vector3(px, py, pz).normalize();

        aPosition.setXYZ(index, px, py, pz);
        aNormal.setXYZ(index, normal.x, normal.y, normal.z);
        aUV.setXY(index, u, 1 - v);

        verticesRow.add(index);

        index++;
      }

      vertices.add(verticesRow);
    }

    var indices = [];
    for (var y = 0; y < heightSegments - 1; y++) {
      for (var x = 0; x < widthSegments; x++) {
        var v1 = vertices[y][x + 1];
        var v2 = vertices[y][x];
        var v3 = vertices[y + 1][x];
        var v4 = vertices[y + 1][x + 1];

        if (y != 0) indices.addAll([v1, v2, v4]);

        indices.addAll([v2, v3, v4]);
      }
    }

    var y = heightSegments;

    for (var x = 0; x < widthSegments; x++) {
      var v2 = vertices[y][x];
      var v3 = vertices[y - 1][x];
      var v4 = vertices[y - 1][x + 1];

      indices.addAll([v2, v4, v3]);
    }

    addAttribute('index', new BufferAttribute(new Uint16List.fromList(indices), 1));

    boundingSphere = new Sphere.centerRadius(new Vector3.zero(), radius);
  }

  noSuchMethod(Invocation invocation) {
    print("'${invocation.memberName}' not available in BufferGeometry");
  }
}
