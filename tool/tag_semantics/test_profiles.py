import csv
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from build_profiles import ROOT, COLUMNS, build, read_profiles, sha256


class ProfilesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.lock = json.loads((ROOT / 'tool/tag_semantics/source_lock.json').read_text('utf-8'))
        self.source = ROOT / 'tool/tag_semantics/sources/tags_enhanced.csv'

    def fixture(self, rows):
        source = self.root / 'source.csv'
        with source.open('w', encoding='gbk', newline='') as stream:
            writer = csv.DictWriter(stream, COLUMNS)
            writer.writeheader()
            writer.writerows(rows)
        lock = {**self.lock, 'sha256': sha256(source), 'size': source.stat().st_size,
                'expectedRows': len(rows)}
        for field in ('expectedProfiles', 'expectedQuarantinedRows', 'expectedMissingSummaries'):
            lock.pop(field)
        return source, lock

    @staticmethod
    def row(tag='grass'):
        return dict(name=tag, cn_name='草地,草,户外', wiki='绿色草本植物。',
                    post_count='100', category='0', nsfw='0')

    def test_every_published_profile_round_trips_the_pinned_source(self):
        profiles, issues, summary = read_profiles(self.source, self.lock)
        db = sqlite3.connect(ROOT / 'assets/databases/tag_semantics.db')
        self.addCleanup(db.close)
        self.assertEqual(db.execute('PRAGMA integrity_check').fetchone()[0], 'ok')
        self.assertEqual(db.execute('SELECT * FROM tag_semantics ORDER BY tag').fetchall(), sorted(profiles))
        self.assertEqual(db.execute('SELECT * FROM source_issues ORDER BY source_row').fetchall(), issues)
        self.assertEqual(summary['profiles'], 53860)
        self.assertEqual(summary['missingSummaries'], 1)
        grass = db.execute("SELECT synonyms_zh,core_zh,summary_zh FROM tag_semantics WHERE tag='grass'").fetchone()
        self.assertEqual(json.loads(grass[0]), ['草地', '草', '户外', '自然'])
        self.assertEqual(grass[1], '草地')
        self.assertIn('植物', grass[2])
        self.assertEqual(len(issues), 3)

    def test_rebuilding_from_original_bytes_is_reproducible(self):
        target = self.root / 'profiles.db'
        result = build(self.source, self.lock, target)
        self.assertEqual(result['sha256'], sha256(ROOT / 'assets/databases/tag_semantics.db'))
        license_file = ROOT / 'assets/licenses/DanbooruSearchOnline-GPL-3.0.txt'
        self.assertEqual(sha256(license_file), self.lock['licenseSha256'])
        db = sqlite3.connect(target)
        self.addCleanup(db.close)
        metadata = dict(db.execute('SELECT key,value FROM metadata'))
        self.assertEqual(metadata['source_sha256'], self.lock['sha256'])
        self.assertEqual(metadata['source_commit'], self.lock['commit'])
        self.assertEqual(metadata['source_license'], 'GPL-3.0')

    def test_changed_source_is_rejected_without_replacing_a_published_file(self):
        source, lock = self.fixture([self.row()])
        target = self.root / 'profiles.db'
        build(source, lock, target)
        before = target.read_bytes()
        source.write_bytes(source.read_bytes() + b'changed')
        with self.assertRaisesRegex(ValueError, 'source_hash_mismatch'):
            build(source, lock, target)
        self.assertEqual(target.read_bytes(), before)

    def test_duplicate_and_noncanonical_names_are_quarantined_losslessly(self):
        rows = [self.row(), self.row(), self.row('bad name'), self.row('valid_tag')]
        source, lock = self.fixture(rows)
        profiles, issues, summary = read_profiles(source, lock)
        self.assertEqual([r[0] for r in profiles], ['valid_tag'])
        self.assertEqual([json.loads(r[3]) for r in issues], rows[:3])
        self.assertEqual(summary['quarantinedRows'], 3)

    def test_missing_summary_stays_empty_and_synonyms_are_not_a_definition(self):
        row = self.row(); row['wiki'] = ''; row['cn_name'] = '草地，草|户外、草地'
        source, lock = self.fixture([row])
        profiles, _, summary = read_profiles(source, lock)
        self.assertEqual(json.loads(profiles[0][1]), ['草地', '草', '户外'])
        self.assertEqual(profiles[0][3], '')
        self.assertEqual(summary['missingSummaries'], 1)

    def test_invalid_metadata_is_not_silently_installed(self):
        rows = [self.row('negative_count'), self.row('bad_category'), self.row('bad_flag')]
        rows[0]['post_count'] = '-1'; rows[1]['category'] = '99'; rows[2]['nsfw'] = '2'
        source, lock = self.fixture(rows)
        profiles, issues, _ = read_profiles(source, lock)
        self.assertEqual(profiles, [])
        self.assertTrue(all(r[2] == 'invalid_metadata_requires_review' for r in issues))

    def test_changed_expected_counts_reject_before_publication(self):
        source, lock = self.fixture([self.row()]); lock['expectedProfiles'] = 2
        target = self.root / 'profiles.db'; target.write_bytes(b'previous')
        with self.assertRaisesRegex(ValueError, 'unexpected_profiles'):
            build(source, lock, target)
        self.assertEqual(target.read_bytes(), b'previous')


if __name__ == '__main__':
    unittest.main()
