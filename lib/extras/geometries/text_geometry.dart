/*
 * @author zz85 / http://www.lab4games.net/zz85/blog
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three;

class TextGeometry extends ExtrudeGeometry {
  String type = 'TextGeometry';
  factory TextGeometry(String text, {int size: 100, int height: 50, int curveSegments: 12,
    String font: 'helvetiker', String weight: 'normal', String style: 'normal',
    bool bevelEnabled: false, double bevelThickness: 10.0, double bevelSize: 8.0, int bevelSegments: 3,
    int steps: 1, Curve extrudePath}) {
    var textShapes = font_utils.generateShapes(text, size, curveSegments, font, weight, style);

    return new TextGeometry._internal(textShapes, height, bevelThickness, bevelSize, bevelSegments, bevelEnabled,
        curveSegments, steps, extrudePath);
  }

  TextGeometry._internal(List<Shape> shapes, int height, double bevelThickness, double bevelSize, int bevelSegments,
      bool bevelEnabled, int curveSegments, int steps, Curve extrudePath)
      : super(shapes, amount: height, bevelThickness: bevelThickness, bevelSize: bevelSize, bevelSegments: bevelSegments,
          bevelEnabled: bevelEnabled, curveSegments: curveSegments, steps: steps, extrudePath: extrudePath);
}
