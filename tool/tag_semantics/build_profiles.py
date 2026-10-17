"""Build a separate Chinese semantic supplement from a pinned public CSV.

No network, model, user database or vector index is opened by this builder.
The original source remains available, including rows quarantined by validation.
"""
import argparse
import csv
import hashlib
import json
import re
import sqlite3
import tempfile
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
COLUMNS = ('name', 'cn_name', 'wiki', 'post_count', 'category', 'nsfw')
SCHEMA_VERSION = 1
BUILD_RULE = 'wof-zh-tag-profiles-v1'


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def row_digest(row):
    return hashlib.sha256(json.dumps([row[c] for c in COLUMNS],
        ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()


def read_profiles(source, lock):
    if source.stat().st_size != lock['size'] or sha256(source) != lock['sha256']:
        raise ValueError('source_hash_mismatch')
    with source.open(encoding=lock['encoding'], newline='') as stream:
        reader = csv.DictReader(stream)
        if tuple(reader.fieldnames or []) != COLUMNS:
            raise ValueError('source_columns_changed')
        rows = list(reader)
    if len(rows) != lock['expectedRows']:
        raise ValueError('source_count_mismatch')
    if any(set(row) != set(COLUMNS) or any(v is None for v in row.values()) for row in rows):
        raise ValueError('malformed_source_row')
    counts = Counter(row['name'] for row in rows)
    profiles, issues = [], []
    for number, row in enumerate(rows, 2):
        tag = row['name']
        reason = ''
        if counts[tag] > 1:
            reason = 'duplicate_tag_requires_review'
        elif not tag or tag != tag.strip().lower() or any(c.isspace() or ord(c) < 32 for c in tag):
            reason = 'noncanonical_name_requires_review'
        try:
            count, category, sensitive = (int(row[c]) for c in ('post_count', 'category', 'nsfw'))
            if count < 0 or category not in (0, 1, 3, 4, 5) or sensitive not in (0, 1):
                raise ValueError()
        except ValueError:
            reason = reason or 'invalid_metadata_requires_review'
            count = category = sensitive = 0
        terms = list(dict.fromkeys(t.strip() for t in re.split(r'[,，|、]', row['cn_name']) if t.strip()))
        if not terms:
            reason = reason or 'missing_chinese_terms'
        if reason:
            issues.append((number, tag, reason, json.dumps(row, ensure_ascii=False), row_digest(row)))
            continue
        # A missing summary remains missing: never turn synonyms into a made-up definition.
        profiles.append((tag, json.dumps(terms, ensure_ascii=False), terms[0], row['wiki'].strip(),
                         category, count, sensitive, number, row_digest(row)))
    summary = {'sourceRows': len(rows), 'profiles': len(profiles),
               'quarantinedRows': len(issues), 'missingSummaries': sum(not r[3] for r in profiles),
               'categories': dict(sorted(Counter(str(r[4]) for r in profiles).items()))}
    for field, expected in [('profiles', 'expectedProfiles'), ('quarantinedRows', 'expectedQuarantinedRows'),
                            ('missingSummaries', 'expectedMissingSummaries')]:
        if expected in lock and summary[field] != lock[expected]:
            raise ValueError('unexpected_' + field)
    return profiles, issues, summary


def build(source, lock, target):
    """Validate first, then atomically publish this one independent database."""
    source, target = Path(source), Path(target)
    if source.resolve() == target.resolve():
        raise ValueError('source_is_target')
    profiles, issues, summary = read_profiles(source, lock)
    version = hashlib.sha256((BUILD_RULE + ':' + lock['sha256']).encode()).hexdigest()[:12]
    metadata = {'schema_version': str(SCHEMA_VERSION), 'data_version': version,
                'build_rule': BUILD_RULE, 'language': 'zh', 'source_repository': lock['repository'],
                'source_commit': lock['commit'], 'source_path': lock['path'],
                'source_sha256': lock['sha256'], 'source_license': lock['license'],
                **{key: json.dumps(value, ensure_ascii=False, sort_keys=True) for key, value in summary.items()}}
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='tag-profiles-', dir=target.parent) as temporary:
        pending = Path(temporary) / 'profiles.db'
        db = sqlite3.connect(pending)
        try:
            db.executescript('''
                PRAGMA page_size=4096;
                PRAGMA journal_mode=OFF;
                CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL) WITHOUT ROWID;
                CREATE TABLE tag_semantics(
                  tag TEXT PRIMARY KEY, synonyms_zh TEXT NOT NULL, core_zh TEXT NOT NULL,
                  summary_zh TEXT NOT NULL, category INTEGER NOT NULL,
                  source_post_count INTEGER NOT NULL, sensitive INTEGER NOT NULL,
                  source_row INTEGER NOT NULL, source_row_sha256 TEXT NOT NULL
                ) WITHOUT ROWID;
                CREATE TABLE source_issues(
                  source_row INTEGER PRIMARY KEY, source_tag TEXT NOT NULL, reason TEXT NOT NULL,
                  original_json TEXT NOT NULL, source_row_sha256 TEXT NOT NULL
                );
            ''')
            db.executemany('INSERT INTO metadata VALUES(?,?)', sorted(metadata.items()))
            db.executemany('INSERT INTO tag_semantics VALUES(?,?,?,?,?,?,?,?,?)', sorted(profiles))
            db.executemany('INSERT INTO source_issues VALUES(?,?,?,?,?)', issues)
            db.commit()
            db.execute('VACUUM')
            if db.execute('PRAGMA integrity_check').fetchone()[0] != 'ok':
                raise ValueError('database_integrity_failed')
            if db.execute('SELECT COUNT(*) FROM tag_semantics').fetchone()[0] != len(profiles):
                raise ValueError('database_count_mismatch')
        finally:
            db.close()
        pending.replace(target)
    return {'schemaVersion': SCHEMA_VERSION, 'dataVersion': version,
            'sha256': sha256(target), 'size': target.stat().st_size, **summary}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=ROOT / 'tool/tag_semantics/sources/tags_enhanced.csv')
    args = parser.parse_args()
    lock = json.loads((ROOT / 'tool/tag_semantics/source_lock.json').read_text('utf-8'))
    license_file = ROOT / 'assets/licenses/DanbooruSearchOnline-GPL-3.0.txt'
    if sha256(license_file) != lock['licenseSha256']:
        raise ValueError('upstream_license_changed')
    target = ROOT / 'assets/databases/tag_semantics.db'
    result = build(args.source, lock, target)
    manifest_file = ROOT / 'assets/databases/manifest.json'
    manifest = json.loads(manifest_file.read_text('utf-8'))
    manifest['databases'][target.name] = {key: result[key] for key in ('schemaVersion', 'dataVersion', 'sha256', 'size')}
    pending = manifest_file.with_suffix('.json.building')
    pending.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', 'utf-8')
    pending.replace(manifest_file)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
