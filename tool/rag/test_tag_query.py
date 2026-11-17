"""Explicit tag queries cannot carry host-draft or obsolete context inputs."""
import inspect
import unittest
import test_tag_search as fixtures

class TagQueryTests(unittest.TestCase):
    setUp = fixtures.TagSearchTests.setUp
    tearDown = fixtures.TagSearchTests.tearDown
    build = fixtures.TagSearchTests.build

    def test_api_has_no_retired_inputs(self):
        self.assertEqual(list(inspect.signature(self.engine.search).parameters),
                         ['query','existing','limit','cancelled','options'])

    def test_explicit_query_splits_without_host_context(self):
        self.build()
        self.engine.search('独立袖子 蓝色眼睛')
        self.assertEqual(self.models.queries,['独立袖子 蓝色眼睛','独立袖子','蓝色眼睛'])

    def test_queries_do_not_write_vectors(self):
        self.build()
        before=self.engine.db.execute('SELECT * FROM documents ORDER BY id').fetchall()
        self.engine.search('cat ears')
        self.assertEqual(before,self.engine.db.execute('SELECT * FROM documents ORDER BY id').fetchall())

    def test_empty_query_does_not_infer(self):
        self.build()
        self.assertEqual(self.engine.search('')['items'],[])
        self.assertEqual(self.models.queries,[])

if __name__=='__main__': unittest.main()
