library three.constants;

// GL STATE CONSTANTS

const int CullFaceNone = 0;
const int CullFaceBack = 1;
const int CullFaceFront = 2;
const int CullFaceFrontBack = 3;

const int FrontFaceDirectionCW = 0;
const int FrontFaceDirectionCCW = 1;

// SHADOWING TYPES

const int BasicShadowMap = 0;
const int PCFShadowMap = 1;
const int PCFSoftShadowMap = 2;

// MATERIAL CONSTANTS

// side

const int FrontSide = 0;
const int BackSide = 1;
const int DoubleSide = 2;

// shading

const int NoShading = 0;
const int FlatShading = 1;
const int SmoothShading = 2;

// colors

const int NoColors = 0;
const int FaceColors = 1;
const int VertexColors = 2;

// blending modes

const int NoBlending = 0;
const int NormalBlending = 1;
const int AdditiveBlending = 2;
const int SubtractiveBlending = 3;
const int MultiplyBlending = 4;
const int CustomBlending = 5;

// custom blending equations
// (numbers start from 100 not to clash with other
//  mappings to OpenGL constants defined in Texture.js)

const int AddEquation = 100;
const int SubtractEquation = 101;
const int ReverseSubtractEquation = 102;
const int MinEquation = 103;
const int MaxEquation = 104;

// custom blending destination factors

const int ZeroFactor = 200;
const int OneFactor = 201;
const int SrcColorFactor = 202;
const int OneMinusSrcColorFactor = 203;
const int SrcAlphaFactor = 204;
const int OneMinusSrcAlphaFactor = 205;
const int DstAlphaFactor = 206;
const int OneMinusDstAlphaFactor = 207;

// custom blending source factors

//const int ZeroFactor = 200;
//const int OneFactor = 201;
//const int SrcAlphaFactor = 204;
//const int OneMinusSrcAlphaFactor = 205;
//const int DstAlphaFactor = 206;
//const int OneMinusDstAlphaFactor = 207;
const int DstColorFactor = 208;
const int OneMinusDstColorFactor = 209;
const int SrcAlphaSaturateFactor = 210;

// depth modes

const int NeverDepth = 0;
const int AlwaysDepth = 1;
const int LessDepth = 2;
const int LessEqualDepth = 3;
const int EqualDepth = 4;
const int GreaterEqualDepth = 5;
const int GreaterDepth = 6;
const int NotEqualDepth = 7;


// TEXTURE CONSTANTS

const int MultiplyOperation = 0;
const int MixOperation = 1;
const int AddOperation = 2;

// Mapping modes

const int UVMapping = 300;

const int CubeReflectionMapping = 301;
const int CubeRefractionMapping = 302;

const int EquirectangularReflectionMapping = 303;
const int EquirectangularRefractionMapping = 304;

const int SphericalReflectionMapping = 305;

// Wrapping modes

const int RepeatWrapping = 1000;
const int ClampToEdgeWrapping = 1001;
const int MirroredRepeatWrapping = 1002;

// Filters

const int NearestFilter = 1003;
const int NearestMipMapNearestFilter = 1004;
const int NearestMipMapLinearFilter = 1005;
const int LinearFilter = 1006;
const int LinearMipMapNearestFilter = 1007;
const int LinearMipMapLinearFilter = 1008;

// Data types

const int UnsignedByteType = 1009;
const int ByteType = 1010;
const int ShortType = 1011;
const int UnsignedShortType = 1012;
const int IntType = 1013;
const int UnsignedIntType = 1014;
const int FloatType = 1015;
const int HalfFloatType = 1025;

// Pixel types

//const int UnsignedByteType = 1009;
const int UnsignedShort4444Type = 1016;
const int UnsignedShort5551Type = 1017;
const int UnsignedShort565Type = 1018;

// Pixel formats

const int AlphaFormat = 1019;
const int RGBFormat = 1020;
const int RGBAFormat = 1021;
const int LuminanceFormat = 1022;
const int LuminanceAlphaFormat = 1023;
// const int RGBEFormat handled as const int RGBAFormat in shaders
const int RGBEFormat = RGBAFormat; //1024;

// DDS / ST3C Compressed texture formats

const int RGB_S3TC_DXT1_Format = 2001;
const int RGBA_S3TC_DXT1_Format = 2002;
const int RGBA_S3TC_DXT3_Format = 2003;
const int RGBA_S3TC_DXT5_Format = 2004;


// PVRTC compressed texture formats

const int RGB_PVRTC_4BPPV1_Format = 2100;
const int RGB_PVRTC_2BPPV1_Format = 2101;
const int RGBA_PVRTC_4BPPV1_Format = 2102;
const int RGBA_PVRTC_2BPPV1_Format = 2103;