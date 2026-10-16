"""Library stdout must not corrupt the worker's strict JSON protocol."""
import io
import json
import sys
import types
import unittest
from unittest.mock import patch

import worker


class ProtocolOutputTests(unittest.TestCase):
    def test_import_and_executor_progress_go_to_stderr(self):
        protocol, diagnostics = io.StringIO(), io.StringIO()
        fake_modules = {name: types.ModuleType(name) for name in
                        ('numpy', 'torch', 'sentence_transformers', 'usearch', 'usearch.index')}
        instance = worker.Worker()
        def inference():
            print('library inference progress')
        instance.run = inference
        with patch.dict(sys.modules, fake_modules), \
             patch.object(worker, 'protocol_stdout', protocol), \
             patch.object(sys, 'stdin', io.StringIO('')), \
             patch.object(sys, 'stderr', diagnostics), \
             patch.object(worker.importlib.metadata, 'version', return_value='fixture'):
            instance.main()
        message = json.loads(protocol.getvalue())
        self.assertEqual(message['event'], 'ready')
        self.assertEqual(diagnostics.getvalue(), 'library inference progress\n')


if __name__ == '__main__':
    unittest.main()
