/*
 * @author alteredq / http://alteredqualia.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

class ShaderMaterial extends Material implements Morphing, Wireframe {
  static const defaultVertexShader = 'void main() {\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n}';
  static const defaultFragmentShader = 'void main() {\n\tgl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );\n}';

  String type = 'ShaderMaterial';

  Map defines;
  Map<String, Attribute> attributes;

  double lineWidth;

  bool wireframe;
  double wireframeLinewidth;

  bool lights; // set to use scene lights

  bool skinning; // set to use skinning attribute streams

  bool morphTargets; // set to use morph targets
  bool morphNormals; // set to use morph normals

  // When rendered geometry doesn't include these attributes but the material does,
  // use these default values in WebGL. This avoids errors when buffer data is missing.
  final Map<String, List<num>> defaultAttributeValues = {
    'color': [1, 1, 1],
    'uv': [0, 0],
    'uv2': [0, 0]
  };

  String index0AttributeName;

  // Not used
  var wireframeLinecap, wireframeLinejoin;

  ShaderMaterial({Map defines, Map<String, Uniform> uniforms, this.attributes, String vertexShader: defaultVertexShader,
    String fragmentShader: defaultFragmentShader, int shading: SmoothShading, this.lineWidth: 1.0, this.wireframe: false,
    this.wireframeLinewidth: 1.0, bool fog: true, this.lights: false, int vertexColors: NoColors, this.skinning: false,
    this.morphTargets: false, this.morphNormals: false,
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

            fog: fog, vertexColors: vertexColors, shading: shading) {
    this.defines = defines != null ? defines : {};
    this._uniforms = uniforms != null ? uniforms : {};
    this._fragmentShader = fragmentShader;
    this._vertexShader = vertexShader;
  }

  set vertexShader(String value) {
    _vertexShader = value;
    needsUpdate = true;
  }

  set fragmentShader(String value) {
    _fragmentShader = value;
    needsUpdate = true;
  }

  set uniforms(Map<String, Uniform> value) {
    _uniforms = value;
    needsUpdate = true;
  }
}
