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
  try {
    request = JSON.parse(line);
    const result = request.resource === 'mcp'
      ? await inspectStudioMcp({ ...request, emit: send })
      : request.action === 'resolve' ? await resolveStudioPackages(request)
      : await manageStudioPackage(request);
    send({ result });
  } catch (error) {
    const clean = mcpRedactor({}, { mcpServers: request?.config ? { server: request.config } : {} });
    send(clean({ error: error.message }));
  }
  break;
}
input.close();
await flushRawStdout();
