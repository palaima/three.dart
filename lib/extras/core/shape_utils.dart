library three.extras.core.shape_utils;

import 'package:three/three.dart' show Vector2;
import 'package:three/extras/font_utils.dart' as font_utils;

List<List<Vector2>> triangulateShape(List<Vector2> contour, List<List<Vector2>> holes) {
  bool point_in_segment_2D_colin(Vector2 inSegPt1, Vector2 inSegPt2, Vector2 inOtherPt) {
    // inOtherPt needs to be colinear to the inSegment
    if (inSegPt1.x != inSegPt2.x) {
      if (inSegPt1.x < inSegPt2.x) {
        return ((inSegPt1.x <= inOtherPt.x) && (inOtherPt.x <= inSegPt2.x));
      } else {
        return ((inSegPt2.x <= inOtherPt.x) && (inOtherPt.x <= inSegPt1.x));
      }
    } else {
      if (inSegPt1.y < inSegPt2.y) {
        return ((inSegPt1.y <= inOtherPt.y) && (inOtherPt.y <= inSegPt2.y));
      } else {
        return ((inSegPt2.y <= inOtherPt.y) && (inOtherPt.y <= inSegPt1.y));
      }
    }
  }

  List<Vector2> intersect_segments_2D(Vector2 inSeg1Pt1, Vector2 inSeg1Pt2, Vector2 inSeg2Pt1,
      Vector2 inSeg2Pt2, bool inExcludeAdjacentSegs) {
    var EPSILON = 0.0000000001;

    var seg1dx = inSeg1Pt2.x - inSeg1Pt1.x,
        seg1dy = inSeg1Pt2.y - inSeg1Pt1.y;
    var seg2dx = inSeg2Pt2.x - inSeg2Pt1.x,
        seg2dy = inSeg2Pt2.y - inSeg2Pt1.y;

    var seg1seg2dx = inSeg1Pt1.x - inSeg2Pt1.x;
    var seg1seg2dy = inSeg1Pt1.y - inSeg2Pt1.y;

    var limit = seg1dy * seg2dx - seg1dx * seg2dy;
    var perpSeg1 = seg1dy * seg1seg2dx - seg1dx * seg1seg2dy;

    if (limit.abs() > EPSILON) {
      // not parallel

      var perpSeg2;
      if (limit > 0) {
        if ((perpSeg1 < 0) || (perpSeg1 > limit)) return [];
        perpSeg2 = seg2dy * seg1seg2dx - seg2dx * seg1seg2dy;
        if ((perpSeg2 < 0) || (perpSeg2 > limit)) return [];
      } else {
        if ((perpSeg1 > 0) || (perpSeg1 < limit)) return [];
        perpSeg2 = seg2dy * seg1seg2dx - seg2dx * seg1seg2dy;
        if ((perpSeg2 > 0) || (perpSeg2 < limit)) return [];
      }

      // i.e. to reduce rounding errors
      // intersection at endpoint of segment#1?
      if (perpSeg2 == 0) {
        if ((inExcludeAdjacentSegs) && ((perpSeg1 == 0) || (perpSeg1 == limit))) return [];
        return [inSeg1Pt1];
      }
      if (perpSeg2 == limit) {
        if ((inExcludeAdjacentSegs) && ((perpSeg1 == 0) || (perpSeg1 == limit))) return [];
        return [inSeg1Pt2];
      }
      // intersection at endpoint of segment#2?
      if (perpSeg1 == 0) return [inSeg2Pt1];
      if (perpSeg1 == limit) return [inSeg2Pt2];

      // return real intersection point
      var factorSeg1 = perpSeg2 / limit;
      return [{'x': inSeg1Pt1.x + factorSeg1 * seg1dx, 'y': inSeg1Pt1.y + factorSeg1 * seg1dy}];
    } else {
      // parallel or colinear
      if ((perpSeg1 != 0) || (seg2dy * seg1seg2dx != seg2dx * seg1seg2dy)) return [];

      // they are collinear or degenerate
      var seg1Pt = ((seg1dx == 0) && (seg1dy == 0)); // segment1 ist just a point?
      var seg2Pt = ((seg2dx == 0) && (seg2dy == 0)); // segment2 ist just a point?
      // both segments are points
      if (seg1Pt && seg2Pt) {
        if ((inSeg1Pt1.x != inSeg2Pt1.x) || (inSeg1Pt1.y != inSeg2Pt1.y)) return [
        ]; // they are distinct  points
        return [inSeg1Pt1]; // they are the same point
      }
      // segment#1  is a single point
      if (seg1Pt) {
        if (!point_in_segment_2D_colin(inSeg2Pt1, inSeg2Pt2, inSeg1Pt1)) return [
        ]; // but not in segment#2
        return [inSeg1Pt1];
      }
      // segment#2  is a single point
      if (seg2Pt) {
        if (!point_in_segment_2D_colin(inSeg1Pt1, inSeg1Pt2, inSeg2Pt1)) return [
        ]; // but not in segment#1
        return [inSeg2Pt1];
      }

      // they are collinear segments, which might overlap
      var seg1min, seg1max, seg1minVal, seg1maxVal;
      var seg2min, seg2max, seg2minVal, seg2maxVal;
      if (seg1dx != 0) {
        // the segments are NOT on a vertical line
        if (inSeg1Pt1.x < inSeg1Pt2.x) {
          seg1min = inSeg1Pt1;
          seg1minVal = inSeg1Pt1.x;
          seg1max = inSeg1Pt2;
          seg1maxVal = inSeg1Pt2.x;
        } else {
          seg1min = inSeg1Pt2;
          seg1minVal = inSeg1Pt2.x;
          seg1max = inSeg1Pt1;
          seg1maxVal = inSeg1Pt1.x;
        }
        if (inSeg2Pt1.x < inSeg2Pt2.x) {
          seg2min = inSeg2Pt1;
          seg2minVal = inSeg2Pt1.x;
          seg2max = inSeg2Pt2;
          seg2maxVal = inSeg2Pt2.x;
        } else {
          seg2min = inSeg2Pt2;
          seg2minVal = inSeg2Pt2.x;
          seg2max = inSeg2Pt1;
          seg2maxVal = inSeg2Pt1.x;
        }
      } else {
        // the segments are on a vertical line
        if (inSeg1Pt1.y < inSeg1Pt2.y) {
          seg1min = inSeg1Pt1;
          seg1minVal = inSeg1Pt1.y;
          seg1max = inSeg1Pt2;
          seg1maxVal = inSeg1Pt2.y;
        } else {
          seg1min = inSeg1Pt2;
          seg1minVal = inSeg1Pt2.y;
          seg1max = inSeg1Pt1;
          seg1maxVal = inSeg1Pt1.y;
        }
        if (inSeg2Pt1.y < inSeg2Pt2.y) {
          seg2min = inSeg2Pt1;
          seg2minVal = inSeg2Pt1.y;
          seg2max = inSeg2Pt2;
          seg2maxVal = inSeg2Pt2.y;
        } else {
          seg2min = inSeg2Pt2;
          seg2minVal = inSeg2Pt2.y;
          seg2max = inSeg2Pt1;
          seg2maxVal = inSeg2Pt1.y;
        }
      }
      if (seg1minVal <= seg2minVal) {
        if (seg1maxVal < seg2minVal) return [];
        if (seg1maxVal == seg2minVal) {
          if (inExcludeAdjacentSegs) return [];
          return [seg2min];
        }
        if (seg1maxVal <= seg2maxVal) return [seg2min, seg1max];
        return [seg2min, seg2max];
      } else {
        if (seg1minVal > seg2maxVal) return [];
        if (seg1minVal == seg2maxVal) {
          if (inExcludeAdjacentSegs) return [];
          return [seg1min];
        }
        if (seg1maxVal <= seg2maxVal) return [seg1min, seg1max];
        return [seg1min, seg2max];
      }
    }
  }

  bool isPointInsideAngle(
      Vector2 inVertex, Vector2 inLegFromPt, Vector2 inLegToPt, Vector2 inOtherPt) {
    // The order of legs is important

    var EPSILON = 0.0000000001;

    // translation of all points, so that Vertex is at (0,0)
    var legFromPtX = inLegFromPt.x - inVertex.x,
        legFromPtY = inLegFromPt.y - inVertex.y;
    var legToPtX = inLegToPt.x - inVertex.x,
        legToPtY = inLegToPt.y - inVertex.y;
    var otherPtX = inOtherPt.x - inVertex.x,
        otherPtY = inOtherPt.y - inVertex.y;

    // main angle >0: < 180 deg.; 0: 180 deg.; <0: > 180 deg.
    var from2toAngle = legFromPtX * legToPtY - legFromPtY * legToPtX;
    var from2otherAngle = legFromPtX * otherPtY - legFromPtY * otherPtX;

    if (from2toAngle.abs() > EPSILON) {
      // angle != 180 deg.

      var other2toAngle = otherPtX * legToPtY - otherPtY * legToPtX;
      // console.log( 'from2to: ' + from2toAngle + ', from2other: ' + from2otherAngle + ', other2to: ' + other2toAngle );

      if (from2toAngle > 0) {
        // main angle < 180 deg.
        return ((from2otherAngle >= 0) && (other2toAngle >= 0));
      } else {
        // main angle > 180 deg.
        return ((from2otherAngle >= 0) || (other2toAngle >= 0));
      }
    } else {
      // angle == 180 deg.
      // console.log( 'from2to: 180 deg., from2other: ' + from2otherAngle  );
      return (from2otherAngle > 0);
    }
  }

  List<Vector2> removeHoles(List<Vector2> contour, List<List<Vector2>> holes) {
    List<Vector2> shape = contour.toList(); // work on this shape
    List<Vector2> hole;

    bool isCutLineInsideAngles(int inShapeIdx, int inHoleIdx) {
      // Check if hole point lies within angle around shape point
      var lastShapeIdx = shape.length - 1;

      var prevShapeIdx = inShapeIdx - 1;
      if (prevShapeIdx < 0) prevShapeIdx = lastShapeIdx;

      var nextShapeIdx = inShapeIdx + 1;
      if (nextShapeIdx > lastShapeIdx) nextShapeIdx = 0;

      var insideAngle = isPointInsideAngle(
          shape[inShapeIdx], shape[prevShapeIdx], shape[nextShapeIdx], hole[inHoleIdx]);
      if (!insideAngle) {
        // console.log( 'Vertex (Shape): ' + inShapeIdx + ', Point: ' + hole[inHoleIdx].x + '/' + hole[inHoleIdx].y );
        return false;
      }

      // Check if shape point lies within angle around hole point
      var lastHoleIdx = hole.length - 1;

      var prevHoleIdx = inHoleIdx - 1;
      if (prevHoleIdx < 0) prevHoleIdx = lastHoleIdx;

      var nextHoleIdx = inHoleIdx + 1;
      if (nextHoleIdx > lastHoleIdx) nextHoleIdx = 0;

      insideAngle = isPointInsideAngle(
          hole[inHoleIdx], hole[prevHoleIdx], hole[nextHoleIdx], shape[inShapeIdx]);
      if (!insideAngle) {
        // console.log( 'Vertex (Hole): ' + inHoleIdx + ', Point: ' + shape[inShapeIdx].x + '/' + shape[inShapeIdx].y );
        return false;
      }

      return true;
    }

    bool intersectsShapeEdge(Vector2 inShapePt, Vector2 inHolePt) {
      // checks for intersections with shape edges
      var sIdx, nextIdx, intersection;
      for (sIdx = 0; sIdx < shape.length; sIdx++) {
        nextIdx = sIdx + 1;
        nextIdx %= shape.length;
        intersection =
            intersect_segments_2D(inShapePt, inHolePt, shape[sIdx], shape[nextIdx], true);
        if (intersection.length > 0) return true;
      }

      return false;
    }

    var indepHoles = [];

    bool intersectsHoleEdge(Vector2 inShapePt, Vector2 inHolePt) {
      // checks for intersections with hole edges
      var ihIdx, chkHole, hIdx, nextIdx, intersection;
      for (ihIdx = 0; ihIdx < indepHoles.length; ihIdx++) {
        chkHole = holes[indepHoles[ihIdx]];
        for (hIdx = 0; hIdx < chkHole.length; hIdx++) {
          nextIdx = hIdx + 1;
          nextIdx %= chkHole.length;
          intersection =
              intersect_segments_2D(inShapePt, inHolePt, chkHole[hIdx], chkHole[nextIdx], true);
          if (intersection.length > 0) return true;
        }
      }
      return false;
    }

    var failedCuts = {};

    for (var h = 0, hl = holes.length; h < hl; h++) {
      indepHoles.add(h);
    }

    var minShapeIndex = 0;
    var counter = indepHoles.length * 2;
    while (indepHoles.length > 0) {
      counter--;
      if (counter < 0) {
        print('Infinite Loop! Holes left: ${indepHoles.length}, Probably Hole outside Shape!');
        break;
      }

      // search for shape-vertex and hole-vertex,
      // which can be connected without intersections
      for (var shapeIndex = minShapeIndex; shapeIndex < shape.length; shapeIndex++) {
        var shapePt = shape[shapeIndex];
        var holeIndex = -1;

        // search for hole which can be reached without intersections
        for (var h = 0; h < indepHoles.length; h++) {
          var holeIdx = indepHoles[h];

          // prevent multiple checks
          var cutKey = '${shapePt.x}:${shapePt.y}:${holeIdx}';
          if (failedCuts[cutKey] != null) continue;

          hole = holes[holeIdx];
          for (var h2 = 0; h2 < hole.length; h2++) {
            var holePt = hole[h2];
            if (!isCutLineInsideAngles(shapeIndex, h2)) continue;
            if (intersectsShapeEdge(shapePt, holePt)) continue;
            if (intersectsHoleEdge(shapePt, holePt)) continue;

            holeIndex = h2;
            indepHoles.removeAt(h);

            var tmpShape1 = shape.sublist(0, shapeIndex + 1);
            var tmpShape2 = shape.sublist(shapeIndex);
            var tmpHole1 = hole.sublist(holeIndex);
            var tmpHole2 = hole.sublist(0, holeIndex + 1);

            shape = tmpShape1
              ..addAll(tmpHole1)
              ..addAll(tmpHole2)
              ..addAll(tmpShape2);

            minShapeIndex = shapeIndex;
            break;
          }
          if (holeIndex >= 0) break; // hole-vertex found

          failedCuts[cutKey] = true; // remember failure
        }
        if (holeIndex >= 0) break; // hole-vertex found
      }
    }

    return shape; /* shape with no holes */
  }

  var allPointsMap = {};

  // To maintain reference to old shape, one must match coordinates, or offset the indices from original arrays. It's probably easier to do the first.

  var allpoints = contour.toList();

  for (var h = 0, hl = holes.length; h < hl; h++) {
    allpoints.addAll(holes[h]);
  }

  // prepare all points map

  for (var i = 0; i < allpoints.length; i++) {
    var key = '${allpoints[i].x}:${allpoints[i].y}';

    if (allPointsMap[key] != null) {
      print('Shape: Duplicate point $key');
    }

    allPointsMap[key] = i;
  }

  // remove holes by cutting paths to holes and adding them to the shape
  var shapeWithoutHoles = removeHoles(contour, holes);

  var triangles = font_utils.triangulate(
      shapeWithoutHoles, false); // True returns indices for points of spooled shape

  // check all face vertices against all points map

  for (var i = 0; i < triangles.length; i++) {
    var face = triangles[i];

    for (var f = 0; f < 3; f++) {
      var key = '${face[f].x}:${face[f].y}';

      var index = allPointsMap[key];

      if (index != null) {
        face[f] = index;
      }
    }
  }

  return triangles.toList();
}

bool isClockWise(pts) => font_utils.area(pts) < 0;

// Bezier Curves formulas obtained from
// http://en.wikipedia.org/wiki/B%C3%A9zier_curve

// Quad Bezier Functions

num b2p0(num t, num p) {
  var k = 1 - t;
  return k * k * p;
}

num b2p1(num t, num p) => 2 * (1 - t) * t * p;

num b2p2(num t, num p) => t * t * p;

num b2(num t, num p0, num p1, num p2) => b2p0(t, p0) + b2p1(t, p1) + b2p2(t, p2);

// Cubic Bezier Functions

num b3p0(num t, num p) {
  var k = 1 - t;
  return k * k * k * p;
}

num b3p1(num t, num p) {
  var k = 1 - t;
  return 3 * k * k * t * p;
}

num b3p2(num t, num p) {
  var k = 1 - t;
  return 3 * k * t * t * p;
}

num b3p3(num t, num p) => t * t * t * p;

num b3(num t, num p0, num p1, num p2, num p3) =>
    b3p0(t, p0) + b3p1(t, p1) + b3p2(t, p2) + b3p3(t, p3);
