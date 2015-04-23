/*
 * @author mr.doob / http://mrdoob.com/
 * based on http://papervision3d.googlecode.com/svn/trunk/as3/trunk/src/org/papervision3d/objects/primitives/Plane.as
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

class PlaneGeometry extends Geometry {
  String type = 'PlaneGeometry';

  /// Creates a new plane geometry.
  PlaneGeometry(double width, double height, [int widthSegments = 1, int heightSegments = 1]) : super() {
    log('PlaneGeometry: Consider using PlaneBufferGeometry for lower memory footprint.');
    fromBufferGeometry(new PlaneBufferGeometry(width, height, widthSegments, heightSegments));
  }
}