/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on r71
 */

part of three.materials;

class LineDashedMaterial extends Material implements LineMaterial {
  String type = 'LineDashedMaterial';

  double linewidth;

  double scale;
  double dashSize;
  double gapSize;

  LineDashedMaterial({num color: 0xffffff, this.linewidth: 1.0, this.scale: 1.0, this.dashSize: 3.0,
    this.gapSize: 1.0, int vertexColors: NoColors, bool fog: true,
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
