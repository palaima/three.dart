/*
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

/// A material for drawing wireframe-style geometries.
class LineBasicMaterial extends Material implements LineMaterial {
  String type = 'LineBasicMaterial';

  /// Controls line thickness. Default is 1.
  ///
  /// Due to limitations in the ANGLE layer, on Windows platforms linewidth
  /// will always be 1 regardless of the set value.
  double linewidth;

  /// Define appearance of line ends.
  ///
  /// Possible values are "butt", "round" and "square". Default is 'round'.
  ///
  /// This setting might not have any effect when used with certain renderers.
  /// For example, it is ignored with the WebGL renderer, but does work with
  /// the Canvas renderer.
  String linecap;

  /// Define appearance of line joints.
  ///
  /// Possible values are "round", "bevel" and "miter". Default is 'round'.
  ///
  /// This setting might not have any effect when used with certain renderers.
  /// For example, it is ignored with the WebGL renderer, but does work with
  /// the Canvas renderer.
  String linejoin;

  // Not used
  var scale, dashSize, gapSize;

  LineBasicMaterial({num color: 0xffffff, this.linewidth: 1.0, this.linecap: 'round',
    this.linejoin: 'round', int vertexColors: NoColors, bool fog: true,
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
          overdraw: overdraw, visible: visible,

          color: color, fog: fog, vertexColors: vertexColors);

  clone() {
    throw new UnimplementedError();
  }
}
