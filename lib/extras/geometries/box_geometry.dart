/*
 * @author mr.doob / http://mrdoob.com/
 *
 * based on r71
 */

part of three;

class BoxGeometry extends Geometry {
  int _widthSegments;
  int _heightSegments;
  int _depthSegments;

  BoxGeometry(double width, double height, double depth, [this._widthSegments = 1,
      this._heightSegments = 1, this._depthSegments = 1])
      : super() {
    var width_half = width / 2;
    var height_half = height / 2;
    var depth_half = depth / 2;

    _buildPlane('z', 'y', -1, -1, depth, height, width_half); // px
    _buildPlane('z', 'y',  1, -1, depth, height, - width_half); // nx
    _buildPlane('x', 'z',  1,  1, width, depth, height_half); // py
    _buildPlane('x', 'z',  1, -1, width, depth, - height_half); // ny
    _buildPlane('x', 'y',  1, -1, width, height, depth_half); // pz
    _buildPlane('x', 'y', -1, -1, width, height, - depth_half); // nz

    mergeVertices();
  }

  void _buildPlane(String u, String v, int udir, int vdir,
                   double width, double height, double depth) {
    var w, ix, iy,
        gridX = _widthSegments,
        gridY = _heightSegments,
        width_half = width / 2,
        height_half = height / 2,
        offset = vertices.length;

    if ((u == 'x' && v == 'y') || (u == 'y' && v == 'x')) {
      w = 'z';
    } else if ((u == 'x' && v == 'z') || (u == 'z' && v == 'x')) {
      w = 'y';
      gridY = _depthSegments;
    } else if ((u == 'z' && v == 'y') || (u == 'y' && v == 'z')) {
      w = 'x';
      gridX = _depthSegments;
    }

    var gridX1 = gridX + 1,
        gridY1 = gridY + 1,
        segment_width = width / gridX,
        segment_height = height / gridY,
        normal = new Vector3.zero();

    var p2i = {'x': 0, 'y': 1, 'z': 2};

    normal[p2i[w]] = depth > 0 ? 1.0 : - 1.0;

    for (iy = 0; iy < gridY1; iy ++) {
      for (ix = 0; ix < gridX1; ix ++) {
        var vector = new Vector3.zero();
        vector[p2i[u]] = (ix * segment_width - width_half) * udir;
        vector[p2i[v]] = (iy * segment_height - height_half) * vdir;
        vector[p2i[w]] = depth;

        vertices.add(vector);
      }
    }

    for (iy = 0; iy < gridY; iy ++) {
      for (ix = 0; ix < gridX; ix ++) {
        var a = ix + gridX1 * iy;
        var b = ix + gridX1 * (iy + 1);
        var c = (ix + 1) + gridX1 * (iy + 1);
        var d = (ix + 1) + gridX1 * iy;

        var uva = new Vector2(ix / gridX, 1 - iy / gridY);
        var uvb = new Vector2(ix / gridX, 1 - (iy + 1) / gridY);
        var uvc = new Vector2((ix + 1) / gridX, 1 - (iy + 1) / gridY);
        var uvd = new Vector2((ix + 1) / gridX, 1 - iy / gridY);

        var face = new Face3(a + offset, b + offset, d + offset);
        face.normal.setFrom(normal);
        face.vertexNormals = [normal.clone(), normal.clone(), normal.clone()];

        faces.add(face);
        faceVertexUvs[0].add([uva, uvb, uvd]);

        face = new Face3(b + offset, c + offset, d + offset);
        face.normal.setFrom(normal);
        face.vertexNormals = [normal.clone(), normal.clone(), normal.clone()];

        faces.add(face);
        faceVertexUvs[0].add([uvb.clone(), uvc, uvd.clone()]);
      }
    }
  }
}