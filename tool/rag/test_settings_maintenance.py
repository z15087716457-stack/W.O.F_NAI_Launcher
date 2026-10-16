"""Settings rebuild validation must happen before deleting a usable index."""
import sqlite3
import threading
import time
import unittest

import test_rag as fixtures
from worker import Worker


class SettingsMaintenanceTests(unittest.TestCase):
    setUp = fixtures.IndexTests.setUp
    tearDown = fixtures.IndexTests.tearDown
    build = fixtures.IndexTests.build
    def test_rebuild_with_stale_plan_keeps_existing_vectors(self):
        self.build()
        plan = self.engine.preview()
        db = sqlite3.connect(self.source)
        db.execute("UPDATE tags SET name='source_drift' WHERE id=1")
        db.commit()
        db.close()
        worker = Worker()
        worker.models = self.models
        worker.engines = {'tags': self.engine}
        with self.assertRaisesRegex(ValueError, 'source_changed'):
            worker.execute('start', {'source': 'tags', 'plan_id': plan['plan_id'], 'rebuild': True}, threading.Event())
        self.assertEqual(self.engine.status()['indexed'], 70)
        self.assertEqual(worker.jobs, {})

    def test_rebuild_with_expired_plan_keeps_existing_vectors(self):
        self.build()
        plan = self.engine.preview()
        self.engine.plan['expires'] = time.monotonic() - 1
        worker = Worker()
        worker.models = self.models
        worker.engines = {'tags': self.engine}
        with self.assertRaisesRegex(ValueError, 'invalid_plan'):
            worker.execute('start', {'source': 'tags', 'plan_id': plan['plan_id'], 'rebuild': True}, threading.Event())
        self.assertEqual(self.engine.status()['indexed'], 70)


if __name__ == '__main__':
    unittest.main()
