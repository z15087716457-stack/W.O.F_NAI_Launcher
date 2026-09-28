"""Snapshot Danbooru's public Tag Groups directory for offline browsing.

The snapshot is navigation data, not a second tag catalog. Tag metadata stays
in the shared local catalog and the runtime Danbooru database. Run explicitly
when refreshing the bundled directory; the application never crawls on open.
"""

import concurrent.futures
import json
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / "assets" / "databases" / "wiki_directory.json"
BASE = "https://safebooru.donmai.us/wiki_pages.json"
AGENT = "WOF-NAI-Studio-Wiki-Directory/1.0"
BULLET = re.compile(r"^([*]+)\s+(.+)$")
WIKI_LINK = re.compile(r"\[\[([^\]]+)\]\]")
HEADING = re.compile(r"^h([456])(?:#[^.]+)?\.\s+(.+)$")
MAX_PAGES = 320


def key(title: str) -> str:
    return title.split("|", 1)[0].strip().lower().replace(" ", "_")


def is_group(title: str) -> bool:
    return title.startswith("tag_group:") or title.startswith("list_of_")


def fetch(title: str) -> dict | None:
    query = urllib.parse.urlencode({"search[title]": title, "limit": 5})
    request = urllib.request.Request(
        f"{BASE}?{query}", headers={"User-Agent": AGENT}
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=25) as response:
                pages = json.load(response)
            return next((page for page in pages if key(page["title"]) == key(title)), None)
        except (OSError, ValueError) as error:
            if attempt == 3:
                print(f"Skipped {title}: {error}", flush=True)
                return None
            time.sleep(2 ** attempt)
    return None


def without_expands(body: str) -> str:
    return re.sub(r"\[expand(?:=[^\]]*)?\].*?\[/expand\]", "", body, flags=re.S)


def parse_root(body: str) -> tuple[list[dict], set[str]]:
    roots: list[dict] = []
    headings: dict[int, dict] = {}
    bullets: dict[int, dict] = {}
    referenced: set[str] = set()
    for line in without_expands(body).splitlines():
        heading = HEADING.match(line)
        if heading:
            level = int(heading.group(1))
            if heading.group(2).strip().lower() in {"intro", "see also"}:
                headings.clear()
                bullets.clear()
                continue
            node = {"label": heading.group(2).strip(), "children": []}
            if level == 5 or 5 not in headings:
                roots.append(node)
            else:
                headings[5]["children"].append(node)
            headings[level] = node
            for old in list(headings):
                if old > level:
                    del headings[old]
            bullets.clear()
            continue
        bullet = BULLET.match(line)
        if not bullet or not headings:
            continue
        link = WIKI_LINK.search(bullet.group(2))
        if link is None:
            continue
        title = key(link.group(1))
        if not is_group(title):
            continue
        depth = len(bullet.group(1))
        node = {
            "label": title.removeprefix("tag_group:").replace("_", " ").title(),
            "group": title,
            "children": [],
        }
        parent = bullets.get(depth - 1) or headings.get(6) or headings.get(5)
        if parent is None:
            continue
        parent["children"].append(node)
        bullets[depth] = node
        for old in list(bullets):
            if old > depth:
                del bullets[old]
        referenced.add(title)
    return roots, referenced


def parse_group(body: str) -> tuple[list[str], list[str]]:
    members: list[str] = []
    children: list[str] = []
    seen_members: set[str] = set()
    seen_children: set[str] = set()
    for line in without_expands(body).splitlines():
        heading = HEADING.match(line)
        if heading and heading.group(2).strip().lower().startswith(("related", "see also")):
            break
        bullet = BULLET.match(line)
        if not bullet:
            continue
        for link in WIKI_LINK.finditer(bullet.group(2)):
            title = key(link.group(1))
            if title == "tag_groups":
                continue
            if is_group(title):
                if title not in seen_children:
                    seen_children.add(title)
                    children.append(title)
            elif title not in seen_members:
                seen_members.add(title)
                members.append(title)
    return members, children


def main() -> None:
    root_page = fetch("tag_groups")
    if root_page is None:
        raise SystemExit("Official tag_groups page was unavailable")
    roots, pending = parse_root(root_page["body"])
    groups: dict[str, dict] = {}
    visited: set[str] = set()
    while pending and len(visited) < MAX_PAGES:
        batch = sorted(pending - visited)[:32]
        pending.difference_update(batch)
        if not batch:
            break
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            results = list(executor.map(fetch, batch))
        for title, page in zip(batch, results):
            visited.add(title)
            if page is None:
                continue
            members, children = parse_group(page["body"])
            groups[title] = {
                "title": page["title"],
                "members": members,
                "children": children,
                "source_url": "https://safebooru.donmai.us/wiki_pages/"
                + urllib.parse.quote(title, safe=":"),
            }
            pending.update(child for child in children if child not in visited)
        print(f"Fetched {len(visited)} groups, {len(pending)} queued", flush=True)
    if len(groups) < 80 or not roots:
        raise SystemExit(f"Directory snapshot incomplete: {len(groups)} groups")
    payload = {
        "source_url": "https://safebooru.donmai.us/wiki_pages/tag_groups",
        "source_updated_at": root_page.get("updated_at"),
        "roots": roots,
        "groups": {name: groups[name] for name in sorted(groups)},
    }
    TARGET.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"Wrote {TARGET}: {len(groups)} groups", flush=True)


if __name__ == "__main__":
    main()
