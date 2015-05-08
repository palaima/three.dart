/*
 * @author mrdoob / http://mrdoob.com/
 */

part of three.extras.helpers;

class GridHelper extends LineSegments {
  Color color1 = new Color(0x444444);
  Color color2 = new Color(0x888888);

  GridHelper(double size, double step)
      : super(new Geometry(), new LineBasicMaterial(vertexColors: VertexColors)) {
    for (var i = -size; i <= size; i += step) {
      geometry.vertices.addAll([
        new Vector3(-size, 0.0, i),
        new Vector3(size, 0.0, i),
        new Vector3(i, 0.0, -size),
        new Vector3(i, 0.0, size)
      ]);

      var color = i == 0 ? color1 : color2;

      (geometry as Geometry).colors.addAll([color, color, color, color]);
    }
  }

  void setColors(num colorCenterLine, num colorGrid) {
    color1.setHex(colorCenterLine);
    color2.setHex(colorGrid);
  }
}
