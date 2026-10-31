"""Auxiliary WAL lifecycle must not invalidate an unchanged tag index."""
import hashlib
import os
import sqlite3
import unittest

import test_rag as fixtures


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
