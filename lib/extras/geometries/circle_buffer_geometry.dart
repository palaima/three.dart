/*
 * @author benaadams / https://twitter.com/ben_a_adams
 */

part of three;

class CircleBufferGeometry extends BufferGeometry {
  String type = 'CircleBufferGeometry';

  CircleBufferGeometry(
      [double radius = 50.0, int segments, double thetaStart = 0.0, double thetaLength = math.PI * 2]) {
    segments = segments != null ? math.max(3, segments) : 8;

    var vertices = segments + 2;

    var positions = new Float32List(vertices * 3);
    var normals = new Float32List(vertices * 3);
    var uvs = new Float32List(vertices * 2);

    // center data is already zero, but need to set a few extras
    normals[3] = 1.0;
    uvs[0] = 0.5;
    uvs[1] = 0.5;

    for (var s = 0, i = 3, ii = 2; s <= segments; s++, i += 3, ii += 2) {
      var segment = thetaStart + s / segments * thetaLength;

      positions[i] = radius * math.cos(segment);
      positions[i + 1] = radius * math.sin(segment);

      normals[i + 2] = 1.0; // normal z

      uvs[ii] = (positions[i] / radius + 1) / 2;
      uvs[ii + 1] = (positions[i + 1] / radius + 1) / 2;
    }

    var indices = [];

    for (var i = 1; i <= segments; i++) {
      indices.add(i);
      indices.add(i + 1);
      indices.add(0);
    }

    aIndex = new BufferAttribute(new Uint16List.fromList(indices), 1);
    aPosition = new BufferAttribute(positions, 3);
    aNormal = new BufferAttribute(normals, 3);
    aUV = new BufferAttribute(uvs, 2);

    boundingSphere = new Sphere.centerRadius(new Vector3.zero(), radius);
  }
}
