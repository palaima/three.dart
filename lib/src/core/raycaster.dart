/*
 * @author mrdoob / http://mrdoob.com/
 * @author bhouston / http://exocortex.com/
 * @author stephomi / http://stephaneginier.com/
 *
 * based on r71
 */

part of three;

class Raycaster {
  Ray ray;

  double near;
  double far;

  double precision = 0.0001;
  double linePrecision = 1.0;

  Raycaster([Vector3 origin, Vector3 direction, this.near = 0.0, this.far = double.INFINITY]) {
    if (origin == null) origin = new Vector3.zero();
    if (direction == null) direction = new Vector3.zero();

    ray = new Ray.originDirection(origin, direction);
  }

  int _descSort(RayIntersection a, RayIntersection b) => (a.distance - b.distance).toInt();

  void _intersectObject(Object3D object, Raycaster raycaster, List<RayIntersection> intersects,
                        bool recursive) {
    object.raycast(raycaster, intersects);

    if (recursive) {
      object.children.forEach((child) => _intersectObject(child, raycaster, intersects, true));
    }
  }

  void setOriginDirection(Vector3 origin, Vector3 direction) {
    // direction is assumed to be normalized (for accurate distance calculations)
    ray.setOriginDirection(origin, direction);
  }

  void setFromCamera(Vector2 coords, Camera camera) {
    var origin = ray.origin;
    var direction = ray.direction;
    if (camera is PerspectiveCamera) {
      origin.setFromMatrixTranslation(camera.matrixWorld);
      direction.setValues(coords.x, coords.y, 0.5);
      direction.unproject(camera);
      direction.sub(origin);
      direction.normalize();
    } else if (camera is OrthographicCamera) {
      origin.setValues(coords.x, coords.y, -1.0);
      origin.unproject(camera);
      direction.setValues(0.0, 0.0, -1.0);
      direction.transformDirection(camera.matrixWorld);
    } else {
      error('Raycaster: Unsupported camera type.');
    }
  }

  List<RayIntersection> intersectObject(Object3D object, {bool recursive: false}) {
    var intersects = [];
    _intersectObject(object, this, intersects, recursive);
    intersects.sort(_descSort);
    return intersects;
  }

  List<RayIntersection> intersectObjects(List<Object3D> objects, {bool recursive: false}) {
    var intersects = [];
    objects.forEach((object) => _intersectObject(object, this, intersects, recursive));
    intersects.sort(_descSort);
    return intersects;
  }
}

class RayIntersection {
  double distance;
  Vector3 point;
  Face3 face;
  int faceIndex;
  Object3D object;
  RayIntersection({this.distance, this.point, this.face, this.faceIndex, this.object});
}

