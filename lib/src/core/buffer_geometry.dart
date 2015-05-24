/*
 * @author alteredq / http://alteredqualia.com/
 * @author mrdoob / http://mrdoob.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three.core;

class BufferGeometry implements IGeometry {
  static int maxIndex = 65535;

  int id = GeometryIdCount++;

  String uuid = generateUUID();

  String name = '';
  String type = 'BufferGeometry';

  Map<String, BufferAttribute> attributes = {};

  List<DrawCall> drawcalls = [];
  List<DrawCall> offsets;

  // boundings
  Aabb3 boundingBox;
  Sphere boundingSphere;

  bool hasTangents;

  // for compatibility
  List morphTargets = [];
  List morphNormals = [];

  int maxInstancedCount;

  List morphAttributes = [];

  // default attributes
  BufferAttribute get aPosition => attributes['position'];
  BufferAttribute get aNormal => attributes['normal'];
  BufferAttribute get aIndex => attributes['index'];
  BufferAttribute get aUV => attributes['uv'];
  BufferAttribute get aUV2 => attributes['uv2'];
  BufferAttribute get aTangent => attributes['tangent'];
  BufferAttribute get aColor => attributes['color'];

  BufferGeometry() {
    offsets = drawcalls; // backwards compatibility.
  }

  BufferGeometry.fromGeometry(Geometry geometry, [Material material]) {
    setFromGeometry(geometry, material);
  }

  void addAttribute(String name, BufferAttribute attribute) {
    attributes[name] = attribute;
  }

  BufferAttribute getAttribute(String name) => attributes[name];

  void addDrawCall({int start, int count, int indexOffset: 0}) {
    drawcalls.add(new DrawCall(start: start, count: count, index: indexOffset));
  }

  void applyMatrix(Matrix4 matrix) {
    if (aPosition != null) {
      matrix.applyToVector3Array(aPosition.array);
      aPosition.needsUpdate = true;
    }

    if (aNormal != null) {
      var normalMatrix = matrix.getNormalMatrix();
      normalMatrix.applyToVector3Array(aNormal.array);
      aNormal.needsUpdate = true;
    }

    if (boundingBox != null) {
      computeBoundingBox();
    }

    if (boundingSphere != null) {
      computeBoundingSphere();
    }
  }

  BufferGeometry setFrom(BufferGeometry geometry) {
    var attributes = geometry.attributes;
    var offsets = geometry.offsets;

    for (var name in attributes.keys) {
      var attribute = attributes[name];
      addAttribute(name, attribute.clone());
    }

    for (var i = 0; i < offsets.length; i++) {
      var offset = offsets[i];

      offsets.add(new DrawCall(start: offset.start, index: offset.index, count: offset.count));
    }

    return this;
  }

  Vector3 center() {
    computeBoundingBox();
    var offset = boundingBox.center..negate();
    applyMatrix(new Matrix4.translation(offset));
    return offset;
  }

  void setFromObject(Object3D object) {
    log('BufferGeometry.setFromObject(). Converting $object $this');

    var geometry = (object as GeometryObject).geometry;
    var material = (object as MaterialObject).material;

    if (object is PointCloud || object is Line) {
      var positions = new BufferAttribute.float32(geometry.vertices.length * 3, 3);
      var colors = new BufferAttribute.float32(geometry.colors.length * 3, 3);

      addAttribute('position', positions..copyVector3sArray(geometry.vertices));
      addAttribute('color', colors..copyColorsArray(geometry.colors));
      computeBoundingSphere();
    } else if (object is Mesh) {

      // skinning

      if (object is SkinnedMesh) {
        if (geometry is Geometry) {
          log('BufferGeometry.setFromObject(): Converted Geometry to DynamicGeometry as required for SkinnedMesh. $geometry');
          geometry = new DirectGeometry.fromGeometry(geometry);
        }

        var skinIndices = new BufferAttribute.float32(geometry.skinIndices.length * 4, 4);
        var skinWeights = new BufferAttribute.float32(geometry.skinWeights.length * 4, 4);

        addAttribute('skinIndex', skinIndices..copyVector4sArray(geometry.skinIndices));
        addAttribute('skinWeight', skinWeights..copyVector4sArray(geometry.skinWeights));
      }

      // morphs

      if (object.morphTargetInfluences != null) {
        if (geometry is Geometry) {
          log('BufferGeometry.setFromObject(): Converted Geometry to DynamicGeometry as required for MorphTargets. $geometry');
          geometry = new DirectGeometry.fromGeometry(geometry);
        }

        // positions

        var morphTargets = geometry.morphTargets;

        if (morphTargets.length > 0) {
          for (var i = 0; i < morphTargets.length; i++) {
            var morphTarget = morphTargets[i];

            var attribute = new BufferAttribute.float32(morphTarget.vertices.length * 3, 3);

            morphAttributes.add(attribute..copyVector3sArray(morphTarget.vertices));
          }
        }
      }

      if (geometry is DirectGeometry) {
        fromDynamicGeometry(geometry);
      } else if (geometry is Geometry) {
        setFromGeometry(geometry, material);
      }
    }
  }

  void updateFromObject(Object3D object) {
    var geometry = (object as GeometryObject).geometry as DirectGeometry;

    if (geometry.verticesNeedUpdate) {
      if (aPosition != null) {
        aPosition.copyVector3sArray(geometry.vertices);
        aPosition.needsUpdate = true;
      }

      geometry.verticesNeedUpdate = false;
    }

    if (geometry.colorsNeedUpdate) {
      if (aColor != null) {
        aColor.copyColorsArray(geometry.colors);
        aColor.needsUpdate = true;
      }

      geometry.colorsNeedUpdate = false;
    }
  }

  BufferGeometry setFromGeometry(Geometry geometry, [Material material]) {
    var vertices = geometry.vertices;
    var faces = geometry.faces;
    var faceVertexUvs = geometry.faceVertexUvs;
    var vertexColors = material != null ? material.vertexColors : NoColors;

    var hasFaceVertexUv = faceVertexUvs.length > 0 && faceVertexUvs[0].length > 0;
    var hasFaceVertexUv2 = faceVertexUvs.length > 1 && faceVertexUvs[1].length > 0;

    var colors, uvs, uvs2;

    var positions = new Float32List(faces.length * 3 * 3);
    addAttribute('position', new BufferAttribute(positions, 3));

    var normals = new Float32List(faces.length * 3 * 3);
    addAttribute('normal', new BufferAttribute(normals, 3));

    if (vertexColors != NoColors) {
      colors = new Float32List(faces.length * 3 * 3);
      addAttribute('color', new BufferAttribute(colors, 3));
    }

    if (hasFaceVertexUv) {
      uvs = new Float32List(faces.length * 3 * 2);
      addAttribute('uv', new BufferAttribute(uvs, 2));
    }

    if (hasFaceVertexUv2) {
      uvs2 = new Float32List(faces.length * 3 * 2);
      addAttribute('uv2', new BufferAttribute(uvs2, 2));
    }

    for (var i = 0, i2 = 0, i3 = 0; i < faces.length; i++, i2 += 6, i3 += 9) {
      var face = faces[i];

      var a = vertices[face.a];
      var b = vertices[face.b];
      var c = vertices[face.c];

      positions[i3] = a.x;
      positions[i3 + 1] = a.y;
      positions[i3 + 2] = a.z;

      positions[i3 + 3] = b.x;
      positions[i3 + 4] = b.y;
      positions[i3 + 5] = b.z;

      positions[i3 + 6] = c.x;
      positions[i3 + 7] = c.y;
      positions[i3 + 8] = c.z;

      var vertexNormals = face.vertexNormals;

      if (vertexNormals.length == 3) {
        var na = face.vertexNormals[0];
        var nb = face.vertexNormals[1];
        var nc = face.vertexNormals[2];

        normals[i3] = na.x;
        normals[i3 + 1] = na.y;
        normals[i3 + 2] = na.z;

        normals[i3 + 3] = nb.x;
        normals[i3 + 4] = nb.y;
        normals[i3 + 5] = nb.z;

        normals[i3 + 6] = nc.x;
        normals[i3 + 7] = nc.y;
        normals[i3 + 8] = nc.z;
      } else {
        var n = face.normal;

        normals[i3] = n.x;
        normals[i3 + 1] = n.y;
        normals[i3 + 2] = n.z;

        normals[i3 + 3] = n.x;
        normals[i3 + 4] = n.y;
        normals[i3 + 5] = n.z;

        normals[i3 + 6] = n.x;
        normals[i3 + 7] = n.y;
        normals[i3 + 8] = n.z;
      }

      if (vertexColors == FaceColors) {
        var fc = face.color;

        colors[i3] = fc.r;
        colors[i3 + 1] = fc.g;
        colors[i3 + 2] = fc.b;

        colors[i3 + 3] = fc.r;
        colors[i3 + 4] = fc.g;
        colors[i3 + 5] = fc.b;

        colors[i3 + 6] = fc.r;
        colors[i3 + 7] = fc.g;
        colors[i3 + 8] = fc.b;
      } else if (vertexColors == VertexColors) {
        var vca = face.vertexColors[0];
        var vcb = face.vertexColors[1];
        var vcc = face.vertexColors[2];

        colors[i3] = vca.r;
        colors[i3 + 1] = vca.g;
        colors[i3 + 2] = vca.b;

        colors[i3 + 3] = vcb.r;
        colors[i3 + 4] = vcb.g;
        colors[i3 + 5] = vcb.b;

        colors[i3 + 6] = vcc.r;
        colors[i3 + 7] = vcc.g;
        colors[i3 + 8] = vcc.b;
      }

      if (hasFaceVertexUv) {
        // faces.length > faceVertexUvs[0].length in some cases
        var vertexUvs = i < faceVertexUvs[0].length ? faceVertexUvs[0][i] : null;

        if (vertexUvs != null) {
          var uva = vertexUvs[0];
          var uvb = vertexUvs[1];
          var uvc = vertexUvs[2];

          uvs[i2] = uva.x;
          uvs[i2 + 1] = uva.y;

          uvs[i2 + 2] = uvb.x;
          uvs[i2 + 3] = uvb.y;

          uvs[i2 + 4] = uvc.x;
          uvs[i2 + 5] = uvc.y;
        } else {
          warn('BufferGeometry.fromGeometry(): Undefined vertexUv $i');
        }
      }

      if (hasFaceVertexUv2) {
        var vertexUvs = faceVertexUvs[1][i];

        if (vertexUvs != null) {
          var uva = vertexUvs[0];
          var uvb = vertexUvs[1];
          var uvc = vertexUvs[2];

          uvs2[i2] = uva.x;
          uvs2[i2 + 1] = uva.y;

          uvs2[i2 + 2] = uvb.x;
          uvs2[i2 + 3] = uvb.y;

          uvs2[i2 + 4] = uvc.x;
          uvs2[i2 + 5] = uvc.y;
        } else {
          warn('BufferGeometry.fromGeometry(): Undefined vertexUv2 $i)');
        }
      }
    }

    computeBoundingSphere();
    return this;
  }

  void fromDynamicGeometry(DirectGeometry geometry) {
    addAttribute('index', new BufferAttribute.uint16(geometry.faces.length * 3, 1)
      ..copyFacesArray(geometry.faces));

    addAttribute('position', new BufferAttribute.float32(geometry.vertices.length * 3, 3)
      ..copyVector3sArray(geometry.vertices));

    if (geometry.normals.length > 0) {
      addAttribute('normal', new BufferAttribute.float32(geometry.normals.length * 3, 3)
        ..copyVector3sArray(geometry.normals));
    }

    if (geometry.colors.length > 0) {
      addAttribute('color', new BufferAttribute.float32(geometry.colors.length * 3, 3)
        ..copyColorsArray(geometry.colors));
    }

    if (geometry.uvs.length > 0) {
      addAttribute('uv', new BufferAttribute.float32(geometry.uvs.length * 2, 2)
        ..copyVector2sArray(geometry.uvs));
    }

    computeBoundingSphere();
  }

  static final _box = new Aabb3();
  static final _vector = new Vector3.zero();

  void computeBoundingBox() {
    if (boundingBox == null) {
      boundingBox = new Aabb3();
    }

    var positions = aPosition.array;

    if (positions != null) {
      var bb = boundingBox..makeEmpty();

      for (var i = 0; i < positions.length; i += 3) {
        _vector.copyFromArray(positions, i);
        bb.hullPoint(_vector);
      }
    }

    if (positions == null || positions.length == 0) {
      boundingBox.min.setZero();
      boundingBox.max.setZero();
    }

    if (boundingBox.min.x.isNaN || boundingBox.min.y.isNaN || boundingBox.min.z.isNaN) {
      error(
          'BufferGeometry.computeBoundingBox: Computed min/max have NaN values. The "position" attribute is likely to have NaN values.');
    }
  }

  void computeBoundingSphere() {
    if (boundingSphere == null) {
      boundingSphere = new Sphere();
    }

    var positions = aPosition.array;

    if (positions != null) {
      var center = boundingSphere.center;

      for (var i = 0; i < positions.length; i += 3) {
        _vector.copyFromArray(positions, i);
        _box.hullPoint(_vector);
      }

      _box.copyCenter(center);

      // hoping to find a boundingSphere with a radius smaller than the
      // boundingSphere of the boundingBox:  sqrt(3) smaller in the best case

      var maxRadiusSq = 0;

      for (var i = 0; i < positions.length; i += 3) {
        _vector.copyFromArray(positions, i);
        maxRadiusSq = math.max(maxRadiusSq, center.distanceToSquared(_vector));
      }

      boundingSphere.radius = math.sqrt(maxRadiusSq);

      if (boundingSphere.radius.isNaN) {
        error(
            'BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.');
      }
    }
  }

  computeFaceNormals() {
    // backwards compatibility
  }

  void computeVertexNormals({bool areaWeighted: false}) {
    if (aPosition != null) {
      var positions = aPosition.array;

      if (aNormal == null) {
        addAttribute('normal', new BufferAttribute.float32(positions.length, 3));
      } else {
        // reset existing normals to zero
        aNormal.array.map((_) => 0.0);
      }

      var normals = aNormal.array;

      var pA = new Vector3.zero(),
          pB = new Vector3.zero(),
          pC = new Vector3.zero(),
          cb = new Vector3.zero(),
          ab = new Vector3.zero();

      // indexed elements
      if (aIndex != null) {
        var indices = aIndex.array;

        var offsets = this.offsets.length > 0
            ? this.offsets
            : new DrawCall(start: 0, count: indices.length, index: 0);

        for (var j = 0; j < offsets.length; ++j) {
          var start = offsets[j].start;
          var count = offsets[j].count;
          var index = offsets[j].index;

          for (var i = start; i < start + count; i += 3) {
            var vA = (index + indices[i]) * 3;
            var vB = (index + indices[i + 1]) * 3;
            var vC = (index + indices[i + 2]) * 3;

            pA.copyFromArray(positions, vA);
            pB.copyFromArray(positions, vB);
            pC.copyFromArray(positions, vC);

            cb.subVectors(pC, pB);
            ab.subVectors(pA, pB);
            cb.crossVectors(cb, ab);

            normals[vA] += cb.x;
            normals[vA + 1] += cb.y;
            normals[vA + 2] += cb.z;

            normals[vB] += cb.x;
            normals[vB + 1] += cb.y;
            normals[vB + 2] += cb.z;

            normals[vC] += cb.x;
            normals[vC + 1] += cb.y;
            normals[vC + 2] += cb.z;
          }
        }
      } else {
        // non-indexed elements (unconnected triangle soup)
        for (var i = 0; i < positions.length; i += 9) {
          pA.copyFromArray(positions, i);
          pB.copyFromArray(positions, i + 3);
          pC.copyFromArray(positions, i + 6);

          cb.subVectors(pC, pB);
          ab.subVectors(pA, pB);
          cb.crossVectors(cb, ab);

          normals[i] = cb.x;
          normals[i + 1] = cb.y;
          normals[i + 2] = cb.z;

          normals[i + 3] = cb.x;
          normals[i + 4] = cb.y;
          normals[i + 5] = cb.z;

          normals[i + 6] = cb.x;
          normals[i + 7] = cb.y;
          normals[i + 8] = cb.z;
        }
      }

      normalizeNormals();
      aNormal.needsUpdate = true;
    }
  }

  // TODO optimize
  void computeTangents() {
    // based on http://www.terathon.com/code/tangent.html
    // (per vertex tangents)

    if (aIndex == null || aPosition == null || aNormal == null || aUV == null) {
      warn(
          'BufferGeometry: Missing required attributes (index, position, normal or uv) in BufferGeometry.computeTangents()');
      return;
    }

    var indices = aIndex.array;
    var positions = aPosition.array;
    var normals = aNormal.array;
    var uvs = aUV.array;

    var nVertices = positions.length ~/ 3;

    if (aTangent == null) {
      addAttribute('tangent', new BufferAttribute.float32(4 * nVertices, 4));
    }

    var tangents = aTangent.array;

    var tan1 = [],
        tan2 = [];

    for (var k = 0; k < nVertices; k++) {
      tan1[k] = new Vector3.zero();
      tan2[k] = new Vector3.zero();
    }

    handleTriangle(int a, int b, int c) {
      var vA = new Vector3.array(positions, a * 3);
      var vB = new Vector3.array(positions, b * 3);
      var vC = new Vector3.array(positions, c * 3);

      var uvA = new Vector3.array(uvs, a * 2);
      var uvB = new Vector3.array(uvs, b * 2);
      var uvC = new Vector3.array(uvs, c * 2);

      var x1 = vB.x - vA.x;
      var x2 = vC.x - vA.x;

      var y1 = vB.y - vA.y;
      var y2 = vC.y - vA.y;

      var z1 = vB.z - vA.z;
      var z2 = vC.z - vA.z;

      var s1 = uvB.x - uvA.x;
      var s2 = uvC.x - uvA.x;

      var t1 = uvB.y - uvA.y;
      var t2 = uvC.y - uvA.y;

      var r = 1.0 / (s1 * t2 - s2 * t1);

      var sdir =
          new Vector3((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r);

      var tdir =
          new Vector3((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r);

      tan1[a].add(sdir);
      tan1[b].add(sdir);
      tan1[c].add(sdir);

      tan2[a].add(tdir);
      tan2[b].add(tdir);
      tan2[c].add(tdir);
    }

    if (drawcalls.length == 0) {
      drawcalls.add(new DrawCall(start: 0, count: indices.length, index: 0));
    }

    for (var j = 0; j < drawcalls.length; ++j) {
      var start = drawcalls[j].start;
      var count = drawcalls[j].count;
      var index = drawcalls[j].index;

      for (var i = start; i < start + count; i += 3) {
        var iA = index + indices[i];
        var iB = index + indices[i + 1];
        var iC = index + indices[i + 2];

        handleTriangle(iA, iB, iC);
      }
    }

    handleVertex(int v) {
      var n = new Vector3.array(normals, v * 3);

      var t = tan1[v];

      // Gram-Schmidt orthogonalize
      var tmp = new Vector3.copy(t);
      tmp.sub(n.scale(n.dot(t))).normalize();

      // Calculate handedness
      var tmp2 = n.cross(t);
      var test = tmp2.dot(tan2[v]);
      var w = (test < 0.0) ? -1.0 : 1.0;

      tangents[v * 4] = tmp.x;
      tangents[v * 4 + 1] = tmp.y;
      tangents[v * 4 + 2] = tmp.z;
      tangents[v * 4 + 3] = w;
    }

    for (var j = 0; j < drawcalls.length; ++j) {
      var start = drawcalls[j].start;
      var count = drawcalls[j].count;
      var index = drawcalls[j].index;

      for (var i = start; i < start + count; i += 3) {
        var iA = index + indices[i];
        var iB = index + indices[i + 1];
        var iC = index + indices[i + 2];

        handleVertex(iA);
        handleVertex(iB);
        handleVertex(iC);
      }
    }
  }

  void computeOffsets([int size]) {
    if (size == null) size = BufferGeometry.maxIndex;

    var indices = aIndex.array;
    var vertices = aPosition.array;

    var facesCount = (indices.length / 3);

    var sortedIndices = new Uint16List(indices.length); //16-bit buffers
    var indexPtr = 0;
    var vertexPtr = 0;

    var offsets = [new DrawCall(start: 0, count: 0, index: 0)];
    var offset = offsets[0];

    var newVerticeMaps = 0;
    var faceVertices = new Int32List(6);
    var vertexMap = new Int32List.fromList(new List.filled(vertices.length, -1));
    var revVertexMap = new Int32List.fromList(new List.filled(vertices.length, -1));

    /*
      Traverse every face and reorder vertices in the proper offsets of 65k.
      We can have more than 65k entries in the index buffer per offset, but only reference 65k values.
    */
    for (var findex = 0; findex < facesCount; findex++) {
      newVerticeMaps = 0;

      for (var vo = 0; vo < 3; vo++) {
        var vid = indices[findex * 3 + vo];

        if (vertexMap[vid] == -1) {
          //Unmapped vertice
          faceVertices[vo * 2] = vid;
          faceVertices[vo * 2 + 1] = -1;
          newVerticeMaps++;
        } else if (vertexMap[vid] < offset.index) {
          //Reused vertices from previous block (duplicate)
          faceVertices[vo * 2] = vid;
          faceVertices[vo * 2 + 1] = -1;
        } else {
          //Reused vertice in the current block
          faceVertices[vo * 2] = vid;
          faceVertices[vo * 2 + 1] = vertexMap[vid];
        }
      }

      var faceMax = vertexPtr + newVerticeMaps;

      if (faceMax > (offset.index + size)) {
        var new_offset = new DrawCall(start: indexPtr, count: 0, index: vertexPtr);
        offsets.add(new_offset);
        offset = new_offset;

        //Re-evaluate reused vertices in light of new offset.
        for (var v = 0; v < 6; v += 2) {
          var new_vid = faceVertices[v + 1];
          if (new_vid > -1 && new_vid < offset.index) faceVertices[v + 1] = -1;
        }
      }

      //Reindex the face.
      for (var v = 0; v < 6; v += 2) {
        var vid = faceVertices[v];
        var new_vid = faceVertices[v + 1];

        if (new_vid == -1) new_vid = vertexPtr++;

        vertexMap[vid] = new_vid;
        revVertexMap[new_vid] = vid;
        sortedIndices[indexPtr++] = new_vid - offset.index; //XXX overflows at 16bit
        offset.count++;
      }
    }

    /* Move all attribute values to map to the new computed indices , also expand the vertice stack to match our new vertexPtr. */
    this.reorderBuffers(sortedIndices, revVertexMap, vertexPtr);
    this.offsets = offsets; // TODO: Deprecate
    this.drawcalls = offsets;

    return offsets;
  }

  BufferGeometry merge(BufferGeometry geometry, {int offset: 0, matrix, materialIndexOffset: 0}) {
    var keys = attributes.keys;

    for (var key in keys) {
      if (geometry.attributes[key] == null) continue;

      var attribute1 = attributes[key];
      var attributeArray1 = attribute1.array;

      var attribute2 = geometry.attributes[key];
      var attributeArray2 = attribute2.array;

      var attributeSize = attribute2.itemSize;

      for (var i = 0, j = attributeSize * offset; i < attributeArray2.length; i++, j++) {
        attributeArray1[j] = attributeArray2[i];
      }
    }

    return this;
  }

  void normalizeNormals() {
    for (var i = 0; i < aNormal.array.length; i += 3) {
      var x = aNormal.array[i];
      var y = aNormal.array[i + 1];
      var z = aNormal.array[i + 2];

      var n = 1.0 / math.sqrt(x * x + y * y + z * z);

      aNormal.array[i] *= n;
      aNormal.array[i + 1] *= n;
      aNormal.array[i + 2] *= n;
    }
  }

  /*
    reoderBuffers:
    Reorder attributes based on a new indexBuffer and indexMap.
    indexBuffer - Uint16Array of the new ordered indices.
    indexMap - Int32Array where the position is the new vertex ID and the value the old vertex ID for each vertex.
    vertexCount - Amount of total vertices considered in this reordering (in case you want to grow the vertice stack).
  */
  void reorderBuffers(indexBuffer, Int32List indexMap, int vertexCount) {
    /* Create a copy of all attributes for reordering. */
    var sortedAttributes = {};
    for (var attr in attributes.keys) {
      if (attr == 'index') continue;

      var sourceArray = attributes[attr].array;

      var length = attributes[attr].itemSize * vertexCount;

      if (sourceArray is Float32List) {
        sortedAttributes[attr] = new Float32List(length);
      } else if (sourceArray is Int32List) {
        sortedAttributes[attr] = new Int32List(length);
      }
    }

    /* Move attribute positions based on the new index map */
    for (var new_vid = 0; new_vid < vertexCount; new_vid++) {
      var vid = indexMap[new_vid];
      for (var attr in this.attributes) {
        if (attr == 'index') continue;
        var attrArray = attributes[attr].array;
        var attrSize = attributes[attr].itemSize;
        var sortedAttr = sortedAttributes[attr];
        for (var k = 0; k < attrSize; k++) {
          sortedAttr[new_vid * attrSize + k] = attrArray[vid * attrSize + k];
        }
      }
    }

    /* Carry the new sorted buffers locally */
    aIndex.array = indexBuffer;

    for (var attr in attributes.keys) {
      if (attr == 'index') continue;

      attributes[attr].array = sortedAttributes[attr];
      attributes[attr].numItems = attributes[attr].itemSize * vertexCount;
    }
  }

  BufferGeometry clone() {
    var geometry = new BufferGeometry();

    for (var attr in attributes.keys) {
      var sourceAttr = attributes[attr];
      geometry.attributes[attr] = sourceAttr.clone();
    }

    offsets.forEach((offset) => geometry.offsets
        .add(new DrawCall(start: offset.start, index: offset.index, count: offset.count)));

    return geometry;
  }

  toJSON() {
    throw new UnimplementedError();
  }

  StreamController _onDisposeController = new StreamController.broadcast();
  Stream get onDispose => _onDisposeController.stream;

  void dispose() {
    _onDisposeController.add(this);
  }

  noSuchMethod(Invocation invocation) {
    print("'${invocation.memberName}' not available in BufferGeometry");
  }

  Map _data = {};
  operator [](k) => _data[k];
  operator []=(k, v) => _data[k] = v;
}

class DrawCall {
  int start, count, index, instances;
  DrawCall({this.start, this.count, this.index, this.instances});
}
