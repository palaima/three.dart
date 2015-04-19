/*
 * @author mr.doob / http://mrdoob.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

/// A material that maps the normal vectors to RGB colors.
class MeshNormalMaterial extends Material implements Wireframe {
  String type = 'MeshNormalMaterial';

  /// Render geometry as wireframe. Default is false (i.e. render as smooth shaded).
  bool wireframe;

  /// Controls wireframe thickness. Default is 1.
  ///
  /// Due to limitations in the ANGLE layer, on Windows platforms linewidth will
  /// always be 1 regardless of the set value.
  double wireframeLinewidth;

  bool morphTargets;

  // Not used
  var wireframeLinecap, wireframeLinejoin;

  MeshNormalMaterial({this.wireframe: false, this.wireframeLinewidth: 1.0, this.morphTargets: false,
    // Material
    String name: '', int side: FrontSide, double opacity: 1.0, bool transparent: false,
    int blending: NormalBlending, blendSrc: SrcAlphaFactor, blendDst: OneMinusSrcAlphaFactor,
    int blendEquation: AddEquation, blendSrcAlpha, blendDstAlpha, blendEquationAlpha, int depthFunc: LessEqualDepth,
    bool depthTest: true, bool depthWrite: true, bool colorWrite: true, bool polygonOffset: false,
    int polygonOffsetFactor: 0, int polygonOffsetUnits: 0, double alphaTest: 0.0, double overdraw: 0.0,
    bool visible: true})
      : super._(name: name, side: side, opacity: opacity, transparent: transparent, blending: blending,
          blendSrc: blendSrc, blendDst: blendDst, blendEquation: blendEquation, blendSrcAlpha: blendSrcAlpha,
          blendDstAlpha: blendDstAlpha, blendEquationAlpha: blendEquationAlpha, depthFunc: depthFunc,
          depthTest: depthTest, depthWrite: depthWrite, colorWrite: colorWrite, polygonOffset: polygonOffset,
          polygonOffsetFactor: polygonOffsetFactor, polygonOffsetUnits: polygonOffsetUnits, alphaTest: alphaTest,
          overdraw: overdraw, visible: visible);

  clone() {
    throw new UnimplementedError();
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
