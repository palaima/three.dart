/*
 * Based on r71
 */

library shaders;

import 'dart:math' show exp;
import 'package:three/three.dart' show Uniform, ShaderChunk, UniformsLib;
import 'package:three/src/renderers/shaders/uniforms_utils.dart' as UniformsUtils;

Map basicShader = {
  'uniforms': {},
  'vertexShader': '''
void main() {
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
void main() {
  gl_FragColor = vec4(1.0, 0.0, 0.0, 0.5);
}
'''
};

Map bleachBypassShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'opacity': new Uniform.float(1.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float opacity;

uniform sampler2D tDiffuse;

varying vec2 vUv;

void main() {
  vec4 base = texture2D(tDiffuse, vUv);

  vec3 lumCoeff = vec3(0.25, 0.65, 0.1);
  float lum = dot(lumCoeff, base.rgb);
  vec3 blend = vec3(lum);

  float L = min(1.0, max(0.0, 10.0 * (lum - 0.45)));

  vec3 result1 = 2.0 * base.rgb * blend;
  vec3 result2 = 1.0 - 2.0 * (1.0 - blend) * (1.0 - base.rgb);

  vec3 newColor = mix(result1, result2, L);

  float A2 = opacity * base.a;
  vec3 mixRGB = A2 * newColor.rgb;
  mixRGB += ((1.0 - A2) * base.rgb);

  gl_FragColor = vec4(mixRGB, base.a);
}
'''
};

Map blendShader = {
  'uniforms': {
    'tDiffuse1': new Uniform.texture(),
    'tDiffuse2': new Uniform.texture(),
    'mixRatio': new Uniform.float(0.5),
    'opacity': new Uniform.float(1.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float opacity;
uniform float mixRatio;

uniform sampler2D tDiffuse1;
uniform sampler2D tDiffuse2;

varying vec2 vUv;

void main() {
  vec4 texel1 = texture2D(tDiffuse1, vUv);
  vec4 texel2 = texture2D(tDiffuse2, vUv);
  gl_FragColor = opacity * mix(texel1, texel2, mixRatio);
}
'''
};

Map bokehShader = {
  'uniforms': {
    'tColor': new Uniform.texture(),
    'tDepth': new Uniform.texture(),
    'focus': new Uniform.float(1.0),
    'aspect': new Uniform.float(1.0),
    'aperture': new Uniform.float(0.025),
    'maxblur': new Uniform.float(1.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
varying vec2 vUv;

uniform sampler2D tColor;
uniform sampler2D tDepth;

uniform float maxblur;  // max blur amount
uniform float aperture; // aperture - bigger values for shallower depth of field

uniform float focus;
uniform float aspect;

void main() {
  vec2 aspectcorrect = vec2(1.0, aspect);

  vec4 depth1 = texture2D(tDepth, vUv);

  float factor = depth1.x - focus;

  vec2 dofblur = vec2 (clamp(factor * aperture, -maxblur, maxblur));

  vec2 dofblur9 = dofblur * 0.9;
  vec2 dofblur7 = dofblur * 0.7;
  vec2 dofblur4 = dofblur * 0.4;

  vec4 col = vec4(0.0);

  col += texture2D(tColor, vUv.xy);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,   0.4) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.15,  0.37) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.29,  0.29) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.37,  0.15) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.40,  0.0) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.37, -0.15) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.29, -0.29) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.15, -0.37) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,  -0.4) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.15,  0.37) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29,  0.29) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.37,  0.15) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.4,   0.0) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.37, -0.15) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29, -0.29) * aspectcorrect) * dofblur);
  col += texture2D(tColor, vUv.xy + (vec2(0.15, -0.37) * aspectcorrect) * dofblur);

  col += texture2D(tColor, vUv.xy + (vec2(0.15,  0.37) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(-0.37,  0.15) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(0.37, -0.15) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(-0.15, -0.37) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(-0.15,  0.37) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(0.37,  0.15) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(-0.37, -0.15) * aspectcorrect) * dofblur9);
  col += texture2D(tColor, vUv.xy + (vec2(0.15, -0.37) * aspectcorrect) * dofblur9);

  col += texture2D(tColor, vUv.xy + (vec2(0.29,  0.29) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(0.40,  0.0) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(0.29, -0.29) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,  -0.4) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29,  0.29) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(-0.4,   0.0) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29, -0.29) * aspectcorrect) * dofblur7);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,   0.4) * aspectcorrect) * dofblur7);

  col += texture2D(tColor, vUv.xy + (vec2(0.29,  0.29) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(0.4,   0.0) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(0.29, -0.29) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,  -0.4) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29,  0.29) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(-0.4,   0.0) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(-0.29, -0.29) * aspectcorrect) * dofblur4);
  col += texture2D(tColor, vUv.xy + (vec2(0.0,   0.4) * aspectcorrect) * dofblur4);

  gl_FragColor = col / 41.0;
  gl_FragColor.a = 1.0;
}
'''
};

Map bokehShader2 = {
  'uniforms': {
    'textureWidth': new Uniform.float(1.0),
    'textureHeight': new Uniform.float(1.0),

    'focalDepth': new Uniform.float(1.0),
    'focalLength': new Uniform.float(24.0),
    'fstop': new Uniform.float(0.9),

    'tColor': new Uniform.texture(),
    'tDepth': new Uniform.texture(),

    'maxblur': new Uniform.float(1.0),

    'showFocus': new Uniform.int(0),
    'manualdof': new Uniform.int(0),
    'vignetting': new Uniform.int(0),
    'depthblur':new Uniform.int(0),

    'threshold': new Uniform.float(0.5),
    'gain': new Uniform.float(2.0),
    'bias': new Uniform.float(0.5),
    'fringe': new Uniform.float(0.7),

    'znear': new Uniform.float(0.1),
    'zfar': new Uniform.float(100.0),

    'noise': new Uniform.int(1),
    'dithering':  new Uniform.float(0.0001),
    'pentagon': new Uniform.int(0),

    'shaderFocus': new Uniform.int(1),
    'focusCoords': new Uniform.vector2(0.0, 0.0),
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
varying vec2 vUv;

uniform sampler2D tColor;
uniform sampler2D tDepth;
uniform float textureWidth;
uniform float textureHeight;

const float PI = 3.14159265;

float width = textureWidth; //texture width
float height = textureHeight; //texture height

vec2 texel = vec2(1.0/width,1.0/height);

uniform float focalDepth;  //focal distance value in meters, but you may use autofocus option below
uniform float focalLength; //focal length in mm
uniform float fstop; //f-stop value
uniform bool showFocus; //show debug focus point and focal range (red = focal point, green = focal range)

/*
make sure that these two values are the same for your camera, otherwise distances will be wrong.
*/

uniform float znear; // camera clipping start
uniform float zfar; // camera clipping end

//------------------------------------------
//user variables

const int samples = SAMPLES; //samples on the first ring
const int rings = RINGS; //ring count

const int maxringsamples = rings * samples;

uniform bool manualdof; // manual dof calculation
float ndofstart = 1.0; // near dof blur start
float ndofdist = 2.0; // near dof blur falloff distance
float fdofstart = 1.0; // far dof blur start
float fdofdist = 3.0; // far dof blur falloff distance

float CoC = 0.03; //circle of confusion size in mm (35mm film = 0.03mm)

uniform bool vignetting; // use optical lens vignetting

float vignout = 1.3; // vignetting outer border
float vignin = 0.0; // vignetting inner border
float vignfade = 22.0; // f-stops till vignete fades

uniform bool shaderFocus;

bool autofocus = shaderFocus;
//use autofocus in shader - use with focusCoords
// disable if you use external focalDepth value

uniform vec2 focusCoords;
// autofocus point on screen (0.0,0.0 - left lower corner, 1.0,1.0 - upper right)
// if center of screen use vec2(0.5, 0.5);

uniform float maxblur;
//clamp value of max blur (0.0 = no blur, 1.0 default)

uniform float threshold; // highlight threshold;
uniform float gain; // highlight gain;

uniform float bias; // bokeh edge bias
uniform float fringe; // bokeh chromatic aberration / fringing

uniform bool noise; //use noise instead of pattern for sample dithering

uniform float dithering;
float namount = dithering; //dither amount

uniform bool depthblur; // blur the depth buffer
float dbsize = 1.25; // depth blur size

/*
next part is experimental
not looking good with small sample and ring count
looks okay starting from samples = 4, rings = 4
*/

uniform bool pentagon; //use pentagon as bokeh shape?
float feather = 0.4; //pentagon shape feather

//------------------------------------------

float penta(vec2 coords) {
  //pentagonal shape
  float scale = float(rings) - 1.3;
  vec4  HS0 = vec4(1.0,         0.0,         0.0,  1.0);
  vec4  HS1 = vec4(0.309016994, 0.951056516, 0.0,  1.0);
  vec4  HS2 = vec4(-0.809016994, 0.587785252, 0.0,  1.0);
  vec4  HS3 = vec4(-0.809016994,-0.587785252, 0.0,  1.0);
  vec4  HS4 = vec4(0.309016994,-0.951056516, 0.0,  1.0);
  vec4  HS5 = vec4(0.0        ,0.0         , 1.0,  1.0);

  vec4  one = vec4(1.0);

  vec4 P = vec4((coords),vec2(scale, scale));

  vec4 dist = vec4(0.0);
  float inorout = -4.0;

  dist.x = dot(P, HS0);
  dist.y = dot(P, HS1);
  dist.z = dot(P, HS2);
  dist.w = dot(P, HS3);

  dist = smoothstep(-feather, feather, dist);

  inorout += dot(dist, one);

  dist.x = dot(P, HS4);
  dist.y = HS5.w - abs(P.z);

  dist = smoothstep(-feather, feather, dist);
  inorout += dist.x;

  return clamp(inorout, 0.0, 1.0);
}

float bdepth(vec2 coords) {
  // Depth buffer blur
  float d = 0.0;
  float kernel[9];
  vec2 offset[9];

  vec2 wh = vec2(texel.x, texel.y) * dbsize;

  offset[0] = vec2(-wh.x,-wh.y);
  offset[1] = vec2(0.0, -wh.y);
  offset[2] = vec2(wh.x -wh.y);

  offset[3] = vec2(-wh.x,  0.0);
  offset[4] = vec2(0.0,   0.0);
  offset[5] = vec2(wh.x,  0.0);

  offset[6] = vec2(-wh.x, wh.y);
  offset[7] = vec2(0.0,  wh.y);
  offset[8] = vec2(wh.x, wh.y);

  kernel[0] = 1.0/16.0;   kernel[1] = 2.0/16.0;   kernel[2] = 1.0/16.0;
  kernel[3] = 2.0/16.0;   kernel[4] = 4.0/16.0;   kernel[5] = 2.0/16.0;
  kernel[6] = 1.0/16.0;   kernel[7] = 2.0/16.0;   kernel[8] = 1.0/16.0;


  for(int i=0; i<9; i++) {
    float tmp = texture2D(tDepth, coords + offset[i]).r;
    d += tmp * kernel[i];
  }

  return d;
}


vec3 color(vec2 coords,float blur) {
  //processing the sample

  vec3 col = vec3(0.0);

  col.r = texture2D(tColor,coords + vec2(0.0,1.0)*texel*fringe*blur).r;
  col.g = texture2D(tColor,coords + vec2(-0.866,-0.5)*texel*fringe*blur).g;
  col.b = texture2D(tColor,coords + vec2(0.866,-0.5)*texel*fringe*blur).b;

  vec3 lumcoeff = vec3(0.299,0.587,0.114);
  float lum = dot(col.rgb, lumcoeff);
  float thresh = max((lum-threshold)*gain, 0.0);
  return col+mix(vec3(0.0),col,thresh*blur);
}

vec2 rand(vec2 coord) {
  // generating noise / pattern texture for dithering

  float noiseX = ((fract(1.0-coord.s*(width/2.0))*0.25)+(fract(coord.t*(height/2.0))*0.75))*2.0-1.0;
  float noiseY = ((fract(1.0-coord.s*(width/2.0))*0.75)+(fract(coord.t*(height/2.0))*0.25))*2.0-1.0;

  if (noise) {
    noiseX = clamp(fract(sin(dot(coord ,vec2(12.9898,78.233))) * 43758.5453),0.0,1.0)*2.0-1.0;
    noiseY = clamp(fract(sin(dot(coord ,vec2(12.9898,78.233)*2.0)) * 43758.5453),0.0,1.0)*2.0-1.0;
  }

  return vec2(noiseX,noiseY);
}

vec3 debugFocus(vec3 col, float blur, float depth) {
  float edge = 0.002*depth; //distance based edge smoothing
  float m = clamp(smoothstep(0.0,edge,blur),0.0,1.0);
  float e = clamp(smoothstep(1.0-edge,1.0,blur),0.0,1.0);

  col = mix(col,vec3(1.0,0.5,0.0),(1.0-m)*0.6);
  col = mix(col,vec3(0.0,0.5,1.0),((1.0-e)-(1.0-m))*0.2);

  return col;
}

float linearize(float depth) {
  return -zfar * znear / (depth * (zfar - znear) - zfar);
}


float vignette() {
  float dist = distance(vUv.xy, vec2(0.5,0.5));
  dist = smoothstep(vignout+(fstop/vignfade), vignin+(fstop/vignfade), dist);
  return clamp(dist,0.0,1.0);
}

float gather(float i, float j, int ringsamples, inout vec3 col, float w, float h, float blur) {
  float rings2 = float(rings);
  float step = PI*2.0 / float(ringsamples);
  float pw = cos(j*step)*i;
  float ph = sin(j*step)*i;
  float p = 1.0;
  if (pentagon) {
    p = penta(vec2(pw,ph));
  }
  col += color(vUv.xy + vec2(pw*w,ph*h), blur) * mix(1.0, i/rings2, bias) * p;
  return 1.0 * mix(1.0, i /rings2, bias) * p;
}

void main() {
  //scene depth calculation

  float depth = linearize(texture2D(tDepth,vUv.xy).x);

  // Blur depth?
  if (depthblur) {
    depth = linearize(bdepth(vUv.xy));
  }

  //focal plane calculation

  float fDepth = focalDepth;

  if (autofocus) {

    fDepth = linearize(texture2D(tDepth,focusCoords).x);

  }

  // dof blur factor calculation

  float blur = 0.0;

  if (manualdof) {
    float a = depth-fDepth; // Focal plane
    float b = (a-fdofstart)/fdofdist; // Far DoF
    float c = (-a-ndofstart)/ndofdist; // Near Dof
    blur = (a>0.0) ? b : c;
  } else {
    float f = focalLength; // focal length in mm
    float d = fDepth*1000.0; // focal plane in mm
    float o = depth*1000.0; // depth in mm

    float a = (o*f)/(o-f);
    float b = (d*f)/(d-f);
    float c = (d-f)/(d*fstop*CoC);

    blur = abs(a-b)*c;
  }

  blur = clamp(blur,0.0,1.0);

  // calculation of pattern for dithering

  vec2 noise = rand(vUv.xy)*namount*blur;

  // getting blur x and y step factor

  float w = (1.0/width)*blur*maxblur+noise.x;
  float h = (1.0/height)*blur*maxblur+noise.y;

  // calculation of final color

  vec3 col = vec3(0.0);

  if(blur < 0.05) {
    //some optimization thingy
    col = texture2D(tColor, vUv.xy).rgb;
  } else {
    col = texture2D(tColor, vUv.xy).rgb;
    float s = 1.0;
    int ringsamples;

    for (int i = 1; i <= rings; i++) {
      /*unboxstart*/
      ringsamples = i * samples;

      for (int j = 0 ; j < maxringsamples ; j++) {
        if (j >= ringsamples) break;
        s += gather(float(i), float(j), ringsamples, col, w, h, blur);
      }
      /*unboxend*/
    }

    col /= s; //divide by sample count
  }

  if (showFocus) {
    col = debugFocus(col, blur, depth);
  }

  if (vignetting) {
    col *= vignette();
  }

  gl_FragColor.rgb = col;
  gl_FragColor.a = 1.0;
}
'''
};

Map brightnessContrastShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'brightness': new Uniform.float(0.0),
    'contrast': new Uniform.float(0.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform float brightness;
uniform float contrast;

varying vec2 vUv;

void main() {
  gl_FragColor = texture2D(tDiffuse, vUv);

  gl_FragColor.rgb += brightness;

  if (contrast > 0.0) {
    gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) / (1.0 - contrast) + 0.5;
  } else {
    gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) * (1.0 + contrast) + 0.5;
  }
}
'''
};

Map colorCorrectionShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'powRGB': new Uniform.vector3(0.0, 0.0, 0.0),
    'mulRGB': new Uniform.vector3(0.0, 0.0, 0.0),
    'addRGB': new Uniform.vector3(0.0, 0.0, 0.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform vec3 powRGB;
uniform vec3 mulRGB;
uniform vec3 addRGB;

varying vec2 vUv;

void main() {
  gl_FragColor = texture2D(tDiffuse, vUv);
  gl_FragColor.rgb = mulRGB * pow((gl_FragColor.rgb + addRGB), powRGB);
}
'''
};

Map colorifyShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'color': new Uniform.color(0xffffff)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform vec3 color;
uniform sampler2D tDiffuse;

varying vec2 vUv;

void main() {
  vec4 texel = texture2D(tDiffuse, vUv);

  vec3 luma = vec3(0.299, 0.587, 0.114);
  float v = dot(texel.xyz, luma);

  gl_FragColor = vec4(v * color, texel.w);
}
'''
};

Map convolutionShader = {
  'defines': {
    'KERNEL_SIZE_FLOAT': '25.0',
    'KERNEL_SIZE_INT': '25',
  },
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'uImageIncrement': new Uniform.vector2(0.001953125, 0.0),
    'cKernel': new Uniform.floatv1([])
  },
  'vertexShader': '''
uniform vec2 uImageIncrement;
varying vec2 vUv;
void main() {
  vUv = uv - ((KERNEL_SIZE_FLOAT - 1.0) / 2.0) * uImageIncrement;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float cKernel[KERNEL_SIZE_INT];

uniform sampler2D tDiffuse;
uniform vec2 uImageIncrement;

varying vec2 vUv;

void main() {
  vec2 imageCoord = vUv;
  vec4 sum = vec4(0.0, 0.0, 0.0, 0.0);

  for(int i = 0; i < KERNEL_SIZE_INT; i ++) {
    sum += texture2D(tDiffuse, imageCoord) * cKernel[i];
    imageCoord += uImageIncrement;
  }

  gl_FragColor = sum;
}
''',
  'buildKernel': (sigma) {
    double gauss(x, sigma) => exp(-(x * x) / (2.0 * sigma * sigma));

    var kMaxKernelSize = 25, kernelSize = 2 * (sigma * 3.0).ceil() + 1;

    if (kernelSize > kMaxKernelSize) {
      kernelSize = kMaxKernelSize;
    }

    var halfWidth = (kernelSize - 1) * 0.5;

    var values = new List(kernelSize);
    var sum = 0.0;
    for (var i = 0; i < kernelSize; ++i) {
      values[i] = gauss(i - halfWidth, sigma);
      sum += values[i];
    }

    // normalize the kernel

    for (var i = 0; i < kernelSize; ++i) {
      values[i] /= sum;
    }

    return values;
  }
};

Map copyShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'opacity': new Uniform.float(1.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float opacity;

uniform sampler2D tDiffuse;

varying vec2 vUv;

void main() {
  vec4 texel = texture2D(tDiffuse, vUv);
  gl_FragColor = opacity * texel;
}
'''
};

Map dofMipMapShader = {
  'uniforms': {
    'tColor': new Uniform.texture(),
    'tDepth': new Uniform.texture(),
    'focus': new Uniform.float(1.0),
    'maxblur': new Uniform.float(1.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float focus;
uniform float maxblur;

uniform sampler2D tColor;
uniform sampler2D tDepth;

varying vec2 vUv;

void main() {
  vec4 depth = texture2D(tDepth, vUv);

  float factor = depth.x - focus;

  vec4 col = texture2D(tColor, vUv, 2.0 * maxblur * abs(focus - depth.x));

  gl_FragColor = col;
  gl_FragColor.a = 1.0;
}
'''
};

Map digitalGlitch = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(), //diffuse texture
    'tDisp': new Uniform.texture(), //displacement texture for digital glitch squares
    'byp': new Uniform.int(0), //apply the glitch ?
    'amount': new Uniform.float(0.08),
    'angle': new Uniform.float(0.02),
    'seed': new Uniform.float(0.02),
    'seed_x': new Uniform.float(0.02), //-1,1
    'seed_y': new Uniform.float(0.02), //-1,1
    'distortion_x': new Uniform.float(0.5),
    'distortion_y': new Uniform.float(0.6),
    'col_s': new Uniform.float(0.05)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform int byp;//should we apply the glitch ?

uniform sampler2D tDiffuse;
uniform sampler2D tDisp;

uniform float amount;
uniform float angle;
uniform float seed;
uniform float seed_x;
uniform float seed_y;
uniform float distortion_x;
uniform float distortion_y;
uniform float col_s;
  
varying vec2 vUv;

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
    
void main() {
  if(byp<1) {
    vec2 p = vUv;
    float xs = floor(gl_FragCoord.x / 0.5);
    float ys = floor(gl_FragCoord.y / 0.5);
    //based on staffantans glitch shader for unity https://github.com/staffantan/unityglitch
    vec4 normal = texture2D (tDisp, p*seed*seed);
    if(p.y<distortion_x+col_s && p.y>distortion_x-col_s*seed) {
      if(seed_x>0.){
        p.y = 1. - (p.y + distortion_y);
      }
      else {
        p.y = distortion_y;
      }
    }
    if(p.x<distortion_y+col_s && p.x>distortion_y-col_s*seed) {
      if(seed_y>0.){
        p.x=distortion_x;
      }
      else {
        p.x = 1. - (p.x + distortion_x);
      }
    }
    p.x+=normal.x*seed_x*(seed/5.);
    p.y+=normal.y*seed_y*(seed/5.);
    //base from RGB shift shader
    vec2 offset = amount * vec2(cos(angle), sin(angle));
    vec4 cr = texture2D(tDiffuse, p + offset);
    vec4 cga = texture2D(tDiffuse, p);
    vec4 cb = texture2D(tDiffuse, p - offset);
    gl_FragColor = vec4(cr.r, cga.g, cb.b, cga.a);
    //add noise
    vec4 snow = 200.*amount*vec4(rand(vec2(xs * seed,ys * seed*50.))*0.2);
    gl_FragColor = gl_FragColor+ snow;
  }
  else {
    gl_FragColor=texture2D (tDiffuse, vUv);
  }
}
'''
};

Map dotScreenShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'tSize': new Uniform.vector2(256.0, 256.0),
    'center': new Uniform.vector2(0.5, 0.5),
    'angle': new Uniform.float(1.57),
    'scale': new Uniform.float(1.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform vec2 center;
uniform float angle;
uniform float scale;
uniform vec2 tSize;

uniform sampler2D tDiffuse;

varying vec2 vUv;

float pattern() {
  float s = sin(angle), c = cos(angle);

  vec2 tex = vUv * tSize - center;
  vec2 point = vec2(c * tex.x - s * tex.y, s * tex.x + c * tex.y) * scale;

  return (sin(point.x) * sin(point.y)) * 4.0;
}

void main() {
  vec4 color = texture2D(tDiffuse, vUv);

  float average = (color.r + color.g + color.b) / 3.0;

  gl_FragColor = vec4(vec3(average * 10.0 - 5.0 + pattern()), color.a);
}
'''
};

Map edgeShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'aspect': new Uniform.vector2(512.0, 512.0),
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
varying vec2 vUv;

uniform vec2 aspect;

vec2 texel = vec2(1.0 / aspect.x, 1.0 / aspect.y);


mat3 G[9];

// hard coded matrix values!!!! as suggested in https://github.com/neilmendoza/ofxPostProcessing/blob/master/src/EdgePass.cpp#L45

const mat3 g0 = mat3(0.3535533845424652, 0, -0.3535533845424652, 0.5, 0, -0.5, 0.3535533845424652, 0, -0.3535533845424652);
const mat3 g1 = mat3(0.3535533845424652, 0.5, 0.3535533845424652, 0, 0, 0, -0.3535533845424652, -0.5, -0.3535533845424652);
const mat3 g2 = mat3(0, 0.3535533845424652, -0.5, -0.3535533845424652, 0, 0.3535533845424652, 0.5, -0.3535533845424652, 0);
const mat3 g3 = mat3(0.5, -0.3535533845424652, 0, -0.3535533845424652, 0, 0.3535533845424652, 0, 0.3535533845424652, -0.5);
const mat3 g4 = mat3(0, -0.5, 0, 0.5, 0, 0.5, 0, -0.5, 0);
const mat3 g5 = mat3(-0.5, 0, 0.5, 0, 0, 0, 0.5, 0, -0.5);
const mat3 g6 = mat3(0.1666666716337204, -0.3333333432674408, 0.1666666716337204, -0.3333333432674408, 0.6666666865348816, -0.3333333432674408, 0.1666666716337204, -0.3333333432674408, 0.1666666716337204);
const mat3 g7 = mat3(-0.3333333432674408, 0.1666666716337204, -0.3333333432674408, 0.1666666716337204, 0.6666666865348816, 0.1666666716337204, -0.3333333432674408, 0.1666666716337204, -0.3333333432674408);
const mat3 g8 = mat3(0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408, 0.3333333432674408);

void main(void)
{

  G[0] = g0,
  G[1] = g1,
  G[2] = g2,
  G[3] = g3,
  G[4] = g4,
  G[5] = g5,
  G[6] = g6,
  G[7] = g7,
  G[8] = g8;

  mat3 I;
  float cnv[9];
  vec3 sample;

  /* fetch the 3x3 neighbourhood and use the RGB vector's length as intensity value */
  for (float i=0.0; i<3.0; i++) {
    for (float j=0.0; j<3.0; j++) {
      sample = texture2D(tDiffuse, vUv + texel * vec2(i-1.0,j-1.0)).rgb;
      I[int(i)][int(j)] = length(sample);
    }
  }

  /* calculate the convolution values for all the masks */
  for (int i=0; i<9; i++) {
    float dp3 = dot(G[i][0], I[0]) + dot(G[i][1], I[1]) + dot(G[i][2], I[2]);
    cnv[i] = dp3 * dp3;
  }

  float M = (cnv[0] + cnv[1]) + (cnv[2] + cnv[3]);
  float S = (cnv[4] + cnv[5]) + (cnv[6] + cnv[7]) + (cnv[8] + M);

  gl_FragColor = vec4(vec3(sqrt(M/S)), 1.0);
}
'''
};

Map edgeShader2 = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'aspect': new Uniform.vector2(512.0, 512.0),
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
varying vec2 vUv;
uniform vec2 aspect;

vec2 texel = vec2(1.0 / aspect.x, 1.0 / aspect.y);

mat3 G[2];

const mat3 g0 = mat3(1.0, 2.0, 1.0, 0.0, 0.0, 0.0, -1.0, -2.0, -1.0);
const mat3 g1 = mat3(1.0, 0.0, -1.0, 2.0, 0.0, -2.0, 1.0, 0.0, -1.0);


void main(void)
{
  mat3 I;
  float cnv[2];
  vec3 sample;

  G[0] = g0;
  G[1] = g1;

  /* fetch the 3x3 neighbourhood and use the RGB vector's length as intensity value */
  for (float i=0.0; i<3.0; i++)
  for (float j=0.0; j<3.0; j++) {
    sample = texture2D(tDiffuse, vUv + texel * vec2(i-1.0,j-1.0)).rgb;
    I[int(i)][int(j)] = length(sample);
  }

  /* calculate the convolution values for all the masks */
  for (int i=0; i<2; i++) {
    float dp3 = dot(G[i][0], I[0]) + dot(G[i][1], I[1]) + dot(G[i][2], I[2]);
    cnv[i] = dp3 * dp3; 
  }

  gl_FragColor = vec4(0.5 * sqrt(cnv[0]*cnv[0]+cnv[1]*cnv[1]));
} 
'''
};

Map fxaaShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'resolution': new Uniform.vector2(1 / 1024, 1 / 512),
  },
  'vertexShader': '''
void main() {
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform vec2 resolution;

#define FXAA_REDUCE_MIN   (1.0/128.0)
#define FXAA_REDUCE_MUL   (1.0/8.0)
#define FXAA_SPAN_MAX     8.0

void main() {

  vec3 rgbNW = texture2D(tDiffuse, (gl_FragCoord.xy + vec2(-1.0, -1.0)) * resolution).xyz;
  vec3 rgbNE = texture2D(tDiffuse, (gl_FragCoord.xy + vec2(1.0, -1.0)) * resolution).xyz;
  vec3 rgbSW = texture2D(tDiffuse, (gl_FragCoord.xy + vec2(-1.0, 1.0)) * resolution).xyz;
  vec3 rgbSE = texture2D(tDiffuse, (gl_FragCoord.xy + vec2(1.0, 1.0)) * resolution).xyz;
  vec4 rgbaM  = texture2D(tDiffuse,  gl_FragCoord.xy  * resolution);
  vec3 rgbM  = rgbaM.xyz;
  vec3 luma = vec3(0.299, 0.587, 0.114);

  float lumaNW = dot(rgbNW, luma);
  float lumaNE = dot(rgbNE, luma);
  float lumaSW = dot(rgbSW, luma);
  float lumaSE = dot(rgbSE, luma);
  float lumaM  = dot(rgbM,  luma);
  float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
  float lumaMax = max(lumaM, max(max(lumaNW, lumaNE) , max(lumaSW, lumaSE)));

  vec2 dir;
  dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
  dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

  float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);

  float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
  dir = min(vec2(FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
      max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
        dir * rcpDirMin)) * resolution;
  vec4 rgbA = (1.0/2.0) * (
      texture2D(tDiffuse,  gl_FragCoord.xy  * resolution + dir * (1.0/3.0 - 0.5)) +
  texture2D(tDiffuse,  gl_FragCoord.xy  * resolution + dir * (2.0/3.0 - 0.5)));
    vec4 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
  texture2D(tDiffuse,  gl_FragCoord.xy  * resolution + dir * (0.0/3.0 - 0.5)) +
      texture2D(tDiffuse,  gl_FragCoord.xy  * resolution + dir * (3.0/3.0 - 0.5)));
    float lumaB = dot(rgbB, vec4(luma, 0.0));

  if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
    gl_FragColor = rgbA;
  } else {
    gl_FragColor = rgbB;
  }
}
'''
};

Map filmShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'time': new Uniform.float(0.0),
    'nIntensity': new Uniform.float(0.5),
    'sIntensity': new Uniform.float(0.05),
    'sCount': new Uniform.float(4096),
    'grayscale': new Uniform.int(1),
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
// control parameter
uniform float time;

uniform bool grayscale;

// noise effect intensity value (0 = no effect, 1 = full effect)
uniform float nIntensity;

// scanlines effect intensity value (0 = no effect, 1 = full effect)
uniform float sIntensity;

// scanlines effect count value (0 = no effect, 4096 = full effect)
uniform float sCount;

uniform sampler2D tDiffuse;

varying vec2 vUv;

void main() {
  // sample the source
  vec4 cTextureScreen = texture2D(tDiffuse, vUv);

  // make some noise
  float x = vUv.x * vUv.y * time *  1000.0;
  x = mod(x, 13.0) * mod(x, 123.0);
  float dx = mod(x, 0.01);

  // add noise
  vec3 cResult = cTextureScreen.rgb + cTextureScreen.rgb * clamp(0.1 + dx * 100.0, 0.0, 1.0);

  // get us a sine and cosine
  vec2 sc = vec2(sin(vUv.y * sCount), cos(vUv.y * sCount));

  // add scanlines
  cResult += cTextureScreen.rgb * vec3(sc.x, sc.y, sc.x) * sIntensity;

  // interpolate between source and result by intensity
  cResult = cTextureScreen.rgb + clamp(nIntensity, 0.0,1.0) * (cResult - cTextureScreen.rgb);

  // convert to grayscale if desired
  if(grayscale) {
    cResult = vec3(cResult.r * 0.3 + cResult.g * 0.59 + cResult.b * 0.11);
  }

  gl_FragColor = vec4(cResult, cTextureScreen.a);
}
'''
};

Map focusShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'screenWidth': new Uniform.float(1024.0),
    'screenHeight': new Uniform.float(1024.0),
    'sampleDistance': new Uniform.float(0.94),
    'waveFactor': new Uniform.float(0.00125),
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float screenWidth;
uniform float screenHeight;
uniform float sampleDistance;
uniform float waveFactor;

uniform sampler2D tDiffuse;

varying vec2 vUv;

void main() {
  vec4 color, org, tmp, add;
  float sample_dist, f;
  vec2 vin;
  vec2 uv = vUv;

  add = color = org = texture2D(tDiffuse, uv);

  vin = (uv - vec2(0.5)) * vec2(1.4);
  sample_dist = dot(vin, vin) * 2.0;

  f = (waveFactor * 100.0 + sample_dist) * sampleDistance * 4.0;

  vec2 sampleSize = vec2( 1.0 / screenWidth, 1.0 / screenHeight) * vec2(f);

  add += tmp = texture2D(tDiffuse, uv + vec2(0.111964, 0.993712) * sampleSize);
  if(tmp.b < color.b) color = tmp;

  add += tmp = texture2D(tDiffuse, uv + vec2(0.846724, 0.532032) * sampleSize);
  if(tmp.b < color.b) color = tmp;

  add += tmp = texture2D(tDiffuse, uv + vec2(0.943883, -0.330279) * sampleSize);
  if(tmp.b < color.b) color = tmp;

  add += tmp = texture2D(tDiffuse, uv + vec2(0.330279, -0.943883) * sampleSize);
  if(tmp.b < color.b) color = tmp;

  add += tmp = texture2D(tDiffuse, uv + vec2(-0.532032, -0.846724) * sampleSize);
  if(tmp.b < color.b) color = tmp;

  add += tmp = texture2D(tDiffuse, uv + vec2(-0.993712, -0.111964) * sampleSize);
  if(tmp.b < color.b) color = tmp;

  add += tmp = texture2D(tDiffuse, uv + vec2(-0.707107, 0.707107) * sampleSize);
  if(tmp.b < color.b) color = tmp;

  color = color * vec4(2.0) - (add / vec4(8.0));
  color = color + (add / vec4(8.0) - color) * (vec4(1.0) - vec4(sample_dist * 0.5));

  gl_FragColor = vec4(color.rgb * color.rgb * vec3(0.95) + color.rgb, 1.0);
}
'''
};

Map fresnelShader = {
  'uniforms': {
    'mRefractionRatio': new Uniform.float(1.02),
    'mFresnelBias': new Uniform.float(0.1),
    'mFresnelPower': new Uniform.float(2.0),
    'mFresnelScale': new Uniform.float(1.0),
    'tCube': new Uniform.texture(),
  },
  'vertexShader': '''
uniform float mRefractionRatio;
uniform float mFresnelBias;
uniform float mFresnelScale;
uniform float mFresnelPower;

varying vec3 vReflect;
varying vec3 vRefract[3];
varying float vReflectionFactor;

void main() {

  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  vec4 worldPosition = modelMatrix * vec4(position, 1.0);

  vec3 worldNormal = normalize(mat3(modelMatrix[0].xyz, modelMatrix[1].xyz, modelMatrix[2].xyz) * normal);

  vec3 I = worldPosition.xyz - cameraPosition;

  vReflect = reflect(I, worldNormal);
  vRefract[0] = refract(normalize(I), worldNormal, mRefractionRatio);
  vRefract[1] = refract(normalize(I), worldNormal, mRefractionRatio * 0.99);
  vRefract[2] = refract(normalize(I), worldNormal, mRefractionRatio * 0.98);
  vReflectionFactor = mFresnelBias + mFresnelScale * pow(1.0 + dot(normalize(I), worldNormal), mFresnelPower);

  gl_Position = projectionMatrix * mvPosition;

}
''',
  'fragmentShader': '''
uniform samplerCube tCube;

varying vec3 vReflect;
varying vec3 vRefract[3];
varying float vReflectionFactor;

void main() {
  vec4 reflectedColor = textureCube(tCube, vec3(-vReflect.x, vReflect.yz));
  vec4 refractedColor = vec4(1.0);

  refractedColor.r = textureCube(tCube, vec3(-vRefract[0].x, vRefract[0].yz)).r;
  refractedColor.g = textureCube(tCube, vec3(-vRefract[1].x, vRefract[1].yz)).g;
  refractedColor.b = textureCube(tCube, vec3(-vRefract[2].x, vRefract[2].yz)).b;

  gl_FragColor = mix(refractedColor, reflectedColor, clamp(vReflectionFactor, 0.0, 1.0));
}
'''
};

Map gammaCorrectionShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
#define GAMMA_OUTPUT
#define GAMMA_FACTOR 2

uniform sampler2D tDiffuse;

varying vec2 vUv;

${ShaderChunk['common']},

void main() {
  vec4 tex = texture2D(tDiffuse, vec2(vUv.x, vUv.y));

  gl_FragColor = vec4(linearToOutput(tex.rgb), tex.a);
}
'''
};

Map horizontalBlurShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'h': new Uniform.float(1.0 / 512.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform float h;

varying vec2 vUv;

void main() {
  vec4 sum = vec4(0.0);

  sum += texture2D(tDiffuse, vec2(vUv.x - 4.0 * h, vUv.y)) * 0.051;
  sum += texture2D(tDiffuse, vec2(vUv.x - 3.0 * h, vUv.y)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x - 2.0 * h, vUv.y)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x - 1.0 * h, vUv.y)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y)) * 0.1633;
  sum += texture2D(tDiffuse, vec2(vUv.x + 1.0 * h, vUv.y)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x + 2.0 * h, vUv.y)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x + 3.0 * h, vUv.y)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x + 4.0 * h, vUv.y)) * 0.051;

  gl_FragColor = sum;
}
'''
};

Map horizontalTiltShiftShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'h': new Uniform.float(1.0 / 512.0),
    'r': new Uniform.float(0.35)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform float h;
uniform float r;

varying vec2 vUv;

void main() {
  vec4 sum = vec4(0.0);

  float hh = h * abs(r - vUv.y);

  sum += texture2D(tDiffuse, vec2(vUv.x - 4.0 * hh, vUv.y)) * 0.051;
  sum += texture2D(tDiffuse, vec2(vUv.x - 3.0 * hh, vUv.y)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x - 2.0 * hh, vUv.y)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x - 1.0 * hh, vUv.y)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y)) * 0.1633;
  sum += texture2D(tDiffuse, vec2(vUv.x + 1.0 * hh, vUv.y)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x + 2.0 * hh, vUv.y)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x + 3.0 * hh, vUv.y)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x + 4.0 * hh, vUv.y)) * 0.051;

  gl_FragColor = sum;
}
'''
};

Map hueSaturationShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'hue': new Uniform.float(0.0),
    'saturation': new Uniform.float(0.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform float hue;
uniform float saturation;

varying vec2 vUv;

void main() {

  gl_FragColor = texture2D(tDiffuse, vUv);

  // hue
  float angle = hue * 3.14159265;
  float s = sin(angle), c = cos(angle);
  vec3 weights = (vec3(2.0 * c, -sqrt(3.0) * s - c, sqrt(3.0) * s - c) + 1.0) / 3.0;
  float len = length(gl_FragColor.rgb);
  gl_FragColor.rgb = vec3(
    dot(gl_FragColor.rgb, weights.xyz),
    dot(gl_FragColor.rgb, weights.zxy),
    dot(gl_FragColor.rgb, weights.yzx)
 );

  // saturation
  float average = (gl_FragColor.r + gl_FragColor.g + gl_FragColor.b) / 3.0;
  if (saturation > 0.0) {
    gl_FragColor.rgb += (average - gl_FragColor.rgb) * (1.0 - 1.0 / (1.001 - saturation));
  } else {
    gl_FragColor.rgb += (average - gl_FragColor.rgb) * (-saturation);
  }

}
'''
};

Map kaleidoShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'sides': new Uniform.float(6.0),
    'angle': new Uniform.float(0.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform float sides;
uniform float angle;

varying vec2 vUv;

void main() {

  vec2 p = vUv - 0.5;
  float r = length(p);
  float a = atan(p.y, p.x) + angle;
  float tau = 2. * 3.1416 ;
  a = mod(a, tau/sides);
  a = abs(a - tau/sides/2.) ;
  p = r * vec2(cos(a), sin(a));
  vec4 color = texture2D(tDiffuse, p + 0.5);
  gl_FragColor = color;

}
'''
};

Map luminosityShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture()
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;

varying vec2 vUv;

void main() {

  vec4 texel = texture2D(tDiffuse, vUv);

  vec3 luma = vec3(0.299, 0.587, 0.114);

  float v = dot(texel.xyz, luma);

  gl_FragColor = vec4(v, v, v, texel.w);

}
'''
};

Map mirrorShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'side': new Uniform.int(1)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform int side;

varying vec2 vUv;

void main() {

  vec2 p = vUv;
  if (side == 0){
    if (p.x > 0.5) p.x = 1.0 - p.x;
  }else if (side == 1){
    if (p.x < 0.5) p.x = 1.0 - p.x;
  }else if (side == 2){
    if (p.y < 0.5) p.y = 1.0 - p.y;
  }else if (side == 3){
    if (p.y > 0.5) p.y = 1.0 - p.y;
  }
  vec4 color = texture2D(tDiffuse, p);
  gl_FragColor = color;

}
'''
};

Map normalDisplacementShader = {
  'uniforms': UniformsUtils.merge([
    UniformsLib['fog'],
    UniformsLib['lights'],
    UniformsLib['shadowmap'], {
      'enableAO': new Uniform.int(0),
      'enableDiffuse': new Uniform.int(0),
      'enableSpecular': new Uniform.int(0),
      'enableReflection': new Uniform.int(0),
      'enableDisplacement': new Uniform.int(0),

      'tDisplacement': new Uniform.texture(), // must go first as this is vertex texture
      'tDiffuse': new Uniform.texture(),
      'tCube': new Uniform.texture(),
      'tNormal': new Uniform.texture(),
      'tSpecular': new Uniform.texture(),
      'tAO': new Uniform.texture(),

      'uNormalScale': new Uniform.vector2(1.0, 1.0),

      'uDisplacementBias': new Uniform.float(0.0),
      'uDisplacementScale': new Uniform.float(1.0),

      'diffuse': new Uniform.color(0xffffff),
      'specular': new Uniform.color(0x111111),
      'shininess': new Uniform.float(30.0),
      'opacity': new Uniform.float(1.0),

      'refractionRatio': new Uniform.float(0.98),
      'reflectivity': new Uniform.float(0.5),

      'uOffset': new Uniform.vector2(0.0, 0.0),
      'uRepeat': new Uniform.vector2(1.0, 1.0),

      'wrapRGB': new Uniform.vector3(1.0, 1.0, 1.0)
    }]),
  'vertexShader': '''
attribute vec4 tangent;

uniform vec2 uOffset;
uniform vec2 uRepeat;

uniform bool enableDisplacement;

#ifdef VERTEX_TEXTURES

 uniform sampler2D tDisplacement;
 uniform float uDisplacementScale;
 uniform float uDisplacementBias;

#endif

varying vec3 vTangent;
varying vec3 vBinormal;
varying vec3 vNormal;
varying vec2 vUv;

varying vec3 vWorldPosition;
varying vec3 vViewPosition;

${ShaderChunk['skinning_pars_vertex']}
${ShaderChunk['shadowmap_pars_vertex']}
${ShaderChunk['logdepthbuf_pars_vertex']}

void main() {

  ${ShaderChunk['skinbase_vertex']}
  ${ShaderChunk['skinnormal_vertex']}

  // normal, tangent and binormal vectors

 #ifdef USE_SKINNING

   vNormal = normalize(normalMatrix * skinnedNormal.xyz);

   vec4 skinnedTangent = skinMatrix * vec4(tangent.xyz, 0.0);
   vTangent = normalize(normalMatrix * skinnedTangent.xyz);

 #else

   vNormal = normalize(normalMatrix * normal);
   vTangent = normalize(normalMatrix * tangent.xyz);

 #endif

 vBinormal = normalize(cross(vNormal, vTangent) * tangent.w);

 vUv = uv * uRepeat + uOffset;

  // displacement mapping

 vec3 displacedPosition;

 #ifdef VERTEX_TEXTURES

   if (enableDisplacement) {

     vec3 dv = texture2D(tDisplacement, uv).xyz;
     float df = uDisplacementScale * dv.x + uDisplacementBias;
     displacedPosition = position + normalize(normal) * df;

   } else {

     #ifdef USE_SKINNING

       vec4 skinVertex = bindMatrix * vec4(position, 1.0);

       vec4 skinned = vec4(0.0);
       skinned += boneMatX * skinVertex * skinWeight.x;
       skinned += boneMatY * skinVertex * skinWeight.y;
       skinned += boneMatZ * skinVertex * skinWeight.z;
       skinned += boneMatW * skinVertex * skinWeight.w;
       skinned  = bindMatrixInverse * skinned;

       displacedPosition = skinned.xyz;

     #else

       displacedPosition = position;

     #endif

   }

 #else

   #ifdef USE_SKINNING

     vec4 skinVertex = bindMatrix * vec4(position, 1.0);

     vec4 skinned = vec4(0.0);
     skinned += boneMatX * skinVertex * skinWeight.x;
     skinned += boneMatY * skinVertex * skinWeight.y;
     skinned += boneMatZ * skinVertex * skinWeight.z;
     skinned += boneMatW * skinVertex * skinWeight.w;
     skinned  = bindMatrixInverse * skinned;

     displacedPosition = skinned.xyz;

   #else

     displacedPosition = position;

   #endif

 #endif

  //

 vec4 mvPosition = modelViewMatrix * vec4(displacedPosition, 1.0);
 vec4 worldPosition = modelMatrix * vec4(displacedPosition, 1.0);

 gl_Position = projectionMatrix * mvPosition;

  ${ShaderChunk['logdepthbuf_vertex']}

  //

 vWorldPosition = worldPosition.xyz;
 vViewPosition = -mvPosition.xyz;

  // shadows

 #ifdef USE_SHADOWMAP

   for(int i = 0; i < MAX_SHADOWS; i ++) {

     vShadowCoord[i] = shadowMatrix[i] * worldPosition;

   }

 #endif

}
''',
  'fragmentShader': '''
uniform vec3 diffuse;
uniform vec3 specular;
uniform float shininess;
uniform float opacity;

uniform bool enableDiffuse;
uniform bool enableSpecular;
uniform bool enableAO;
uniform bool enableReflection;

uniform sampler2D tDiffuse;
uniform sampler2D tNormal;
uniform sampler2D tSpecular;
uniform sampler2D tAO;

uniform samplerCube tCube;

uniform vec2 uNormalScale;

uniform float refractionRatio;
uniform float reflectivity;

varying vec3 vTangent;
varying vec3 vBinormal;
varying vec3 vNormal;
varying vec2 vUv;

uniform vec3 ambientLightColor;

#if MAX_DIR_LIGHTS > 0

 uniform vec3 directionalLightColor[MAX_DIR_LIGHTS];
 uniform vec3 directionalLightDirection[MAX_DIR_LIGHTS];

#endif

#if MAX_HEMI_LIGHTS > 0

 uniform vec3 hemisphereLightSkyColor[MAX_HEMI_LIGHTS];
 uniform vec3 hemisphereLightGroundColor[MAX_HEMI_LIGHTS];
 uniform vec3 hemisphereLightDirection[MAX_HEMI_LIGHTS];

#endif

#if MAX_POINT_LIGHTS > 0

 uniform vec3 pointLightColor[MAX_POINT_LIGHTS];
 uniform vec3 pointLightPosition[MAX_POINT_LIGHTS];
 uniform float pointLightDistance[MAX_POINT_LIGHTS];

#endif

#if MAX_SPOT_LIGHTS > 0

 uniform vec3 spotLightColor[MAX_SPOT_LIGHTS];
 uniform vec3 spotLightPosition[MAX_SPOT_LIGHTS];
 uniform vec3 spotLightDirection[MAX_SPOT_LIGHTS];
 uniform float spotLightAngleCos[MAX_SPOT_LIGHTS];
 uniform float spotLightExponent[MAX_SPOT_LIGHTS];
 uniform float spotLightDistance[MAX_SPOT_LIGHTS];

#endif

#ifdef WRAP_AROUND

 uniform vec3 wrapRGB;

#endif

varying vec3 vWorldPosition;
varying vec3 vViewPosition;

${ShaderChunk['common']}
${ShaderChunk['shadowmap_pars_fragment']}
${ShaderChunk['fog_pars_fragment']}
${ShaderChunk['logdepthbuf_pars_fragment']}

void main() {
  ${ShaderChunk['logdepthbuf_fragment']}

 vec3 outgoingLight = vec3(0.0); // outgoing light does not have an alpha, the surface does
 vec4 diffuseColor = vec4(diffuse, opacity);

 vec3 specularTex = vec3(1.0);

 vec3 normalTex = texture2D(tNormal, vUv).xyz * 2.0 - 1.0;
 normalTex.xy *= uNormalScale;
 normalTex = normalize(normalTex);

 if(enableDiffuse) {

   #ifdef GAMMA_INPUT

     vec4 texelColor = texture2D(tDiffuse, vUv);
     texelColor.xyz *= texelColor.xyz;

     diffuseColor *= texelColor;

   #else

     diffuseColor *= texture2D(tDiffuse, vUv);

   #endif

 }

 if(enableAO) {

   #ifdef GAMMA_INPUT

     vec4 aoColor = texture2D(tAO, vUv);
     aoColor.xyz *= aoColor.xyz;

     diffuseColor.rgb *= aoColor.xyz;

   #else

     diffuseColor.rgb *= texture2D(tAO, vUv).xyz;

   #endif

 }

${ShaderChunk['alphatest_fragment']}

 if(enableSpecular)
   specularTex = texture2D(tSpecular, vUv).xyz;

 mat3 tsb = mat3(normalize(vTangent), normalize(vBinormal), normalize(vNormal));
 vec3 finalNormal = tsb * normalTex;

 #ifdef FLIP_SIDED

   finalNormal = -finalNormal;

 #endif

 vec3 normal = normalize(finalNormal);
 vec3 viewPosition = normalize(vViewPosition);

 vec3 totalDiffuseLight = vec3(0.0);
 vec3 totalSpecularLight = vec3(0.0);

  // point lights

 #if MAX_POINT_LIGHTS > 0

   for (int i = 0; i < MAX_POINT_LIGHTS; i ++) {

     vec4 lPosition = viewMatrix * vec4(pointLightPosition[i], 1.0);
     vec3 pointVector = lPosition.xyz + vViewPosition.xyz;

     float pointDistance = 1.0;
     if (pointLightDistance[i] > 0.0)
       pointDistance = 1.0 - min((length(pointVector) / pointLightDistance[i]), 1.0);

     pointVector = normalize(pointVector);

      // diffuse

     #ifdef WRAP_AROUND

       float pointDiffuseWeightFull = max(dot(normal, pointVector), 0.0);
       float pointDiffuseWeightHalf = max(0.5 * dot(normal, pointVector) + 0.5, 0.0);

       vec3 pointDiffuseWeight = mix(vec3(pointDiffuseWeightFull), vec3(pointDiffuseWeightHalf), wrapRGB);

     #else

       float pointDiffuseWeight = max(dot(normal, pointVector), 0.0);

     #endif

     totalDiffuseLight += pointDistance * pointLightColor[i] * pointDiffuseWeight;

      // specular

     vec3 pointHalfVector = normalize(pointVector + viewPosition);
     float pointDotNormalHalf = max(dot(normal, pointHalfVector), 0.0);
     float pointSpecularWeight = specularTex.r * max(pow(pointDotNormalHalf, shininess), 0.0);

     float specularNormalization = (shininess + 2.0) / 8.0;

     vec3 schlick = specular + vec3(1.0 - specular) * pow(max(1.0 - dot(pointVector, pointHalfVector), 0.0), 5.0);
     totalSpecularLight += schlick * pointLightColor[i] * pointSpecularWeight * pointDiffuseWeight * pointDistance * specularNormalization;

   }

 #endif

  // spot lights

 #if MAX_SPOT_LIGHTS > 0

   for (int i = 0; i < MAX_SPOT_LIGHTS; i ++) {

     vec4 lPosition = viewMatrix * vec4(spotLightPosition[i], 1.0);
     vec3 spotVector = lPosition.xyz + vViewPosition.xyz;

     float spotDistance = 1.0;
     if (spotLightDistance[i] > 0.0)
       spotDistance = 1.0 - min((length(spotVector) / spotLightDistance[i]), 1.0);

     spotVector = normalize(spotVector);

     float spotEffect = dot(spotLightDirection[i], normalize(spotLightPosition[i] - vWorldPosition));

     if (spotEffect > spotLightAngleCos[i]) {

       spotEffect = max(pow(max(spotEffect, 0.0), spotLightExponent[i]), 0.0);

        // diffuse

       #ifdef WRAP_AROUND

         float spotDiffuseWeightFull = max(dot(normal, spotVector), 0.0);
         float spotDiffuseWeightHalf = max(0.5 * dot(normal, spotVector) + 0.5, 0.0);

         vec3 spotDiffuseWeight = mix(vec3(spotDiffuseWeightFull), vec3(spotDiffuseWeightHalf), wrapRGB);

       #else

         float spotDiffuseWeight = max(dot(normal, spotVector), 0.0);

       #endif

       totalDiffuseLight += spotDistance * spotLightColor[i] * spotDiffuseWeight * spotEffect;

        // specular

       vec3 spotHalfVector = normalize(spotVector + viewPosition);
       float spotDotNormalHalf = max(dot(normal, spotHalfVector), 0.0);
       float spotSpecularWeight = specularTex.r * max(pow(spotDotNormalHalf, shininess), 0.0);

       float specularNormalization = (shininess + 2.0) / 8.0;

       vec3 schlick = specular + vec3(1.0 - specular) * pow(max(1.0 - dot(spotVector, spotHalfVector), 0.0), 5.0);
       totalSpecularLight += schlick * spotLightColor[i] * spotSpecularWeight * spotDiffuseWeight * spotDistance * specularNormalization * spotEffect;

     }

   }

 #endif

  // directional lights

 #if MAX_DIR_LIGHTS > 0

   for(int i = 0; i < MAX_DIR_LIGHTS; i++) {

     vec4 lDirection = viewMatrix * vec4(directionalLightDirection[i], 0.0);
     vec3 dirVector = normalize(lDirection.xyz);

      // diffuse

     #ifdef WRAP_AROUND

       float directionalLightWeightingFull = max(dot(normal, dirVector), 0.0);
       float directionalLightWeightingHalf = max(0.5 * dot(normal, dirVector) + 0.5, 0.0);

       vec3 dirDiffuseWeight = mix(vec3(directionalLightWeightingFull), vec3(directionalLightWeightingHalf), wrapRGB);

     #else

       float dirDiffuseWeight = max(dot(normal, dirVector), 0.0);

     #endif

     totalDiffuseLight += directionalLightColor[i] * dirDiffuseWeight;

      // specular

     vec3 dirHalfVector = normalize(dirVector + viewPosition);
     float dirDotNormalHalf = max(dot(normal, dirHalfVector), 0.0);
     float dirSpecularWeight = specularTex.r * max(pow(dirDotNormalHalf, shininess), 0.0);

     float specularNormalization = (shininess + 2.0) / 8.0;

     vec3 schlick = specular + vec3(1.0 - specular) * pow(max(1.0 - dot(dirVector, dirHalfVector), 0.0), 5.0);
     totalSpecularLight += schlick * directionalLightColor[i] * dirSpecularWeight * dirDiffuseWeight * specularNormalization;

   }

 #endif

  // hemisphere lights

 #if MAX_HEMI_LIGHTS > 0

   for(int i = 0; i < MAX_HEMI_LIGHTS; i ++) {

     vec4 lDirection = viewMatrix * vec4(hemisphereLightDirection[i], 0.0);
     vec3 lVector = normalize(lDirection.xyz);

      // diffuse

     float dotProduct = dot(normal, lVector);
     float hemiDiffuseWeight = 0.5 * dotProduct + 0.5;

     vec3 hemiColor = mix(hemisphereLightGroundColor[i], hemisphereLightSkyColor[i], hemiDiffuseWeight);

     totalDiffuseLight += hemiColor;

      // specular (sky light)


     vec3 hemiHalfVectorSky = normalize(lVector + viewPosition);
     float hemiDotNormalHalfSky = 0.5 * dot(normal, hemiHalfVectorSky) + 0.5;
     float hemiSpecularWeightSky = specularTex.r * max(pow(max(hemiDotNormalHalfSky, 0.0), shininess), 0.0);

      // specular (ground light)

     vec3 lVectorGround = -lVector;

     vec3 hemiHalfVectorGround = normalize(lVectorGround + viewPosition);
     float hemiDotNormalHalfGround = 0.5 * dot(normal, hemiHalfVectorGround) + 0.5;
     float hemiSpecularWeightGround = specularTex.r * max(pow(max(hemiDotNormalHalfGround, 0.0), shininess), 0.0);

     float dotProductGround = dot(normal, lVectorGround);

     float specularNormalization = (shininess + 2.0) / 8.0;

     vec3 schlickSky = specular + vec3(1.0 - specular) * pow(max(1.0 - dot(lVector, hemiHalfVectorSky), 0.0), 5.0);
     vec3 schlickGround = specular + vec3(1.0 - specular) * pow(max(1.0 - dot(lVectorGround, hemiHalfVectorGround), 0.0), 5.0);
     totalSpecularLight += hemiColor * specularNormalization * (schlickSky * hemiSpecularWeightSky * max(dotProduct, 0.0) + schlickGround * hemiSpecularWeightGround * max(dotProductGround, 0.0));
   }

 #endif

 #ifdef METAL

   outgoingLight += diffuseColor.xyz * (totalDiffuseLight + ambientLightColor + totalSpecularLight);

 #else

   outgoingLight += diffuseColor.xyz * (totalDiffuseLight + ambientLightColor) + totalSpecularLight;

 #endif

 if (enableReflection) {

   vec3 cameraToVertex = normalize(vWorldPosition - cameraPosition);

   vec3 worldNormal = inverseTransformDirection(normal, viewMatrix);

   #ifdef ENVMAP_MODE_REFLECTION

     vec3 vReflect = reflect(cameraToVertex, worldNormal);

   #else

     vec3 vReflect = refract(cameraToVertex, worldNormal, refractionRatio);

   #endif

   vec4 cubeColor = textureCube(tCube, vec3(-vReflect.x, vReflect.yz));

   #ifdef GAMMA_INPUT

     cubeColor.xyz *= cubeColor.xyz;

   #endif

   outgoingLight = mix(outgoingLight, cubeColor.xyz, specularTex.r * reflectivity);

 }

  ${ShaderChunk['shadowmap_fragment']}
  ${ShaderChunk['linear_to_gamma_fragment']}
  ${ShaderChunk['fog_fragment']}

 gl_FragColor = vec4(outgoingLight, diffuseColor.a); // TODO, this should be pre-multiplied to allow for bright highlights on very transparent objects

}
'''
};

Map normalMapShader = {
  'uniforms': {
    'heightMap': new Uniform.texture(),
    'resolution': new Uniform.vector2(512.0, 512.0),
    'scale': new Uniform.vector2(1.0, 1.0),
    'height': new Uniform.float(0.05)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float height;
uniform vec2 resolution;
uniform sampler2D heightMap;

varying vec2 vUv;

void main() {
  float val = texture2D(heightMap, vUv).x;

  float valU = texture2D(heightMap, vUv + vec2(1.0 / resolution.x, 0.0)).x;
  float valV = texture2D(heightMap, vUv + vec2(0.0, 1.0 / resolution.y)).x;

  gl_FragColor = vec4((0.5 * normalize(vec3(val - valU, val - valV, height )) + 0.5), 1.0);
}
'''
};

Map oceanSimVertex = {
  'varying': {
    'vUV': {'type': 'v2'}
  },
  'vertexShader': '''
varying vec2 vUV;

void main (void) {
  vUV = position.xy * 0.5 + 0.5;
  gl_Position = vec4(position, 1.0);
}
'''
};

Map oceanSubtransform = {
  'uniforms': {
    'u_input': new Uniform.texture(),
    'u_transformSize': new Uniform.float(512.0),
    'u_subtransformSize': new Uniform.float(250.0)
  },
  'varying': {
    'vUV': {'type': 'v2'}
  },
  'fragmentShader': '''
//GPU FFT using a Stockham formulation
precision highp float;

const float PI = 3.14159265359;

uniform sampler2D u_input;
uniform float u_transformSize;
uniform float u_subtransformSize;

varying vec2 vUV;

vec2 multiplyComplex (vec2 a, vec2 b) {
  return vec2(a[0] * b[0] - a[1] * b[1], a[1] * b[0] + a[0] * b[1]);
}

void main (void) {
  #ifdef HORIZONTAL
  float index = vUV.x * u_transformSize - 0.5;
  #else
  float index = vUV.y * u_transformSize - 0.5;
  #endif

  float evenIndex = floor(index / u_subtransformSize) * (u_subtransformSize * 0.5) + mod(index, u_subtransformSize * 0.5);

  //transform two complex sequences simultaneously
  #ifdef HORIZONTAL
  vec4 even = texture2D(u_input, vec2(evenIndex + 0.5, gl_FragCoord.y) / u_transformSize).rgba;
  vec4 odd = texture2D(u_input, vec2(evenIndex + u_transformSize * 0.5 + 0.5, gl_FragCoord.y) / u_transformSize).rgba;
  #else
  vec4 even = texture2D(u_input, vec2(gl_FragCoord.x, evenIndex + 0.5) / u_transformSize).rgba;
  vec4 odd = texture2D(u_input, vec2(gl_FragCoord.x, evenIndex + u_transformSize * 0.5 + 0.5) / u_transformSize).rgba;
  #endif

  float twiddleArgument = -2.0 * PI * (index / u_subtransformSize);
  vec2 twiddle = vec2(cos(twiddleArgument), sin(twiddleArgument));

  vec2 outputA = even.xy + multiplyComplex(twiddle, odd.xy);
  vec2 outputB = even.zw + multiplyComplex(twiddle, odd.zw);

  gl_FragColor = vec4(outputA, outputB);
}
'''
};

Map oceanInitialSpectrum = {
  'uniforms': {
    'u_wind': new Uniform.vector2(10.0, 10.0),
    'u_resolution': new Uniform.float(512.0),
    'u_size': new Uniform.float(250.0)
  },
  'fragmentShader': '''
precision highp float;

const float PI = 3.14159265359;
const float G = 9.81;
const float KM = 370.0;
const float CM = 0.23;

uniform vec2 u_wind;
uniform float u_resolution;
uniform float u_size;

float square (float x) {
  return x * x;
}

float omega (float k) {
  return sqrt(G * k * (1.0 + square(k / KM)));
}

float tanh (float x) {
  return (1.0 - exp(-2.0 * x)) / (1.0 + exp(-2.0 * x));
}

void main (void) {
  vec2 coordinates = gl_FragCoord.xy - 0.5;
  
  float n = (coordinates.x < u_resolution * 0.5) ? coordinates.x : coordinates.x - u_resolution;
  float m = (coordinates.y < u_resolution * 0.5) ? coordinates.y : coordinates.y - u_resolution;
  
  vec2 K = (2.0 * PI * vec2(n, m)) / u_size;
  float k = length(K);
  
  float l_wind = length(u_wind);

  float Omega = 0.84;
  float kp = G * square(Omega / l_wind);

  float c = omega(k) / k;
  float cp = omega(kp) / kp;

  float Lpm = exp(-1.25 * square(kp / k));
  float gamma = 1.7;
  float sigma = 0.08 * (1.0 + 4.0 * pow(Omega, -3.0));
  float Gamma = exp(-square(sqrt(k / kp) - 1.0) / 2.0 * square(sigma));
  float Jp = pow(gamma, Gamma);
  float Fp = Lpm * Jp * exp(-Omega / sqrt(10.0) * (sqrt(k / kp) - 1.0));
  float alphap = 0.006 * sqrt(Omega);
  float Bl = 0.5 * alphap * cp / c * Fp;

  float z0 = 0.000037 * square(l_wind) / G * pow(l_wind / cp, 0.9);
  float uStar = 0.41 * l_wind / log(10.0 / z0);
  float alpham = 0.01 * ((uStar < CM) ? (1.0 + log(uStar / CM)) : (1.0 + 3.0 * log(uStar / CM)));
  float Fm = exp(-0.25 * square(k / KM - 1.0));
  float Bh = 0.5 * alpham * CM / c * Fm * Lpm;

  float a0 = log(2.0) / 4.0;
  float am = 0.13 * uStar / CM;
  float Delta = tanh(a0 + 4.0 * pow(c / cp, 2.5) + am * pow(CM / c, 2.5));

  float cosPhi = dot(normalize(u_wind), normalize(K));

  float S = (1.0 / (2.0 * PI)) * pow(k, -4.0) * (Bl + Bh) * (1.0 + Delta * (2.0 * cosPhi * cosPhi - 1.0));

  float dk = 2.0 * PI / u_size;
  float h = sqrt(S / 2.0) * dk;

  if (K.x == 0.0 && K.y == 0.0) {
    h = 0.0; //no DC term
  }
  gl_FragColor = vec4(h, 0.0, 0.0, 0.0);
}
'''
};

Map oceanPhase = {
  'uniforms': {
    'u_phases': new Uniform.texture(),
    'u_deltaTime': new Uniform.float(),
    'u_resolution': new Uniform.float(),
    'u_size': new Uniform.float()
  },
  'varying': {
    'vUV': {'type': 'v2'}
  },
  'fragmentShader': '''
precision highp float;

const float PI = 3.14159265359;
const float G = 9.81;
const float KM = 370.0;

varying vec2 vUV;

uniform sampler2D u_phases;
uniform float u_deltaTime;
uniform float u_resolution;
uniform float u_size;

float omega (float k) {
  return sqrt(G * k * (1.0 + k * k / KM * KM));
}

void main (void) {
  float deltaTime = 1.0 / 60.0;
  vec2 coordinates = gl_FragCoord.xy - 0.5;
  float n = (coordinates.x < u_resolution * 0.5) ? coordinates.x : coordinates.x - u_resolution;
  float m = (coordinates.y < u_resolution * 0.5) ? coordinates.y : coordinates.y - u_resolution;
  vec2 waveVector = (2.0 * PI * vec2(n, m)) / u_size;

  float phase = texture2D(u_phases, vUV).r;
  float deltaPhase = omega(length(waveVector)) * u_deltaTime;
  phase = mod(phase + deltaPhase, 2.0 * PI);

  gl_FragColor = vec4(phase, 0.0, 0.0, 0.0);
}
'''
};

Map oceanSpectrum = {
  'uniforms': {
    'u_size': new Uniform.float(),
    'u_resolution': new Uniform.float(),
    'u_choppiness': new Uniform.float(),
    'u_phases': new Uniform.texture(),
    'u_initialSpectrum': new Uniform.texture()
  },
  'varying': {
    'vUV': {'type': 'v2'}
  },
  'fragmentShader': '''
precision highp float;

const float PI = 3.141592659;
const float G = 9.81;
const float KM = 370.0;

varying vec2 vUV;

uniform float u_size;
uniform float u_resolution;
uniform float u_choppiness;
uniform sampler2D u_phases;
uniform sampler2D u_initialSpectrum;

vec2 multiplyComplex (vec2 a, vec2 b) {
  return vec2(a[0] * b[0] - a[1] * b[1], a[1] * b[0] + a[0] * b[1]);
}

vec2 multiplyByI (vec2 z) {
  return vec2(-z[1], z[0]);
}

float omega (float k) {
  return sqrt(G * k * (1.0 + k * k / KM * KM));
}

void main (void) {
  vec2 coordinates = gl_FragCoord.xy - 0.5;
  float n = (coordinates.x < u_resolution * 0.5) ? coordinates.x : coordinates.x - u_resolution;
  float m = (coordinates.y < u_resolution * 0.5) ? coordinates.y : coordinates.y - u_resolution;
  vec2 waveVector = (2.0 * PI * vec2(n, m)) / u_size;

  float phase = texture2D(u_phases, vUV).r;
  vec2 phaseVector = vec2(cos(phase), sin(phase));

  vec2 h0 = texture2D(u_initialSpectrum, vUV).rg;
  vec2 h0Star = texture2D(u_initialSpectrum, vec2(1.0 - vUV + 1.0 / u_resolution)).rg;
  h0Star.y *= -1.0;

  vec2 h = multiplyComplex(h0, phaseVector) + multiplyComplex(h0Star, vec2(phaseVector.x, -phaseVector.y));

  vec2 hX = -multiplyByI(h * (waveVector.x / length(waveVector))) * u_choppiness;
  vec2 hZ = -multiplyByI(h * (waveVector.y / length(waveVector))) * u_choppiness;

  //no DC term
  if (waveVector.x == 0.0 && waveVector.y == 0.0) {
    h = vec2(0.0);
    hX = vec2(0.0);
    hZ = vec2(0.0);
  }

  gl_FragColor = vec4(hX + multiplyByI(h), hZ);
}
'''
};

Map oceanNormals = {
  'uniforms': {
    'u_displacementMap': new Uniform.texture(),
    'u_resolution': new Uniform.float(),
    'u_size': new Uniform.float(),
  },
  'varying': {
    'vUV': {'type': 'v2'}
  },
  'fragmentShader': '''
precision highp float;

varying vec2 vUV;

uniform sampler2D u_displacementMap;
uniform float u_resolution;
uniform float u_size;

void main (void) {
  float texel = 1.0 / u_resolution;
  float texelSize = u_size / u_resolution;

  vec3 center = texture2D(u_displacementMap, vUV).rgb;
  vec3 right = vec3(texelSize, 0.0, 0.0) + texture2D(u_displacementMap, vUV + vec2(texel, 0.0)).rgb - center;
  vec3 left = vec3(-texelSize, 0.0, 0.0) + texture2D(u_displacementMap, vUV + vec2(-texel, 0.0)).rgb - center;
  vec3 top = vec3(0.0, 0.0, -texelSize) + texture2D(u_displacementMap, vUV + vec2(0.0, -texel)).rgb - center;
  vec3 bottom = vec3(0.0, 0.0, texelSize) + texture2D(u_displacementMap, vUV + vec2(0.0, texel)).rgb - center;

  vec3 topRight = cross(right, top);
  vec3 topLeft = cross(top, left);
  vec3 bottomLeft = cross(left, bottom);
  vec3 bottomRight = cross(bottom, right);

  gl_FragColor = vec4(normalize(topRight + topLeft + bottomLeft + bottomRight), 1.0);
}
'''
};

Map oceanMain = {
  'uniforms': {
    'u_displacementMap': new Uniform.texture(),
    'u_normalMap': new Uniform.texture(),
    'u_geometrySize': new Uniform.float(),
    'u_size': new Uniform.float(),
    'u_projectionMatrix': new Uniform.matrix4(null),
    'u_viewMatrix': new Uniform.matrix4(null),
    'u_cameraPosition': new Uniform.vector3(0.0, 0.0, 0.0),
    'u_skyColor': new Uniform.vector3(0.0, 0.0, 0.0),
    'u_oceanColor': new Uniform.vector3(0.0, 0.0, 0.0),
    'u_sunDirection': new Uniform.vector3(0.0, 0.0, 0.0),
    'u_exposure': new Uniform.float(),
  },
  'varying': {
    'vPos': {'type': 'v3'},
    'vUV': {'type': 'v2'}
  },
  'vertexShader': '''
precision highp float;

varying vec3 vPos;
varying vec2 vUV;

uniform mat4 u_projectionMatrix;
uniform mat4 u_viewMatrix;
uniform float u_size;
uniform float u_geometrySize;
uniform sampler2D u_displacementMap;

void main (void) {
  vec3 newPos = position + texture2D(u_displacementMap, uv).rgb * (u_geometrySize / u_size);
  vPos = newPos;
  vUV = uv;
  gl_Position = u_projectionMatrix * u_viewMatrix * vec4(newPos, 1.0);
}
''',
  'fragmentShader': '''
precision highp float;

varying vec3 vPos;
varying vec2 vUV;

uniform sampler2D u_displacementMap;
uniform sampler2D u_normalMap;
uniform vec3 u_cameraPosition;
uniform vec3 u_oceanColor;
uniform vec3 u_skyColor;
uniform vec3 u_sunDirection;
uniform float u_exposure;

vec3 hdr (vec3 color, float exposure) {
  return 1.0 - exp(-color * exposure);
}

void main (void) {
  vec3 normal = texture2D(u_normalMap, vUV).rgb;

  vec3 view = normalize(u_cameraPosition - vPos);
  float fresnel = 0.02 + 0.98 * pow(1.0 - dot(normal, view), 5.0);
  vec3 sky = fresnel * u_skyColor;

  float diffuse = clamp(dot(normal, normalize(u_sunDirection)), 0.0, 1.0);
  vec3 water = (1.0 - fresnel) * u_oceanColor * u_skyColor * diffuse;

  vec3 color = sky + water;

  gl_FragColor = vec4(hdr(color, u_exposure), 1.0);
}
'''
};

Map parallaxShader = {
  'modes': {
    'none':  'NO_PARALLAX',
    'basic': 'USE_BASIC_PARALLAX',
    'steep': 'USE_STEEP_PARALLAX',
    'occlusion': 'USE_OCLUSION_PARALLAX', // a.k.a. POM
    'relief': 'USE_RELIEF_PARALLAX',
  },
  'uniforms': {
    'bumpMap': new Uniform.texture(),
    'map': new Uniform.texture(),
    'parallaxScale': new Uniform.float(),
    'parallaxMinLayers': new Uniform.float(),
    'parallaxMaxLayers': new Uniform.float(),
  },
  'vertexShader': '''
varying vec2 vUv;
varying vec3 vViewPosition;
varying vec3 vNormal;

void main() {
  vUv = uv;
  vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
  vViewPosition = -mvPosition.xyz;
  vNormal = normalize(normalMatrix * normal);
  gl_Position = projectionMatrix * mvPosition;
}
''',
  'fragmentShader': '''
uniform sampler2D bumpMap;
uniform sampler2D map;

uniform float parallaxScale;
uniform float parallaxMinLayers;
uniform float parallaxMaxLayers;

varying vec2 vUv;
varying vec3 vViewPosition;
varying vec3 vNormal;

#ifdef USE_BASIC_PARALLAX

  vec2 parallaxMap(in vec3 V) {

    float initialHeight = texture2D(bumpMap, vUv).r;

    // No Offset Limitting: messy, floating output at grazing angles.
    //vec2 texCoordOffset = parallaxScale * V.xy / V.z * initialHeight;

    // Offset Limiting
    vec2 texCoordOffset = parallaxScale * V.xy * initialHeight;
    return vUv - texCoordOffset;

  }

#else

  vec2 parallaxMap(in vec3 V) {

    // Determine number of layers from angle between V and N
    float numLayers = mix(parallaxMaxLayers, parallaxMinLayers, abs(dot(vec3(0.0, 0.0, 1.0), V)));

    float layerHeight = 1.0 / numLayers;
    float currentLayerHeight = 0.0;
    // Shift of texture coordinates for each iteration
    vec2 dtex = parallaxScale * V.xy / V.z / numLayers;

    vec2 currentTextureCoords = vUv;

    float heightFromTexture = texture2D(bumpMap, currentTextureCoords).r;

    // while (heightFromTexture > currentLayerHeight)
    for (int i = 0; i == 0; i += 0) {
      if (heightFromTexture <= currentLayerHeight) {
        break;
      }
      currentLayerHeight += layerHeight;
      // Shift texture coordinates along vector V
      currentTextureCoords -= dtex;
      heightFromTexture = texture2D(bumpMap, currentTextureCoords).r;
    }

    #ifdef USE_STEEP_PARALLAX

      return currentTextureCoords;

    #elif defined(USE_RELIEF_PARALLAX)

      vec2 deltaTexCoord = dtex / 2.0;
      float deltaHeight = layerHeight / 2.0;

      // Return to the mid point of previous layer
      currentTextureCoords += deltaTexCoord;
      currentLayerHeight -= deltaHeight;

      // Binary search to increase precision of Steep Parallax Mapping
      const int numSearches = 5;
      for (int i = 0; i < numSearches; i += 1) {

        deltaTexCoord /= 2.0;
        deltaHeight /= 2.0;
        heightFromTexture = texture2D(bumpMap, currentTextureCoords).r;
        // Shift along or against vector V
        if(heightFromTexture > currentLayerHeight) { // Below the surface

          currentTextureCoords -= deltaTexCoord;
          currentLayerHeight += deltaHeight;

        } else { // above the surface

          currentTextureCoords += deltaTexCoord;
          currentLayerHeight -= deltaHeight;

        }

      }
      return currentTextureCoords;

    #elif defined(USE_OCLUSION_PARALLAX)

      vec2 prevTCoords = currentTextureCoords + dtex;

      // Heights for linear interpolation
      float nextH = heightFromTexture - currentLayerHeight;
      float prevH = texture2D(bumpMap, prevTCoords).r - currentLayerHeight + layerHeight;

      // Proportions for linear interpolation
      float weight = nextH / (nextH - prevH);

      // Interpolation of texture coordinates
      return prevTCoords * weight + currentTextureCoords * (1.0 - weight);

    #else // NO_PARALLAX

      return vUv;

    #endif

  }
#endif

vec2 perturbUv(vec3 surfPosition, vec3 surfNormal, vec3 viewPosition) {

  vec2 texDx = dFdx(vUv);
  vec2 texDy = dFdy(vUv);

  vec3 vSigmaX = dFdx(surfPosition);
  vec3 vSigmaY = dFdy(surfPosition);
  vec3 vR1 = cross(vSigmaY, surfNormal);
  vec3 vR2 = cross(surfNormal, vSigmaX);
  float fDet = dot(vSigmaX, vR1);

  vec2 vProjVscr = (1.0 / fDet) * vec2(dot(vR1, viewPosition), dot(vR2, viewPosition));
  vec3 vProjVtex;
  vProjVtex.xy = texDx * vProjVscr.x + texDy * vProjVscr.y;
  vProjVtex.z = dot(surfNormal, viewPosition);

  return parallaxMap(vProjVtex);
}

void main() {
  vec2 mapUv = perturbUv(-vViewPosition, normalize(vNormal), normalize(vViewPosition));
  gl_FragColor = texture2D(map, mapUv);
}
'''
};

Map rgbShiftShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'amount': new Uniform.float(0.005),
    'angle': new Uniform.float(0.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform float amount;
uniform float angle;

varying vec2 vUv;

void main() {
  vec2 offset = amount * vec2(cos(angle), sin(angle));
  vec4 cr = texture2D(tDiffuse, vUv + offset);
  vec4 cga = texture2D(tDiffuse, vUv);
  vec4 cb = texture2D(tDiffuse, vUv - offset);
  gl_FragColor = vec4(cr.r, cga.g, cb.b, cga.a);
}
'''
};

Map ssaoShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'tDepth': new Uniform.texture(),
    'size': new Uniform.vector2(512.0, 512.0),
    'cameraNear': new Uniform.float(1.0),
    'cameraFar': new Uniform.float(100.0),
    'onlyAO': new Uniform.int(0),
    'aoClamp': new Uniform.float(0.5),
    'lumInfluence': new Uniform.float(0.5)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float cameraNear;
uniform float cameraFar;

uniform bool onlyAO;      // use only ambient occlusion pass?

uniform vec2 size;        // texture width, height
uniform float aoClamp;    // depth clamp - reduces haloing at screen edges

uniform float lumInfluence;  // how much luminance affects occlusion

uniform sampler2D tDiffuse;
uniform sampler2D tDepth;

varying vec2 vUv;

// #define PI 3.14159265
#define DL 2.399963229728653  // PI * (3.0 - sqrt(5.0))
#define EULER 2.718281828459045

// helpers

float width = size.x;   // texture width
float height = size.y;  // texture height

float cameraFarPlusNear = cameraFar + cameraNear;
float cameraFarMinusNear = cameraFar - cameraNear;
float cameraCoef = 2.0 * cameraNear;

// user variables

const int samples = 8;     // ao sample count
const float radius = 5.0;  // ao radius

const bool useNoise = false;      // use noise instead of pattern for sample dithering
const float noiseAmount = 0.0003; // dithering amount

const float diffArea = 0.4;   // self-shadowing reduction
const float gDisplace = 0.4;  // gauss bell center


// RGBA depth

float unpackDepth(const in vec4 rgba_depth) {

  const vec4 bit_shift = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
  float depth = dot(rgba_depth, bit_shift);
  return depth;

}

// generating noise / pattern texture for dithering

vec2 rand(const vec2 coord) {

  vec2 noise;

  if (useNoise) {

    float nx = dot (coord, vec2(12.9898, 78.233));
    float ny = dot (coord, vec2(12.9898, 78.233) * 2.0);

    noise = clamp(fract (43758.5453 * sin(vec2(nx, ny))), 0.0, 1.0);

  } else {

    float ff = fract(1.0 - coord.s * (width / 2.0));
    float gg = fract(coord.t * (height / 2.0));

    noise = vec2(0.25, 0.75) * vec2(ff) + vec2(0.75, 0.25) * gg;

  }

  return (noise * 2.0  - 1.0) * noiseAmount;

}

float readDepth(const in vec2 coord) {

  // return (2.0 * cameraNear) / (cameraFar + cameraNear - unpackDepth(texture2D(tDepth, coord)) * (cameraFar - cameraNear));
  return cameraCoef / (cameraFarPlusNear - unpackDepth(texture2D(tDepth, coord)) * cameraFarMinusNear);


}

float compareDepths(const in float depth1, const in float depth2, inout int far) {

  float garea = 2.0;                         // gauss bell width
  float diff = (depth1 - depth2) * 100.0;  // depth difference (0-100)

  // reduce left bell width to avoid self-shadowing

  if (diff < gDisplace) {

    garea = diffArea;

  } else {

    far = 1;

  }

  float dd = diff - gDisplace;
  float gauss = pow(EULER, -2.0 * dd * dd / (garea * garea));
  return gauss;

}

float calcAO(float depth, float dw, float dh) {

  float dd = radius - depth * radius;
  vec2 vv = vec2(dw, dh);

  vec2 coord1 = vUv + dd * vv;
  vec2 coord2 = vUv - dd * vv;

  float temp1 = 0.0;
  float temp2 = 0.0;

  int far = 0;
  temp1 = compareDepths(depth, readDepth(coord1), far);

  // DEPTH EXTRAPOLATION

  if (far > 0) {

    temp2 = compareDepths(readDepth(coord2), depth, far);
    temp1 += (1.0 - temp1) * temp2;

  }

  return temp1;

}

void main() {

  vec2 noise = rand(vUv);
  float depth = readDepth(vUv);

  float tt = clamp(depth, aoClamp, 1.0);

  float w = (1.0 / width)  / tt + (noise.x * (1.0 - noise.x));
  float h = (1.0 / height) / tt + (noise.y * (1.0 - noise.y));

  float ao = 0.0;

  float dz = 1.0 / float(samples);
  float z = 1.0 - dz / 2.0;
  float l = 0.0;

  for (int i = 0; i <= samples; i ++) {

    float r = sqrt(1.0 - z);

    float pw = cos(l) * r;
    float ph = sin(l) * r;
    ao += calcAO(depth, pw * w, ph * h);
    z = z - dz;
    l = l + DL;

  }

  ao /= float(samples);
  ao = 1.0 - ao;

  vec3 color = texture2D(tDiffuse, vUv).rgb;

  vec3 lumcoeff = vec3(0.299, 0.587, 0.114);
  float lum = dot(color.rgb, lumcoeff);
  vec3 luminance = vec3(lum);

  vec3 final = vec3(color * mix(vec3(ao), vec3(1.0), luminance * lumInfluence));  // mix(color * ao, white, luminance)

  if (onlyAO) {

    final = vec3(mix(vec3(ao), vec3(1.0), luminance * lumInfluence));  // ambient occlusion only

  }

  gl_FragColor = vec4(final, 1.0);
}
'''
};

Map sepiaShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'amount': new Uniform.float(1.0),
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float amount;

uniform sampler2D tDiffuse;

varying vec2 vUv;

void main() {
  vec4 color = texture2D(tDiffuse, vUv);
  vec3 c = color.rgb;

  color.r = dot(c, vec3(1.0 - 0.607 * amount, 0.769 * amount, 0.189 * amount));
  color.g = dot(c, vec3(0.349 * amount, 1.0 - 0.314 * amount, 0.168 * amount));
  color.b = dot(c, vec3(0.272 * amount, 0.534 * amount, 1.0 - 0.869 * amount));

  gl_FragColor = vec4(min(vec3(1.0), color.rgb), color.a);
}
'''
};

Map technicolorShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture()
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
varying vec2 vUv;

void main() {
  vec4 tex = texture2D(tDiffuse, vec2(vUv.x, vUv.y));
  vec4 newTex = vec4(tex.r, (tex.g + tex.b) * .5, (tex.g + tex.b) * .5, 1.0);

  gl_FragColor = newTex;
}
'''
};

Map toneMapShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'averageLuminance': new Uniform.float(1.0),
    'luminanceMap': new Uniform.texture(),
    'maxLuminance': new Uniform.float(16.0),
    'middleGrey': new Uniform.float(0.6)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;

varying vec2 vUv;

uniform float middleGrey;
uniform float maxLuminance;
#ifdef ADAPTED_LUMINANCE
  uniform sampler2D luminanceMap;
#else
  uniform float averageLuminance;
#endif

const vec3 LUM_CONVERT = vec3(0.299, 0.587, 0.114);

vec3 ToneMap(vec3 vColor) {
  #ifdef ADAPTED_LUMINANCE
    // Get the calculated average luminance 
    float fLumAvg = texture2D(luminanceMap, vec2(0.5, 0.5)).r;
  #else
    float fLumAvg = averageLuminance;
  #endif
  
  // Calculate the luminance of the current pixel
  float fLumPixel = dot(vColor, LUM_CONVERT);

  // Apply the modified operator (Eq. 4)
  float fLumScaled = (fLumPixel * middleGrey) / fLumAvg;

  float fLumCompressed = (fLumScaled * (1.0 + (fLumScaled / (maxLuminance * maxLuminance)))) / (1.0 + fLumScaled);
  return fLumCompressed * vColor;
}

void main() {
  vec4 texel = texture2D(tDiffuse, vUv);
  
  gl_FragColor = vec4(ToneMap(texel.xyz), texel.w);
}
'''
};

Map triangleBlurShader = {
  'uniforms': {
    'texture': new Uniform.texture(),
    'delta': new Uniform.vector2(1.0, 1.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
#define ITERATIONS 10.0

uniform sampler2D texture;
uniform vec2 delta;

varying vec2 vUv;

float random(vec3 scale, float seed) {
  // use the fragment position for a different seed per-pixel

  return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}

void main() {
  vec4 color = vec4(0.0);

  float total = 0.0;

  // randomize the lookup values to hide the fixed number of samples

  float offset = random(vec3(12.9898, 78.233, 151.7182), 0.0);

  for (float t = -ITERATIONS; t <= ITERATIONS; t ++) {

    float percent = (t + offset - 0.5) / ITERATIONS;
    float weight = 1.0 - abs(percent);

    color += texture2D(texture, vUv + delta * percent) * weight;
    total += weight;
  }

  gl_FragColor = color / total;
}
'''
};

Map unpackDepthRGBAShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'opacity': new Uniform.float(1.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float opacity;

uniform sampler2D tDiffuse;

varying vec2 vUv;

// RGBA depth

float unpackDepth(const in vec4 rgba_depth) {
  const vec4 bit_shift = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
  float depth = dot(rgba_depth, bit_shift);
  return depth;
}

void main() {
  float depth = 1.0 - unpackDepth(texture2D(tDiffuse, vUv));
  gl_FragColor = opacity * vec4(vec3(depth), 1.0);
}
'''
};

Map verticalBlurShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'v': new Uniform.float(1.0 / 512.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform float v;

varying vec2 vUv;

void main() {
  vec4 sum = vec4(0.0);

  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 4.0 * v)) * 0.051;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 3.0 * v)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 2.0 * v)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 1.0 * v)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y)) * 0.1633;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 1.0 * v)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 2.0 * v)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 3.0 * v)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 4.0 * v)) * 0.051;

  gl_FragColor = sum;
}
'''
};

Map verticalTiltShiftShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'v': new Uniform.float(1.0 / 512.0),
    'r': new Uniform.float(0.35)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform sampler2D tDiffuse;
uniform float v;
uniform float r;

varying vec2 vUv;

void main() {
  vec4 sum = vec4(0.0);

  float vv = v * abs(r - vUv.y);

  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 4.0 * vv)) * 0.051;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 3.0 * vv)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 2.0 * vv)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y - 1.0 * vv)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y)) * 0.1633;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 1.0 * vv)) * 0.1531;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 2.0 * vv)) * 0.12245;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 3.0 * vv)) * 0.0918;
  sum += texture2D(tDiffuse, vec2(vUv.x, vUv.y + 4.0 * vv)) * 0.051;

  gl_FragColor = sum;
}
'''
};

Map vignetteShader = {
  'uniforms': {
    'tDiffuse': new Uniform.texture(),
    'offset': new Uniform.float(1.0),
    'darkness': new Uniform.float(1.0)
  },
  'vertexShader': '''
varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
''',
  'fragmentShader': '''
uniform float offset;
uniform float darkness;

uniform sampler2D tDiffuse;

varying vec2 vUv;

void main() {
  // Eskil's vignette

  vec4 texel = texture2D(tDiffuse, vUv);
  vec2 uv = (vUv - vec2(0.5)) * vec2(offset);
  gl_FragColor = vec4(mix(texel.rgb, vec3(1.0 - darkness), dot(uv, uv)), texel.a);

  /*
  // alternative version from glfx.js
  // this one makes more dusty look (as opposed to burned)
  vec4 color = texture2D(tDiffuse, vUv);
  float dist = distance(vUv, vec2(0.5));
  color.rgb *= smoothstep(0.8, offset * 0.799, dist *(darkness + offset));
  gl_FragColor = color;
  */
}
'''
};
