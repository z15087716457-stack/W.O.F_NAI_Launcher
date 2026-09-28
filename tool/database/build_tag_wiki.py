"""Build the read-only, exact-tag wiki index from the bundled CSV.

Run from the repository root with Python 3. The source CSV remains the source
of truth; this small lookup database is shared by tag expansion and the future
standalone tag encyclopedia.
"""

import csv
import hashlib
import json
import sqlite3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/translations/github_chening233.csv"
TARGET = ROOT / "assets/databases/tag_wiki.db"
MANIFEST = ROOT / "assets/databases/manifest.json"
SCHEMA_VERSION = 1


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    version = sha256(SOURCE)[:12]
    temporary = TARGET.with_suffix(".db.building")
    temporary.unlink(missing_ok=True)
    connection = sqlite3.connect(temporary)
    try:
        connection.executescript(
            """
            PRAGMA page_size=4096;
            PRAGMA journal_mode=OFF;
            PRAGMA synchronous=OFF;
            CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL);
            CREATE TABLE wiki_pages (
              tag TEXT PRIMARY KEY,
              body TEXT NOT NULL,
              source_url TEXT NOT NULL
            ) WITHOUT ROWID;
            """
        )
        connection.executemany(
            "INSERT INTO metadata(key, value) VALUES (?, ?)",
            [("schema_version", str(SCHEMA_VERSION)), ("data_version", version)],
        )
        count = 0
        with SOURCE.open("r", encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream)
            if reader.fieldnames is None or not {
                "tag", "danbooru_text", "danbooru_url"
            }.issubset(reader.fieldnames):
                raise ValueError("Wiki CSV columns changed")
            for row in reader:
                tag = row["tag"].strip().lower().replace(" ", "_")
                body = " ".join(row["danbooru_text"].split())
                if not tag or not body or body.lower() == "none":
                    continue
                url = row["danbooru_url"].strip()
                if not url.startswith("https://danbooru.donmai.us/wiki_pages/"):
                    url = ""
                connection.execute(
                    "INSERT OR REPLACE INTO wiki_pages VALUES (?, ?, ?)",
                    (tag, body, url),
                )
                count += 1
        connection.commit()
        connection.execute("VACUUM")
        if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
            raise ValueError("Wiki database integrity check failed")
    finally:
        connection.close()
    temporary.replace(TARGET)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    manifest["databases"][TARGET.name] = {
        "schemaVersion": SCHEMA_VERSION,
        "dataVersion": version,
        "sha256": sha256(TARGET),
        "size": TARGET.stat().st_size,
    }
    MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Indexed {count} wiki rows; database {TARGET.stat().st_size} bytes")


if __name__ == "__main__":
    main()
