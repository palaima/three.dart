/*
 * @author zz85 / https://github.com/zz85
 * Parametric Surfaces Geometry based on the brilliant article by @prideout http://prideout.net/blog/?p=44
 *
 * based on r66
 */

part of three.extras.geometries;

class ParametricGeometry extends Geometry {
  ParametricGeometry(Function func, int slices, int stacks) : super() {
    var uvs = faceVertexUvs[0];

    var sliceCount = slices + 1;

    for (var i = 0; i <= stacks; i++) {
      var v = i / stacks;

      for (var j = 0; j <= slices; j++) {
        var u = j / slices;

        var p = func(u, v);
        vertices.add(p);
      }
    }

    for (var i = 0; i < stacks; i ++) {
      for (var j = 0; j < slices; j ++) {
        var a = i * sliceCount + j;
        var b = i * sliceCount + j + 1;
        var c = (i + 1) * sliceCount + j + 1;
        var d = (i + 1) * sliceCount + j;

        var uva = new Vector2(j / slices, i / stacks);
        var uvb = new Vector2((j + 1) / slices, i / stacks);
        var uvc = new Vector2((j + 1) / slices, (i + 1) / stacks);
        var uvd = new Vector2(j / slices, (i + 1) / stacks);

        faces.add(new Face3(a, b, d));
        uvs.add([uva, uvb, uvd]);

        faces.add(new Face3(b, c, d));
        uvs.add([uvb.clone(), uvc, uvd.clone()]);
      }
    }

    computeFaceNormals();
    computeVertexNormals();
    computeCentroids();
  }

  factory ParametricGeometry.klein(int slices, int stacks) {
    var func = (v, u) {
      u *= math.PI;
      v *= 2 * math.PI;

      u = u * 2;
      var x, y, z;
      if (u < math.PI) {
        x = 3 * math.cos(u) * (1 + math.sin(u)) + (2 * (1 - math.cos(u) / 2)) * math.cos(u) * math.cos(v);
        z = -8 * math.sin(u) - 2 * (1 - math.cos(u) / 2) * math.sin(u) * math.cos(v);
      } else {
        x = 3 * math.cos(u) * (1 + math.sin(u)) + (2 * (1 - math.cos(u) / 2)) * math.cos(v + math.PI);
        z = -8 * math.sin(u);
      }

      y = -2 * (1 - math.cos(u) / 2) * math.sin(v);

      return new Vector3(x, y, z);
    };

    return new ParametricGeometry(func, slices, stacks);
  }

  /// Parametric Replacement for PlaneGeometry.
  factory ParametricGeometry.plane(double width, double height, int slices, int stacks) {
    return new ParametricGeometry((u, v) => new Vector3(u * width, 0.0, v * height), slices, stacks);
  }

  factory ParametricGeometry.mobius(int slices, int stacks) {
    var func = (u, t) {
      u = u - 0.5;
      var v = 2 * math.PI * t;

      var x, y, z;

      var a = 2;
      x = math.cos(v) * (a + u * math.cos(v/2));
      y = math.sin(v) * (a + u * math.cos(v/2));
      z = u * math.sin(v/2);
      return new Vector3(x, y, z);
    };

    return new ParametricGeometry(func, slices, stacks);
  }

  factory ParametricGeometry.mobius3d(int slices, int stacks) {
    var func = (u, t) {
      u *= math.PI;
      t *= 2 * math.PI;

      u = u * 2;
      var phi = u / 2;
      var major = 2.25, a = 0.125, b = 0.65;
      var x, y, z;
      x = a * math.cos(t) * math.cos(phi) - b * math.sin(t) * math.sin(phi);
      z = a * math.cos(t) * math.sin(phi) + b * math.sin(t) * math.cos(phi);
      y = (major + x) * math.sin(u);
      x = (major + x) * math.cos(u);
      return new Vector3(x, y, z);
    };

    return new ParametricGeometry(func, slices, stacks);
  }

  /// Parametric Replacement for SphereGeometry
  factory ParametricGeometry.sphere(double size, int u, int v) {
      var sphere = (u, v) {
        u *= math.PI;
        v *= 2 * math.PI;

        var x = size * math.sin(u) * math.cos(v);
        var y = size * math.sin(u) * math.sin(v);
        var z = size * math.cos(u);


        return new Vector3(x, y, z);
      };

      return new ParametricGeometry(sphere, u, v);
  }

  /// Parametric Replacement for TubeGeometry.
  factory ParametricGeometry.tube(path,
                                {int segments: 64,
                                 double radius: 1.0,
                                 int segmentsRadius: 8,
                                 bool closed: false,
                                 bool debug: false}) {
    var frames = new TubeGeometryFrenetFrames(path, segments, closed);

    var func = (u, v) {
      v *= 2 * math.PI;

      var i = (u * segments).floor();

      var pos = path.getPointAt(u);

      var tangent = frames.tangents[i];
      var normal = frames.normals[i];
      var binormal = frames.binormals[i];

      //if (debug) {
      //  debugObject.add(new ArrowHelper(tangent, pos, radius, 0x0000ff));
      //  debugObject.add(new ArrowHelper(normal, pos, radius, 0xff0000));
      //  debugObject.add(new ArrowHelper(binormal, pos, radius, 0x00ff00));
      //}

      var cx = -radius * math.cos(v);
      var cy = radius * math.sin(v);

      var pos2 = pos.clone();
      pos2.x += cx * normal.x + cy * binormal.x;
      pos2.y += cx * normal.y + cy * binormal.y;
      pos2.z += cx * normal.z + cy * binormal.z;

      return pos2.clone();
    };

    return new ParametricGeometry(func, segments, segmentsRadius);
  }

  /// Parametric Replacement for TorusKnotGeometry.
  factory ParametricGeometry.torusKnot({double radius: 200.0,
                                 double tube: 40.0,
                                 int segmentsR: 64,
                                 int segmentsT: 8,
                                 double p: 2.0,
                                 double q: 3.0,
                                 double heightScale: 1.0}) {
    var path = new Curve.create((double t) {
      t *= math.PI * 2;
      var r = 0.5;
      var tx = (1 + r * math.cos(q * t)) * math.cos(p * t),
        ty = (1 + r * math.cos(q * t)) * math.sin(p * t),
        tz = r * math.sin(q * t);

      return new Vector3(tx, ty * heightScale, tz)..scale(radius);
    });

    return new ParametricGeometry.tube(path, segments: segmentsR, radius: tube, segmentsRadius: segmentsT, closed: true);
  }
}