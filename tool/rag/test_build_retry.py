"""Failed local builds retain committed rows and require an explicit retry."""
import threading
import unittest
from unittest.mock import patch

from engine import Engine
from models import Models
import test_rag as fixtures
from test_rag import FakeModels
from worker import Worker


class TextRoutingTests(unittest.TestCase):
    def test_urls_and_paths_are_explicit_text_for_documents_and_queries(self):
        from sentence_transformers.base.modality import infer_modality
        texts = ['cat ears', 'https://www.youtube.com/watch?v=fixture',
                 'https://example.invalid/picture.png', 'C:/fixture/clip.mp4']
        class Encoder:
            def encode(self, values, **options):
                for value in values:
                    if infer_modality(value, supported_modalities={'text','image','video','audio'}) != 'text':
                        raise AssertionError('Text was routed to a media loader')
                self.options = options
                self.values = values
                return FakeModels().embed(texts)
        model = Models.__new__(Models)
        model.encoder = Encoder()
        for query in (False, True):
            with patch.object(model, '_encoder'):
                vectors = model.embed(texts, query=query)
            self.assertEqual(vectors.shape, (4,768))
            self.assertEqual(model.encoder.values, [{'text': text} for text in texts])
            self.assertEqual(model.encoder.options['prompt_name'], 'SearchQuery' if query else 'Document')


class BuildRetryTests(unittest.TestCase):
    setUp = fixtures.IndexTests.setUp
    tearDown = fixtures.IndexTests.tearDown

    def test_failure_stays_visible_across_heartbeat_and_reopen_then_continues(self):
        worker = Worker()
        worker.engines = {'tags':self.engine}
        worker.models = self.models
        iterator = self.engine.build(self.engine.preview()['plan_id'], lambda:False)
        worker.jobs['build'] = {'id':'build','source':'tags','generator':iterator,
                                'cancel':threading.Event(),'paused':False}
        with patch.object(worker, '_event'):
            worker._step('build')
            with patch.object(self.models, 'embed', side_effect=RuntimeError('fixture failure')):
                worker._step('build')
        self.assertEqual(self.engine.status()['indexed'],32)
        for _ in range(2):
            status = worker.status()['sources']['tags']
            self.assertEqual(status.get('error'), 'rag_runtime_error')
            self.assertFalse(status['auto_update_allowed'])
        self.engine.close()
        self.engine = Engine(self.root/'index',self.models,self.engine.sources)
        self.assertEqual(self.engine.status().get('error'),'rag_runtime_error')
        self.models.embedded.clear()
        list(self.engine.build(self.engine.preview()['plan_id'],lambda:False))
        self.assertEqual(len(self.models.embedded),38)
        self.assertEqual(self.engine.status()['indexed'],70)
        self.assertIsNone(self.engine.status().get('error'))
        self.assertTrue(self.engine.status()['auto_update_allowed'])

    def test_missing_job_is_reported_so_the_client_can_create_a_new_continuation(self):
        worker = Worker()
        worker.engines = {'tags':self.engine}
        worker.models = self.models
        with self.assertRaisesRegex(ValueError,'job_missing'):
            worker.execute('resume',{'source':'tags','job_id':'old'},threading.Event())


if __name__ == '__main__': unittest.main()
