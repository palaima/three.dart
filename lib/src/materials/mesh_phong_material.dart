/*
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

/// A material for shiny surfaces, evaluated per pixel.
class MeshPhongMaterial extends Material implements Lighting, Mapping, Morphing {
  /// Emissive (light) color of the material, essentially a solid color
  /// unaffected by other lighting. Default is black.
  Color emissive;

  /// Specular color of the material, i.e., how shiny the material is and the
  /// color of its shine.
  ///
  /// Setting this the same color as the diffuse value (times some intensity)
  /// makes the material more metallic-looking; setting this to some gray makes
  /// the material look more plastic. Default is dark gray.
  Color specular;

  /// How shiny the specular highlight is; a higher value gives a sharper highlight. Default is 30.
  double shininess;

  bool metal;

  Texture map;

  Texture lightMap;
  double lightMapIntensity;

  Texture aoMap;
  double aoMapIntensity;

  Texture bumpMap;
  double bumpScale;

  Texture normalMap;
  Vector2 normalScale;

  Texture specularMap;

  Texture alphaMap;

  CubeTexture envMap;
  int combine;
  double reflectivity;
  double refractionRatio;

  /// Whether the triangles' edges are displayed instead of surfaces. Default is false.
  bool wireframe;

  /// Line thickness for wireframe mode. Default is 1.0.
  ///
  /// Due to limitations in the ANGLE layer, on Windows platforms linewidth will
  /// always be 1 regardless of the set value.
  double wireframeLinewidth;

  /// Define appearance of line ends.
  ///
  /// Possible values are "butt", "round" and "square". Default is 'round'.
  ///
  /// This setting might not have any effect when used with certain renderers.
  /// For example, it is ignored with the WebGL renderer, but does work with the
  /// Canvas renderer.
  String wireframeLinecap;

  /// Define appearance of line joints.
  ///
  /// Possible values are "round", "bevel" and "miter". Default is 'round'.
  ///
  /// This setting might not have any effect when used with certain renderers.
  /// For example, it is ignored with the WebGL renderer, but does work with the
  /// Canvas renderer.
  String wireframeLinejoin;

  /// Define whether the material uses skinning. Default is false.
  bool skinning;

  /// Define whether the material uses morphTargets. Default is false.
  bool morphTargets;
  bool morphNormals;

  MeshPhongMaterial({num color: 0xffffff, num emissive: 0x000000, num specular: 0x111111, this.shininess: 30.0,
    this.metal: false, this.map, this.lightMap, this.lightMapIntensity: 1.0, this.aoMap, this.aoMapIntensity: 1.0,
    this.bumpMap, this.bumpScale: 1.0, this.normalMap, Vector2 normalScale, this.specularMap, this.alphaMap,
    this.envMap, this.combine: MultiplyOperation, this.reflectivity: 1.0, this.refractionRatio: 0.98, bool fog: true,
    int shading: SmoothShading, this.wireframe: false, this.wireframeLinewidth: 1.0, this.wireframeLinecap: 'round',
    this.wireframeLinejoin: 'round', int vertexColors: NoColors, this.skinning: false, this.morphTargets: false,
    this.morphNormals: false,
    // Material
    String name: '', int side: FrontSide, double opacity: 1.0, bool transparent: false,
    int blending: NormalBlending, blendSrc: SrcAlphaFactor, blendDst: OneMinusSrcAlphaFactor,
    int blendEquation: AddEquation, blendSrcAlpha, blendDstAlpha, blendEquationAlpha, int depthFunc: LessEqualDepth,
    bool depthTest: true, bool depthWrite: true, bool colorWrite: true, bool polygonOffset: false,
    int polygonOffsetFactor: 0, int polygonOffsetUnits: 0, double alphaTest: 0.0, double overdraw: 0.0,
    bool visible: true})
      : this.emissive = new Color(emissive),
        this.specular = new Color(specular),
        this.normalScale = normalScale != null ? normalScale : new Vector2(1.0, 1.0),
        super._(name: name, side: side, opacity: opacity, transparent: transparent, blending: blending,
                blendSrc: blendSrc, blendDst: blendDst, blendEquation: blendEquation, blendSrcAlpha: blendSrcAlpha,
                blendDstAlpha: blendDstAlpha, blendEquationAlpha: blendEquationAlpha, depthFunc: depthFunc,
                depthTest: depthTest, depthWrite: depthWrite, colorWrite: colorWrite, polygonOffset: polygonOffset,
                polygonOffsetFactor: polygonOffsetFactor, polygonOffsetUnits: polygonOffsetUnits, alphaTest: alphaTest,
                overdraw: overdraw, visible: visible,

                color: color, fog: fog, vertexColors: vertexColors, shading: shading);
  clone() {
    throw new UnimplementedError();
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
