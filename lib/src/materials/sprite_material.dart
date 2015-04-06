/*
 * @author alteredq / http://alteredqualia.com/
 *
 * parameters = {
 *  color: <hex>,
 *  opacity: <float>,
 *  map: new THREE.Texture( <Image> ),
 *
 *  blending: THREE.NormalBlending,
 *  depthTest: <bool>,
 *  depthWrite: <bool>,
 *
 *  uvOffset: new THREE.Vector2(),
 *  uvScale: new THREE.Vector2(),
 *
 *  fog: <bool>
 * }
 * 
 * based on r66
 */

part of three;

class SpriteMaterial extends Material {
  Color color;
  
  Texture map;
  
  double rotation;
  
  bool fog;
  
  SpriteMaterial({int color: 0xffffff, this.map, this.rotation: 0.0, this.fog: false, Vector2 uvOffset, Vector2 uvScale,  
    // Material
    String name: '', int side: FrontSide, double opacity: 1.0, bool transparent: false, int blending: NormalBlending, int blendSrc: SrcAlphaFactor,
    int blendDst: OneMinusSrcAlphaFactor, int blendEquation: AddEquation, bool depthTest: true, bool depthWrite: true, bool polygonOffset: false,
    int polygonOffsetFactor: 0, int polygonOffsetUnits: 0, int alphaTest: 0, bool overdraw: false, visible: true})
      : super(name: name, side: side, opacity: opacity, transparent: transparent, blending: blending, blendSrc: blendSrc, blendDst: blendDst, 
          blendEquation: blendEquation, depthTest: depthTest, depthWrite: depthWrite, polygonOffset: polygonOffset, 
          polygonOffsetFactor: polygonOffsetFactor, polygonOffsetUnits: polygonOffsetUnits, alphaTest: alphaTest, overdraw: overdraw, visible: visible);
  
  // TODO implement clone
  clone() {
    throw new UnimplementedError();
  }
}