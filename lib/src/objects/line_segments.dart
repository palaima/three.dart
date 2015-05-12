/*
 * @author mrdoob / http://mrdoob.com/
 */

part of three.objects;

class LineSegments extends Line {
  String type = 'LineSegments';

  LineSegments([IGeometry geometry, LineMaterial material]) : super(geometry, material);
}