// A package manager may start npm, git and lifecycle scripts. Give this one
// operation its own POSIX process group, separate from Studio and other jobs.
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

let worker;
function cancel() {
  if (!worker?.pid) return;
  try {
    process.kill(-worker.pid, 'SIGKILL');
  } catch (error) {
    if (error.code !== 'ESRCH') throw error;
  }
}
// Register before spawning. If a signal arrives earlier there are no children.
process.on('SIGTERM', cancel);
process.on('SIGINT', cancel);
worker = spawn(process.execPath, [fileURLToPath(new URL('./manage-resources.mjs', import.meta.url))], {
  detached: true,
  stdio: 'inherit',
});
worker.once('error', error => {
  process.stderr.write(error.message + '\n');
});
worker.once('close', code => {
  process.off('SIGTERM', cancel);
  process.off('SIGINT', cancel);
  process.exitCode = code ?? 1;
});
