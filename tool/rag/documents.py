"""Separate text collections for Wiki passages and saved prompt blocks."""
import hashlib
import json
from pathlib import Path

from engine import Engine, readonly

CHUNK = 1200
OVERLAP = 120
STRIDE = CHUNK - OVERLAP


def count_chunks(text):
    return max(1, (len(text) - OVERLAP + STRIDE - 1) // STRIDE)


def key(owner, section, index):
    return json.dumps([owner, section, index], ensure_ascii=False, separators=(',', ':'))


def document(owner, title, section, index, body, category=0, extra=''):
    snippet = body[index * STRIDE:index * STRIDE + CHUNK]
    text = title[:256] + ('; ' + extra[:512] if extra else '') + '\n' + section + ': ' + snippet
    return {'name': key(owner, section, index), 'category': category, 'post_count': 0,
            'aliases': [], 'text': text, 'digest': hashlib.sha256(text.encode()).hexdigest(),
            'owner': owner, 'title': title, 'snippet': snippet[:320], 'section': section}


class TextSources:
    def __init__(self, path):
        self.path = Path(path).resolve(strict=True)
        self._counts = None

    def signature(self):
        records = ['wof-text-passages-v1', CHUNK, OVERLAP]
        for path in (self.path, Path(str(self.path) + '-wal')):
            if path.exists():
                info = path.stat(); records.append((str(path), info.st_size, info.st_mtime_ns))
        return hashlib.sha256(json.dumps(records).encode()).hexdigest()

    def counts(self): raise NotImplementedError
    def count(self): return self.counts()[1]
    def document_count(self): return self.counts()[0]


class WikiSources(TextSources):
    def __init__(self, path, catalog):
        super().__init__(path)
        self.catalog = Path(catalog).resolve(strict=True)

    def signature(self):
        info = self.catalog.stat()
        return hashlib.sha256((super().signature()+str((info.st_size,info.st_mtime_ns))).encode()).hexdigest()

    def counts(self):
        signature = self.signature()
        if self._counts and self._counts[0] == signature: return self._counts[1]
        db = readonly(self.path)
        try:
            result = db.execute('SELECT COUNT(*),COALESCE(SUM(MAX(1,(length(body)-120+1079)/1080)),0) FROM wiki_pages WHERE length(trim(body))>0').fetchone()
            self._counts = (signature, result); return result
        finally: db.close()

    def ordered_names(self):
        db = readonly(self.path)
        try:
            return [key(tag, 'article', i) for tag, size in db.execute('SELECT tag,length(body) FROM wiki_pages WHERE length(trim(body))>0 ORDER BY tag')
                    for i in range(max(1, (size - OVERLAP + STRIDE - 1) // STRIDE))]
        finally: db.close()

    def rows(self, offset=0, limit=64, names=None):
        if names is None: names = self.ordered_names()[offset:offset+limit]
        if not names: return []
        decoded = [json.loads(name) for name in names[:limit]]
        owners = list(dict.fromkeys(item[0] for item in decoded))
        db = readonly(self.path); catalog = readonly(self.catalog)
        try:
            placeholders = ','.join('?' for _ in owners)
            pages = {r[0]: r[1] for r in db.execute('SELECT tag,body FROM wiki_pages WHERE tag IN (' + placeholders + ')', owners)}
            categories = dict(catalog.execute('SELECT name,category FROM tags WHERE name IN (' + placeholders + ')', owners))
            return [document(owner, owner.replace('_',' '), section, index, pages[owner], categories.get(owner,0))
                    for owner, section, index in decoded if owner in pages and pages[owner].strip()
                    and section == 'article' and 0 <= index < count_chunks(pages[owner])]
        finally: db.close(); catalog.close()


class BlockSources(TextSources):
    def __init__(self, path):
        super().__init__(path); self._snapshot = None

    def snapshot(self):
        signature = self.signature()
        if self._snapshot and self._snapshot[0] == signature: return self._snapshot[1]
        if self.path.stat().st_size > 64 * 1024 * 1024: raise ValueError('source_too_large')
        data = json.loads(self.path.read_text('utf-8'))
        if data.get('version') != 1 or not isinstance(data.get('blocks'), list): raise ValueError('invalid_snapshot')
        records = {}
        for item in data['blocks']:
            if not isinstance(item.get('id'), str) or not isinstance(item.get('title'), str): raise ValueError('invalid_snapshot')
            if item['id'] in records: raise ValueError('invalid_snapshot')
            records[item['id']] = item
        self._snapshot = (signature, records); return records

    @staticmethod
    def sections(item):
        return [(name, item.get(name, '')) for name in ('positive','negative','reading') if item.get(name, '').strip()] or [('title', item['title'])]

    def counts(self):
        records = self.snapshot()
        return len(records), sum(count_chunks(body) for item in records.values() for _,body in self.sections(item))

    def ordered_names(self):
        return [key(owner, section, i) for owner,item in sorted(self.snapshot().items())
                for section,body in self.sections(item) for i in range(count_chunks(body))]

    def rows(self, offset=0, limit=64, names=None):
        records = self.snapshot()
        if names is None: names = self.ordered_names()[offset:offset+limit]
        result = []
        for name in names[:limit]:
            owner, section, index = json.loads(name); item = records.get(owner)
            if not item: continue
            body = dict(self.sections(item)).get(section)
            if body is None or not 0 <= index < count_chunks(body): continue
            result.append(document(owner,item['title'],section,index,body,
                extra=', '.join(item.get('tags', []))))
        return result


class TextEngine(Engine):
    def __init__(self, directory, models, sources):
        super().__init__(directory, models, sources)
        self.db.execute("CREATE INDEX IF NOT EXISTS documents_owner ON documents(json_extract(name,'$[0]'))")
        self.db.execute('CREATE INDEX IF NOT EXISTS documents_category ON documents(category)')
        self.db.commit()

    def preview(self):
        return {**super().preview(), 'documents':self.sources.document_count()}

    def search_text(self, query, allowed=None, categories=None, limit=40, cancelled=lambda:False):
        import numpy as np
        query = query.strip()
        if not query or not len(self.ann) or allowed == [] or categories == []: return {'items':[]}
        if cancelled(): raise ValueError('cancelled')
        # Search queries have their own bounded budget; the 120-token modes
        # apply only to prompt-editor recommendations, never whole articles.
        if self.models.count(query) > 256:
            low, high = 0, len(query)
            while low < high:
                middle = (low+high+1)//2
                if self.models.count(query[:middle]) <= 256: low = middle
                else: high = middle-1
            query = query[:low]
        vector = self.models.embed([query],query=True)[0]
        conditions = []; args = []
        if categories is not None:
            conditions.append('category IN (' + ','.join('?' for _ in categories) + ')'); args.extend(categories)
        rows = []
        if allowed is not None or categories is not None:
            # A scoped query ranks the vectors inside the scope. Filtering only
            # the global nearest neighbours loses small folders/bookmarks.
            groups = [None] if allowed is None else [allowed[i:i+400] for i in range(0,len(allowed),400)]
            for group in groups:
                where = list(conditions); values = list(args)
                if group is not None:
                    where.append("json_extract(name,'$[0]') IN (" + ','.join('?' for _ in group) + ')'); values.extend(group)
                for row in self.db.execute('SELECT name,digest,vector FROM documents WHERE ' + ' AND '.join(where),values):
                    if cancelled(): raise ValueError('cancelled')
                    stored = np.frombuffer(row[2],dtype=np.float32)
                    score = float(np.dot(stored,vector)/max(np.linalg.norm(stored),1e-8))
                    rows.append((score,row[0],row[1]))
            rows.sort(reverse=True); rows = rows[:160]
        else:
            matches = self.ann.search(vector,min(160,len(self.ann)))
            for rank, item in enumerate(matches.keys):
                row = self.db.execute('SELECT name,digest FROM documents WHERE id=?',(int(item),)).fetchone()
                if row: rows.append((-rank,*row))
        live = {r['name']:r for r in self.sources.rows(names=[r[1] for r in rows],limit=160)}
        candidates = {}; rank = {}
        for index,(_,name,digest) in enumerate(rows):
            item = live.get(name)
            if not item or item['digest'] != digest or item['owner'] in candidates: continue
            candidates[item['owner']] = item; rank[item['owner']] = index
            if len(candidates) == 32: break
        if cancelled(): raise ValueError('cancelled')
        values = list(candidates.values())
        scores = self.models.rerank(query,[item['text'] for item in values],purpose='retrieval')
        if cancelled(): raise ValueError('cancelled')
        order = sorted(range(len(values)),key=lambda i:(-scores[i],rank[values[i]['owner']]))
        return {'items':[{'id':values[i]['owner'],'title':values[i]['title'],'snippet':values[i]['snippet'],
                          'section':values[i]['section']} for i in order[:max(1,min(80,limit))]]}
