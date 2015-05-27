/*
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three.materials;

/// A material for drawing geometries in a simple shaded (flat or wireframe) way.
///
/// The default will render as flat polygons. To draw the mesh as wireframe,
/// simply set the 'wireframe' property to true.
class MeshBasicMaterial extends Material
    implements Mapping, Morphing, Wireframe {
  String type = 'MeshBasicMaterial';

  Texture map;

  Texture aoMap;
  double aoMapIntensity;

  Texture specularMap;

  CubeTexture alphaMap;

  Texture envMap;
  int combine;
  double reflectivity;
  double refractionRatio;

  /// Render geometry as wireframe. Default is false (i.e. render as flat polygons).
  bool wireframe;

  /// Controls wireframe thickness. Default is 1.
  ///
  /// Due to limitations in the ANGLE layer, on Windows platforms linewidth will
  /// always be 1 regardless of the set value.
  double wireframeLinewidth;

  /// Define appearance of line ends.
  ///
  /// Possible values are "butt", "round" and "square". Default is 'round'.
  ///
  /// This setting might not have any effect when used with certain renderers.
  /// For example, it is ignored with the WebGL renderer, but does work with
  /// the Canvas renderer.
  String wireframeLinecap;

  /// Define appearance of line joints.
  ///
  /// Possible values are "round", "bevel" and "miter". Default is 'round'.
  ///
  /// This setting might not have any effect when used with certain renderers.
  /// For example, it is ignored with the WebGL renderer, but does work with
  /// the Canvas renderer.
  String wireframeLinejoin;

  /// Define whether the material uses skinning. Default is false.
  bool skinning;

  /// Define whether the material uses morphTargets. Default is false.
  bool morphTargets;

  // Not used
  var normalMap, bumpMap, bumpScale, normalScale, morphNormals, lightMap;

  MeshBasicMaterial({num color: 0xffffff, this.map, this.aoMap,
      this.aoMapIntensity: 1.0, this.specularMap, this.alphaMap, this.envMap,
      this.combine: MultiplyOperation, this.reflectivity: 1.0,
      this.refractionRatio: 0.98, bool fog: true, int shading: SmoothShading,
      this.wireframe: false, this.wireframeLinewidth: 1.0,
      this.wireframeLinecap: 'round', this.wireframeLinejoin: 'round',
      int vertexColors: NoColors, this.skinning: false,
      this.morphTargets: false,
      // Material
      String name: '', int side: FrontSide, double opacity: 1.0,
      bool transparent: false, int blending: NormalBlending,
      blendSrc: SrcAlphaFactor, blendDst: OneMinusSrcAlphaFactor,
      int blendEquation: AddEquation, blendSrcAlpha, blendDstAlpha,
      blendEquationAlpha, int depthFunc: LessEqualDepth, bool depthTest: true,
      bool depthWrite: true, bool colorWrite: true, bool polygonOffset: false,
      int polygonOffsetFactor: 0, int polygonOffsetUnits: 0,
      double alphaTest: 0.0, double overdraw: 0.0, bool visible: true})
      : super._(
          name: name,
          side: side,
          opacity: opacity,
          transparent: transparent,
          blending: blending,
          blendSrc: blendSrc,
          blendDst: blendDst,
          blendEquation: blendEquation,
          blendSrcAlpha: blendSrcAlpha,
          blendDstAlpha: blendDstAlpha,
          blendEquationAlpha: blendEquationAlpha,
          depthFunc: depthFunc,
          depthTest: depthTest,
          depthWrite: depthWrite,
          colorWrite: colorWrite,
          polygonOffset: polygonOffset,
          polygonOffsetFactor: polygonOffsetFactor,
          polygonOffsetUnits: polygonOffsetUnits,
          alphaTest: alphaTest,
          overdraw: overdraw,
          visible: visible,
          color: color,
          fog: fog,
          vertexColors: vertexColors,
          shading: shading);

  clone() {
    throw new UnimplementedError();
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
