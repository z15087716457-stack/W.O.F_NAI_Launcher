"""Library stdout must not corrupt the worker's strict JSON protocol."""
import io
import json
import sys
import types
import unittest
from unittest.mock import patch

import worker


class ProtocolOutputTests(unittest.TestCase):
    def test_source_errors_are_actionable_without_exposing_local_paths(self):
        import sqlite3,tempfile
        from pathlib import Path
        self.assertEqual(worker.Worker.error_code(FileNotFoundError('private/path')), 'source_unavailable')
        self.assertEqual(worker.Worker.error_code(PermissionError('private/path')), 'source_unavailable')
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'locked.db'
            writer=sqlite3.connect(path);writer.execute('CREATE TABLE sample(x)');writer.commit()
            reader=sqlite3.connect(path,timeout=0.01)
            try:
                writer.execute('BEGIN EXCLUSIVE')
                with self.assertRaises(sqlite3.OperationalError) as error:
                    reader.execute('SELECT * FROM sample').fetchall()
                self.assertEqual(worker.Worker.error_code(error.exception),'database_locked')
            finally:writer.rollback();reader.close();writer.close()

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
