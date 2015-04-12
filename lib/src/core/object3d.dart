/*
 * @author mr.doob / http://mrdoob.com/
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * based on r66
 */

part of three;

abstract class GeometryObject {

}

/// Base class for scene graph objects.
class Object3D {
  /// Unique number of this object instance.
  int id = Object3DCount++;

  // Unique UUID
  //String uuid = MathUtils.generateUUID();

  /// Optional name of the object (doesn't need to be unique).
  String name = '';

  /// Object's parent in the scene graph.
  Object3D parent;

  /// Array with object's children.
  List<Object3D> children = [];

  /// Up direction.
  Vector3 up = new Vector3(0.0, 1.0, 0.0);

  /// Object's local position.
  Vector3 position = new Vector3.zero();

  Euler _rotation = new Euler();
  Quaternion _quaternion = new Quaternion.identity();

  /// Object's local scale.
  Vector3 scale = new Vector3(1.0, 1.0, 1.0);

  /// Override depth-sorting order if non null.
  double renderDepth;

  /// When set, the rotationMatrix gets calculated every frame.
  bool rotationAutoUpdate = true;

  /// Local transform.
  Matrix4 matrix = new Matrix4.identity();

  /// The global transform of the object. If the Object3d has no parent,
  /// then it's identical to the local transform.
  Matrix4 matrixWorld = new Matrix4.identity();

  /// When set, it calculates the matrix of position,
  /// (rotation or quaternion) and scale every frame and also recalculates the matrixWorld property.
  bool matrixAutoUpdate = true;

  /// When this is set, it calculates the matrixWorld in that frame and resets this property to false.
  bool  matrixWorldNeedsUpdate = true;

  /// Object gets rendered if true.
  bool visible = true;

  /// Gets rendered into shadow map.
  bool castShadow = false;

  /// Material gets baked in shadow receiving.
  bool receiveShadow = false;

  /// When set, it checks every frame if the object is in the frustum of the camera.
  /// Otherwise the object gets drawn every frame even if it isn't visible.
  bool frustumCulled = true;

  // TODO : Introduce a mixin for objects with Geometry
  Geometry geometry;

  // TODO : Introduce a mixin for objects with Material
  Material material;

  // WebGL
  bool __webglInit = false;
  bool __webglActive = false;
  var immediateRenderCallback;

  Matrix4 _modelViewMatrix;
  Matrix3 _normalMatrix;

  int count;
  bool hasPositions, hasNormals, hasUvs, hasColors;
  var positionArray, normalArray, uvArray, colorArray;
  gl.Buffer __webglVertexBuffer, __webglNormalBuffer, __webglUVBuffer, __webglColorBuffer;

  var __webglMorphTargetInfluences;

  // TODO remove these
  num boundRadius, boundRadiusScale;
  Matrix4 matrixRotationWorld = new Matrix4.identity();

  StreamController _onObjectAddedController = new StreamController.broadcast();
  Stream get onObjectAdded => _onObjectAddedController.stream;

  StreamController _onObjectRemovedController = new StreamController.broadcast();
  Stream get onObjectRemoved => _onObjectRemovedController.stream;

  StreamController _onAddedToSceneController = new StreamController.broadcast();
  Stream get onAddedToScene => _onAddedToSceneController.stream;

  StreamController _onRemovedFromSceneController = new StreamController.broadcast();
  Stream get onRemovedFromScene => _onRemovedFromSceneController.stream;


  /// An object that can be used to store custom data about the Object3d.
  /// It should not hold references to functions as these will not be cloned.
  Map userData = {};

  ShaderMaterial customDepthMaterial;

  /// The constructor takes no arguments.
  Object3D() {
    // Keep rotation and quaternion in sync.
    _rotation._quaternion = _quaternion;
    _quaternion._euler = _rotation;
  }

  /// Object's local rotation as Euler.
  Euler get rotation => _rotation;
  set rotation(Euler rot) {
    _rotation = rot;
    _rotation._quaternion = _quaternion;
    _quaternion._euler = _rotation;
    _rotation._updateQuaternion();
  }

  /// Object's local rotation as Quaternion.
  Quaternion get quaternion => _quaternion;
  set quaternion(Quaternion q) {
    _quaternion = q;
    _quaternion._euler = _rotation;
    _rotation._quaternion = _quaternion;
    _quaternion._updateEuler();
  }

  /// Updates position, rotation and scale with [matrix].
  void applyMatrix(Matrix4 matrix) {
    this.matrix *= matrix;
    this.matrix.decompose(position, quaternion, scale);
  }

  /// Sets objects rotation with rotation of [radians] around normalized [axis].
  void setRotationFromAxisAngle(Vector3 axis, double radians) {
    quaternion.setAxisAngle(axis, radians);
  }


  /// Sets objects rotation with rotation of [euler].
  void setRotationFromEuler(Euler euler) {
    quaternion.setFromEuler(euler, update: true);
  }

  /// Sets objects rotation with rotation of [matrix].
  void setRotationFromMatrix(Matrix3 matrix) {
    quaternion = new Quaternion.fromRotation(matrix);
  }

  // assumes q is normalized
  void setRotationFromQuaternion(Quaternion q) {
    quaternion.setFrom(q);
  }

  /// Rotates object around normalized [axis] in object space by [radians].
  Object3D rotateOnAxis(Vector3 axis, double radians) {
    quaternion *= new Quaternion.axisAngle(axis, radians);
    return this;
  }

  /// Rotates object around x axis in object space by [radians].
  Object3D rotateX(double radians) => rotateOnAxis(new Vector3(1.0, 0.0, 0.0), radians);

  /// Rotates object around y axis in object space by [radians].
  Object3D rotateY(double radians) => rotateOnAxis(new Vector3(0.0, 1.0, 0.0), radians);

  /// Rotates object around z axis in object space by [radians].
  Object3D rotateZ(double radians) => rotateOnAxis(new Vector3(0.0, 0.0, 1.0), radians);

  /// Translate an object by [distance] along a normalized [axis] in object space.
  Object3D translateOnAxis(Vector3 axis, double distance) {
    position += new Vector3.copy(axis)..applyQuaternion(quaternion)..scale(distance);
    return this;
  }

  /// Translates object along x axis by [distance].
  Object3D translateX(double distance) => translateOnAxis(new Vector3(1.0, 0.0, 0.0), distance);

  /// Translates object along y axis by [distance].
  Object3D translateY(double distance) => translateOnAxis(new Vector3(0.0, 1.0, 0.0), distance);

  /// Translates object along z axis by [distance].
  Object3D translateZ(double distance) => translateOnAxis(new Vector3(0.0, 0.0, 1.0), distance);

  /// Transforms [vector] from local space to world space.
  Vector3 localToWorld(Vector3 vector) => vector..applyMatrix4(matrixWorld);

  /// Transforms [vector] from world space to local space.
  Vector3 worldToLocal(Vector3 vector) => vector..applyMatrix4(matrixWorld.clone()..invert());

  /// Rotates object to face [position].
  /// This routine does not support objects with rotated and/or translated parent(s
  void lookAt(Vector3 vector) {
    var lookAt = makeViewMatrix(vector, position, up)..invert();
    quaternion = new Quaternion.fromRotation(lookAt.getRotation());
  }

  /// Adds [object] as child of this object.
  void add(Object3D object) {
    if (object == this) {
      print('Object3D.add: An object can\'t be added as a child of itself.');
      return;
    }

    if (object is Object3D) {
      if (object.parent != null) {
        object.parent.remove(object);
      }

      object.parent = this;
      object._onObjectAddedController.add(null);

      children.add(object);

      // add to scene
      var scene = this;

      while (scene.parent != null) {
        scene = scene.parent;
      }

      if (scene != null && scene is Scene)  {
        scene.__addObject(object);
      }
    }
  }

  /// Removes [object] as child of this object.
  void remove(Object3D object) {
    if (children.contains(object)) {
      object.parent = null;
      object._onObjectRemovedController.add(null);

      children.remove(object);

      // remove from scene
      var scene = this;

      while (scene.parent != null) {
        scene = scene.parent;
      }

      if (scene != null && scene is Scene) {
        scene.__removeObject(object);
      }
    }
  }

  /// Executes [callback] on this object and all descendants.
  void traverse(void callback(Object3D obj)) {
    callback(this);
    children.forEach((child) => child.traverse(callback));
  }

  /// Searches through the object's children and returns the first with a matching [id],
  /// optionally [recursive].
  Object3D getObjectById(int id, [bool recursive = false]) {
    children.forEach((child) {
      if (child.id == id) return child;

      if (recursive) {
        child = child.getObjectById(id, recursive);
        if (child != null) return child;
      }
    });

    return null;
  }

  /// Searches through the object's children and returns the first with a matching [name],
  /// optionally [recursive].
  Object3D getObjectByName(String name, [bool recursive = false]) {
    children.forEach((child) {
      if (child.name == name) return child;

      if (recursive) {
        child = child.getObjectByName(name, recursive);
        if (child != null) return child;
      }
    });

    return null;
  }

  /// Searches whole subgraph recursively to add all objects in the array.
  List<Object3D> getDescendants([List<Object> array]) {
    if (array == null) array = [];
    array.addAll(children);
    children.forEach((child) => child.getDescendants(array));
    return array;
  }

  void updateMatrix() {
    matrix.setFromTranslationRotationScale(position, quaternion, scale);
    matrixWorldNeedsUpdate = true;
  }

  void updateMatrixWorld({bool force: false}) {
    if (matrixAutoUpdate) updateMatrix();

    if (matrixWorldNeedsUpdate || force) {
      if (parent == null) {
        matrixWorld.setFrom(matrix);
      } else {
        matrixWorld = parent.matrixWorld * matrix;
      }

      matrixWorldNeedsUpdate = false;

      force = true;
    }

    // update children
    children.forEach((child) => child.updateMatrixWorld(force: force));
  }

  Vector3 getWorldPosition() {
    updateMatrixWorld(force: true);
    return matrixWorld.getTranslation();
  }

  Quaternion getWorldQuaternion() {
    var position = new Vector3.zero();
    var scale = new Vector3.zero();
    var result = new Quaternion.identity();

    updateMatrixWorld(force: true);

    matrixWorld.decompose(position, result, scale);

    return result;
  }

  Euler getWorldRotation() =>
      new Euler.fromQuaternion(getWorldQuaternion(), order: rotation.order, update: false);

  Vector3 getWorldScale() {
    var position = new Vector3.zero();
    var quaternion = new Quaternion.identity();
    var result = new Vector3.zero();

    updateMatrixWorld(force: true);

    matrixWorld.decompose(position, quaternion, result);

    return result;
  }

  Vector3 getWorldDirection() => new Vector3(0.0, 0.0, 1.0)..applyQuaternion(getWorldQuaternion());

  /// Creates a new clone of this object and all descendants.
  Object3D clone([Object3D object, bool recursive = true]) {
    if (object == null) object = new Object3D();

    object
      ..name = name

      ..up.setFrom(up)

      ..position.setFrom(position)
      ..quaternion.setFrom(quaternion)
      ..scale.setFrom(scale)

      ..renderDepth = renderDepth

      ..rotationAutoUpdate = rotationAutoUpdate

      ..matrix.setFrom(matrix)
      ..matrixWorld.setFrom(matrixWorld)

      ..matrixAutoUpdate = matrixAutoUpdate
      ..matrixWorldNeedsUpdate = matrixWorldNeedsUpdate

      ..visible = visible

      ..castShadow = castShadow
      ..receiveShadow = receiveShadow

      ..frustumCulled = frustumCulled

      ..userData = new Map.from(userData);

    if (recursive) {
      children.forEach((child) => object.add(child.clone()));
    }

    return object;
  }

  // Quick hack to allow setting new properties (used by the renderer)
  Map __data = {};
  operator [](String key) => __data[key];
  operator []=(String key, value) => __data[key] = value;
}
