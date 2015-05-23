/*
 * @author mr.doob / http://mrdoob.com/
 * @author alteredq / http://alteredqualia.com/
 * @author szimek / https://github.com/szimek/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 */

part of three.textures;

/// Create a texture to apply to a surface or as a reflection or refraction map.
///
/// Example
///
///     // load a texture, set wrap mode to repeat
///     var texture = image_utils.loadTexture('textures/water.jpg');
///     texture.wrapS = RepeatWrapping;
///     texture.wrapT = RepeatWrapping;
///     texture.repeat.setValues(4.0, 4.0);
class Texture {
  static const int defaultMapping = UVMapping;

  /// Unique number for this texture instance.
  int id = TextureIdCount++;

  String uuid = generateUUID();

  /// Given name of the texture, empty string by default.
  String name = '';
  String sourceFile = '';

  /// An Image object, typically created using the ImageUtils or ImageLoader
  /// classes. The Image object can include an image (e.g., PNG, JPG, GIF, DDS),
  /// video (e.g., MP4, OGG/OGV), or set of six images for a cube map.
  /// To use video as a texture you need to have a playing HTML5 video element
  /// as a source for your texture image and continuously update this texture
  /// as long as video is playing.
  var image;

  /// Array of mipmaps generated.
  List mipmaps = [];

  /// How the image is applied to the object. An object type of [UVMapping]
  /// is the default, where the U,V coordinates are used to apply the map, and
  /// a single texture is expected. The other types are [CubeReflectionMapping],
  /// for cube maps used as a reflection map; [CubeRefractionMapping],
  /// refraction mapping; and [SphericalReflectionMapping], a spherical
  /// reflection map projection.
  int mapping;

  /// The default is [ClampToEdgeWrapping], where the edge is clamped to the
  /// outer edge texels. The other two choices are [RepeatWrapping] and
  /// [MirroredRepeatWrapping].
  int wrapS;

  /// The default is [ClampToEdgeWrapping], where the edge is clamped to the
  /// outer edge texels. The other two choices are [RepeatWrapping] and
  /// [MirroredRepeatWrapping].
  ///
  /// NOTE: tiling of images in textures only functions if image dimensions are
  /// powers of two (2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, ...) in
  /// terms of pixels. Individual dimensions need not be equal, but each must
  /// be a power of two. This is a limitation of WebGL, not Three.dart.
  int wrapT;

  /// How the texture is sampled when a texel covers more than one pixel.
  /// The default is [LinearFilter], which takes the four closest texels
  /// and bilinearly interpolates among them. The other option is
  /// [NearestFilter], which uses the value of the closest texel.
  int magFilter;

  /// How the texture is sampled when a texel covers less than one pixel.
  /// The default is [LinearMipMapLinearFilter], which uses mipmapping and
  /// a trilinear filter. Other choices are [NearestFilter],
  /// [NearestMipMapNearestFilter], [NearestMipMapLinearFilter],
  /// [LinearFilter], and [LinearMipMapNearestFilter]. These vary
  /// whether the nearest texel or nearest four texels are retrieved on the
  /// nearest mipmap or nearest two mipmaps. Interpolation occurs among the
  /// samples retrieved.
  int minFilter;

  /// The number of samples taken along the axis through the pixel that has the
  /// highest density of texels. By default, this value is 1. A higher value gives
  /// a less blurry result than a basic mipmap, at the cost of more texture
  /// samples being used. Use renderer.getMaxAnisotropy() to find the maximum
  /// valid anisotropy value for the GPU; this value is usually a power of 2.
  int anisotropy;

  /// The default is [RGBAFormat] for the texture. Other formats are:
  /// [AlphaFormat], [RGBFormat], [LuminanceFormat], and
  /// [LuminanceAlphaFormat]. There are also compressed texture formats,
  /// if the S3TC extension is supported: [RGB_S3TC_DXT1_Format],
  /// [RGBA_S3TC_DXT1_Format], [RGBA_S3TC_DXT3_Format], and
  /// [RGBA_S3TC_DXT5_Format].
  int format;

  /// The default is [UnsignedByteType]. Other valid types (as WebGL allows)
  /// are [ByteType], [ShortType], [UnsignedShortType], [IntType],
  /// [UnsignedIntType], [FloatType], [UnsignedShort4444Type],
  /// [UnsignedShort5551Type], and [UnsignedShort565Type].
  int type;

  /// How much a single repetition of the texture is offset from the beginning,
  /// in each direction U and V. Typical range is 0.0 to 1.0.
  Vector2 offset = new Vector2(0.0, 0.0);

  /// How many times the texture is repeated across the surface,
  /// in each direction U and V.
  Vector2 repeat = new Vector2(1.0, 1.0);

  /// Whether to generate mipmaps (if possible) for a texture. True by default.
  bool generateMipmaps = true;

  /// False by default, which is the norm for PNG images. Set to true if the RGB values have been stored premultiplied by alpha.
  bool premultiplyAlpha = false;

  /// True by default. Flips the image's Y axis to match the WebGL
  /// texture coordinate space.
  bool flipY = true;

  /// 4 by default. Specifies the alignment requirements for the start of each
  /// pixel row in memory. The allowable values are:
  ///
  /// * 1 (byte-alignment)
  /// * 2 (rows aligned to even-numbered bytes)
  /// * 4 (word-alignment)
  /// * 8 (rows start on double-word boundaries)
  ///
  /// See glPixelStorei for more information.
  int unpackAlignment = 4;

  bool _needsUpdate = false;

  StreamController _onUpdateController = new StreamController.broadcast();
  Stream get onUpdate => _onUpdateController.stream;

  StreamController _onDisposeController = new StreamController.broadcast();
  Stream get onDispose => _onDisposeController.stream;

  Texture([this.image, this.mapping = defaultMapping,
      this.wrapS = ClampToEdgeWrapping, this.wrapT = ClampToEdgeWrapping,
      this.magFilter = LinearFilter, this.minFilter = LinearMipMapLinearFilter,
      this.format = RGBAFormat, this.type = UnsignedByteType,
      this.anisotropy = 1]);

  bool get needsUpdate => _needsUpdate;

  /// If a texture is changed after creation, set this flag to true so that the
  /// texture is properly set up. Particularly important for setting the wrap mode.
  set needsUpdate(bool flag) {
    if (flag) update();
    _needsUpdate = flag;
  }

  /// Make copy of texture. Note this is not a "deep copy", the image is shared.
  Texture clone([Texture texture]) {
    if (texture == null) texture = new Texture();

    return texture
      ..image = image
      ..mipmaps = new List.from(mipmaps)
      ..mapping = mapping
      ..wrapS = wrapS
      ..wrapT = wrapT
      ..magFilter = magFilter
      ..minFilter = minFilter
      ..anisotropy = anisotropy
      ..format = format
      ..type = type
      ..offset.setFrom(offset)
      ..repeat.setFrom(repeat)
      ..generateMipmaps = generateMipmaps
      ..premultiplyAlpha = premultiplyAlpha
      ..flipY = flipY
      ..unpackAlignment = unpackAlignment;
  }

  void update() {
    _onUpdateController.add(this);
  }

  void dispose() {
    _onDisposeController.add(this);
  }

  // Quick hack to allow setting new properties (used by the renderer)
  Map _data = {};
  operator [](String key) => _data[key];
  operator []=(String key, value) => _data[key] = value;
}
