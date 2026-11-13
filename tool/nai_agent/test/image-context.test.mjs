import test from 'node:test';
import assert from 'node:assert/strict';
import { PhotonImage } from '@silvia-odwyer/photon-node';
import { resizeImage } from '@earendil-works/pi-coding-agent';
import { createImageContext } from '../lib/image-context.mjs';

const user = (...content) => ({ role: 'user', content, timestamp: 1 });
const text = text => ({ type: 'text', text });
const answer = (stopReason = 'stop', content = [text('Seen.')]) => ({ role: 'assistant', stopReason, content });
const image = (data = 'AQID'.repeat(40)) => ({ type: 'image', mimeType: 'image/png', data });
const pixels = context => context.messages.flatMap(message => message.content).filter(part => part.type === 'image');
const smallCopy = async (_bytes, mimeType, options) => ({ data: 'AQID'.repeat(Math.floor(Math.min(options.maxBytes - 1, 100) / 4)), mimeType });

test('text follow-ups stay unchanged while images remain in their historical message', async () => {
  const project = createImageContext({ resize: smallCopy });
  for (const content of ['What else can we improve?', [text('What else can we improve?')]]) {
    const context = { messages: [user(image(), image()), answer(), { role: 'user', content }] };
    const before = structuredClone(context), result = await project(context);
    assert.equal(pixels({ messages: [result.messages[0]] }).length, 2);
    assert.equal(pixels({ messages: [result.messages[2]] }).length, 0);
    assert.equal(result.messages[2], context.messages[2]);
    assert.deepEqual(await project(context), result);
    assert.deepEqual(context, before);
  }
});

test('image-free conversations and genuine current attachments stay unchanged', async () => {
  const project = createImageContext({ resize: smallCopy });
  const plain = { messages: [user(text('Hello')), answer(), user(text('Continue'))] };
  assert.equal(await project(plain), plain);
  const attached = { messages: [user(image()), answer(), user(text('New attachment'), image())] };
  const result = await project(attached);
  assert.equal(result.messages[2], attached.messages[2]);
});

test('a tool-read image is not attributed to the latest plain user message', async () => {
  const original = image();
  const context = { messages: [user(text('Read source.png')), answer('toolUse', [{ type: 'toolCall', name: 'image_read' }]),
    { role: 'toolResult', content: [original], toolCallId: 'read' }] };
  const before = structuredClone(context), result = await createImageContext({ resize: smallCopy })(context);
  assert.equal(result.messages[0], context.messages[0]);
  assert.equal(pixels({ messages: [result.messages[0]] }).length, 0);
  assert.equal(result.messages[2], context.messages[2]);
  assert.equal(pixels(result)[0], original);
  assert.deepEqual(context, before);
});

test('retiring a user preview for a fresh tool image preserves its file reference and original attachment', async () => {
  const original = image();
  const context = { messages: [user(text('Original file: source.png'), original), answer('toolUse', [{ type: 'toolCall', name: 'image_read' }]),
    { role: 'toolResult', content: [image()], toolCallId: 'read' }] };
  const result = await createImageContext({ maxBytes: 160, resize: smallCopy })(context);
  assert.equal(pixels({ messages: [result.messages[0]] }).length, 0);
  assert.deepEqual(result.messages[0].content[0], text('Original file: source.png'));
  assert.equal(context.messages[0].content[1], original);
  assert.equal(pixels(result).length, 1);
});

test('first view stays full quality; only a successful answer makes it history, cached once', async () => {
  let calls = 0;
  const project = createImageContext({ resize: async (...args) => { calls++; return smallCopy(...args); } });
  const original = image(), context = { messages: [user(text('Original file: .W.O.F/attachments/a.png'), original)] };
  const before = structuredClone(context);
  assert.equal(pixels(await project(context))[0], original);
  assert.equal(calls, 0);
  for (const failed of [answer('aborted'), answer('error'), answer('pending'), answer('stop', [{ type: 'thinking', thinking: 'unfinished' }])]) {
    assert.equal(pixels(await project({ messages: [...context.messages, failed, user(text('Retry'))] }))[0], original);
  }
  const complete = { messages: [...context.messages, answer(), user(text('Follow up'))] };
  const first = await project(complete), second = await project(complete);
  assert.equal(calls, 1);
  assert.notEqual(pixels(first)[0].data, original.data);
  assert.deepEqual(first, second);
  assert.ok(JSON.stringify(first).includes('Re-read the original'));
  assert.ok(JSON.stringify(first).includes('.W.O.F/attachments/a.png'));
  assert.deepEqual(context, before);
});

test('tool image and an explicit re-read receive a fresh full-quality view even when bytes are cached', async () => {
  const original = image(), project = createImageContext({ resize: smallCopy });
  const context = { messages: [user(original), answer('toolUse', [{ type: 'toolCall', name: 'image_read' }]),
    { role: 'toolResult', content: [original], toolCallId: 'read', details: { original: 'preserved' } }] };
  const before = structuredClone(context), result = await project(context);
  assert.notEqual(pixels(result)[0].data, original.data);
  assert.equal(pixels(result)[1], original);
  assert.deepEqual(result.messages[2].details, context.messages[2].details);
  assert.deepEqual(context, before);
});

test('history status follows the supplied branch and works after a fresh runtime is created', async () => {
  const original = image(), context = { messages: [user(original), answer()] };
  const one = await createImageContext({ resize: smallCopy })(context);
  const resumed = await createImageContext({ resize: smallCopy })(context);
  assert.deepEqual(resumed, one);
  const branchBeforeAnswer = { messages: [context.messages[0]] };
  assert.equal(pixels(await createImageContext({ resize: smallCopy })(branchBeforeAnswer))[0], original);
});

test('retire oldest previews before touching fresh images; retain text and file references', async () => {
  const project = createImageContext({ maxBytes: 1000, resize: smallCopy });
  const context = { messages: [user(text('a.png'), image()), user(text('b.png'), image()), answer(), user(image('AQID'.repeat(220)))] };
  const result = await project(context);
  assert.equal(result.messages[0].content[1].type, 'text');
  assert.equal(result.messages[1].content[1].type, 'image');
  assert.equal(result.messages[3], context.messages[3]);
  assert.equal(pixels(result).length, 2);
  assert.ok(pixels(result).reduce((sum, part) => sum + part.data.length, 0) <= 1000);
  assert.ok(JSON.stringify(result).includes('a.png'));
});

test('a large new batch is optimized within the total budget without silently dropping unseen images', async () => {
  const project = createImageContext({ maxBytes: 200, resize: smallCopy });
  const context = { messages: [user(image(), image(), image())] }, before = structuredClone(context);
  const result = await project(context);
  assert.equal(pixels(result).length, 3);
  assert.ok(pixels(result).reduce((sum, part) => sum + part.data.length, 0) <= 200);
  assert.deepEqual(context, before);
});

test('failed history preview keeps a re-read note; an unprocessable fresh batch reports an error', async () => {
  const project = createImageContext({ maxBytes: 100, resize: async () => null });
  const old = await project({ messages: [user(text('source.png'), image()), answer()] });
  assert.equal(pixels(old).length, 0);
  assert.ok(JSON.stringify(old).includes('source.png'));
  await assert.rejects(project({ messages: [user(image())] }), /STUDIO_IMAGE_BUDGET/);
});

test('optimizing a large new batch still keeps affordable history previews', async () => {
  const project = createImageContext({ maxBytes: 300, resize: async (_bytes, mimeType, options) => ({
    data: 'AQID'.repeat(options.maxWidth === 1024 ? 5 : 20), mimeType,
  }) });
  const result = await project({ messages: [user(image()), answer(), user(image(), image(), image())] });
  assert.equal(pixels(result).length, 4);
  assert.ok(pixels(result).reduce((sum, part) => sum + part.data.length, 0) <= 300);
});

test('real decoder preserves first-view pixels, downsamples history, and reuses identical encoded bytes', async () => {
  const rgba = new Uint8Array(2400 * 1200 * 4);
  for (let i = 0; i < rgba.length; i += 4) {
    rgba[i] = i % 251; rgba[i + 1] = (i >>> 7) % 251; rgba[i + 2] = (i >>> 15) % 251; rgba[i + 3] = 255;
  }
  const source = new PhotonImage(rgba, 2400, 1200);
  const original = image(Buffer.from(source.get_bytes()).toString('base64')); source.free();
  let encodes = 0;
  const project = createImageContext({ resize: async (...args) => { encodes++; return resizeImage(...args); } });
  const context = { messages: [user(original)] };
  assert.equal(pixels(await project(context))[0].data, original.data);
  const history = { messages: [...context.messages, answer()] };
  const first = pixels(await project(history))[0], second = pixels(await project(history))[0];
  const decoded = PhotonImage.new_from_byteslice(Buffer.from(first.data, 'base64'));
  assert.equal(decoded.get_width(), 1024); assert.equal(decoded.get_height(), 512); decoded.free();
  assert.ok(first.data.length < original.data.length);
  assert.equal(first.data, second.data); assert.equal(encodes, 1);
  assert.equal(pixels(context)[0].data, original.data);
});
