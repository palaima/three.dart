/*
 * @author mrdoob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 *
 * based on a5cc2899aafab2461c52e4b63498fb284d0c167b
 */

part of three;

/// Materials describe the appearance of objects.
///
/// They are defined in a (mostly) renderer-independent way, so you don't have
/// to rewrite materials if you decide to use a different renderer.
class Material extends Object with DisposeStream {
  /// Unique number for this material instance.
  int id = MaterialIdCount++;

  String uuid = generateUUID();

  /// Material name. Default is an empty string.
  String name = '';

  String type = 'Material';

  /// Defines which of the face sides will be rendered - front, back or both.
  ///
  /// Default is THREE.FrontSide. Other options are THREE.BackSide and THREE.DoubleSide.
  int side;

  /// Float in the range of 0.0 - 1.0 indicating how transparent the material is.
  ///
  /// A value of 0.0 indicates fully transparent, 1.0 is fully opaque.
  /// If transparent is not set to true for the material, the material will
  /// remain fully opaque and this value will only affect its color.
  double opacity;

  bool transparent;

  /// Which blending to use when displaying objects with this material. Default is NormalBlending.
  int blending;

  /// Blending source.
  ///
  /// It's one of the blending mode constants defined in three.dart.
  /// Default is SrcAlphaFactor.
  int blendSrc;

  /// Blending destination.
  ///
  /// It's one of the blending mode constants defined in three.dart.
  /// Default is OneMinusSrcAlphaFactor.
  int blendDst;

  /// Blending equation to use when applying blending.
  ///
  /// It's one of the constants defined in three.dart. Default is AddEquation.
  int blendEquation;

  int blendSrcAlpha;
  int blendDstAlpha;
  int blendEquationAlpha;

  int depthFunc = LessEqualDepth;

  // Whether to have depth test enabled when rendering this material. Default is true.
  bool depthTest = true;

  /// Whether rendering this material has any effect on the depth buffer. Default is true.
  ///
  /// When drawing 2D overlays it can be useful to disable the depth writing in
  /// order to layer several things together without creating z-index artifacts.
  bool depthWrite = true;

  bool colorWrite = true;

  /// Whether to use polygon offset. Default is false.
  ///
  /// This corresponds to the POLYGON_OFFSET_FILL WebGL feature.
  bool polygonOffset;

  /// Sets the polygon offset factor. Default is 0.
  int polygonOffsetFactor;

  /// Sets the polygon offset units. Default is 0.
  int polygonOffsetUnits;

  /// Sets the alpha value to be used when running an alpha test. Default is 0.
  double alphaTest;

  /// Boolean for fixing antialiasing gaps in CanvasRenderer
  double overdraw;

  /// Defines whether this material is visible. Default is true.
  bool visible;

  /// Specifies that the material needs to be updated at the WebGL level.
  ///
  /// Set it to true if you made changes that need to be reflected in WebGL.
  /// This property is automatically set to true when instancing a new material.
  bool _needsUpdate = true;
  get needsUpdate => _needsUpdate;
  set needsUpdate(bool value) {
    if (value) update();
    _needsUpdate = value;
  }

  /// Diffuse color of the material
  Color color;

  bool fog;

  int vertexColors;

  int shading;

  // WebGL
  Map __webglShader;
  WebGLProgram _program;
  List _uniformsList;
  int _numSupportedMorphTargets;
  int _numSupportedMorphNormals;
  bool _shadowPass = false;

  StreamController _onUpdateController = new StreamController();
  Stream get onUpdate => _onUpdateController.stream;

  Material._({this.name, this.side, this.opacity, this.transparent,
    this.blending, this.blendSrc, this.blendDst, this.blendEquation, this.blendSrcAlpha, this.blendDstAlpha,
    this.blendEquationAlpha, this.depthFunc, this.depthTest, this.depthWrite, this.colorWrite, this.polygonOffset,
    this.polygonOffsetFactor, this.polygonOffsetUnits, this.alphaTest, this.overdraw, this.visible,

    num color: 0xffffff, this.fog: false, this.vertexColors, this.shading: NoShading})
      : this.color = new Color(color);

  void update() {
    _onUpdateController.add(null);
  }

  void dispose() {
    _onDisposeController.add(this);
  }
}

abstract class Mapping {
  Texture map, envMap, aoMap, alphaMap, specularMap, lightMap, normalMap, bumpMap;
  double reflectivity, refractionRatio, bumpScale;
  Vector2 normalScale;
  int combine;
}

abstract class Lighting {
  Color emissive, specular;
}

/// Material that uses skinning.
abstract class Morphing {
  bool skinning;
  bool morphTargets, morphNormals;
}

abstract class Wireframe {
  bool wireframe;
  double wireframeLinewidth;
  String wireframeLinecap, wireframeLinejoin;
}

abstract class LineMaterial {
  double linewidth;

  double scale;
  double dashSize;
  double gapSize;
}