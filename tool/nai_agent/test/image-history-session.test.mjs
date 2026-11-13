import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdir, mkdtemp, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { PhotonImage } from '@silvia-odwyer/photon-node';
import { createStudioSession } from '../lib/session.mjs';
import { listenFetchTestServer } from './fixture-http.mjs';

for (const protocol of ['anthropicMessages', 'openaiChatCompletions']) {
  test(`${protocol}: plain follow-ups keep old images out of the latest message, including after resume`, async () => {
    const requests = [];
    const server = createServer(async (req, res) => {
      const chunks = []; for await (const chunk of req) chunks.push(chunk);
      requests.push(JSON.parse(Buffer.concat(chunks)));
      res.writeHead(200, { 'content-type': 'text/event-stream' });
      if (protocol === 'anthropicMessages') {
        const emit = (type, fields) => res.write(`event: ${type}\ndata: ${JSON.stringify({ type, ...fields })}\n\n`);
        emit('message_start', { message: { id: 'msg_test', type: 'message', role: 'assistant',
          model: 'test', content: [], usage: { input_tokens: 12, output_tokens: 0 } } });
        emit('content_block_start', { index: 0, content_block: { type: 'text', text: '' } });
        emit('content_block_delta', { index: 0, delta: { type: 'text_delta', text: 'Synthetic answer' } });
        emit('content_block_stop', { index: 0 });
        emit('message_delta', { delta: { stop_reason: 'end_turn' }, usage: { output_tokens: 6 } });
        emit('message_stop', {});
      } else {
        res.write('data: ' + JSON.stringify({ choices: [{ delta: { content: 'Synthetic answer' }, finish_reason: 'stop' }] })
          + '\n\ndata: [DONE]\n\n');
      }
      res.end();
    });
    await listenFetchTestServer(server);
    await mkdir('.runs', { recursive: true });
    const root = await mkdtemp('.runs/image-attribution-');
    const options = {
      cwd: join(root, 'workspace'), agentDir: join(root, 'agent'), systemPrompt: 'Synthetic attachment attribution test.',
      config: { providerId: 'test', modelId: 'test', protocol,
        baseUrl: 'http://127.0.0.1:' + server.address().port, tools: true, vision: true, cacheWarming: 'off' },
      executeTool: async () => ({ content: [{ type: 'text', text: 'Unused' }] }),
    };
    const images = [40, 180].map(shade => {
      const rgba = new Uint8Array(16 * 10 * 4);
      for (let i = 0; i < rgba.length; i += 4) {
        rgba[i] = shade; rgba[i + 3] = 255;
      }
      const bitmap = new PhotonImage(rgba, 16, 10);
      const data = Buffer.from(bitmap.get_bytes()).toString('base64'); bitmap.free();
      return { type: 'image', mimeType: 'image/png', data };
    });
    const parts = message => Array.isArray(message.content) ? message.content : [];
    const pictureCount = message => parts(message).filter(part => ['image', 'image_url'].includes(part.type)).length;
    let created = await createStudioSession(options);
    try {
      await created.session.prompt('Inspect these two original images.', { images });
      assert.equal(pictureCount(requests[0].messages.find(message => message.role === 'user')), 2);
      await created.session.prompt('What else can we improve?');
      const sessionFile = created.session.sessionFile;
      await created.close();
      created = await createStudioSession({ ...options, sessionFile });
      await created.session.prompt('Continue after reopening.');
      assert.equal(requests.length, 3);
      for (const [index, text] of [[1, 'What else can we improve?'], [2, 'Continue after reopening.']]) {
        const users = requests[index].messages.filter(message => message.role === 'user');
        assert.equal(pictureCount(users[0]), 2);
        assert.equal(pictureCount(users.at(-1)), 0);
        assert.deepEqual(parts(users.at(-1)).map(part => part.type === 'text' ? part.text : part.type), [text]);
        assert.equal(users.flatMap(parts).filter(part => ['image', 'image_url'].includes(part.type)).length, 2);
      }
      const stored = (await readFile(sessionFile, 'utf8')).trim().split('\n').map(line => JSON.parse(line).message)
        .filter(message => message?.role === 'user');
      assert.deepEqual(stored.flatMap(parts).filter(part => part.type === 'image'), images);
      assert.deepEqual(stored.slice(1).map(message => parts(message)), [
        [{ type: 'text', text: 'What else can we improve?' }],
        [{ type: 'text', text: 'Continue after reopening.' }],
      ]);
    } finally {
      await created.close(); server.closeAllConnections();
      await new Promise(resolve => server.close(resolve));
    }
  });
}

test('real provider requests keep first views HD, downscale prior views, and retain original session bytes on resume', async () => {
  const rgba = new Uint8Array(2000 * 1200 * 4);
  for (let i = 0; i < rgba.length; i += 4) {
    rgba[i] = i % 251; rgba[i + 1] = (i >>> 8) % 251; rgba[i + 2] = 80; rgba[i + 3] = 255;
  }
  const bitmap = new PhotonImage(rgba, 2000, 1200);
  const image = { type: 'image', mimeType: 'image/png', data: Buffer.from(bitmap.get_bytes()).toString('base64') };
  bitmap.free();
  const requests = [];
  const server = createServer(async (req, res) => {
    const chunks = []; for await (const chunk of req) chunks.push(chunk);
    requests.push(JSON.parse(Buffer.concat(chunks)));
    res.writeHead(200, { 'content-type': 'text/event-stream' });
    const tool = requests.length === 1;
    res.end('data: ' + JSON.stringify({ choices: [{ delta: tool
      ? { tool_calls: [{ index: 0, id: 'read', type: 'function', function: { name: 'studio_context', arguments: '{}' } }] }
      : { content: 'Synthetic answer' }, finish_reason: tool ? 'tool_calls' : 'stop' }] }) + '\n\ndata: [DONE]\n\n');
  });
  await listenFetchTestServer(server);
  await mkdir('.runs', { recursive: true });
  const root = await mkdtemp('.runs/image-history-');
  const options = {
    cwd: join(root, 'workspace'), agentDir: join(root, 'agent'), systemPrompt: 'Synthetic image context test.',
    config: { providerId: 'test', modelId: 'test', protocol: 'openaiChatCompletions',
      baseUrl: 'http://127.0.0.1:' + server.address().port, tools: true, vision: true, cacheWarming: 'off' },
    executeTool: async () => ({ content: [image, { type: 'text', text: 'Original file: source.png' }] }),
  };
  let created = await createStudioSession(options);
  const payloadImages = body => body.messages.flatMap(message => Array.isArray(message.content) ? message.content : [])
    .filter(part => part.type === 'image_url').map(part => part.image_url.url.split(',')[1]);
  const storedImages = async file => (await readFile(file, 'utf8')).trim().split('\n').flatMap(line => {
    const content = JSON.parse(line).message?.content;
    return Array.isArray(content) ? content.filter(part => part.type === 'image').map(part => part.data) : [];
  });
  try {
    await created.session.prompt('Inspect this original; then read another file.', { images: [image] });
    assert.equal(requests.length, 2);
    assert.deepEqual(payloadImages(requests[0]), [image.data]);
    const next = payloadImages(requests[1]);
    assert.equal(next.length, 2);
    assert.notEqual(next[0], image.data); assert.equal(next[1], image.data);
    await created.session.prompt('Continue using the image history.');
    assert.equal(payloadImages(requests[2]).length, 2);
    assert.ok(payloadImages(requests[2]).every(data => data !== image.data));
    const sessionFile = created.session.sessionFile;
    assert.deepEqual(await storedImages(sessionFile), [image.data, image.data]);
    await created.close();
    created = await createStudioSession({ ...options, sessionFile });
    await created.session.prompt('Continue after reopening.');
    assert.ok(payloadImages(requests[3]).every(data => data !== image.data));
    assert.deepEqual(await storedImages(sessionFile), [image.data, image.data]);
  } finally {
    await created.close(); server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
});
