"""The gallery index reads only the pictures whose rows changed.

Real pool, ANN (usearch) and Pillow with the fake models of test_gallery.py.
Every picture is a real file under a gallery root and a row of danbooru.db as
the app writes it (test_gallery_sources.SCHEMA). An update is what the app
starts: a preview, then every step (GalleryEngine.build). Each test compares
what an update left with the index built from nothing on the gallery as it is
then (rebuilt): the same documents by name (digest, text, vector), and an ANN
that holds exactly their vectors.
"""
import json
import os
from pathlib import Path
import random
import sqlite3
import tempfile
import threading
import unittest
from unittest.mock import Mock, patch

import numpy as np
from PIL import Image
from usearch.index import Index

from documents import count_chunks
import engine as engine_module
import gallery
from gallery import GalleryEngine, GallerySources
from test_gallery import GalleryModels
from test_gallery_sources import SCHEMA
import worker as worker_module
from worker import Worker

# Recorded file times (ms) start here; each version of a picture is a second apart.
TIME = 1_760_000_000
# Prompt lengths of one, two and three parameter chunks.
LENGTHS = (100, 1300, 2400)


class Gallery(unittest.TestCase):
    """Six NovelAI pictures in one root; the index not built yet."""
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.root = Path(self.temp.name)
        self.library = self.root/'图库'; self.other = self.root/'更多'
        for folder in (self.library, self.other): folder.mkdir()
        self.roots = self.root/'roots.json'; self.set_roots(self.library)
        self.database = self.root/'danbooru.db'
        # The app keeps danbooru.db open, so every write lands in its WAL.
        self.app = sqlite3.connect(self.database, isolation_level=None)
        self.app.executescript(SCHEMA)
        self.versions = {}
        for i in range(1, 7): self.save(i)
        self.models = GalleryModels(self.root)
        self.engine = self.open()

    def tearDown(self):
        self.engine.close(); self.app.close(); self.temp.cleanup()

    # The gallery, as the app changes it.
    def set_roots(self, *folders):
        self.roots.write_text(json.dumps({'version': 1, 'roots': [str(f) for f in folders]}), encoding='utf-8')

    def write(self, path, i):
        """A picture of its own colour for each version; returns the size and
        time the gallery records for it."""
        version = self.versions[i] = self.versions.get(i, -1) + 1
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.new('RGB', (8, 8), ((40*i + 90*version) % 256, (70*i) % 256, (110*i + 30*version) % 256)).save(path)
        modified = (TIME + 1000*i + version) * 1000
        os.utime(path, ns=(modified * 1_000_000, modified * 1_000_000))
        return path.stat().st_size, modified

    @staticmethod
    def prompt(i, length):
        words = f'rain {i}, '
        return (words * (length // len(words) + 1))[:length]

    def save(self, i, length=None, nai=True, folder=None):
        path = (folder or self.library)/f'{i}.png'
        size, modified = self.write(path, i)
        self.app.execute('INSERT INTO gallery_images(id,file_path,file_name,file_size,modified_at,indexed_at) VALUES(?,?,?,?,?,1)',
                         (i, str(path), path.name, size, modified))
        prompt = self.prompt(i, length or LENGTHS[i % 3])
        self.app.execute('''INSERT INTO gallery_metadata(image_id,prompt,positive_prompt_text,negative_prompt,model,sampler,
            steps,cfg_scale,seed,width,height,software,source,raw_json,has_metadata) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,1)''',
            (i, prompt, prompt, 'lowres', 'nai-diffusion-4-5-full' if nai else 'sdxl', 'k_euler', 28, 5.0, i, 832, 1216,
             'NovelAI' if nai else 'Other', '', '{}'))

    def path(self, i):
        return Path(self.app.execute('SELECT file_path FROM gallery_images WHERE id=?', (i,)).fetchone()[0])

    def move(self, i, target):
        target.parent.mkdir(parents=True, exist_ok=True)
        os.rename(self.path(i), target)
        self.app.execute('UPDATE gallery_images SET file_path=?,file_name=? WHERE id=?', (str(target), target.name, i))

    def replace(self, i):
        """Another picture written over the file, and the gallery seeing it."""
        size, modified = self.write(self.path(i), i)
        self.app.execute('UPDATE gallery_images SET file_size=?,modified_at=? WHERE id=?', (size, modified, i))

    def edit(self, i, length):
        self.app.execute('UPDATE gallery_metadata SET positive_prompt_text=? WHERE image_id=?',
                         (self.prompt(i, length) + ' edited', i))

    def touch(self, i):
        """The file changed on disk; the gallery has not seen it (same row)."""
        info = self.path(i).stat()
        os.utime(self.path(i), ns=(info.st_atime_ns, info.st_mtime_ns + 10**9))

    # The index.
    def open(self, directory=None, models=None):
        return GalleryEngine(directory or self.root/'index', models or self.models, self.database, self.roots)

    def update(self, engine=None, **preview):
        """One update as the app starts it; which pictures it read the
        documents of, in each index, in order."""
        engine = engine or self.engine
        looked = {'visual': [], 'text': []}
        documents = GallerySources.documents
        def spy(source, owner, record):
            looked['visual' if source.visual else 'text'].append(owner)
            return documents(source, owner, record)
        with patch.object(GallerySources, 'documents', spy):
            list(engine.build(engine.preview(**preview)['plan_id'], lambda: False))
        self.assertTrue(engine.status()['complete'])
        return looked

    def index(self, engine=None):
        """Every document of both indices by name; the ANN must hold exactly
        their vectors."""
        engine = engine or self.engine
        result = {}
        for part, sub in (('visual', engine.visual), ('text', engine.text)):
            rows = sub.db.execute('SELECT id,name,category,post_count,aliases,text,digest,vector FROM documents').fetchall()
            self.assertEqual(sub.ann.keys, {row[0] for row in rows})
            for row in rows:
                np.testing.assert_array_equal(engine.pool.ann.get(row[0]), np.frombuffer(row[7], dtype=np.float32))
            result[part] = {row[1]: row[2:] for row in rows}
        self.assertEqual(len(engine.pool.ann), engine.pool.db.execute('SELECT COUNT(*) FROM pool_documents').fetchone()[0])
        return result

    def rebuilt(self):
        """The index built from nothing on the gallery as it is now."""
        with tempfile.TemporaryDirectory() as folder:
            engine = self.open(Path(folder)/'index', GalleryModels(self.root))
            try:
                list(engine.build(engine.preview()['plan_id'], lambda: False))
                return self.index(engine)
            finally: engine.close()

    def ids(self, owner, *subs):
        """Ids of an owner's documents, in both indices or in those given."""
        prefix = json.dumps([owner])[:-1] + ','
        return sorted(row[0] for sub in subs or (self.engine.visual, self.engine.text)
                      for row in sub.db.execute('SELECT id FROM documents WHERE name>? AND name<?', (prefix, prefix + '~')))

    def owners(self, owner):
        return self.engine.pool.db.execute('SELECT collection FROM pool_owners WHERE owner=?', (owner,)).fetchall()

    def chunks(self, owner):
        return count_chunks(GallerySources(self.database, self.roots, False).records([owner])[owner]['body'])

    def writes(self):
        """From now on, the rows of the pool's documents the two indices
        write: [(insert|update|delete, id)]."""
        subs = (self.engine.visual, self.engine.text)
        for sub in subs:
            sub.db.executescript('''CREATE TEMP TABLE IF NOT EXISTS written(op TEXT,id INTEGER);
                CREATE TEMP TRIGGER IF NOT EXISTS written_insert AFTER INSERT ON main.pool_documents
                    BEGIN INSERT INTO written VALUES('insert',NEW.id); END;
                CREATE TEMP TRIGGER IF NOT EXISTS written_update AFTER UPDATE ON main.pool_documents
                    BEGIN INSERT INTO written VALUES('update',NEW.id); END;
                CREATE TEMP TRIGGER IF NOT EXISTS written_delete AFTER DELETE ON main.pool_documents
                    BEGIN INSERT INTO written VALUES('delete',OLD.id); END;
                DELETE FROM written;''')
        return lambda: sorted(row for sub in subs for row in sub.db.execute('SELECT op,id FROM written'))


ALL = [str(i) for i in range(1, 7)]


class UpdateTests(Gallery):
    def test_a_new_picture_is_read_embedded_and_written_alone(self):
        self.assertEqual(self.update(), {'visual': ALL, 'text': ALL})
        before = self.index(); images = self.models.images; texts = len(self.models.embedded)
        written = self.writes()
        self.save(7, length=LENGTHS[1])
        self.assertEqual(self.update(), {'visual': ['7'], 'text': ['7']})
        self.assertEqual((self.models.images, len(self.models.embedded)), (images + 1, texts + 2))
        # Only its documents are written; no other row is rewritten.
        self.assertEqual(written(), [('insert', i) for i in self.ids('7')])
        after = self.index()
        self.assertEqual({part: {n: v for n, v in docs.items() if not n.startswith('["7",')} for part, docs in after.items()},
                         before)
        self.assertEqual(after, self.rebuilt())

    def test_a_picture_deleted_removed_or_moved_out_of_the_roots_loses_its_documents(self):
        self.update()
        changes = {'2': lambda: self.app.execute('UPDATE gallery_images SET is_deleted=1 WHERE id=2'),
                   '3': lambda: self.app.execute('DELETE FROM gallery_images WHERE id=3'),
                   '4': lambda: self.move(4, self.root/'外面'/'4.png')}
        for owner, change in changes.items():
            gone = self.ids(owner); self.assertTrue(gone)
            written = self.writes(); change()
            self.assertEqual(self.update(), {'visual': [], 'text': []}, owner)
            self.assertEqual(written(), [('delete', i) for i in gone], owner)
            self.assertEqual((self.ids(owner), self.owners(owner)), ([], []), owner)
            self.assertFalse(any(i in self.engine.pool.ann for i in gone), owner)
            self.assertEqual(self.index(), self.rebuilt(), owner)
        # Restored, it is read again.
        self.app.execute('UPDATE gallery_images SET is_deleted=0 WHERE id=2')
        self.assertEqual(self.update(), {'visual': ['2'], 'text': ['2']})
        self.assertEqual(self.index(), self.rebuilt())

    def test_a_picture_moved_in_the_roots_keeps_its_image_vector(self):
        self.update(); images = self.models.images; texts = len(self.models.embedded)
        self.move(2, self.library/'子'/'renamed.png')
        self.assertEqual(self.update(), {'visual': ['2'], 'text': ['2']})
        # The same file (size, time, inode): only the parameters, headed by the file name, again.
        self.assertEqual((self.models.images, len(self.models.embedded)), (images, texts + self.chunks('2')))
        self.assertEqual(self.index(), self.rebuilt())

    def test_a_picture_replaced_in_place_embeds_its_image_again_not_its_parameters(self):
        self.update(); images = self.models.images; texts = len(self.models.embedded)
        self.replace(3)
        self.assertEqual(self.update(), {'visual': ['3'], 'text': []})
        self.assertEqual((self.models.images, len(self.models.embedded)), (images + 1, texts))
        self.assertEqual(self.index(), self.rebuilt())

    def test_edited_parameters_embed_only_that_pictures_chunks(self):
        self.update(); images = self.models.images
        self.edit(3, LENGTHS[2])  # one chunk becomes three
        self.edit(2, LENGTHS[0])  # three become one
        self.app.execute("UPDATE gallery_metadata SET software='Other',model='sdxl' WHERE image_id=5")
        written = self.writes(); five = self.ids('5', self.engine.text)
        self.assertEqual(self.update(), {'visual': [], 'text': ['2', '3']})
        self.assertEqual(self.models.images, images)
        self.assertEqual(self.ids('5', self.engine.text), [])
        self.assertTrue(set(five) <= {i for op, i in written() if op == 'delete'})
        self.assertEqual(self.index(), self.rebuilt())
        # A NovelAI picture again by its request.
        self.app.execute("""UPDATE gallery_metadata SET raw_json='{"v4_prompt":{}}' WHERE image_id=5""")
        self.assertEqual(self.update(), {'visual': [], 'text': ['5']})
        self.assertEqual(self.index(), self.rebuilt())

    def test_a_picture_saved_during_an_update_is_in_the_same_update(self):
        self.update(); self.save(7)
        embed_rows = gallery.VisualEngine.embed_rows
        def save_while_embedding(engine, rows):
            if 8 not in self.versions: self.save(8)
            return embed_rows(engine, rows)
        with patch.object(gallery.VisualEngine, 'embed_rows', save_while_embedding):
            self.assertEqual(self.update(), {'visual': ['7', '8'], 'text': ['7', '8']})
        self.assertEqual(self.index(), self.rebuilt())

    def test_progress_is_reported_and_only_grows(self):
        self.update()
        for i in (7, 8, 9): self.save(i)
        events = []
        with patch.object(gallery.VisualEngine, 'batch_size', 1):
            steps = list(self.engine.build(self.engine.preview()['plan_id'], lambda: False, progress=events.append))
        self.assertTrue(events and all(event['building'] for event in events))
        processed = [step['processed'] for step in steps]
        self.assertEqual(processed, sorted(processed))
        self.assertEqual(processed[-1], self.engine.status()['total'])


class FullCheckTests(Gallery):
    """When an update checks every picture."""
    def test_a_root_added_or_removed_checks_every_picture(self):
        self.update()
        for i in (20, 21): self.save(i, folder=self.other)
        self.set_roots(self.library, self.other)
        self.assertEqual(self.update(), {'visual': [*ALL, '20', '21'], 'text': [*ALL, '20', '21']})
        self.assertEqual(self.index(), self.rebuilt())
        self.set_roots(self.other)
        self.assertEqual(self.update(), {'visual': ['20', '21'], 'text': ['20', '21']})
        self.assertEqual(self.index(), self.rebuilt())
        self.save(22, folder=self.other)
        self.assertEqual(self.update(), {'visual': ['22'], 'text': ['22']})

    def test_another_model_starts_from_an_empty_index(self):
        self.update()
        class Other(GalleryModels): fingerprint = 'another-model-v1'
        models = Other(self.root); engine = self.open(models=models)
        try:
            self.assertEqual(engine.status()['indexed'], 0)
            self.assertEqual(self.update(engine), {'visual': ALL, 'text': ALL})
            self.assertEqual(models.images, 6)
        finally: engine.close()

    def test_a_check_asked_for_while_complete_checks_every_picture_against_its_file(self):
        self.update(); images = self.models.images
        self.touch(4)
        self.assertTrue(self.engine.status()['complete'])
        self.assertEqual(self.update(), {'visual': ALL, 'text': ALL})
        self.assertEqual(self.models.images, images + 1)
        self.assertEqual(self.index(), self.rebuilt())

    def test_a_check_asked_for_while_behind_checks_every_picture_too(self):
        # The settings' build button says so (verify); the app's own updates
        # come while the index is behind and do not.
        self.update(); images = self.models.images
        self.touch(4); self.save(7)
        self.assertFalse(self.engine.status()['complete'])
        self.assertEqual(self.update(verify=True), {'visual': [*ALL, '7'], 'text': [*ALL, '7']})
        self.assertEqual(self.models.images, images + 2)
        self.assertEqual(self.index(), self.rebuilt())
        self.touch(5); self.save(8)
        self.assertEqual(self.update(verify=False), {'visual': ['8'], 'text': ['8']})
        self.touch(6)
        self.assertEqual(self.update(verify=False), {'visual': [], 'text': []})

    def test_the_worker_passes_on_whether_a_check_was_asked_for(self):
        self.update(); token = threading.Event(); worker = Worker()
        worker.models = self.models; worker.engines = {'gallery': self.engine}
        def verify(**params):
            worker.execute('preview', {'source': 'gallery', **params}, token)
            return self.engine.plan['verify']
        self.assertEqual((verify(verify=True), verify(verify=False)), (True, False))
        self.assertTrue(verify())  # an app that does not say: asked for while complete
        self.save(7)
        self.assertEqual((verify(verify=True), verify(verify=False), verify()), (True, False, False))

    def test_the_first_update_after_a_start_checks_the_pictures_against_their_files(self):
        self.update(); self.engine.close(); self.engine = self.open()
        images = self.models.images
        self.touch(4); self.save(7)
        # Parameters depend on the rows alone; pictures on their files too.
        self.assertEqual(self.update(), {'visual': [*ALL, '7'], 'text': ['7']})
        self.assertEqual(self.models.images, images + 2)
        self.save(8)
        self.assertEqual(self.update(), {'visual': ['8'], 'text': ['8']})
        self.assertEqual(self.index(), self.rebuilt())

    def test_an_interrupted_check_of_every_picture_is_done_again_in_full(self):
        self.update()
        steps = self.engine.build(self.engine.preview()['plan_id'], lambda: False)
        next(steps); steps.close()
        self.save(7)
        self.assertEqual(self.update(), {'visual': [*ALL, '7'], 'text': [*ALL, '7']})
        self.save(8)
        self.assertEqual(self.update(), {'visual': ['8'], 'text': ['8']})

    def test_an_index_built_before_the_owner_table_is_checked_in_full_once(self):
        # The old build: both indices walk their documents and mark them seen.
        for sub in (self.engine.visual, self.engine.text):
            list(sub.build(sub.preview()['plan_id'], lambda: False))
        images = self.models.images; texts = len(self.models.embedded)
        self.save(7)
        self.assertEqual(self.update(), {'visual': [*ALL, '7'], 'text': [*ALL, '7']})
        self.assertEqual((self.models.images, len(self.models.embedded)), (images + 1, texts + self.chunks('7')))
        self.assertEqual(self.index(), self.rebuilt())
        self.save(8)
        self.assertEqual(self.update(), {'visual': ['8'], 'text': ['8']})

    def test_documents_the_table_does_not_account_for_are_removed_by_a_full_check(self):
        self.update()
        # Another build left a document of a picture no longer in the gallery.
        stray = self.engine.text
        vector = self.models.embed(['stray'])[0]
        stray.db.execute('INSERT INTO documents(name,category,post_count,aliases,text,digest,vector,seen) VALUES(?,?,?,?,?,?,?,?)',
                         ('["99","parameters",0]', 0, 0, '[]', 'stray', 'digest', vector.tobytes(), 'old'))
        key = stray.db.execute('SELECT id FROM documents WHERE name=?', ('["99","parameters",0]',)).fetchone()[0]
        stray.db.commit(); stray.ann.add(key, vector)
        self.save(7)
        self.assertEqual(self.update()['text'], [*ALL, '7'])
        self.assertEqual(self.index(), self.rebuilt())


class FailureTests(Gallery):
    def test_an_interrupted_update_leaves_the_rest_to_the_next_one(self):
        self.update()
        for i in (7, 8, 9): self.save(i)
        with patch.object(gallery.VisualEngine, 'batch_size', 1):
            steps = self.engine.build(self.engine.preview()['plan_id'], lambda: False)
            next(steps); steps.close()  # picture 7's image only
        self.assertEqual(self.update(), {'visual': ['8', '9'], 'text': ['7', '8', '9']})
        self.assertEqual(self.index(), self.rebuilt())

    def test_a_failed_embedding_writes_nothing_and_the_next_update_does_it(self):
        self.update(); before = self.index(); self.save(7)
        with patch.object(gallery.VisualEngine, 'embed_rows', side_effect=RuntimeError('invalid_embeddings')):
            with self.assertRaisesRegex(RuntimeError, 'invalid_embeddings'):
                list(self.engine.build(self.engine.preview()['plan_id'], lambda: False))
        self.assertEqual(self.index(), before)
        self.assertEqual(self.update(), {'visual': ['7'], 'text': ['7']})
        self.assertEqual(self.index(), self.rebuilt())

    def test_an_ann_that_fails_after_the_commit_is_restored_from_the_rows(self):
        self.update(); self.save(7)
        with patch('pool.CollectionAnn.add', side_effect=MemoryError('fixture allocation')):
            with self.assertRaises(MemoryError):
                list(self.engine.build(self.engine.preview()['plan_id'], lambda: False))
        self.index()  # the ANN holds what the rows hold
        self.assertEqual(self.update(), {'visual': [], 'text': ['7']})
        self.assertEqual(self.index(), self.rebuilt())

    def test_a_crash_before_the_ann_is_saved_replays_the_update_on_the_next_start(self):
        self.update(); self.engine.pool.checkpoint()
        self.save(7); self.update()
        self.assertTrue(self.engine.pool.unsaved())
        expected = self.index(); seven = self.ids('7')
        generation = self.engine.pool.db.execute("SELECT value FROM pool_state WHERE key='generation'").fetchone()[0]
        saved = json.loads((self.engine.pool.folder/'ann.json').read_text())['generation']
        self.assertLess(saved, generation)
        # The process ends: its connections go, nothing more is written.
        for db in (self.engine.visual.db, self.engine.text.db, self.engine.pool.db): db.close()
        added = []; add = Index.add
        def counted(index, keys, vectors, *args, **kwargs):
            added.extend(np.atleast_1d(np.asarray(keys)).tolist()); return add(index, keys, vectors, *args, **kwargs)
        with patch.object(Index, 'add', autospec=True, side_effect=counted):
            self.engine = self.open()
        self.assertEqual(sorted(added), seven)  # its vectors alone, not every one again
        self.assertEqual(json.loads((self.engine.pool.folder/'ann.json').read_text())['generation'], generation)
        self.assertEqual(self.index(), expected)
        images = self.models.images; self.save(8)
        self.assertEqual(self.update(), {'visual': [*ALL, '7', '8'], 'text': ['8']})
        self.assertEqual(self.models.images, images + 1)
        self.assertEqual(self.index(), self.rebuilt())

    def test_a_picture_that_cannot_be_read_is_tried_again_once_by_each_update(self):
        broken = self.library/'9.png'; broken.write_bytes(b'broken')
        self.app.execute('INSERT INTO gallery_images(id,file_path,file_name,file_size,modified_at) VALUES(9,?,?,?,?)',
                         (str(broken), broken.name, broken.stat().st_size, TIME))
        self.update()
        self.assertEqual(self.engine.status()['skipped'], 1)
        load = gallery.load_image; tried = []
        def counted(path):
            tried.append(Path(path).name); return load(path)
        with patch.object(gallery, 'load_image', counted):
            self.save(7)
            self.assertEqual(self.update(), {'visual': ['7', '9'], 'text': ['7']})
        self.assertEqual(sorted(tried), ['7.png', '9.png'])  # in its first round only
        self.assertEqual(self.engine.status()['skipped'], 1)
        self.assertEqual(self.index(), self.rebuilt())

    def test_unread_pictures_are_found_without_sizing_every_picture(self):
        # By their count in the table: an update sizes only what it reads
        # (in its plan and its steps), not each picture of the gallery.
        self.update(); self.save(7)
        sized = []; size = GallerySources.size
        def counted(source, row):
            sized.append('visual' if source.visual else 'text'); return size(source, row)
        with patch.object(GallerySources, 'size', counted):
            self.assertEqual(self.update(), {'visual': ['7'], 'text': ['7']})
        self.assertEqual(sorted(sized), ['text', 'text', 'visual', 'visual'])

    def test_a_picture_that_could_not_be_read_once_is_read_by_the_next_update(self):
        self.update(); self.replace(4)
        load = gallery.load_image
        def locked(path):
            if Path(path).name == '4.png': raise OSError('locked by another app')
            return load(path)
        with patch.object(gallery, 'load_image', locked):
            self.assertEqual(self.update(), {'visual': ['4'], 'text': []})
        self.assertEqual((self.ids('4', self.engine.visual), self.engine.status()['skipped']), ([], 1))
        self.save(7)
        self.assertEqual(self.update(), {'visual': ['4', '7'], 'text': ['7']})
        self.save(8)
        self.assertEqual(self.update(), {'visual': ['8'], 'text': ['8']})
        self.assertEqual(self.engine.status()['skipped'], 0)
        self.assertEqual(self.index(), self.rebuilt())

    def test_a_picture_offline_at_an_update_is_read_once_it_is_back(self):
        self.update(); self.engine.close(); self.engine = self.open()  # the next process
        path = self.path(4); away = self.root/'away.png'
        os.rename(path, away)  # its drive or share is offline; its row stays
        self.save(7)
        self.assertEqual(self.update(), {'visual': [*ALL, '7'], 'text': ['7']})
        self.assertEqual(self.ids('4', self.engine.visual), [])
        os.rename(away, path)
        self.save(8)
        self.assertEqual(self.update(), {'visual': ['4', '8'], 'text': ['8']})
        self.save(9)
        self.assertEqual(self.update(), {'visual': ['9'], 'text': ['9']})
        self.assertEqual(self.engine.status()['skipped'], 0)
        self.assertEqual(self.index(), self.rebuilt())


class SaveTests(Gallery):
    """An update leaves the save of the shared ANN to its caller (the worker,
    once it has been quiet), so both indices are saved once, together."""
    def saves(self):
        return patch.object(Index, 'save', autospec=True, side_effect=Index.save)

    def test_an_update_leaves_the_save_to_its_caller(self):
        # One parameter chunk a step: the pictures are done long before the parameters.
        with patch.object(engine_module.Engine, 'batch_size', 1), self.saves() as saves:
            for change in (lambda: None, lambda: self.save(7)):
                change(); before = saves.call_count; self.update()
                self.assertEqual(saves.call_count, before)
                self.assertTrue(self.engine.pool.unsaved())
                self.engine.pool.checkpoint()
                self.assertEqual(saves.call_count, before + 1)
                self.assertFalse(self.engine.pool.unsaved())

    def test_a_long_build_saves_after_each_so_many_documents(self):
        # 6 pictures in one step, then 12 parameter chunks one a step.
        with patch.object(gallery, 'SAVE_EVERY', 10), patch.object(engine_module.Engine, 'batch_size', 1), \
                self.saves() as saves:
            self.update()
            self.assertEqual(saves.call_count, 1)  # at 10 of 18
            self.assertTrue(self.engine.pool.unsaved())

    def test_an_update_embeds_its_pictures_before_their_parameters(self):
        # An image loads the encoder with vision, which then embeds the
        # parameters too; a chunk first would load it without, then again.
        self.update(); self.engine.close(); self.engine = self.open()
        self.save(7); order = []
        embed = {engine: engine.embed_rows for engine in (gallery.VisualEngine, gallery.ParameterEngine)}
        def recorded(engine):
            def embed_rows(self, rows):
                order.append(engine.section); return embed[engine](self, rows)
            return embed_rows
        # Two pictures a step: the check of every picture reaches 7 in its fourth.
        with patch.object(gallery, 'CHECK', 2), \
             patch.object(gallery.VisualEngine, 'embed_rows', recorded(gallery.VisualEngine)), \
             patch.object(gallery.ParameterEngine, 'embed_rows', recorded(gallery.ParameterEngine)):
            self.assertEqual(self.update(), {'visual': [*ALL, '7'], 'text': ['7']})
        self.assertEqual(order, ['image', 'parameters'])

    def worker(self):
        self.models.unload = Mock()
        worker = Worker(); worker.models = self.models; worker.pool = self.engine.pool
        worker.engines = {'gallery': self.engine}
        return worker

    def run_job(self, worker):
        token = threading.Event()
        plan = worker.execute('preview', {'source': 'gallery'}, token)
        job = worker.execute('start', {'source': 'gallery', 'plan_id': plan['plan_id']}, token)['job_id']
        events = []
        with patch('worker.emit', side_effect=events.append):
            while job in worker.jobs: worker._step(job)
        self.assertEqual(events[-1]['phase'], 'complete')
        return events

    def test_the_worker_saves_an_update_once_it_has_been_quiet(self):
        worker = self.worker(); clock = [1000.0]
        with patch.object(worker_module.time, 'monotonic', lambda: clock[0]), self.saves() as saves:
            # The first build, then two pictures, each less than the quiet time after the last.
            for i in (None, 7, 8):
                if i: self.save(i)
                self.run_job(worker)
                self.assertEqual(saves.call_count, 0)
                self.assertEqual(worker._wait(), worker_module.CHECKPOINT_QUIET_SECONDS)
                clock[0] += worker_module.CHECKPOINT_QUIET_SECONDS - 1
                worker._idle()
            # Searches use the ANN in memory: the new pictures are in it before the save.
            self.assertTrue(all(i in self.engine.pool.ann for i in self.ids('7') + self.ids('8')))
            self.assertEqual(saves.call_count, 0)
            clock[0] += 1; worker._idle()
            self.assertEqual(saves.call_count, 1)
        self.assertFalse(self.engine.pool.unsaved()); self.assertTrue(self.engine.pool.mapped)
        self.assertIsNone(worker._checkpoint_due_in())
        self.assertEqual(self.index(), self.rebuilt())

    def test_a_save_that_fails_while_idle_is_reported_once_and_tried_at_the_next_build(self):
        # A full disk: each try writes the whole ANN before it fails.
        worker = self.worker(); clock = [1000.0]
        with patch.object(worker_module.time, 'monotonic', lambda: clock[0]):
            first = self.run_job(worker)[-1]['job_id']
            events = []
            with patch.object(type(self.engine.pool), 'checkpoint', autospec=True,
                              side_effect=OSError('No space left on device')) as save, \
                    patch('worker.emit', side_effect=events.append):
                # Half an hour of an idle app, until it closes the worker.
                while clock[0] < 1000 + 1800 and worker._wait() is not None:
                    clock[0] += worker._wait(); worker._idle()
                self.assertEqual(save.call_count, 1)
                self.assertEqual([(e['event'], e['source'], e['job_id'], e['phase'], e['code'], e['complete'])
                                  for e in events], [('index', 'gallery', first, 'error', 'rag_runtime_error', True)])
                # The next build that defers its save tries again, once quiet.
                self.save(7); second = self.run_job(worker)[-1]['job_id']
                clock[0] += worker._wait(); worker._idle()
                self.assertEqual(save.call_count, 2)
                self.assertEqual([(e['job_id'], e['phase']) for e in events[1:]], [(second, 'error')])
            self.assertTrue(self.engine.pool.unsaved())
            self.save(8); self.run_job(worker)
            clock[0] += worker._wait(); worker._idle()
        self.assertFalse(self.engine.pool.unsaved())
        self.assertEqual(self.index(), self.rebuilt())

    def test_a_failed_save_while_idle_is_not_reported_over_a_paused_update(self):
        # The pause saved at once (and failed): its own update reports later.
        worker = self.worker(); clock = [1000.0]; token = threading.Event()
        with patch.object(worker_module.time, 'monotonic', lambda: clock[0]):
            self.run_job(worker); self.save(7)
            plan = worker.execute('preview', {'source': 'gallery'}, token)
            job = worker.execute('start', {'source': 'gallery', 'plan_id': plan['plan_id']}, token)['job_id']
            events = []
            with patch.object(type(self.engine.pool), 'checkpoint', autospec=True,
                              side_effect=OSError('No space left on device')) as save, \
                    patch('worker.emit', side_effect=events.append):
                with self.assertRaises(OSError):
                    worker.execute('pause', {'source': 'gallery', 'job_id': job}, token)
                clock[0] += worker._wait(); worker._idle()
                self.assertEqual(save.call_count, 2)
            self.assertEqual(events, [])
            self.assertIsNone(worker._checkpoint_due_in())

    def test_pause_suspend_and_close_save_at_once(self):
        worker = self.worker(); self.run_job(worker); token = threading.Event()
        with self.saves() as saves:
            self.save(7); self.run_job(worker)
            worker.execute('suspend', {}, token)
            self.assertEqual(saves.call_count, 1); self.assertIsNone(worker._checkpoint_due_in())
            worker.execute('release', {}, token)
            self.save(8); self.run_job(worker)
            worker.close()
            self.assertEqual(saves.call_count, 2)

    def test_models_stay_loaded_for_the_next_update(self):
        worker = self.worker(); worker.last_use = 0
        self.models.encoder = object()
        self.run_job(worker)
        self.assertGreater(worker._unload_due_in(), worker_module.IDLE_UNLOAD_SECONDS - 5)

    def test_other_sources_still_save_when_their_build_ends(self):
        from test_rag import fixture
        from engine import Engine, Sources
        catalog = self.root/'catalog.db'; fixture(catalog, 8)
        tags = Engine(self.root/'index', self.models, Sources(catalog), pool=self.engine.pool)
        worker = self.worker(); worker.engines['tags'] = tags
        try:
            with self.saves() as saves:
                token = threading.Event()
                plan = worker.execute('preview', {'source': 'tags'}, token)
                job = worker.execute('start', {'source': 'tags', 'plan_id': plan['plan_id']}, token)['job_id']
                with patch('worker.emit'):
                    while job in worker.jobs: worker._step(job)
                self.assertEqual(saves.call_count, 1)
            self.assertIsNone(worker._checkpoint_due_in())
        finally: tags.close()


class RandomChangeTests(Gallery):
    """Random changes to the gallery, an update after each few: each update
    reads exactly the pictures whose rows changed (every picture after a
    root change, or when asked while complete), and leaves the index a
    build from nothing would make."""
    def records(self):
        return {part: GallerySources(self.database, self.roots, part == 'visual').records() for part in ('visual', 'text')}

    def change(self, rng, state):
        live = [i for i, in self.app.execute('SELECT id FROM gallery_images WHERE is_deleted=0')]
        deleted = [i for i, in self.app.execute('SELECT id FROM gallery_images WHERE is_deleted=1')]
        kind = rng.choice(['save', 'save', 'delete', 'restore', 'remove', 'move', 'replace', 'edit', 'nai',
                           'scanned', 'roots'])
        if kind == 'save' or not live:
            state['next'] += 1
            self.save(state['next'], rng.choice(LENGTHS), rng.random() < .8, rng.choice([self.library, self.other]))
            return kind
        i = rng.choice(live)
        if kind == 'delete': self.app.execute('UPDATE gallery_images SET is_deleted=1 WHERE id=?', (i,))
        elif kind == 'restore' and deleted:
            self.app.execute('UPDATE gallery_images SET is_deleted=0 WHERE id=?', (rng.choice(deleted),))
        elif kind == 'remove': self.app.execute('DELETE FROM gallery_images WHERE id=?', (i,))
        elif kind == 'move':
            folder = rng.choice([self.library/'子', self.other/'b', self.root/'外面', self.library])
            self.move(i, folder/rng.choice([f'{i}.png', f'{i}-moved.png']))
        elif kind == 'replace' and self.path(i).exists(): self.replace(i)
        elif kind == 'edit': self.edit(i, rng.choice(LENGTHS))
        elif kind == 'nai':
            self.app.execute("UPDATE gallery_metadata SET software=CASE software WHEN 'NovelAI' THEN 'Other' ELSE 'NovelAI' END,"
                             "model='sdxl' WHERE image_id=?", (i,))
        elif kind == 'scanned': self.app.execute('UPDATE gallery_images SET modified_at=modified_at+1 WHERE id=?', (i,))
        elif kind == 'roots':
            folders = rng.choice([[self.library], [self.library, self.other], [self.other]])
            self.set_roots(*folders)
            state['changed'] = state['changed'] or set(folders) != state['roots']; state['roots'] = set(folders)
        return kind

    def test_updates_match_a_build_from_nothing(self):
        for seed in range(4):
            with self.subTest(seed=seed):
                if seed: self.tearDown(); self.setUp()
                rng = random.Random(seed); state = {'next': 6, 'roots': {self.library}}
                self.update()
                for _ in range(12):
                    before = self.records(); complete = self.engine.status()['complete']
                    state['changed'] = False
                    kinds = [self.change(rng, state) for _ in range(rng.randint(1, 3))]
                    after = self.records()
                    # Every picture after a root change, or when asked while complete.
                    full = state['changed'] or complete and after == before
                    expected = {part: [o for o in after[part] if full or before[part].get(o) != after[part][o]]
                                for part in after}
                    self.assertEqual(self.update(), expected, kinds)
                    self.assertEqual(self.index(), self.rebuilt(), kinds)


if __name__ == '__main__':
    unittest.main()
