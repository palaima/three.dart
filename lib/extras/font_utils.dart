/*
 * @author zz85 / http://www.lab4games.net/zz85/blog
 * @author alteredq / http://alteredqualia.com/
 *
 * For Text operations in three.js (See TextGeometry)
 *
 * It uses techniques used in:
 *
 *  Triangulation ported from AS3
 *    Simple Polygon Triangulation
 *    http://actionsnippet.com/?p=1462
 *
 *  A Method to triangulate shapes with holes
 *    http://www.sakri.net/blog/2009/06/12/an-approach-to-triangulating-polygons-with-holes/
 *
 */

library three.extras.font_utils;

import 'package:three/three.dart';
import 'core/shape_utils.dart' as shape_utils;

Map<String, Map<String, Map<String, dynamic>>> _faces = {};

String _face = 'helvetiker';
String _weight = 'normal';
String _style = 'normal';

int _size = 150;
int _divisions = 10;

Map<String, Map> getFace() => _faces[_face][_weight][_style];

Map<String, String> loadFace(Map<String, String> data) {
  var family = data['familyName'].toLowerCase();

  if (_faces[family] == null) _faces[family] = {};

  if (_faces[family][data['cssFontWeight']] == null) _faces[family][data['cssFontWeight']] = {};
  _faces[family][data['cssFontWeight']][data['cssFontStyle']] = data;

  _faces[family][data['cssFontWeight']][data['cssFontStyle']] = data;

  return data;
}

// RenderText
Map drawText(String text) {
  var face = getFace(),
      scale = _size / face['resolution'],
      offset = 0,
      chars = text.split('');

  var fontPaths = [];

  for (var i = 0; i < chars.length; i++) {
    var path = new Path();

    var ret = extractGlyphPoints(chars[i], face, scale, offset.toDouble(), path);
    offset += ret['offset'];

    fontPaths.add(ret['path']);
  }

  // get the width

  var width = offset / 2;

  return {'paths': fontPaths, 'offset': width};
}

Map extractGlyphPoints(String c, Map face, double scale, double offset, path) {
  List<Vector2> pts = [];

  var glyph = face['glyphs'][c];
  if (glyph == null) glyph = face['glyphs']['?'];

  if (glyph == null) return null;

  if (glyph['o'] != null) {
    var outline = glyph['_cachedOutline'];
    if (outline == null) {
      glyph['_cachedOutline'] = glyph['o'].split(' ');
      outline = glyph['_cachedOutline'];
    }
    var length = outline.length;

    var scaleX = scale;
    var scaleY = scale;

    for (var i = 0; i < length;) {
      var action = outline[i++];

      switch (action) {
        // Move To
        case 'm':
          var x = int.parse(outline[i++]) * scaleX + offset;
          var y = int.parse(outline[i++]) * scaleY;
          path.moveTo(x, y);
          break;
        // Line To
        case 'l':
          var x = int.parse(outline[i++]) * scaleX + offset;
          var y = int.parse(outline[i++]) * scaleY;
          path.lineTo(x, y);
          break;
        case 'q':
          // QuadraticCurveTo
          var cpx = int.parse(outline[i++]) * scaleX + offset;
          var cpy = int.parse(outline[i++]) * scaleY;
          var cpx1 = int.parse(outline[i++]) * scaleX + offset;
          var cpy1 = int.parse(outline[i++]) * scaleY;

          path.quadraticCurveTo(cpx1, cpy1, cpx, cpy);

          if (pts.length > 0) {
            var laste = pts.last;

            var cpx0 = laste.x;
            var cpy0 = laste.y;

            for (var i2 = 1; i2 <= _divisions; i2++) {
              var t = i2 / _divisions;
              shape_utils.b2(t, cpx0, cpx1, cpx);
              shape_utils.b2(t, cpy0, cpy1, cpy);
            }
          }

          break;
        // Cubic Bezier Curve
        case 'b':
          var cpx = int.parse(outline[i++]) * scaleX + offset;
          var cpy = int.parse(outline[i++]) * scaleY;
          var cpx1 = int.parse(outline[i++]) * scaleX + offset;
          var cpy1 = int.parse(outline[i++]) * scaleY;
          var cpx2 = int.parse(outline[i++]) * scaleX + offset;
          var cpy2 = int.parse(outline[i++]) * scaleY;

          path.bezierCurveTo(cpx1, cpy1, cpx2, cpy2, cpx, cpy);

          if (pts.length > 0) {
            var laste = pts.last;
            var cpx0 = laste.x;
            var cpy0 = laste.y;

            for (var i2 = 1; i2 <= _divisions; i2++) {
              var t = i2 / _divisions;
              shape_utils.b3(t, cpx0, cpx1, cpx2, cpx);
              shape_utils.b3(t, cpy0, cpy1, cpy2, cpy);
            }
          }

          break;
      }
    }
  }

  return {'offset': glyph['ha'] * scale, 'path': path};
}

List<Shape> generateShapes(String text, [int size = 100, int curveSegments = 4,
    String font = 'helvetiker', String weight = 'normal', String style = 'normal']) {
  _size = size;
  _divisions = curveSegments;

  _face = font;
  _weight = weight;
  _style = style;

  // Get a Font data json object

  var data = drawText(text);

  var paths = data['paths'];

  var shapes = [];

  paths.forEach((p) => shapes.addAll(p.toShapes()));

  return shapes;
}

/*
 * This code is a quick port of code written in C++ which was submitted to
 * flipcode.com by John W. Ratcliff  // July 22, 2000
 * See original code and more information here:
 * http://www.flipcode.com/archives/Efficient_Polygon_Triangulation.shtml
 *
 * ported to actionscript by Zevan Rosser
 * www.actionsnippet.com
 *
 * ported to javascript by Joshua Koo
 * http://www.lab4games.net/zz85/blog
 *
 */

var EPSILON = 0.0000000001;

// takes in an contour array and returns
List<List<Vector2>> _process(List<Vector2> contour, bool indices) {
  var n = contour.length;

  if (n < 3) return null;

  var result = [],
      verts = new List(n),
      vertIndices = [];

  /* we want a counter-clockwise polygon in verts */

  if (area(contour) > 0.0) {
    for (var v = 0; v < n; v++) verts[v] = v;
  } else {
    for (var v = 0; v < n; v++) verts[v] = (n - 1) - v;
  }

  var nv = n;

  /*  remove nv - 2 vertices, creating 1 triangle every time */

  var count = 2 * nv;
  /* error detection */

  for (var v = nv - 1; nv > 2;) {
    /* if we loop, it is probably a non-simple polygon */

    if ((count--) <= 0) {

      //** Triangulate: ERROR - probable bad polygon!

      //throw ( 'Warning, unable to triangulate polygon!' );
      //return null;
      // Sometimes warning is fine, especially polygons are triangulated in reverse.
      print('font_utils: Warning, unable to triangulate polygon!');

      if (indices) return vertIndices;
      return result;
    }

    /* three consecutive vertices in current polygon, <u,v,w> */

    var u = v;
    if (nv <= u) u = 0;
    /* previous */
    v = u + 1;
    if (nv <= v) v = 0;
    /* new v    */
    var w = v + 1;
    if (nv <= w) w = 0;
    /* next     */

    if (snip(contour, u, v, w, nv, verts)) {
      /* true names of the vertices */

      var a = verts[u];
      var b = verts[v];
      var c = verts[w];

      /* output Triangle */

      result.add([contour[a], contour[b], contour[c]]);

      vertIndices.addAll([verts[u], verts[v], verts[w]]);

      /* remove v from the remaining polygon */
      var s = v;
      for (var t = v + 1; t < nv; t++) {
        verts[s] = verts[t];
        s++;
      }

      nv--;

      /* reset error detection counter */

      count = 2 * nv;
    }
  }

  if (indices) return vertIndices;
  return result;
}

List<List<Vector2>> triangulate(List<Vector2> contour, bool indices) => _process(contour, indices);

// calculate area of the contour polygon
double area(List contour) {
  var n = contour.length;
  var a = 0.0;

  for (var p = n - 1, q = 0; q < n; p = q++) {
    a += contour[p].x * contour[q].y - contour[q].x * contour[p].y;
  }

  return a * 0.5;
}

bool snip(List<Vector2> contour, int u, int v, int w, int n, List<int> verts) {
  var ax = contour[verts[u]].x;
  var ay = contour[verts[u]].y;

  var bx = contour[verts[v]].x;
  var by = contour[verts[v]].y;

  var cx = contour[verts[w]].x;
  var cy = contour[verts[w]].y;

  if (EPSILON > (((bx - ax) * (cy - ay)) - ((by - ay) * (cx - ax)))) return false;

  var aX, aY, bX, bY, cX, cY;
  var apx, apy, bpx, bpy, cpx, cpy;
  var cCROSSap, bCROSScp, aCROSSbp;

  aX = cx - bx;
  aY = cy - by;
  bX = ax - cx;
  bY = ay - cy;
  cX = bx - ax;
  cY = by - ay;

  for (var p = 0; p < n; p++) {
    var px = contour[verts[p]].x;
    var py = contour[verts[p]].y;

    if (((px == ax) && (py == ay)) ||
        ((px == bx) && (py == by)) ||
        ((px == cx) && (py == cy))) continue;

    apx = px - ax;
    apy = py - ay;
    bpx = px - bx;
    bpy = py - by;
    cpx = px - cx;
    cpy = py - cy;

    // see if p is inside triangle abc

    aCROSSbp = aX * bpy - aY * bpx;
    cCROSSap = cX * apy - cY * apx;
    bCROSScp = bX * cpy - bY * cpx;

    if ((aCROSSbp >= -EPSILON) && (bCROSScp >= -EPSILON) && (cCROSSap >= -EPSILON)) return false;
  }

  return true;
}
