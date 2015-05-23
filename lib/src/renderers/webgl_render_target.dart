part of three.renderers;

class WebGLRenderTarget extends Texture {
  int width, height;

  int wrapS;
  int wrapT;

  int magFilter;
  int minFilter;

  int anisotropy;

  Vector2 offset = new Vector2.zero();
  Vector2 repeat = new Vector2(1.0, 1.0);

  int format;
  int type;

  bool depthBuffer;
  bool stencilBuffer;

  bool generateMipmaps = true;

  var shareDepthFrom;

  var __webglFramebuffer; // List<WebGLFramebuffer> or WebGLFramebuffer
  var __webglRenderbuffer; // List<WebGLRenderbuffer> or WebGLRenderbuffer

  var activeCubeFace;

  WebGLRenderTarget(this.width, this.height, {this.wrapS: ClampToEdgeWrapping, this.wrapT: ClampToEdgeWrapping,
  this.magFilter: LinearFilter, this.minFilter: LinearMipMapLinearFilter, this.anisotropy: 1,
  this.format: RGBAFormat, this.type: UnsignedByteType, this.depthBuffer: true, this.stencilBuffer: true,
  this.shareDepthFrom});

  void setSize(int width, int height) {
    if (this.width != width || this.height != height) {
      this.width = width;
      this.height = height;
      dispose();
    }
  }

  WebGLRenderTarget clone([WebGLRenderTarget renderTarget]) {
    renderTarget = new WebGLRenderTarget(width, height)
      ..wrapS = wrapS
      ..wrapT = wrapT

      ..magFilter = magFilter
      ..minFilter = minFilter

      ..anisotropy = anisotropy

      ..offset.setFrom(offset)
      ..repeat.setFrom(repeat)

      ..format = format
      ..type = type

      ..depthBuffer = depthBuffer
      ..stencilBuffer = stencilBuffer

      ..generateMipmaps = generateMipmaps

      ..shareDepthFrom = shareDepthFrom;
    return renderTarget;
  }

  void dispose() {
    super.dispose();
  }
}
