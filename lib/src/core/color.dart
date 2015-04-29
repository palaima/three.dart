/*
 * @author mr.doob / http://mrdoob.com/
 *
 * Ported to Dart from JS by:
 * @author rob silverton / http://www.unwrong.com/
 *
 * based on r70.
 */

part of three;

/// Represents a color.
class Color {
  Float32List storage = new Float32List(3);

  /// Red channel value represented as a double between 0.0 and 1.0.
  double get r => storage[0];
  set r(double v) {
    storage[0] = v;
  }

  /// Green channel value represented as a double between 0.0 and 1.0.
  double get g => storage[1];
  set g(double v) {
    storage[1] = v;
  }

  /// Blue channel value represented as a double between 0.0 and 1.0.
  double get b => storage[2];
  set b(double v) {
    storage[2] = v;
  }

  /// Red channel value represented as an integer between 0 and 255.
  int get rr => (storage[0] * 255).floor();
  set rr(int v) {
    storage[0] = (1 / 255) * v;
  }

  /// Green channel value represented as an integer between 0 and 255.
  int get gg => (storage[1] * 255).floor();
  set gg(int v) {
    storage[1] = (1 / 255) * v;
  }

  /// Blue channel value represented as an integer between 0 and 255.
  int get bb => (storage[2] * 255).floor();
  set bb(int v) {
    storage[2] = (1 / 255) * v;
  }

  /// Constructs a new color with hex value #000000.
  Color.black() : this.fromRGB(0.0, 0.0, 0.0);

  /// Constructs a new color with hex value #ffffff.
  Color.white() : this.fromRGB(1.0, 1.0, 1.0);

  /// Constructs a new color with specified hex value.
  Color(num color) {
    setHex(color);
  }

  /// Construct a new color with specified RGB values.
  Color.fromRGB(double r, double g, double b) {
    setRGB(r, g, b);
  }

  /// Construct a new color with specified HSL values.
  Color.fromHSL(double h, double s, double l) {
    setHSL(h, s, l);
  }

  // Copy of [other].
  Color.copy(Color other) {
    setRGB(other.r, other.g, other.b);
  }

  /// Constructs a new color from a CSS-style string,
  /// e.g. "rgb(250, 0,0)", "rgb(100%,0%,0%)", "#ff0000", "#f00", or "red".
  Color.fromStyle(String style) {
    setStyle(style);
  }

  /// Initialized with values from [list]
  Color.fromList(List<double> list, [int offset = 0]) {
    storage[0] = list[offset + 0];
    storage[1] = list[offset + 1];
    storage[2] = list[offset + 2];
  }

  /// Random color. If [useNamed] is set, it picks a random color from [Colors].
  Color.random({bool useNamed: false}) {
    if (useNamed) {
      var colors = Colors.toList();
      setHex(colors[ThreeMath.randInt(0, colors.length)]);
    } else {
      storage[0] = ThreeMath.randFloat(0.0, 1.0);
      storage[1] = ThreeMath.randFloat(0.0, 1.0);
      storage[2] = ThreeMath.randFloat(0.0, 1.0);
    }
  }

  /// Sets [this] from [other].
  Color setFrom(Color other) {
    setRGB(other.storage[0], other.storage[1], other.storage[2]);
    return this;
  }

  /// Sets [this] from specified RGB values, ranging from 0.0 to 1.0.
  Color setRGB(double r, double g, double b) {
    storage[0] = r;
    storage[1] = g;
    storage[2] = b;
    return this;
  }

  /// Sets [this] from specified HSL values, ranging from 0.0 to 1.0.
  Color setHSL(double h, double s, double l) {
    if (s == 0) {
      storage[0] = storage[1] = storage[2] = l;
    } else {
      var hue2rgb = (p, q, t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * 6 * (2 / 3 - t);
        return p;
      };

      var p = l <= 0.5 ? l * (1 + s) : l + s - (l * s);
      var q = (2 * l) - p;

      storage[0] = hue2rgb(q, p, h + 1 / 3);
      storage[1] = hue2rgb(q, p, h);
      storage[2] = hue2rgb(q, p, h - 1 / 3);
    }

    return this;
  }

  /// Sets [this] from a CSS-style string, e.g. "rgb(250, 0,0)", "rgb(100%,0%,0%)", "#ff0000", "#f00", or "red".
  Color setStyle(String style) {
    var color;

    // rgb(255,0,0)
    color = new RegExp(r'^rgb\((\d+), ?(\d+), ?(\d+)\)$', caseSensitive: true).firstMatch(style);
    if (color != null) {
      storage[0] = Math.min(255, int.parse(color[1])) / 255;
      storage[1] = Math.min(255, int.parse(color[2])) / 255;
      storage[2] = Math.min(255, int.parse(color[3])) / 255;
      return this;
    }

    // rgb(100%,0%,0%)
    color = new RegExp(r'^rgb\((\d+)\%, ?(\d+)\%, ?(\d+)\%\)$', caseSensitive: true).firstMatch(style);
    if (color != null) {
      storage[0] = Math.min(100, int.parse(color[1])) / 100;
      storage[1] = Math.min(100, int.parse(color[2])) / 100;
      storage[2] = Math.min(100, int.parse(color[3])) / 100;
      return this;
    }

    // #ff0000
    color = new RegExp(r'^\#([0-9a-f]{6})$', caseSensitive: true).firstMatch(style);
    if (color != null) {
      setHex(int.parse(color[1]));
      return this;
    }

    // #f00
    color = new RegExp(r'^\#([0-9a-f])([0-9a-f])([0-9a-f])$', caseSensitive: true).firstMatch(style);
    if (color != null) {
      setHex(int.parse('${color[1]}${color[1]}${color[2]}${color[2]}${color[3]}${color[3]}'));
      return this;
    }

    return this;
  }

  /// Copies [color] making conversion from gamma to linear space.
  Color copyGammaToLinear(Color color, [double gammaFactor = 2.0]) {
    storage[0] = Math.pow(color.storage[0], gammaFactor);
    storage[1] = Math.pow(color.storage[1], gammaFactor);
    storage[2] = Math.pow(color.storage[2], gammaFactor);
    return this;
  }

  /// Copies [color] making conversion from linear to gamma space.
  Color copyLinearToGamma(Color color, [double gammaFactor = 2.0]) {
    var safeInverse = gammaFactor > 0 ? (1.0 / gammaFactor) : 1.0;
    storage[0] = Math.pow(color.storage[0], safeInverse);
    storage[1] = Math.pow(color.storage[1], safeInverse);
    storage[2] = Math.pow(color.storage[2], safeInverse);
    return this;
  }

  /// Converts RGB values from gamma to linear space.
  Color convertGammaToLinear() {
    storage[0] = storage[0] * storage[0];
    storage[1] = storage[1] * storage[1];
    storage[2] = storage[2] * storage[2];
    return this;
  }

  /// Converts RGB values from linear to gamma space.
  Color convertLinearToGamma() {
    storage[0] = Math.sqrt(storage[0]);
    storage[1] = Math.sqrt(storage[1]);
    storage[2] = Math.sqrt(storage[2]);
    return this;
  }

  /// The hexadecimal value of this color.
  int getHex() => (rr << 16) ^ (gg << 8) ^ (bb);

  /// Sets this color from a hexadecimal value.
  Color setHex(num hex) {
    var h = hex.toInt().floor();
    storage[0] = (h >> 16 & 255) / 255;
    storage[1] = (h >> 8 & 255) / 255;
    storage[2] = (h & 255) / 255;
    return this;
  }

  /// The string formated hexadecimal value of this color.
  String getHexString() => '${getHex().toRadixString(16)}';

  /// HSL representation of this color
  HSL getHSL() => new HSL.fromRGB(storage[0], storage[1], storage[2]);

  /// The value of this color as a CSS-style string, e.g. "rgb(255,0,0)"
  String getStyle() => 'rgb($rr,$gg, $bb)';

  /// Adds given h, s, and l to this color's existing h, s, and l values.
  Color offsetHSL(double h, double s, double l) {
    var hsl = getHSL();
    setHSL(hsl.h + h, hsl.s + s, hsl.l + l);
    return this;
  }

  /// Adds rgb values of [color] to RGB values of this color
  Color add(Color color) {
    storage[0] += color.storage[0];
    storage[1] += color.storage[1];
    storage[2] += color.storage[2];
    return this;
  }

  /// Adds [s] to the RGB values of this color
  Color addScalar(double s) {
    storage[0] += s;
    storage[1] += s;
    storage[2] += s;
    return this;
  }

  /// Multiplies this color's RGB values by [color].
  Color multiply(Color color) {
    storage[0] *= color.storage[0];
    storage[1] *= color.storage[1];
    storage[2] *= color.storage[2];
    return this;
  }

  /// Multiplies this color's RGB values by [s]
  Color multiplyScalar(double s) {
    storage[0] = storage[0] * s;
    storage[1] = storage[1] * s;
    storage[2] = storage[2] * s;
    return this;
  }

  /// Linear interpolation of this colors rgb values and the rgb values of the first argument.
  /// The alpha argument can be thought of as the percent between the two colors,
  /// where 0 is this color and 1 is the first argument.
  Color lerp(Color color, double alpha) {
    storage[0] += (color.storage[0] - storage[0]) * alpha;
    storage[1] += (color.storage[1] - storage[1]) * alpha;
    storage[2] += (color.storage[2] - storage[2]) * alpha;
    return this;
  }

  /// Returns an list [r, g, b]
  List<double> toList() => [storage[0], storage[1], storage[2]];

  /// Clones color.
  Color clone() => new Color.fromRGB(storage[0], storage[1], storage[2]);

  /// Compares [this] and [other] and returns true if they are the same, false otherwise.
  bool operator ==(Color other) => (other.storage[0] == storage[0]) && (other.storage[1] == storage[1]) && (other.storage[2] == storage[2]);

  Color operator +(v) {
    if (v is Color) return add(v);
    if (v is double) return addScalar(v);
    throw new ArgumentError(v);
  }

  Color operator *(v) {
    if (v is Color) return multiply(v);
    if (v is double) return multiplyScalar(v);
    throw new ArgumentError(v);
  }
}

class HSL {
  /// Hue.
  double get h => _h;
  double _h;

  /// Saturation.
  double get s => _s;
  double _s;

  /// Lightness
  double get l => _l;
  double _l;

  HSL.fromRGB(double r, double g, double b) {
    // h,s,l ranges are in 0.0 - 1.0
    var max = Math.max(Math.max(r, g), b);
    var min = Math.min(Math.min(r, g), b);

    _l = (min + max) / 2.0;

    if (min == max) {
      _h = _s = 0.0;
    } else {
      var delta = max - min;

      _s = _l <= 0.5 ? delta / (max + min) : delta / (2 - max - min);

      if (max == r) {
        _h = (g - b) / delta + (g < b ? 6 : 0);
      } else if (max == g) {
        _h = (b - r) / delta + 2;
      } else if (max == b) {
        _h = (r - g) / delta + 4;
      }

      _h /= 6;
    }
  }
}

abstract class Colors {
  static const int aliceBlue = 0xf0f8ff;
  static const int antiqueWhite = 0xfaebd7;
  static const int aqua = 0xffff;
  static const int aquamarine = 0x7fffd4;
  static const int azure = 0xf0ffff;
  static const int beige = 0xf5f5dc;
  static const int bisque = 0xffe4c4;
  static const int black = 0x0;
  static const int blanchedAlmond = 0xffebcd;
  static const int blue = 0xff;
  static const int blueViolet = 0x8a2be2;
  static const int brown = 0xa52a2a;
  static const int burlywood = 0xdeb887;
  static const int cadetBlue = 0x5f9ea0;
  static const int chartreuse = 0x7fff00;
  static const int chocolate = 0xd2691e;
  static const int coral = 0xff7f50;
  static const int cornflowerBlue = 0x6495ed;
  static const int cornsilk = 0xfff8dc;
  static const int crimson = 0xdc143c;
  static const int cyan = 0xffff;
  static const int darkBlue = 0x8b;
  static const int darkCyan = 0x8b8b;
  static const int darkGoldenRod = 0xb8860b;
  static const int darkGray = 0xa9a9a9;
  static const int darkGreen = 0x6400;
  static const int darkGrey = 0xa9a9a9;
  static const int darkKhaki = 0xbdb76b;
  static const int darkMagenta = 0x8b008b;
  static const int darkOliveGreen = 0x556b2f;
  static const int darkOrange = 0xff8c00;
  static const int darkOrchid = 0x9932cc;
  static const int darkRed = 0x8b0000;
  static const int darkSalmon = 0xe9967a;
  static const int darkSeaGreen = 0x8fbc8f;
  static const int darkSlateBlue = 0x483d8b;
  static const int darkSlateGray = 0x2f4f4f;
  static const int darkTurquoise = 0xced1;
  static const int darkViolet = 0x9400d3;
  static const int deepPink = 0xff1493;
  static const int deepSkyBlue = 0xbfff;
  static const int dimGray = 0x696969;
  static const int dodgerBlue = 0x1e90ff;
  static const int firebrick = 0xb22222;
  static const int floralWhite = 0xfffaf0;
  static const int forestGreen = 0x228b22;
  static const int fuchsia = 0xff00ff;
  static const int gainsboro = 0xdcdcdc;
  static const int ghostWhite = 0xf8f8ff;
  static const int gold = 0xffd700;
  static const int goldenRod = 0xdaa520;
  static const int gray = 0x808080;
  static const int green = 0x8000;
  static const int greenYellow = 0xadff2f;
  static const int honeyDew = 0xf0fff0;
  static const int hotPink = 0xff69b4;
  static const int indianRed = 0xcd5c5c;
  static const int indigo = 0x4b0082;
  static const int ivory = 0xfffff0;
  static const int khaki = 0xf0e68c;
  static const int lavender = 0xe6e6fa;
  static const int lavenderBlush = 0xfff0f5;
  static const int lawnGreen = 0x7cfc00;
  static const int lemonChiffon = 0xfffacd;
  static const int lightBlue = 0xadd8e6;
  static const int lightCoral = 0xf08080;
  static const int lightCyan = 0xe0ffff;
  static const int lightGoldenRodYellow = 0xfafad2;
  static const int lightGray = 0xd3d3d3;
  static const int lightGreen = 0x90ee90;
  static const int lightPink = 0xffb6c1;
  static const int lightSalmon = 0xffa07a;
  static const int lightSeaGreen = 0x20b2aa;
  static const int lightSkyBlue = 0x87cefa;
  static const int lightSlateGray = 0x778899;
  static const int lightSteelBlue = 0xb0c4de;
  static const int lightYellow = 0xffffe0;
  static const int lime = 0xff00;
  static const int limeGreen = 0x32cd32;
  static const int linen = 0xfaf0e6;
  static const int magenta = 0xff00ff;
  static const int maroon = 0x800000;
  static const int mediumAquamarine = 0x66cdaa;
  static const int mediumBlue = 0xcd;
  static const int mediumOrchid = 0xba55d3;
  static const int mediumPurple = 0x9370db;
  static const int mediumSeaGreen = 0x3cb371;
  static const int mediumSlateBlue = 0x7b68ee;
  static const int mediumSpringGreen = 0xfa9a;
  static const int mediumTurquoise = 0x48d1cc;
  static const int mediumVioletRed = 0xc71585;
  static const int midnightBlue = 0x191970;
  static const int mintCream = 0xf5fffa;
  static const int mistyRose = 0xffe4e1;
  static const int moccasin = 0xffe4b5;
  static const int navajoWhite = 0xffdead;
  static const int navy = 0x80;
  static const int oldLace = 0xfdf5e6;
  static const int olive = 0x808000;
  static const int oliveDrab = 0x6b8e23;
  static const int orange = 0xffa500;
  static const int orangeRed = 0xff4500;
  static const int orchid = 0xda70d6;
  static const int paleGoldenRod = 0xeee8aa;
  static const int paleGreen = 0x98fb98;
  static const int paleTurquoise = 0xafeeee;
  static const int paleVioletRed = 0xdb7093;
  static const int papayaWhip = 0xffefd5;
  static const int peachPuff = 0xffdab9;
  static const int peru = 0xcd853f;
  static const int pink = 0xffc0cb;
  static const int plum = 0xdda0dd;
  static const int powderBlue = 0xb0e0e6;
  static const int purple = 0x800080;
  static const int red = 0xff0000;
  static const int rosyBrown = 0xbc8f8f;
  static const int royalBlue = 0x4169e1;
  static const int saddleBrown = 0x8b4513;
  static const int salmon = 0xfa8072;
  static const int sandyBrown = 0xf4a460;
  static const int seaGreen = 0x2e8b57;
  static const int seaShell = 0xfff5ee;
  static const int sienna = 0xa0522d;
  static const int silver = 0xc0c0c0;
  static const int skyBlue = 0x87ceeb;
  static const int slateBlue = 0x6a5acd;
  static const int slateGray = 0x708090;
  static const int snow = 0xfffafa;
  static const int springGreen = 0xff7f;
  static const int steelBlue = 0x4682b4;
  static const int tan = 0xd2b48c;
  static const int teal = 0x8080;
  static const int thistle = 0xd8bfd8;
  static const int tomato = 0xff6347;
  static const int turquoise = 0x40e0d0;
  static const int violet = 0xee82ee;
  static const int wheat = 0xf5deb3;
  static const int white = 0xffffff;
  static const int whiteSmoke = 0xf5f5f5;
  static const int yellow = 0xffff00;
  static const int yellowGreen = 0x9acd32;

  // TODO Use set instead?
  static final UnmodifiableListView<int> _colors = new UnmodifiableListView([
    aliceBlue, antiqueWhite, aqua, aquamarine, azure, beige, bisque, black, blanchedAlmond, blue, blueViolet,
    brown, burlywood, cadetBlue, chartreuse, chocolate, coral, cornflowerBlue, cornsilk, crimson, cyan, darkBlue, darkCyan,
    darkGoldenRod, darkGray, darkGreen, darkGrey, darkKhaki, darkMagenta, darkOliveGreen, darkOrange, darkOrchid, darkRed,
    darkSalmon, darkSeaGreen, darkSlateBlue, darkSlateGray, darkTurquoise, darkViolet, deepPink, deepSkyBlue, dimGray,
    dodgerBlue, firebrick, floralWhite, forestGreen, fuchsia, gainsboro, ghostWhite, gold, goldenRod, gray, green, greenYellow,
    honeyDew, hotPink, indianRed, indigo, ivory, khaki, lavender, lavenderBlush, lawnGreen, lemonChiffon, lightBlue, lightCoral,
    lightCyan, lightGoldenRodYellow, lightGray, lightGreen, lightPink, lightSalmon, lightSeaGreen, lightSkyBlue,
    lightSlateGray, lightSteelBlue, lightYellow, lime, limeGreen, linen, magenta, maroon, mediumAquamarine,
    mediumBlue, mediumOrchid, mediumPurple, mediumSeaGreen, mediumSlateBlue, mediumSpringGreen, mediumTurquoise, mediumVioletRed,
    midnightBlue, mintCream, mistyRose, moccasin, navajoWhite, navy, oldLace, olive, oliveDrab, orange, orangeRed, orchid,
    paleGoldenRod, paleGreen, paleTurquoise, paleVioletRed, papayaWhip, peachPuff, peru, pink, plum, powderBlue, purple, red,
    rosyBrown, royalBlue, saddleBrown, salmon, sandyBrown, seaGreen, seaShell, sienna, silver, skyBlue, slateBlue, slateGray,
    snow, springGreen, steelBlue, tan, teal, thistle, tomato, turquoise, violet, wheat, white, whiteSmoke, yellow, yellowGreen]);

  static UnmodifiableListView<int> toList() => _colors;
}