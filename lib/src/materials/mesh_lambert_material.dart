/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

/// A material for non-shiny (Lambertian) surfaces, evaluated per vertex.
class MeshLambertMaterial extends Material implements Lighting, TextureMapping, EnvironmentMapping, Skinning, Morphing,
    Wireframe {
  String type = 'MeshLambertMaterial';

  /// Emissive (light) color of the material, essentially a solid color unaffected by other lighting. Default is black.
  Color emissive;

  Texture map;

  Texture specularMap;

  Texture alphaMap;

  CubeTexture envMap;
  int combine;
  double reflectivity;
  double refractionRatio;

  /// How the triangles of a curved surface are rendered: as a smooth surface,
  /// as flat separate facets, or no shading at all.
  ///
  /// Options are SmoothShading (default), FlatShading, NoShading.
  int shading;

  /// Whether the triangles' edges are displayed instead of surfaces. Default is false.
  bool wireframe;

  /// Line thickness for wireframe mode. Default is 1.0.
  ///
  /// Due to limitations in the ANGLE layer, on Windows platforms linewidth
  /// will always be 1 regardless of the set value.
  double wireframeLinewidth;

  /// Define appearance of line ends.
  ///
  /// Possible values are "butt", "round" and "square". Default is 'round'.
  ///
  /// This setting might not have any effect when used with certain renderers.
  /// For example, it is ignored with the WebGL renderer, but does work with the Canvas renderer.
  String wireframeLinecap;

  /// Define appearance of line joints.
  ///
  /// Possible values are "round", "bevel" and "miter". Default is 'round'.
  ///
  /// This setting might not have any effect when used with certain renderers.
  /// For example, it is ignored with the WebGL renderer, but does work with the Canvas renderer.
  String wireframeLinejoin;

  /// Define whether the material uses skinning. Default is false.
  bool skinning;

  /// Define whether the material uses morphTargets. Default is false.
  bool morphTargets;
  bool morphNormals;

  // Used in renderer.
  int numSupportedMorphTargets = 0,
      numSupportedMorphNormals = 0;

  @Deprecated('')
  Color ambient;
  @Deprecated('')
  Color specular;
  @Deprecated('')
  bool wrapAround = false;
  @Deprecated('')
  Vector3 wrapRGB = new Vector3(1.0, 1.0, 1.0);
  @Deprecated('')
  Texture lightMap;

  Color color;

  MeshLambertMaterial({num color: 0xffffff, num emissive: 0x000000, this.map, this.specularMap, this.alphaMap,
    this.envMap, this.combine: MultiplyOperation, this.reflectivity: 1.0, this.refractionRatio: 0.98, bool fog: true,
    this.shading: SmoothShading, this.wireframe: false, this.wireframeLinewidth: 1.0, this.wireframeLinecap: 'round',
    this.wireframeLinejoin: 'round', int vertexColors: NoColors, this.skinning: false, this.morphTargets: false,
    this.morphNormals: false, ambient: 0xffffff, this.lightMap,
    // Material
    String name: '', int side: FrontSide, double opacity: 1.0, bool transparent: false,
    int blending: NormalBlending, blendSrc: SrcAlphaFactor, blendDst: OneMinusSrcAlphaFactor,
    int blendEquation: AddEquation, blendSrcAlpha, blendDstAlpha, blendEquationAlpha, int depthFunc: LessEqualDepth,
    bool depthTest: true, bool depthWrite: true, bool colorWrite: true, bool polygonOffset: false,
    int polygonOffsetFactor: 0, int polygonOffsetUnits: 0, double alphaTest: 0.0, double overdraw: 0.0,
    bool visible: true})
      : this.color = new Color(color),
          this.ambient = new Color(ambient),
          this.emissive = new Color(emissive),
        super._(name: name, side: side, opacity: opacity, transparent: transparent, blending: blending,
          blendSrc: blendSrc, blendDst: blendDst, blendEquation: blendEquation, blendSrcAlpha: blendSrcAlpha,
          blendDstAlpha: blendDstAlpha, blendEquationAlpha: blendEquationAlpha, depthFunc: depthFunc,
          depthTest: depthTest, depthWrite: depthWrite, colorWrite: colorWrite, polygonOffset: polygonOffset,
          polygonOffsetFactor: polygonOffsetFactor, polygonOffsetUnits: polygonOffsetUnits, alphaTest: alphaTest,
          overdraw: overdraw, visible: visible,

          color: color, fog: fog, vertexColors: vertexColors);

  clone() {
    throw new UnimplementedError();
  }

  toJSON() {
    throw new UnimplementedError();
  }
}
