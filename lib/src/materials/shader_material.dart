/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on https://github.com/mrdoob/three.js/blob/59aebeda0837e7ef1e2ad874c4d2dc486b8d3a45/src/materials/ShaderMaterial.js
 */

part of three.materials;

class ShaderMaterial extends Material implements Morphing, Wireframe, LineMaterial {
  static const defaultVertexShader = 'void main() {\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n}';
  static const defaultFragmentShader = 'void main() {\n\tgl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );\n}';

  String type = 'ShaderMaterial';

  Map defines;
  Map<String, Uniform> uniforms;
  List<String> attributes;

  String vertexShader;
  String fragmentShader;

  double linewidth;

  bool wireframe;
  double wireframeLinewidth;

  bool lights; // set to use scene lights

  bool skinning; // set to use skinning attribute streams

  bool morphTargets; // set to use morph targets
  bool morphNormals; // set to use morph normals

  bool derivatives;

  // When rendered geometry doesn't include these attributes but the material does,
  // use these default values in WebGL. This avoids errors when buffer data is missing.
  final Map<String, List<num>> defaultAttributeValues = {
    'color': new Float32List.fromList([1.0, 1.0, 1.0]),
    'uv': new Float32List.fromList([0.0, 0.0]),
    'uv2': new Float32List.fromList([0.0, 0.0])
  };

  String index0AttributeName;

  // Not used
  var wireframeLinecap, wireframeLinejoin, scale, dashSize, gapSize;

  ShaderMaterial({Map defines, Map<String, Uniform> uniforms, List<String> attributes, this.vertexShader: defaultVertexShader,
    this.fragmentShader: defaultFragmentShader, int shading: SmoothShading, this.linewidth: 1.0, this.wireframe: false,
    this.wireframeLinewidth: 1.0, bool fog: true, this.lights: false, int vertexColors: NoColors, this.skinning: false,
    this.morphTargets: false, this.morphNormals: false, this.derivatives: false,
    // Material
    String name: '', int side: FrontSide, double opacity: 1.0, bool transparent: false,
    int blending: NormalBlending, blendSrc: SrcAlphaFactor, blendDst: OneMinusSrcAlphaFactor,
    int blendEquation: AddEquation, blendSrcAlpha, blendDstAlpha, blendEquationAlpha, int depthFunc: LessEqualDepth,
    bool depthTest: true, bool depthWrite: true, bool colorWrite: true, bool polygonOffset: false,
    int polygonOffsetFactor: 0, int polygonOffsetUnits: 0, double alphaTest: 0.0, double overdraw: 0.0,
    bool visible: true})
      : this.attributes =  attributes != null ? attributes : [],
        this.defines = defines != null ? defines : {},
        this.uniforms = uniforms != null ? uniforms : {},
        super._(name: name, side: side, opacity: opacity, transparent: transparent, blending: blending,
          blendSrc: blendSrc, blendDst: blendDst, blendEquation: blendEquation, blendSrcAlpha: blendSrcAlpha,
          blendDstAlpha: blendDstAlpha, blendEquationAlpha: blendEquationAlpha, depthFunc: depthFunc,
          depthTest: depthTest, depthWrite: depthWrite, colorWrite: colorWrite, polygonOffset: polygonOffset,
          polygonOffsetFactor: polygonOffsetFactor, polygonOffsetUnits: polygonOffsetUnits, alphaTest: alphaTest,
          overdraw: overdraw, visible: visible,

          fog: fog, vertexColors: vertexColors, shading: shading);
}
