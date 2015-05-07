/*
 * @author mrdoob / http://mrdoob.com/
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 * @author WestLangley / http://github.com/WestLangley
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

abstract class GeometryObject {
  IGeometry geometry;
}

abstract class MaterialObject {
  Material material;
}

abstract class GeometryMaterialObject = Object with GeometryObject, MaterialObject;

/// Base class for scene graph objects.
class Object3D {
  static Vector3 defaultUp = new Vector3(0.0, 1.0, 0.0);

  /// Unique number of this object instance.
  int id = Object3DIdCount++;

  // Unique UUID
  String uuid = ThreeMath.generateUUID();

  /// Optional name of the object (doesn't need to be unique).
  String name = '';

  String type = 'Object3D';

  /// Object's parent in the scene graph.
  Object3D parent;

  /// Array with object's children.
  List<Object3D> children = [];

  /// Up direction.
  Vector3 up = Object3D.defaultUp.clone();

  /// Object's local position.
  Vector3 position = new Vector3.zero();

  /// Object's local rotation as Euler.
  Euler rotation = new Euler();

  /// Object's local rotation as Quaternion.
  Quaternion quaternion = new Quaternion.identity();

  /// Object's local scale.
  Vector3 scale = new Vector3(1.0, 1.0, 1.0);

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
  bool matrixWorldNeedsUpdate = false;

  /// Object gets rendered if true.
  bool visible = true;

  /// Gets rendered into shadow map.
  bool castShadow = false;

  /// Material gets baked in shadow receiving.
  bool receiveShadow = false;

  /// When set, it checks every frame if the object is in the frustum of the camera.
  /// Otherwise the object gets drawn every frame even if it isn't visible.
  bool frustumCulled = true;

  int renderOrder = 0;

  /// An object that can be used to store custom data about the Object3d.
  /// It should not hold references to functions as these will not be cloned.
  Map userData = {};

  Function immediateRenderCallback;

  ShaderMaterial customDepthMaterial;

  // Streams

  StreamController _onObjectAddedController = new StreamController.broadcast();
  Stream get onObjectAdded => _onObjectAddedController.stream;

  StreamController _onObjectRemovedController = new StreamController.broadcast();
  Stream get onObjectRemoved => _onObjectRemovedController.stream;
  StreamSubscription _objectRemovedSubscription;

  StreamController _onAddedToSceneController = new StreamController.broadcast();
  Stream get onAddedToScene => _onAddedToSceneController.stream;

  StreamController _onRemovedFromSceneController = new StreamController.broadcast();
  Stream get onRemovedFromScene => _onRemovedFromSceneController.stream;

  // WebGL

  bool __webglInit = false;
  bool __webglActive = false;

  Matrix4 _modelViewMatrix;
  Matrix3 _normalMatrix;
  int _count;
  bool _hasPositions, _hasNormals, _hasUvs, _hasColors;
  TypedData _positionArray, _normalArray, _uvArray, _colorArray;
  gl.Buffer __webglVertexBuffer, __webglNormalBuffer, __webglUVBuffer, __webglColorBuffer;

  var __webglMorphTargetInfluences;

  var renderDepth;
  var matrixRotationWorld = new Matrix4.identity();

  /// The constructor takes no arguments.
  Object3D() {
    rotation.onChange.listen(_onRotationChange);
    quaternion.onChange.listen(_onQuaternionChange);
  }

  void _onRotationChange(_) {
    quaternion.setFromEuler(rotation, update: false);
  }

  void _onQuaternionChange(_) {
    rotation.setFromQuaternion(quaternion, update: false);
  }

  /// Updates position, rotation and scale with [matrix].
  void applyMatrix(Matrix4 matrix) {
    this.matrix.multiply(matrix);
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
    quaternion.setFromRotation(matrix);
  }

  // assumes q is normalized
  void setRotationFromQuaternion(Quaternion q) {
    quaternion.setFrom(q);
  }

  /// Rotates object around normalized [axis] in object space by [radians].
  Object3D rotateOnAxis(Vector3 axis, double radians) {
    _q.setAxisAngle(axis, radians);
    quaternion.multiply(_q);
    return this;
  }

  /// Rotates object around x axis in object space by [radians].
  Object3D rotateX(double radians) => rotateOnAxis(_v..setValues(1.0, 0.0, 0.0), radians);

  /// Rotates object around y axis in object space by [radians].
  Object3D rotateY(double radians) => rotateOnAxis(_v..setValues(0.0, 1.0, 0.0), radians);

  /// Rotates object around z axis in object space by [radians].
  Object3D rotateZ(double radians) => rotateOnAxis(_v..setValues(0.0, 0.0, 1.0), radians);

  /// Translate an object by [distance] along a normalized [axis] in object space.
  Object3D translateOnAxis(Vector3 axis, double distance) {
    position.add(_v.setFrom(axis)..applyQuaternion(quaternion)..scale(distance));
    return this;
  }

  /// Translates object along x axis by [distance].
  Object3D translateX(double distance) => translateOnAxis(_v..setValues(1.0, 0.0, 0.0), distance);

  /// Translates object along y axis by [distance].
  Object3D translateY(double distance) => translateOnAxis(_v..setValues(0.0, 1.0, 0.0), distance);

  /// Translates object along z axis by [distance].
  Object3D translateZ(double distance) => translateOnAxis(_v..setValues(0.0, 0.0, 1.0), distance);

  /// Transforms [vector] from local space to world space.
  Vector3 localToWorld(Vector3 vector) => vector..applyMatrix4(matrixWorld);

  /// Transforms [vector] from world space to local space.
  Vector3 worldToLocal(Vector3 vector) => vector..applyMatrix4(_m..copyInverse(matrixWorld));

  /// Rotates object to face [position].
  /// This routine does not support objects with rotated and/or translated parent(s
  void lookAt(Vector3 vector) {
    setViewMatrix(_m, vector, position, up);
    _m.invert();
    quaternion.setFromRotation4(_m);
  }

  /// Adds [object] as child of this object.
  Object3D add(Object3D object) {
    if (object == this) {
      print('Object3D.add: An object can\'t be added as a child of itself.');
      return this;
    }

    if (object.parent != null) {
      object.parent.remove(object);
    }

    object.parent = this;
    object._onObjectAddedController.add(null);

    children.add(object);

    return this;
  }

  /// Removes [object] as child of this object.
  void remove(Object3D object) {
    if (children.contains(object)) {
      object.parent = null;
      object._onObjectRemovedController.add(object);

      children.remove(object);
    }
  }

  Object3D getObjectById(int id) => getObjectByProperty('id', id);

  Object3D getObjectByName(String name) => getObjectByProperty('name', name);

  Object3D getObjectByProperty(String name, value) {
    if ((name == 'id' && this.id == value) ||
        (name == 'name' && this.name == value)) {
      return this;
    }

    children.forEach((child) {
      var object = child.getObjectByProperty(name, value);
      if (object != null) return object;
    });

    return null;
  }

  Vector3 getWorldPosition([Vector3 optionalTarget]) {
    var result = optionalTarget != null ? optionalTarget : new Vector3.zero();
    updateMatrixWorld(force: true);
    return result..setFromMatrixTranslation(matrixWorld);
  }

  Quaternion getWorldQuaternion([Quaternion optionalTarget]) {
    var result = optionalTarget != null ? optionalTarget : new Quaternion.identity();
    updateMatrixWorld(force: true);
    matrixWorld.decompose(_v, result, _v);
    return result;
  }

  Euler getWorldRotation([Euler optionalTarget]) {
    var result = optionalTarget != null ? optionalTarget : new Euler();
    getWorldQuaternion(_q);
    return result..setFromQuaternion(_q, order: rotation.order, update: false);
  }

  Vector3 getWorldScale([Vector3 optionalTarget]) {
    var result = optionalTarget != null ? optionalTarget : new Vector3.zero();
    updateMatrixWorld(force: true);
    matrixWorld.decompose(_v, _q, result);
    return result;
  }

  Vector3 getWorldDirection([Vector3 optionalTarget]) {
    var result = optionalTarget != null ? optionalTarget: new Vector3.zero();
    getWorldQuaternion(_q);
    return result..setValues(0.0, 0.0, 1.0)..applyQuaternion(_q);
  }

  void raycast(Raycaster raycaster, List<RayIntersection> intersects) {}

  /// Executes [callback] on this object and all descendants.
  void traverse(void callback(Object3D obj)) {
    callback(this);
    for (var i = 0; i < children.length; i++) {
      children[i].traverse(callback);
    }
  }

  /// Like [traverse], except that [callback] is only executed on visible objects.
  void traverseVisible(void callback(Object3D obj)) {
    if (!visible) return;
    callback(this);
    for (var i = 0; i < children.length; i++) {
      children[i].traverseVisible(callback);
    }
  }

  void traverseAncestors(void callback(Object3D obj)) {
    if (parent != null) {
      callback(parent);
      parent.traverseAncestors(callback);
    }
  }

  /// Updates local transform.
  void updateMatrix() {
    matrix.setFromTranslationRotationScale(position, quaternion, scale);
    matrixWorldNeedsUpdate = true;
  }

  /// Updates global transform of the object and its children.
  void updateMatrixWorld({bool force: false}) {
    if (matrixAutoUpdate) updateMatrix();

    if (matrixWorldNeedsUpdate || force) {
      if (parent == null) {
        matrixWorld.setFrom(matrix);
      } else {
        matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
      }

      matrixWorldNeedsUpdate = false;

      force = true;
    }

    // update children
    for (var i = 0; i < children.length; i++) {
      children[i].updateMatrixWorld(force: force);
    }
  }

  toJSON() {
    throw new UnimplementedError();
  }

  /// Creates a new clone of this object and all descendants.
  Object3D clone([Object3D object, bool recursive = true]) {
    if (object == null) object = new Object3D();

    object
      ..name = name

      ..up.setFrom(up)

      ..position.setFrom(position)
      ..quaternion.setFrom(quaternion)
      ..scale.setFrom(scale)

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

  static final Vector3 _v = new Vector3.zero();
  static final Quaternion _q = new Quaternion.identity();
  static final Matrix4 _m = new Matrix4.zero();
}
