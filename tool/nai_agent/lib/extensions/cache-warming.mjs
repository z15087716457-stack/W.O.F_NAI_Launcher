// Pi 1.5.0 does not export getCacheWarmingDelayMs through its package exports.
// Mirror its delay for status projection. The live-mode compatibility bridge
// rearms Pi's first timer using its existing run, replay checks and deadlines;
// later refreshes and the 30-minute / one-hour safety limits remain Pi-owned.
function warmingDelayMs(ttlSeconds) {
  const ttlMs = ttlSeconds * 1000;
  return ttlMs <= 10_000 ? undefined : Math.max(1, Math.floor(Math.min(ttlMs * 0.9, ttlMs - 10_000)));
}

function priceUnknown(model) {
  return model.provider.startsWith('studio/') && !Object.values(model.cost).some(price => price > 0);
}

export class StudioCacheWarming {
  constructor({ model, settingsManager, onChange }) {
    this.model = model;
    this.settingsManager = settingsManager;
    this.onChange = onChange;
    this.running = false;
    this.warmCount = 0;
    this.extension = {
      name: 'nai-cache-warming',
      factory: pi => {
        pi.on('agent_start', () => { this.running = true; });
        // agent_end can be followed by retry/recovery/queued work.
        pi.on('agent_settled', () => { this.running = false; this.currentRequest = undefined; });
        pi.on('cache_warming_decision', (_event, ctx) => {
          if (!priceUnknown(ctx.model ?? this.model)) return;
          const mode = this.settingsManager.getCacheWarmingMode();
          const action = mode === 'idle' || (mode === 'streaming' && this.running) ? 'warm' : 'stop';
          this.onChange?.();
          return { action };
        });
      },
    };
  }

  attach(session) {
    this.session = session;
    // Pi 1.5.0's public mode setter only reconciles an existing warmer. Keep
    // this compatibility bridge here: reuse Pi's request validity, replay
    // checks, timers and safety limits when enabling an off-started run.
    const warmer = session._cacheWarmer;
    const start = warmer.start.bind(warmer);
    warmer.start = (request, isCurrent) => {
      this.currentRequest = { request, isCurrent, startedAt: Date.now() };
      return start(request, isCurrent);
    };
    const modeChanged = warmer.onModeChanged.bind(warmer);
    warmer.onModeChanged = () => {
      modeChanged();
      this.resumeCurrentRequest(warmer, start);
      this.onChange?.();
    };
    // Counts belong to this Pi session, including usage persisted before resume.
    for (const entry of session.sessionManager.getEntries()) this.recordWarm(entry);
    const stream = session.agent.streamFunction;
    session.agent.streamFunction = (...args) => {
      const result = stream(...args);
      // Pi schedules from the main request's START, not its completion. Observing
      // here also handles a long first request before any assistant message ends.
      const delay = warmingDelayMs(this.model.promptCache.short);
      this.nextWarmAt = delay === undefined ? undefined : Date.now() + delay;
      this.onChange?.();
      return result;
    };
    session.subscribe(event => {
      if (event.type === 'entry_appended') this.recordWarm(event.entry);
    });
  }

  resumeCurrentRequest(warmer, start) {
    const current = this.currentRequest;
    if (!this.running || this.settingsManager.getCacheWarmingMode() === 'off' || warmer.run
      || !current || !current.isCurrent() || warmer.inactive.reason !== 'cache warming disabled') return;
    start(current.request, current.isCurrent);
    const run = warmer.run;
    if (!run) return; // Pi rejected the request's replay or cache lifetime.
    clearTimeout(run.timer);
    run.startedAt = current.startedAt;
    run.nextWarmAt = Math.max(current.startedAt, this.lastWarmAt ?? 0) + run.delayMs;
    run.refreshDeadlineAt = run.nextWarmAt + Math.floor((run.ttlMs - run.delayMs) / 2);
    const reason = warmer.getModeStopReason(run);
    if (reason || Date.now() > run.refreshDeadlineAt) {
      warmer.stop(reason ?? 'cache refresh deadline missed');
      return;
    }
    this.nextWarmAt = run.nextWarmAt;
    run.timer = setTimeout(() => void warmer.refresh(run), Math.max(0, run.nextWarmAt - Date.now()));
    run.timer.unref();
  }

  recordWarm(entry) {
    if (entry.type !== 'usage' || entry.kind !== 'cache_warm') return;
    this.warmCount++;
    this.lastWarmAt = Date.parse(entry.timestamp);
    const delay = warmingDelayMs(this.model.promptCache.short);
    this.nextWarmAt = delay === undefined ? undefined : this.lastWarmAt + delay;
  }

  get status() {
    const mode = this.settingsManager.getCacheWarmingMode();
    const piStatus = this.session.cacheWarmingStatus;
    const status = { mode, ...piStatus, ttlSeconds: this.model.promptCache.short,
      lastWarmAt: this.lastWarmAt, warmCount: this.warmCount };
    if (!priceUnknown(this.session.model)) return status;
    // Unknown prices are not zero-dollar savings. Never project Pi's synthetic
    // $0 decision as economics, including while its extension override runs.
    delete status.decision;
    // Only this specific Pi reporting bug hides an active timer. All actual
    // stop reasons (off/settled/context/deadlines/unsafe replay) remain Pi-owned.
    if (piStatus.state === 'inactive' && piStatus.reason === 'cache economics unavailable'
        && !piStatus.decision && this.nextWarmAt !== undefined) {
      status.state = 'scheduled';
      status.nextWarmAt = this.nextWarmAt;
    }
    if (status.state !== 'inactive') {
      status.reason = mode === 'idle' ? 'user-selected idle warming (price unknown)'
        : 'user-selected running warming (price unknown)';
    }
    return status;
  }
}
