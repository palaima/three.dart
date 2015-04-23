/*
 * @author jonobr1 / http://jonobr1.com
 *
 * Creates a one-sided polygonal geometry from a path shape. Similar to
 * ExtrudeGeometry.
 *
 * parameters = {
 *
 *  curveSegments: <int>, // number of points on the curves. NOT USED AT THE MOMENT.
 *
 *  material: <int> // material index for front and back faces
 *  uvGenerator: <Object> // object that provides UV generator functions
 *
 * }
 */

part of three;

class ShapeGeometry extends Geometry {
  String type = 'ShapeGeometry';

  List<Shape> shapes;

  ShapeGeometry(shapes, {int curveSegments: 12, WorldUVGenerator uvGenerator})
      : super() {

    if (shapes == null) {
      this.shapes = [];
      return;
    }

    this.shapes = shapes is! List ? [shapes] : shapes;

    addShapeList(this.shapes, curveSegments: curveSegments, uvGenerator: uvGenerator);

    computeFaceNormals();
  }

  void addShapeList(List<Shape> shapes, {int curveSegments, WorldUVGenerator uvGenerator}) {
    shapes.forEach((shape) => addShape(shape, curveSegments: curveSegments, uvGenerator: uvGenerator));
  }

  void addShape(Shape shape, {int curveSegments: 12, WorldUVGenerator uvGenerator}) {
    var uvgen = uvGenerator != null ? uvGenerator : new ExtrudeGeometryWorldUVGenerator();

    //

    var shapesOffset = this.vertices.length;
    var shapePoints = shape.extractPoints(curveSegments);

    List vertices = shapePoints['shape'];
    List holes = shapePoints['holes'];

    var reverse = !ShapeUtils.isClockWise(vertices);

    if (reverse) {
      vertices = vertices.reversed.toList();

      // Maybe we should also check if holes are in the opposite direction, just to be safe...

      for (var i = 0; i < holes.length; i++) {
        var hole = holes[i];

        if (ShapeUtils.isClockWise(hole)) {
          holes[i] = hole.reversed.toList();
        }
      }

      reverse = false;
    }

    var faces = ShapeUtils.triangulateShape(vertices, holes);

    // Vertices

    holes.forEach((hole) => vertices.addAll(hole));

    //

    vertices.forEach((vertex) =>  this.vertices.add(new Vector3(vertex.x, vertex.y, 0.0)));

    faces.forEach((face) {
      var a = face[0] + shapesOffset;
      var b = face[1] + shapesOffset;
      var c = face[2] + shapesOffset;

      this.faces.add(new Face3(a, b, c));
      this.faceVertexUvs[0].add(uvgen.generateTopUV(this, a, b, c));
    });
  }
}

