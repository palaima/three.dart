part of three.objects;

/**
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

class Particle extends Object3D implements MaterialObject {
  Material material;
  Particle(Material material) : super() {
    this.material = material;
  }
}
