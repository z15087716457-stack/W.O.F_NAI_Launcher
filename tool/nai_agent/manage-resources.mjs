// The same SDK helpers serve the form and the unified management tool.
import { createInterface } from 'node:readline';
import { manageStudioPackage, resolveStudioPackages } from './lib/packages.mjs';
import { inspectStudioMcp, mcpRedactor } from './lib/mcp.mjs';
const sdkRoot = new URL('.', import.meta.resolve('@earendil-works/pi-coding-agent'));
const { takeOverStdout, writeRawStdout, flushRawStdout } = await import(new URL('core/output-guard.js', sdkRoot));
takeOverStdout();
const send = value => writeRawStdout(JSON.stringify(value) + '\n');
const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
for await (const line of input) {
  let request;
  const cancellation = new AbortController();
  const cancel = () => cancellation.abort();
  try {
    request = JSON.parse(line);
    // POSIX termination does not kill owned MCP children. Let Pi close the
    // transport (including a pending handshake/OAuth) before this helper exits.
    if (request.resource === 'mcp' && process.platform !== 'win32') {
      process.once('SIGTERM', cancel);
      process.once('SIGINT', cancel);
    }
    if (request.resource === 'chatgpt') {
      const { studioChatGpt } = await import('./lib/model.mjs');
      send({ result: await studioChatGpt(request, send, cancellation.signal) });
      break;
    }
    const result = request.resource === 'mcp'
      ? await inspectStudioMcp({ ...request, emit: send, signal: cancellation.signal })
      : request.action === 'resolve' ? await resolveStudioPackages(request)
      : await manageStudioPackage(request);
    send({ result });
  } catch (error) {
    if (request?.resource === 'chatgpt') {
      send({ error: 'ChatGPT connection failed' });
      break;
    }
    const clean = mcpRedactor({}, { mcpServers: request?.config ? { server: request.config } : {} });
    send(clean({ error: error.message }));
  } finally {
    process.removeListener('SIGTERM', cancel);
    process.removeListener('SIGINT', cancel);
  }
  break;
}
input.close();
await flushRawStdout();
