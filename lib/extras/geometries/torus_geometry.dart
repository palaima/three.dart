/*
 * @author oosmoxiecode
 * @author mrdoob / http://mrdoob.com/
 * based on http://code.google.com/p/away3d/source/browse/trunk/fp10/Away3DLite/src/away3dlite/primitives/Torus.as?r=2888
 *
 * based on r66
 */

part of three;

/**
 * A class for generating torus geometries
 *
 *     var geometry = new TorusGeometry(10.0, 3.0, 16, 100);
 *     var material = new MeshBasicMaterial(color: 0xffff00);
 *     var torus = new Mesh(geometry, material);
 *     scene.add(torus);
 */
class TorusGeometry extends Geometry {
  /// Creates a new torus geometry.
  TorusGeometry([double radius = 100.0,
                 double tube = 40.0,
                 int radialSegments = 8,
                 int tubularSegments = 6,
                 double arc = math.PI * 2]) : super() {

    List<Vector2> uvs = [];
    List<Vector3> normals = [];

    for (var j = 0; j <= radialSegments; j++) {
      for (var i = 0; i <= tubularSegments; i++) {
        var u = i / tubularSegments * arc;
        var v = j / radialSegments * math.PI * 2;

        var center = new Vector3.zero()
            ..x = radius * math.cos(u)
            ..y = radius * math.sin(u);

        var vertex = new Vector3.zero()
            ..x = (radius + tube * math.cos(v)) * math.cos(u)
            ..y = (radius + tube * math.cos(v)) * math.sin(u)
            ..z = tube * math.sin(v);

        vertices.add(vertex);

        uvs.add(new Vector2(i / tubularSegments, j / radialSegments));
        normals.add((vertex - center).normalize());
      }
    }

    for (var j = 1; j <= radialSegments; j++) {
      for (var i = 1; i <= tubularSegments; i++) {
        var a = (tubularSegments + 1) * j + i - 1;
        var b = (tubularSegments + 1) * (j - 1) + i - 1;
        var c = (tubularSegments + 1) * (j - 1) + i;
        var d = (tubularSegments + 1) * j + i;

        faces.add(new Face3(a, b, d, normal: [normals[a].clone(), normals[b].clone(), normals[d].clone()]));
        faceVertexUvs[0].add([uvs[a].clone(), uvs[b].clone(), uvs[d].clone()]);

        faces.add(new Face3(b, c, d, normal: [normals[b].clone(), normals[c].clone(), normals[d].clone()]));
        faceVertexUvs[0].add([uvs[b].clone(), uvs[c].clone(), uvs[d].clone()]);
      }
    }

    computeFaceNormals();
    computeCentroids();
  }
}
