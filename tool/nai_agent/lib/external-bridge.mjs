import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { randomUUID } from 'node:crypto';

export class ExternalBridge {
  constructor({ client = 'External Agent', discovery, workspace } = {}) {
    this.client = client;
    this.discovery = discovery ?? join(process.env.APPDATA ?? join(homedir(), '.nai-launcher'),
      ...(process.env.APPDATA ? ['nai-launcher', 'krita-bridge.json'] : ['krita-bridge.json']));
    this.workspace = workspace;
    this.pending = new Map();
    this.session = null;
    this.attached = false;
  }
  async connect() {
    if (this.socket?.readyState === WebSocket.OPEN) return;
    if (this.connecting) return this.connecting;
    this.connecting = this.#connect();
    try { await this.connecting; } finally { this.connecting = null; }
  }
  async #connect() {
    const config = JSON.parse(await readFile(this.discovery, 'utf8'));
    if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535 || typeof config.secret !== 'string') {
      throw new Error('Invalid local Studio discovery file');
    }
    const socket = this.socket = new WebSocket(`ws://127.0.0.1:${config.port}/krita`);
    await new Promise((resolve, reject) => {
      const timer = setTimeout(() => { socket.close(); reject(new Error('Studio handshake timed out')); }, 10000);
      const fail = () => { clearTimeout(timer); reject(new Error('Studio bridge connection failed')); };
      socket.addEventListener('error', fail, { once: true });
      socket.addEventListener('open', () => socket.send(JSON.stringify({ type: 'ping', version: 1,
        secret: config.secret, client: { kind: 'agent', name: this.client } })), { once: true });
      socket.addEventListener('message', event => {
        if (typeof event.data !== 'string') return;
        let message;
        try { message = JSON.parse(event.data); } catch { return; }
        if (message.type === 'pong') {
          clearTimeout(timer);
          if (!message.capabilities?.includes('agent_tools_v1')) {
            socket.close(); reject(new Error('Studio does not support external Agent tools; update Studio')); return;
          }
          resolve(); return;
        }
        const pending = this.pending.get(message.id);
        if (pending) {
          this.pending.delete(message.id);
          if (message.type === 'error') pending.reject(new Error(`${message.code}: ${message.message}`));
          else if (message.type === 'agent_result') pending.resolve(message.result);
        } else if (message.type === 'error') {
          clearTimeout(timer); socket.close(); reject(new Error(`Studio handshake rejected: ${message.code}`));
        }
      });
      socket.addEventListener('close', () => {
        this.attached = false;
        if (this.session) this.session.connected = false;
        clearTimeout(timer); reject(new Error('Studio connection closed'));
        for (const request of this.pending.values()) request.reject(new Error('Studio disconnected; existing artifacts are retained'));
        this.pending.clear();
      });
    });
  }
  async request(operation, payload = {}, id = randomUUID()) {
    await this.connect();
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.socket.send(JSON.stringify({ type: 'agent_request', id, payload: { operation, ...payload } }));
    });
  }
  async open({ session_id, workspace_id = this.workspace, summary } = {}) {
    const session = await this.request('session', { session_id, workspace_id, summary });
    this.session = session;
    this.attached = true;
    return session;
  }
  async ensureSession() {
    if (!this.opening) this.opening = this.session ?
      this.connect().then(() => this.attached ? this.session : this.open(this.session)) : this.open();
    try { return await this.opening; } finally { this.opening = null; }
  }
  async operation(operation, payload = {}, id, signal) {
    signal?.throwIfAborted();
    const session = await this.ensureSession();
    signal?.throwIfAborted();
    return this.request(operation, { ...payload, session_id: session.session_id }, id);
  }
  async end() {
    if (!this.session) return { connected: false };
    const result = await this.operation('end'); this.session = null; this.attached = false; return result;
  }
  close() { this.socket?.close(); }
}
