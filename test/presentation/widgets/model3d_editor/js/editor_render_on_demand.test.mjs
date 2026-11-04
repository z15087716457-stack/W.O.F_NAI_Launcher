// 3D 模型图层编辑器（assets/model3d_editor/editor.js）按需渲染：有变化才画一帧，静止时一帧都不画。
// 跑法：node --test test/presentation/widgets/model3d_editor/js/editor_render_on_demand.test.mjs
// （flutter test 里由 editor_render_on_demand_test.dart 代跑）。
import assert from 'node:assert/strict';
import * as nodeModule from 'node:module';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '../../../../..');
const editorDir = path.join(root, 'assets/model3d_editor');
const url = (p) => pathToFileURL(p).href;

// 'three' → 换掉渲染器的真 three.js；'three/addons/…' → 仓库里带的 addons。
const routes = {
  three: url(path.join(here, 'three_stub.mjs')),
  real: url(path.join(editorDir, 'vendor/three.module.min.js')),
  addons: url(path.join(editorDir, 'vendor/addons')) + '/',
};
function route(specifier) {
  if (specifier === 'three') return routes.three;
  if (specifier === 'real-three') return routes.real;
  if (specifier.startsWith('three/addons/')) {
    return routes.addons + specifier.slice('three/addons/'.length);
  }
  return null;
}
if (typeof nodeModule.registerHooks === 'function') {
  nodeModule.registerHooks({
    resolve(specifier, context, next) {
      const target = route(specifier);
      return target ? { url: target, shortCircuit: true } : next(specifier, context);
    },
  });
} else {
  // 旧版 Node（没有同步钩子）
  nodeModule.register(
    'data:text/javascript,' +
      encodeURIComponent(`
const routes = ${JSON.stringify(routes)};
${route.toString()}
export async function resolve(specifier, context, next) {
  const target = route(specifier);
  return target ? { url: target, shortCircuit: true } : next(specifier, context);
}`),
  );
}

// ---- 浏览器环境的最小替身 ----
class Element extends EventTarget {
  constructor(tag) {
    super();
    this.tagName = tag;
    this.style = {};
    this.hidden = false;
    this.clientWidth = 400;
    this.clientHeight = 300;
  }
  getRootNode() {
    return globalThis.document;
  }
  get ownerDocument() {
    return globalThis.document;
  }
  getBoundingClientRect() {
    return { left: 0, top: 0, width: this.clientWidth, height: this.clientHeight };
  }
  setPointerCapture() {}
  releasePointerCapture() {}
  hasPointerCapture() {
    return false;
  }
  toDataURL() {
    return 'data:image/png;base64,AAAA';
  }
}

const elements = {
  viewport: new Element('CANVAS'),
  'context-below': new Element('IMG'),
  'context-above': new Element('IMG'),
};
const doc = new EventTarget();
doc.getElementById = (id) => elements[id];
doc.pointerLockElement = null;
globalThis.document = doc;

const frames = [];
const messages = [];
const win = new EventTarget();
win.devicePixelRatio = 2;
win.flutter_inappwebview = { callHandler: (_, msg) => messages.push(msg) };
globalThis.window = win;
globalThis.requestAnimationFrame = (callback) => frames.push(callback);
globalThis.cancelAnimationFrame = () => {};

/** 把排着的帧都跑完（跑的过程中又要的帧也跑），返回这次画了几帧。 */
function flushFrames() {
  const renderer = globalThis.__editorRenderer;
  const before = renderer.renders;
  for (let i = 0; frames.length > 0; i++) {
    assert.ok(i < 100, '帧一直停不下来');
    frames.shift()(performance.now());
  }
  return renderer.renders - before;
}

const settle = () => new Promise((resolve) => setTimeout(resolve, 0));

let requestId = 0;
async function command(type, params = {}) {
  window.naiEditor.dispatch(JSON.stringify({ type, requestId: ++requestId, ...params }));
  await settle();
  return messages.findLast((m) => m.type === 'response' && m.requestId === requestId);
}

const editor = await import(url(path.join(editorDir, 'editor.js')));
await settle();

test('不再用 setAnimationLoop 一直画；启动画一帧后就停', () => {
  assert.equal(globalThis.__editorRenderer.loop, null);
  assert.ok(messages.some((m) => m.type === 'onReady'));
  assert.equal(flushFrames(), 1);
  assert.equal(frames.length, 0);
  assert.equal(flushFrames(), 0, '静止时一帧都不画');
});

test('Dart 发来的命令：做完画一帧', async () => {
  const response = await command('loadModel', { builtin: 'mannequin' });
  assert.equal(response.ok, true);
  assert.equal(flushFrames(), 1);
  assert.ok((await command('setLight', { intensity: 1, azimuth: 30, elevation: 20 })).ok);
  assert.equal(flushFrames(), 1);
  assert.ok((await command('setMode', { mode: 'pose' })).ok);
  assert.equal(flushFrames(), 1);
  assert.equal(flushFrames(), 0);
});

test('拖动相机：每次 change 画一帧，同一帧里多次只画一次', () => {
  const controls = editor.ctx.controls;
  controls.dispatchEvent({ type: 'change' });
  assert.equal(flushFrames(), 1);
  controls.dispatchEvent({ type: 'change' });
  controls.dispatchEvent({ type: 'change' });
  controls.dispatchEvent({ type: 'change' });
  assert.equal(flushFrames(), 1);
  editor.ctx.camera.position.x += 0.5;
  editor.ctx.controls.update();
  assert.equal(flushFrames(), 1);
  assert.equal(flushFrames(), 0);
});

test('窗口尺寸变了、WASD 平移、撤销快捷键：各画一帧', () => {
  window.dispatchEvent(new Event('resize'));
  assert.equal(flushFrames(), 1);
  const key = (init) => Object.assign(new Event('keydown'), init);
  window.dispatchEvent(key({ key: 'w' }));
  assert.equal(flushFrames(), 1);
  window.dispatchEvent(key({ key: 'z', ctrlKey: true }));
  assert.equal(flushFrames(), 1);
  assert.equal(flushFrames(), 0);
});

test('导出 PNG：导出时画一次，之后把视口画回来', async () => {
  const before = globalThis.__editorRenderer.renders;
  const response = await command('render', { width: 64, height: 64 });
  assert.equal(response.ok, true);
  assert.equal(globalThis.__editorRenderer.renders - before, 1, '导出那一次');
  assert.equal(flushFrames(), 1, '视口画回来');
  assert.equal(flushFrames(), 0);
});

test('换成正交相机后，新的相机控制照样按需画', async () => {
  assert.ok((await command('setSettings', { settings: { projection: 'orthographic' } })).ok);
  // 新建的相机控制第一次 update() 会报一次“动了”，多画一帧后停下
  assert.ok(flushFrames() <= 2);
  assert.equal(flushFrames(), 0);
  editor.ctx.controls.dispatchEvent({ type: 'change' });
  assert.equal(flushFrames(), 1);
  assert.equal(flushFrames(), 0);
});
