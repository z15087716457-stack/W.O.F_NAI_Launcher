import { createHash } from 'node:crypto';
import { resizeImage } from '@earendil-works/pi-coding-agent';

// Limits count base64 bytes, as sent to providers, rather than file sizes.
export const imageContextMaxBytes = 8 * 1024 * 1024;
const historyMaxBytes = 256 * 1024;
const historyNote = '[Earlier image downscaled for history. Re-read the original file with image_read or read when fine detail is needed.]';
const omittedNote = '[Earlier image omitted from this request to fit the image budget. Its original file/attachment reference remains available; re-read it when needed.]';

function answered(message) {
  return message.role === 'assistant' && ['stop', 'toolUse', 'length'].includes(message.stopReason)
    && message.content.some(part => part.type === 'toolCall' || part.type === 'text' && part.text.trim());
}

// Only projects outgoing requests. Session messages, attachments and their
// original bytes remain untouched. Successful responses establish which image
// occurrences were seen, including after resume or moving to another branch.
export function createImageContext({ maxBytes = imageContextMaxBytes, resize = resizeImage } = {}) {
  const cache = new Map();
  let cachedBytes = 0;
  async function copy(image, edge, limit) {
    const digest = createHash('sha256').update(image.mimeType).update(image.data).digest('hex');
    const key = `${digest}/${edge}/${limit}`;
    if (cache.has(key)) return cache.get(key);
    const result = await resize(Buffer.from(image.data, 'base64'), image.mimeType, {
      maxWidth: edge, maxHeight: edge, maxBytes: limit, jpegQuality: edge === 1024 ? 75 : 85,
    });
    const compressed = result && result.data.length <= limit
      ? { ...image, data: result.data, mimeType: result.mimeType } : null;
    if (compressed) {
      cache.set(key, compressed);
      cachedBytes += compressed.data.length;
      while (cachedBytes > maxBytes * 2) {
        const oldest = cache.keys().next().value;
        cachedBytes -= cache.get(oldest).data.length;
        cache.delete(oldest);
      }
    }
    return compressed;
  }

  return async context => {
    const images = [];
    let seen = false;
    for (let m = context.messages.length - 1; m >= 0; m--) {
      const message = context.messages[m];
      if (answered(message)) seen = true;
      if (!Array.isArray(message.content)) continue;
      for (let p = message.content.length - 1; p >= 0; p--) {
        const image = message.content[p];
        if (image.type === 'image') images.push({ m, p, image, seen, replacement: [image] });
      }
    }
    if (!images.length) return context;
    images.reverse();

    let bytes = 0;
    for (const entry of images) {
      if (entry.seen) {
        const compressed = await copy(entry.image, 1024, historyMaxBytes);
        entry.replacement = compressed
          ? [compressed, { type: 'text', text: historyNote }]
          : [{ type: 'text', text: omittedNote }];
      }
      bytes += entry.replacement[0].type === 'image' ? entry.replacement[0].data.length : 0;
    }
    const fresh = images.filter(entry => !entry.seen);
    const freshBytes = fresh.reduce((sum, entry) => sum + entry.image.data.length, 0);
    let historyBytes = bytes - freshBytes;
    // Preserve HD new images when they fit. If the new batch alone exceeds the
    // budget, reserve up to a quarter for previews rather than dropping all
    // history only to free space again after optimizing the new batch.
    const historyLimit = Math.max(0, maxBytes - (freshBytes > maxBytes ? maxBytes * .75 : freshBytes));
    for (const entry of images.filter(entry => entry.seen)) {
      if (bytes <= maxBytes || historyBytes <= historyLimit) break;
      if (entry.replacement[0].type === 'image') {
        bytes -= entry.replacement[0].data.length;
        historyBytes -= entry.replacement[0].data.length;
      }
      entry.replacement = [{ type: 'text', text: omittedNote }];
    }
    if (bytes > maxBytes) {
      fresh.sort((a, b) => a.image.data.length - b.image.data.length);
      let remaining = maxBytes - historyBytes;
      for (const [i, entry] of fresh.entries()) {
        const limit = Math.floor(remaining / (fresh.length - i));
        const image = entry.image.data.length <= limit ? entry.image : await copy(entry.image, 2048, limit);
        if (!image) throw new Error('STUDIO_IMAGE_BUDGET: Reduce the number or size of new images and retry.');
        entry.replacement = [image];
        remaining -= image.data.length;
      }
    }
    const changed = new Map();
    for (const entry of images) {
      if (entry.replacement.length === 1 && entry.replacement[0] === entry.image) continue;
      if (!changed.has(entry.m)) changed.set(entry.m, new Map());
      changed.get(entry.m).set(entry.p, entry.replacement);
    }
    return { ...context, messages: context.messages.map((message, m) => changed.has(m)
      ? { ...message, content: message.content.flatMap((part, p) => changed.get(m).get(p) ?? [part]) }
      : message) };
  };
}
