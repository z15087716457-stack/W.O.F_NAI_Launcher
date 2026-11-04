"""The inference thread sleeps until there is work; it never polls every second.

Standard library only: models, engines and the native runtimes are fakes.
"""
import io
import queue
import sys
import threading
import time
import types
import unittest
from types import SimpleNamespace
from unittest.mock import patch

import worker


class RecordingQueue(queue.PriorityQueue):
    """Records every timeout the inference thread waits with."""
    def __init__(self):
        super().__init__()
        self.timeouts = []

    def get(self, block=True, timeout=None):
        self.timeouts.append(timeout)
        return super().get(block, timeout)


class IdleWaitTests(unittest.TestCase):
    def worker(self):
        instance = worker.Worker()
        instance.queue = RecordingQueue()
        instance.close = lambda: None
        return instance

    def run_thread(self, instance):
        thread = threading.Thread(target=instance.run, daemon=True)
        thread.start()
        return thread

    def stop(self, instance, thread):
        instance.running = False
        instance.enqueue(worker.WAKE, -2)
        thread.join(5)
        self.assertFalse(thread.is_alive())

    def test_idle_worker_without_loaded_models_waits_without_a_deadline(self):
        instance = self.worker()
        with patch.object(worker, 'emit'):
            thread = self.run_thread(instance)
            time.sleep(0.5)
            # Before: one wake-up per second, forever.
            self.assertEqual(instance.queue.timeouts, [None])
            self.stop(instance, thread)

    def test_loaded_models_unload_at_their_deadline_then_the_thread_sleeps(self):
        unloads = []
        models = SimpleNamespace(encoder=object(), scorer=None)
        def unload():
            models.encoder = None
            unloads.append(time.monotonic())
        models.unload = unload
        instance = self.worker()
        instance.models = models
        with patch.object(worker, 'IDLE_UNLOAD_SECONDS', 0.2), patch.object(worker, 'emit'):
            started = instance.last_use = time.monotonic()
            thread = self.run_thread(instance)
            time.sleep(0.8)
            self.assertEqual(len(unloads), 1)
            self.assertGreaterEqual(unloads[0] - started, 0.19)
            # One wait until the deadline, then one without any deadline.
            self.assertEqual(len(instance.queue.timeouts), 2)
            self.assertIsNotNone(instance.queue.timeouts[0])
            self.assertIsNone(instance.queue.timeouts[1])
            self.stop(instance, thread)

    def test_a_running_build_keeps_its_models_and_sets_no_deadline(self):
        instance = self.worker()
        instance.models = SimpleNamespace(encoder=object(), scorer=None, unload=lambda: self.fail('unloaded during a build'))
        instance.jobs = {'job': {'paused': False}}
        instance.last_use = 0
        self.assertIsNone(instance._unload_due_in())
        instance.jobs['job']['paused'] = True
        self.assertEqual(instance._unload_due_in(), 0)

    def test_a_request_wakes_the_sleeping_thread_at_once(self):
        instance = self.worker()
        replies = []
        instance.execute = lambda op, params, token, progress=None: {'op': op}
        with patch.object(worker, 'emit', side_effect=replies.append):
            thread = self.run_thread(instance)
            time.sleep(0.2)
            instance.tokens[1] = threading.Event()
            instance.enqueue({'id': 1, 'op': 'status'})
            for _ in range(100):
                if replies: break
                time.sleep(0.01)
            self.assertEqual(replies, [{'id': 1, 'result': {'op': 'status'}}])
            self.stop(instance, thread)

    def test_shutdown_wakes_a_thread_that_sleeps_without_a_deadline(self):
        fake_modules = {name: types.ModuleType(name) for name in
                        ('numpy', 'torch', 'sentence_transformers', 'usearch', 'usearch.index')}
        instance = self.worker()
        events = []
        done = threading.Event()
        def main():
            instance.main()
            done.set()
        with patch.dict(sys.modules, fake_modules), \
             patch.object(sys, 'stdin', io.StringIO('{"op":"shutdown"}\n')), \
             patch.object(worker, 'emit', side_effect=events.append), \
             patch.object(worker.importlib.metadata, 'version', return_value='fixture'):
            runner = threading.Thread(target=main, daemon=True)
            runner.start()
            self.assertTrue(done.wait(5), 'shutdown left the inference thread asleep')
        self.assertEqual(events[0]['event'], 'ready')
        self.assertEqual(events[-1], {'event': 'shutdown', 'phase': 'complete'})


if __name__ == '__main__':
    unittest.main()
