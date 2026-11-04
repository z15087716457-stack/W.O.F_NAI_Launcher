// 测试用的 'three'：真的 three.js（数学、场景、控件都是真的），只把 WebGLRenderer 换成数帧数的假货，
// 在 Node 里不用 WebGL 也能把 assets/model3d_editor/editor.js 跑起来。
export * from 'real-three';

export class WebGLRenderer {
  constructor({ canvas } = {}) {
    this.domElement = canvas;
    this.shadowMap = { enabled: false };
    this.renders = 0;
    this.loop = null;
    this._pixelRatio = 1;
    globalThis.__editorRenderer = this;
  }

  setPixelRatio(value) {
    this._pixelRatio = value;
  }

  getPixelRatio() {
    return this._pixelRatio;
  }

  setSize() {}

  render() {
    this.renders++;
  }

  setAnimationLoop(callback) {
    this.loop = callback;
  }
}
