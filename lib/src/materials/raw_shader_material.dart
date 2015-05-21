/*
 * @author mrdoob / http://mrdoob.com/
 *
 * based on r71
 */

part of three.materials;

class RawShaderMaterial extends ShaderMaterial {
  String type = 'RawShaderMaterial';

  RawShaderMaterial({Map defines, Map<String, Uniform> uniforms, List<String> attributes,
    String vertexShader: ShaderMaterial.defaultVertexShader, String fragmentShader: ShaderMaterial.defaultFragmentShader,
    int shading: SmoothShading, double lineWidth: 1.0, bool wireframe: false, double wireframeLinewidth: 1.0,
    bool fog: true, bool lights: false, int vertexColors: NoColors, bool skinning: false, bool morphTargets: false,
    bool morphNormals: false,
    // Material
    String name: '', int side: FrontSide, double opacity: 1.0, bool transparent: false,
    int blending: NormalBlending, blendSrc: SrcAlphaFactor, blendDst: OneMinusSrcAlphaFactor,
    int blendEquation: AddEquation, blendSrcAlpha, blendDstAlpha, blendEquationAlpha, int depthFunc: LessEqualDepth,
    bool depthTest: true, bool depthWrite: true, bool colorWrite: true, bool polygonOffset: false,
    int polygonOffsetFactor: 0, int polygonOffsetUnits: 0, double alphaTest: 0.0, double overdraw: 0.0,
    bool visible: true})
      : super(defines: defines, uniforms: uniforms, attributes: attributes, vertexShader: vertexShader,
          fragmentShader: fragmentShader, shading: shading, linewidth: lineWidth, wireframe: wireframe,
          wireframeLinewidth: wireframeLinewidth, fog: fog, lights: lights, vertexColors: vertexColors,
          skinning: skinning, morphTargets: morphTargets, morphNormals: morphNormals,

          name: name, side: side, opacity: opacity, transparent: transparent, blending: blending,
          blendSrc: blendSrc, blendDst: blendDst, blendEquation: blendEquation, blendSrcAlpha: blendSrcAlpha,
          blendDstAlpha: blendDstAlpha, blendEquationAlpha: blendEquationAlpha, depthFunc: depthFunc,
          depthTest: depthTest, depthWrite: depthWrite, colorWrite: colorWrite, polygonOffset: polygonOffset,
          polygonOffsetFactor: polygonOffsetFactor, polygonOffsetUnits: polygonOffsetUnits, alphaTest: alphaTest,
          overdraw: overdraw, visible: visible);

  clone() {
    throw new UnimplementedError();
  }
}