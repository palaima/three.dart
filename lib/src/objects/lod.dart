/*
 * @author mikael emtinger / http://gomo.se/
 * @author alteredq / http://alteredqualia.com/
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r71
 */

part of three;

class LOD extends Object3D {
  List<LODObject> objects = [];

  void addLevel(Object3D object, [double distance = 0.0]) {
    distance = distance.abs();

    var l = 0;
    for (; l < objects.length; l++) {
      if (distance < objects[l].distance) break;
    }

    objects.insert(l, new LODObject(distance, object));
    add(object);
  }

  Object3D getObjectForDistance(double distance) {
    var i = 1;
    for (; i < objects.length; i++) {
      if (distance < objects[i].distance) break;
    }

    return objects[i - 1].object;
  }

  raycast(raycaster, intersects) {
    throw new UnimplementedError();
  }

  void update(Camera camera) {
    if (objects.length > 1) {
      var v1 = camera.matrixWorld.getTranslation();
      var v2 = matrixWorld.getTranslation();

      var distance = v1.distanceTo(v2);
      objects[0].object.visible = true;

      var l = 1;
      for (; l < objects.length; l++) {
        if (distance >= objects[l].distance) {
          objects[l - 1].object.visible = false;
          objects[l    ].object.visible = true;
        } else {
          break;
        }
      }

      for(; l < objects.length; l++) {
        objects[l].object.visible = false;
      }
    }
  }

  /// Returns clone of [this].
  LOD clone([LOD object, bool recursive = true]) {
    if (object == null) object = new LOD();

    super.clone(object, recursive);

    for (var i = 0; i < objects.length; i++) {
      var x = objects[i].object.clone();
      x.visible = i == 0;
      object.addLevel(x, objects[i].distance);
    }

    return object;
  }
}

class LODObject {
  double distance;
  Object3D object;

  LODObject(this.distance, this.object);
}
