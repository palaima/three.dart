/*
 * @author alteredq / http://alteredqualia.com/
 *
 * Ported to Dart from JS by:
 * @author nelson silva / http://www.inevo.pt/
 *
 * based on r71
 */

part of three;

class Loader {
  static List handlers = [];

  static addHandler(regex, loader) {
    handlers.add(regex);
    handlers.add(loader);
  }

  static getHandler(String file) {
    for (var i = 0; i < handlers.length; i += 2) {
      var regex = handlers[i];
      var loader = handlers[i + 1];

      if (regex.test(file)) {
        return loader;
      }
    }

    return null;
  }

  bool showStatus;
  Element statusDomElement;

  StreamController _onLoadStartController = new StreamController();
  Stream get onLoadStart => _onLoadStartController.stream;

  StreamController _onLoadProgressController = new StreamController();
  Stream get onLoadProgress => _onLoadProgressController.stream;

  StreamController _onLoadCompleteController = new StreamController();
  Stream get onLoadComplete => _onLoadCompleteController.stream;

  ImageLoader imageLoader = new ImageLoader();

  String crossOrigin;

  Loader({this.showStatus}) {
    statusDomElement = showStatus ? Loader.addStatusElement() : null;
  }

  static addStatusElement() {
    var e = new DivElement();

    e.style
        ..position = 'absolute'
        ..right = '0px'
        ..top = '0px'
        ..fontSize = '0.8em'
        ..textAlign = 'left'
        ..background = 'rgba(0,0,0,0.25)'
        ..color = '#fff'
        ..width = '120px'
        ..padding = '0.5em 0.5em 0.5em 0.5em'
        ..zIndex = '1000';

    e.innerHtml = 'Loading ...';

    return e;
  }

  void _updateProgress(ProgressEvent progress) {
    var message = 'Loaded ';

    if (progress.total != null) {
      message += (100 * progress.loaded / progress.total).toStringAsFixed(0) + '%';
    } else {
      message += (progress.loaded / 1024).toStringAsFixed(2) + ' KB';
    }

    statusDomElement.innerHtml = message;
  }

  String _extractUrlBase(String url) {
    var parts = url.split('/');

    if (parts.length == 1) return './';

    parts.removeLast();

    return parts.join('/') + '/';
  }

  List _initMaterials(List materials, String texturePath) {
    var array = [];

    for (var i = 0; i < materials.length; ++i) {
      array.add(_createMaterial(materials[i], texturePath));
    }

    return array;
  }

  bool _needsTangents(List<Material> materials) {
    for (var i = 0; i < materials.length; i++) {
      if (materials[i] is ShaderMaterial) return true;
    }

    return false;
  }

  _createMaterial(Map m, String texturePath) {
    nearest_pow2(n) => Math.pow(2, (Math.log(n) / Math.LN2).round());

    create_texture(String sourceFile, List repeat, List offset, List wrap, int anisotropy) {
      var fullPath = texturePath + sourceFile;

      Texture texture;

      var loader = Loader.getHandler(fullPath);

      if (loader != null) {
        texture = loader.load(fullPath);
      } else {
        texture = new Texture();

        loader = imageLoader;
        loader.crossOrigin = crossOrigin;
        loader.onLoad.listen((image) {
          if (!ThreeMath.isPowerOfTwo(image.width) || !ThreeMath.isPowerOfTwo(image.height)) {
            var width = nearest_pow2(image.width);
            var height = nearest_pow2(image.height);

            var canvas = new CanvasElement()
              ..width = width
              ..height = height;

            canvas.context2D.drawImageScaled(image, 0, 0, width, height);

            texture.image = canvas;
          } else {
            texture.image = image;
          }

          texture.needsUpdate = true;
        });

        loader.load(fullPath);
      }

      texture.sourceFile = sourceFile;

      if (repeat != null) {
        texture.repeat.setValues(repeat[0], repeat[1]);

        if (repeat[0] != 1) texture.wrapS = RepeatWrapping;
        if (repeat[1] != 1) texture.wrapT = RepeatWrapping;
      }

      if (offset != null) {
        texture.offset.setValues(offset[0], offset[1]);
      }

      if (wrap != null) {
        var wrapMap = {'repeat': RepeatWrapping, 'mirror': MirroredRepeatWrapping};

        if (wrapMap[wrap[0]] != null) texture.wrapS = wrapMap[wrap[0]];
        if (wrapMap[wrap[1]] != null) texture.wrapT = wrapMap[wrap[1]];
      }

      if (anisotropy != null) {
        texture.anisotropy = anisotropy;
      }

      return texture;
    }

    rgb2hex(List<double> rgb) => (rgb[0].toInt() * 255 << 16) + (rgb[1].toInt() * 255 << 8) + rgb[2] * 255;

    // defaults

    var mtype = 'MeshLambertMaterial';

    var color = 0xeeeeee,
        emissive = 0x000000,
        opacity = 1.0,
        map,
        lightMap,
        normalMap,
        bumpMap,
        aoMap,
        specularMap,
        alphaMap,
        wireframe = false,
        blending = NormalBlending,
        transparent = false,
        depthTest = true,
        depthWrite = true,
        visible = true,
        side = FrontSide,
        vertexColors = NoColors,
        specular = 0x111111,
        shininess = 30.0,
        bumpScale,
        normalScale;

    // parameters from model file

    if (m['shading'] != null) {
      var shading = m['shading'].toLowerCase();

      if (shading == 'phong') mtype = 'MeshPhongMaterial';
      else if (shading == 'basic') mtype = 'MeshBasicMaterial';
    }

    var blendingModes = {
      'NoBlending': NoBlending,
      'NormalBlending': NormalBlending,
      'AdditiveBlending': AdditiveBlending,
      'SubtractiveBlending': SubtractiveBlending,
      'MultiplyBlending': MultiplyBlending,
      'CustomBlending': CustomBlending
    };

    if (m['blending'] != null && blendingModes.keys.contains(m['blending'])) {
      blending = blendingModes[m['blending']];
    }

    if (m['transparent'] != null) {
      transparent = m['transparent'];
    }

    if (m['opacity'] != null && m['opacity'] < 1.0) {
      transparent = true;
    }

    if (m['depthTest'] != null) {
      depthTest = m['depthTest'];
    }

    if (m['depthWrite'] != null) {
      depthWrite = m['depthWrite'];
    }

    if (m['visible'] != null) {
      visible = m['visible'];
    }

    if (m['flipSided'] != null) {
      side = BackSide;
    }

    if (m['doubleSided'] != null) {
      side = DoubleSide;
    }

    if (m['wireframe'] != null) {
      wireframe = m['wireframe'];
    }

    if (m['vertexColors'] != null) {
      if (m['vertexColors'] == 'face') {
        vertexColors = FaceColors;
      } else if (m['vertexColors'] == true) {
        vertexColors = VertexColors;
      }
    }

    // colors

    if (m['colorDiffuse'] != null) {
      color = rgb2hex(m['colorDiffuse']);
    } else if (m['DbgColor'] != null) {
      color = m['DbgColor'];
    }

    if (m['colorSpecular'] != null) {
      specular = rgb2hex(m['colorSpecular']);
    }

    if (m['colorEmissive'] != null) {
      emissive = rgb2hex(m['colorEmissive']);
    }

    // modifiers

    if (m['transparency'] != null) {
      warn('Loader: transparency has been renamed to opacity');
      m['opacity'] = m['transparency'];
    }

    if (m['opacity'] != null) {
      opacity = m['opacity'];
    }

    if (m['specularCoef'] != null) {
      shininess = m['specularCoef'];
    }

    // textures

    if (m['mapDiffuse'] != null && texturePath != null) {
      map = create_texture(m['mapDiffuse'], m['mapDiffuseRepeat'], m['mapDiffuseOffset'], m['mapDiffuseWrap'],
          m['mapDiffuseAnisotropy']);
    }

    if (m['mapLight'] != null && texturePath != null) {
      lightMap = create_texture(m['mapLight'], m['mapLightRepeat'], m['mapLightOffset'], m['mapLightWrap'],
          m['mapLightAnisotropy']);
    }

    if (m['mapAO'] != null && texturePath != null) {
      aoMap = create_texture(
          m['mapAO'], m['mapAORepeat'], m['mapAOOffset'], m['mapAOWrap'], m['mapAOAnisotropy']);
    }

    if (m['mapBump'] != null && texturePath != null) {
      bumpMap = create_texture(
          m['mapBump'], m['mapBumpRepeat'], m['mapBumpOffset'], m['mapBumpWrap'], m['mapBumpAnisotropy']);
    }

    if (m['mapNormal'] != null && texturePath != null) {
      normalMap = create_texture(m['mapNormal'], m['mapNormalRepeat'], m['mapNormalOffset'],
          m['mapNormalWrap'], m['mapNormalAnisotropy']);
    }

    if (m['mapSpecular'] != null && texturePath != null) {
      specularMap = create_texture(m['mapSpecular'], m['mapSpecularRepeat'], m['mapSpecularOffset'],
          m['mapSpecularWrap'], m['mapSpecularAnisotropy']);
    }

    if (m['mapAlpha'] != null && texturePath != null) {
      alphaMap = create_texture(m['mapAlpha'], m['mapAlphaRepeat'], m['mapAlphaOffset'], m['mapAlphaWrap'],
          m['mapAlphaAnisotropy']);
    }

    //

    if (m['mapBumpScale'] != null) {
      bumpScale = m['mapBumpScale'];
    }

    if (m['mapNormalFactor'] != null) {
      normalScale = new Vector2(m['mapNormalFactor'], m['mapNormalFactor']);
    }

    Material material;

    if (mtype == 'MeshLambertMaterial') {
      material = new MeshLambertMaterial(
          map: map,
          color: color,
          emissive: emissive,
          specularMap: specularMap,
          alphaMap: alphaMap,
          vertexColors: vertexColors,
          wireframe: wireframe,
          side: side,
          opacity: opacity,
          transparent: transparent,
          blending: blending,
          depthTest: depthTest,
          depthWrite: depthWrite,
          visible: visible);
    } else if (mtype == 'MeshPhongMaterial') {
      material = new MeshPhongMaterial(
          map: map,
          color: color,
          emissive: emissive,
          shininess: shininess,
          lightMap: lightMap,
          bumpMap: bumpMap,
          aoMap: aoMap,
          alphaMap: alphaMap,
          bumpScale: bumpScale,
          normalScale: normalScale,
          specularMap: specularMap,
          specular: specular,
          normalMap: normalMap,
          vertexColors: vertexColors,
          wireframe: wireframe,
          side: side,
          opacity: opacity,
          transparent: transparent,
          blending: blending,
          depthTest: depthTest,
          depthWrite: depthWrite,
          visible: visible);
    } else if (mtype == 'MeshBasicMaterial') {
      material = new MeshBasicMaterial(
          alphaMap: alphaMap,
          map: map,
          color: color,
          specularMap: specularMap,
          vertexColors: vertexColors,
          wireframe: wireframe,
          side: side,
          opacity: opacity,
          transparent: transparent,
          blending: blending,
          depthTest: depthTest,
          depthWrite: depthWrite,
          visible: visible);
    }

    if (m['DbgName'] != null) material.name = m['DbgName'];

    return material;
  }
}
