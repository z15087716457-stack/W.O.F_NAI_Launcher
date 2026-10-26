// A single cancellable side request. Never prompt the agent or execute tools.
export const suggestionInstruction = '用用户的语气，预测用户下一条最可能发送的简短消息，只输出这句话，不超过 60 字，不要引号；如果没有合理预测输出空。';

export class NextSuggestion {
  constructor({ session, send, enabled = true, onUsage = () => {} }) {
    Object.assign(this, { session, send, enabled, onUsage });
    this.epoch = 0;
  }
  invalidate(suspended = false) {
    this.suspended = suspended;
    this.epoch++;
    this.controller?.abort();
    this.controller = undefined;
    this.send({ type: 'suggestion', text: '', forTurn: this.epoch });
  }
  setEnabled(enabled) {
    this.enabled = enabled;
    this.invalidate(this.suspended);
  }
  async generate() {
    const session = this.session;
    if (!this.enabled || this.suspended || !session.isIdle) return;
    const last = session.messages.findLast(message => message.role === 'assistant');
    if (!last || ['error', 'aborted', 'toolUse'].includes(last.stopReason)) return;
    this.controller?.abort();
    const controller = this.controller = new AbortController(), epoch = this.epoch;
    try {
      // Pi 1.3 stores system/tool changes in the message prefix. Convert using
      // the agent's own converter, preserving that prefix (including compaction).
      const projected = session.agent.transformContext
        ? await session.agent.transformContext([...session.messages], controller.signal) : [...session.messages];
      const messages = await session.agent.convertToLlm(projected);
      controller.signal.throwIfAborted();
      const reply = await session.modelRuntime.completeSimple(session.model, {
        messages: [...messages, { role: 'user', content: suggestionInstruction, timestamp: Date.now() }],
      }, { signal: controller.signal, sessionId: session.sessionId, maxTokens: 128,
        reasoning: 'off', studioSuggestion: true });
      // Usage-only entries are included by getSessionStats but not model context.
      if (reply.usage?.totalTokens > 0) {
        session.sessionManager.appendUsage('next_suggestion', reply.provider, reply.model, reply.usage);
        this.onUsage();
      }
      if (epoch !== this.epoch || controller.signal.aborted || !this.enabled
          || !session.isIdle || ['error', 'aborted', 'toolUse'].includes(reply.stopReason)
          || reply.content.some(part => part.type === 'toolCall')) return;
      const text = reply.content.filter(part => part.type === 'text').map(part => part.text).join('').trim();
      this.send({ type: 'suggestion', text: [...text].slice(0, 60).join(''), forTurn: epoch });
    } catch {
      // Suggestions are optional. Cancellation/provider failures must not fail a completed run.
    } finally {
      if (this.controller === controller) this.controller = undefined;
    }
  }
}
