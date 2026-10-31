"""Auxiliary WAL lifecycle must not invalidate an unchanged tag index."""
import hashlib
import os
import sqlite3
import unittest
from unittest.mock import patch

import test_rag as fixtures
from engine import Engine, Sources


class SourceSignatureTests(unittest.TestCase):
    setUp = fixtures.IndexTests.setUp
    tearDown = fixtures.IndexTests.tearDown
    build = fixtures.IndexTests.build

    def test_read_only_wal_lifecycle_does_not_trigger_another_scan(self):
        db=sqlite3.connect(self.source)
        self.assertEqual(db.execute('PRAGMA journal_mode=WAL').fetchone()[0],'wal')
        db.close()
        self.build();self.models.embedded.clear()
        source_hash=hashlib.sha256(self.source.read_bytes()).hexdigest()
        metadata=self.engine.db.execute('SELECT key,value FROM metadata ORDER BY key').fetchall()
        wal=self.source.with_name(self.source.name+'-wal')
        for _ in range(3):
            owner=sqlite3.connect(self.source)
            owner.execute('SELECT COUNT(*) FROM tags').fetchone();owner.close()
            reader=sqlite3.connect(self.source.as_uri()+'?mode=ro',uri=True)
            reader.execute('SELECT COUNT(*) FROM tags').fetchone()
            self.assertEqual(wal.stat().st_size,0)
            info=wal.stat();os.utime(wal,ns=(info.st_atime_ns,info.st_mtime_ns+1000000000))
            reader.close()
            status=self.engine.status()
            self.assertTrue(status['complete']);self.assertFalse(status['partial'])
            self.assertTrue(status['auto_update_allowed'])
            self.assertEqual(status['indexed'],status['total'])
        self.assertEqual(self.engine.db.execute('SELECT key,value FROM metadata ORDER BY key').fetchall(),metadata)
        self.assertEqual(self.models.embedded,[])
        self.assertEqual(hashlib.sha256(self.source.read_bytes()).hexdigest(),source_hash)

    def test_real_committed_wal_changes_are_detected_without_a_row_count_change(self):
        db=sqlite3.connect(self.source);db.execute('PRAGMA journal_mode=WAL');db.close()
        self.build();self.models.embedded.clear()
        source_hash=hashlib.sha256(self.source.read_bytes()).hexdigest()
        writer=sqlite3.connect(self.source)
        try:
            writer.execute('UPDATE tags SET category=4 WHERE id=1');writer.commit()
            self.assertEqual(hashlib.sha256(self.source.read_bytes()).hexdigest(),source_hash)
            self.assertGreater(self.source.with_name(self.source.name+'-wal').stat().st_size,0)
            status=self.engine.status()
            self.assertFalse(status['complete']);self.assertTrue(status['partial'])
            self.assertEqual(status['indexed'],status['total'])
            self.build()
            self.assertTrue(self.engine.status()['complete'])
            self.assertEqual(len(self.models.embedded),1)
            self.assertEqual(self.engine.db.execute("SELECT category FROM documents WHERE name='tag_0'").fetchone()[0],4)
        finally:writer.close()
        self.assertTrue(self.engine.status()['complete'])

    def test_last_writer_checkpoint_keeps_completed_index_complete_after_restart(self):
        writer=sqlite3.connect(self.source)
        writer.execute('PRAGMA journal_mode=WAL');writer.execute('PRAGMA wal_autocheckpoint=0')
        writer.execute('UPDATE tags SET post_count=post_count+1 WHERE id=1');writer.commit()
        try:
            self.build();self.models.embedded.clear()
            before=self.engine.db.execute('SELECT id,vector,digest FROM documents ORDER BY id').fetchall()
            metadata=self.engine.db.execute('SELECT key,value FROM metadata ORDER BY key').fetchall()
            self.assertTrue(self.engine.status()['complete'])
        finally:writer.close()
        self.assertTrue(self.engine.status()['complete'])
        self.assertEqual(self.engine.db.execute('SELECT key,value FROM metadata ORDER BY key').fetchall(),metadata)
        self.engine.close()
        self.engine=Engine(self.root/'index',self.models,Sources(self.source))
        self.assertTrue(self.engine.status()['complete'])
        self.assertEqual(self.engine.db.execute('SELECT id,vector,digest FROM documents ORDER BY id').fetchall(),before)
        self.assertEqual(self.models.embedded,[])

    def test_checkpoint_during_build_finalization_keeps_signature_complete(self):
        writer=sqlite3.connect(self.source)
        writer.execute('PRAGMA journal_mode=WAL');writer.execute('PRAGMA wal_autocheckpoint=0')
        writer.execute('UPDATE tags SET post_count=post_count+1 WHERE id=1');writer.commit()
        checkpoint=self.engine._checkpoint
        def finish():
            writer.close()
            checkpoint()
        try:
            with patch.object(self.engine,'_checkpoint',side_effect=finish):self.build()
        finally:writer.close()
        metadata=dict(self.engine.db.execute('SELECT key,value FROM metadata'))
        self.assertTrue(self.engine.status()['complete'])
        self.assertEqual(metadata['source_base'],self.engine.sources.change_state()['base'])
        self.assertEqual(metadata['complete_signature'],self.engine.sources.signature())

    def test_real_change_during_final_checkpoint_is_not_marked_complete(self):
        writer=sqlite3.connect(self.source)
        writer.execute('PRAGMA journal_mode=WAL');writer.execute('PRAGMA wal_autocheckpoint=0')
        checkpoint=self.engine._checkpoint
        def finish():
            writer.execute('UPDATE tags SET category=4 WHERE id=1');writer.commit()
            checkpoint()
        try:
            with patch.object(self.engine,'_checkpoint',side_effect=finish):self.build()
            self.assertFalse(self.engine.status()['complete'])
            self.models.embedded.clear();self.build()
            self.assertEqual(len(self.models.embedded),1)
            self.assertEqual(self.engine.db.execute("SELECT category FROM documents WHERE name='tag_0'").fetchone()[0],4)
        finally:writer.close()
        self.assertTrue(self.engine.status()['complete'])

    def test_completion_metadata_uses_the_revision_that_was_validated(self):
        overlay=self.root/'supplements.db'
        db=sqlite3.connect(overlay)
        db.executescript('''CREATE TABLE tag_semantics(tag TEXT PRIMARY KEY,core_zh TEXT,synonyms_zh TEXT,summary_zh TEXT,wiki_hash TEXT);
            INSERT INTO tag_semantics VALUES('tag_0','旧名称','[]','','');
            CREATE TABLE semantic_state(revision INTEGER); INSERT INTO semantic_state VALUES(1);
            CREATE TABLE semantic_changes(tag TEXT PRIMARY KEY,revision INTEGER);
            INSERT INTO semantic_changes VALUES('tag_0',1);''')
        db.close()
        self.engine.sources=Sources(self.source,supplements=overlay)
        plan=self.engine.preview();building=self.engine.build(plan['plan_id'],lambda:False)
        while next(building)['processed']<plan['total']:pass
        signature=self.engine.sources.signature
        changed=False
        def final_check():
            nonlocal changed
            result=signature()
            if not changed:
                db=sqlite3.connect(overlay)
                db.executescript("UPDATE tag_semantics SET core_zh='新名称'; UPDATE semantic_state SET revision=2; UPDATE semantic_changes SET revision=2;")
                db.close();changed=True
            return result
        with patch.object(self.engine.sources,'signature',side_effect=final_check):list(building)
        metadata=dict(self.engine.db.execute('SELECT key,value FROM metadata'))
        self.assertEqual(metadata['semantic_revision'],'1')
        self.assertTrue(self.engine.status()['partial'])
        self.models.embedded.clear();self.build()
        self.assertEqual(len(self.models.embedded),1)
        self.assertIn('新名称',self.engine.db.execute("SELECT text FROM documents WHERE name='tag_0'").fetchone()[0])
        self.assertTrue(self.engine.status()['complete'])

    def test_old_signature_alignment_reuses_vectors_and_then_stays_complete(self):
        self.build();self.models.embedded.clear()
        before=self.engine.db.execute('SELECT id,vector,digest FROM documents ORDER BY id').fetchall()
        self.engine.db.execute("INSERT OR REPLACE INTO metadata VALUES('complete_signature','old-signature')")
        self.engine.db.commit()
        self.assertTrue(self.engine.status()['partial'])
        self.build()
        self.assertTrue(self.engine.status()['complete'])
        self.assertEqual(self.models.embedded,[])
        self.assertEqual(self.engine.db.execute('SELECT id,vector,digest FROM documents ORDER BY id').fetchall(),before)


if __name__=='__main__':unittest.main()
