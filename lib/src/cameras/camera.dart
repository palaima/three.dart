/*
 * @author mr.doob / http://mrdoob.com/
 * @author mikael emtinger / http://gomo.se
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 * 
 * based on r66
 */

part of three;

class Camera extends Object3D {
  Matrix4 matrixWorldInverse = new Matrix4.identity();
  Matrix4 projectionMatrix = new Matrix4.identity();
  
  double near;
  double far;
  
  Camera(this.near, this.far) : super();
  
  void lookAt(Vector3 vector) {
    quaternion = new Quaternion.fromRotation(new Matrix4.identity().lookAt(position, vector, up).getRotation());
  }
  
  Camera clone([Camera camera, bool recursive = true]) {
    if (camera == null) camera = new Camera(near, far);
    
    super.clone(camera, recursive);
    
    camera.matrixWorldInverse.setFrom(matrixWorldInverse);
    camera.projectionMatrix.setFrom(projectionMatrix);
    
    return camera;
  }
}
