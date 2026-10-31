"""Persistent, resumable tag vectors and a derived USearch ANN index.

Sources are opened read-only. Only an explicit confirmed plan creates vectors.
Draft windows are query data and are never written into the index or diagnostics.
"""
import hashlib
import json
import math
import os
import re
from pathlib import Path
import sqlite3
import time

from context import context_window, clean_tag
from pool import VectorPool


def readonly(path, *, timeout=5.0):
    return sqlite3.connect(Path(path).resolve(strict=True).as_uri() + '?mode=ro', uri=True, timeout=timeout)


class Sources:
    representation_version = 'tag-profile-v2'

    def __init__(self, catalog, runtime='', wiki='', semantics='', supplements='', *, optional_supplements=False):
        self.paths = [str(Path(p).resolve(strict=True)) if p else '' for p in (catalog, runtime, wiki, semantics, supplements)]
        self._count_cache = None
        self.optional_supplements = optional_supplements
        self.degraded = False

    def _file_signature(self, paths):
        records = []
        for name in paths:
            if not name: continue
            for p in (Path(name), Path(name + '-wal')):
                if p.exists():
                    s = p.stat(); records.append((str(p), s.st_size, s.st_mtime_ns))
        return hashlib.sha256(json.dumps([self.representation_version, records]).encode()).hexdigest()

    def change_state(self):
        revision = 0
        if self.paths[4]:
            db = readonly(self.paths[4], timeout=0.2)
            try: revision = db.execute('SELECT revision FROM semantic_state').fetchone()[0]
            except sqlite3.OperationalError: revision = None
            finally: db.close()
        return {'base':self._file_signature(self.paths[:4]), 'revision':revision}

    def signature(self):
        state = self.change_state()
        if state['revision'] is None: return self._file_signature(self.paths)
        return hashlib.sha256(json.dumps([state,self.paths[4]]).encode()).hexdigest()

    def changed_names(self, metadata):
        state = self.change_state()
        if (state['revision'] is None or not self.paths[4] or
            metadata.get('source_base') != state['base'] or 'semantic_revision' not in metadata): return None
        db, union = self.connect()
        try:
            return [r[0] for r in db.execute('SELECT c.tag FROM supplements.semantic_changes c JOIN ('+union+
                ') t ON t.name=c.tag WHERE c.revision>? ORDER BY c.revision,c.tag', (int(metadata['semantic_revision']),))]
        finally: db.close()

    def connect(self, *, details=True):
        db = readonly(self.paths[0])
        if self.optional_supplements: db.execute('PRAGMA busy_timeout=200')
        runtime = False
        if self.paths[1]:
            db.execute('ATTACH DATABASE ? AS runtime', (Path(self.paths[1]).as_uri() + '?mode=ro',))
            runtime = bool(db.execute("SELECT 1 FROM runtime.sqlite_master WHERE name='danbooru_tags'").fetchone())
        if details and self.paths[2]:
            db.execute('ATTACH DATABASE ? AS wiki', (Path(self.paths[2]).as_uri() + '?mode=ro',))
        for schema, name in zip(('semantics', 'supplements'), self.paths[3:]):
            if not details or not name: continue
            try:
                db.execute('ATTACH DATABASE ? AS ' + schema, (Path(name).as_uri() + '?mode=ro',))
                if schema == 'supplements' and self.optional_supplements:
                    db.execute('SELECT tag FROM supplements.tag_semantics LIMIT 1').fetchone()
            except sqlite3.OperationalError as error:
                db.close()
                if (schema != 'supplements' or not self.optional_supplements or
                    getattr(error, 'sqlite_errorcode', 0) & 255 not in (sqlite3.SQLITE_BUSY, sqlite3.SQLITE_LOCKED)):
                    raise
                # Only the per-search Sources copy may omit an unavailable overlay.
                self.paths[4] = ''; self.degraded = True
                return self.connect()
        union = ('SELECT tag name, category, post_count FROM runtime.danbooru_tags UNION ALL '
                 'SELECT name, category, post_count FROM tags t WHERE NOT EXISTS '
                 '(SELECT 1 FROM runtime.danbooru_tags r WHERE r.tag=t.name)' if runtime else
                 'SELECT name, category, post_count FROM tags')
        return db, union

    def count(self):
        signature = self._file_signature(self.paths[:2])
        if self._count_cache and self._count_cache[0] == signature:
            return self._count_cache[1]
        db, union = self.connect(details=False)
        try:
            total = db.execute('SELECT COUNT(*) FROM (' + union + ')').fetchone()[0]
            if self._file_signature(self.paths[:2]) == signature: self._count_cache = (signature, total)
            return total
        finally: db.close()

    def rows(self, offset=0, limit=64, names=None):
        db, union = self.connect()
        try:
            sql = 'SELECT name, category, post_count FROM (' + union + ')'
            args = []
            if names is not None:
                if not names: return []
                sql += ' WHERE name IN (' + ','.join('?' for _ in names) + ')'; args.extend(names)
            sql += ' ORDER BY post_count DESC, name LIMIT ? OFFSET ?'; args.extend([limit, offset])
            rows = db.execute(sql, args).fetchall(); result = []
            for name, category, count in rows:
                aliases = [r[0] for r in db.execute('SELECT a.alias FROM aliases a JOIN tags t ON t.id=a.tag_id WHERE t.name=? ORDER BY a.alias LIMIT 24', (name,))]
                body = ''; full_body = ''
                if self.paths[2]:
                    row = db.execute('SELECT body FROM wiki.wiki_pages WHERE tag=?', (name,)).fetchone()
                    if row: full_body = row[0] or ''; body = full_body[:500]
                profile = {'core_zh':'', 'synonyms_zh':[], 'summary_zh':''}
                for schema, path in zip(('semantics', 'supplements'), self.paths[3:]):
                    if not path: continue
                    row = db.execute('SELECT core_zh,synonyms_zh,summary_zh FROM '+schema+'.tag_semantics WHERE tag=?',(name,)).fetchone()
                    if row:
                        summary = row[2]
                        if schema == 'supplements' and summary:
                            columns = {r[1] for r in db.execute('PRAGMA supplements.table_info(tag_semantics)')}
                            column = 'summary_hash' if 'summary_hash' in columns else 'wiki_hash'
                            saved = db.execute('SELECT '+column+' FROM supplements.tag_semantics WHERE tag=?',(name,)).fetchone()[0]
                            if saved != hashlib.sha256(full_body.encode()).hexdigest(): summary = ''
                        for key, value in zip(profile, (row[0], json.loads(row[1]), summary)):
                            if value: profile[key] = value
                text = clean_tag(name)
                if self.paths[3] or self.paths[4]:
                    text = 'Tag: ' + text + '\nCategory: ' + category_name(category)
                    if profile['core_zh']: text += '\nChinese name: ' + profile['core_zh']
                    if profile['synonyms_zh']: text += '\nChinese synonyms: ' + '; '.join(profile['synonyms_zh'])
                    if profile['summary_zh']: text += '\nMeaning: ' + profile['summary_zh']
                if aliases: text += '; aliases: ' + ', '.join(aliases)
                if body: text += '; description: ' + body
                digest = hashlib.sha256(json.dumps([self.representation_version, text, category], ensure_ascii=False).encode()).hexdigest()
                result.append({'name': name, 'category': category, 'post_count': count,
                    'aliases': aliases, 'text': text, 'digest': digest, **profile})
            return result
        finally: db.close()

    def exact_names(self, query, limit=80):
        """Canonical/official aliases and Chinese names, always checked live."""
        normalized = clean_tag(query).lower().replace(' ', '_')
        db, union = self.connect()
        try:
            names = [r[0] for r in db.execute('SELECT name FROM ('+union+') WHERE name=?', (normalized,))]
            names.extend(r[0] for r in db.execute('SELECT t.name FROM aliases a JOIN tags t ON t.id=a.tag_id WHERE a.alias=? LIMIT ?', (normalized, limit)))
            for schema, path in zip(('semantics', 'supplements'), self.paths[3:]):
                if not path: continue
                # Expanded expressions are recall hints, not canonical aliases.
                # For example "nature" in grass's profile must not pin grass as
                # an exact identity match ahead of the semantic ranking.
                names.extend(r[0] for r in db.execute('SELECT tag FROM '+schema+'''.tag_semantics s
                    WHERE core_zh=? LIMIT ?''', (query, limit)))
            return list(dict.fromkeys(names))[:limit]
        finally: db.close()

    def danbooru_counts(self, names):
        if not self.paths[1] or not names: return {}
        db=readonly(self.paths[1])
        try:
            if not db.execute("SELECT 1 FROM sqlite_master WHERE name='danbooru_tags'").fetchone(): return {}
            return dict(db.execute('SELECT tag,post_count FROM danbooru_tags WHERE tag IN ('+
                ','.join('?' for _ in names)+')',names))
        finally: db.close()

    def core_concepts(self, query, limit=4):
        """Protect explicit known concepts in compound Chinese descriptions.

        Broad expansion terms are not treated as identity evidence. A one-Han
        core additionally needs a longer matching name from the same profile.
        Negated mentions and nested shorter cores are not pinned.
        """
        if not re.search(r'[\u3400-\u9fff]',query): return []
        db, _ = self.connect(); records = {}
        try:
            for schema,path in zip(('semantics','supplements'),self.paths[3:]):
                if not path: continue
                for name,core,terms in db.execute('SELECT tag,core_zh,synonyms_zh FROM '+schema+
                    '.tag_semantics WHERE length(core_zh)>0 AND instr(?,core_zh)>0 ORDER BY length(core_zh) DESC,tag LIMIT 128',(query,)):
                    start=query.find(core)
                    if re.search(r'(?:不要|没有|不是|并非|不带|不含|避免|排除|无)[\u3400-\u9fff]{0,2}$',query[max(0,start-5):start]): continue
                    if len(core)<2 and not any(len(t)>=2 and core in t and t in query for t in json.loads(terms)): continue
                    records[name]=core
        finally: db.close()
        live={r['name']:r for r in self.rows(names=list(records),limit=256)}
        groups={}
        for name in records:
            if name not in live: continue
            core=live[name]['core_zh']
            if not core or core not in query: continue
            start=query.find(core)
            if re.search(r'(?:不要|没有|不是|并非|不带|不含|避免|排除|无)[\u3400-\u9fff]{0,2}$',query[max(0,start-5):start]): continue
            if len(core)<2 and not any(len(t)>=2 and core in t and t in query for t in live[name]['synonyms_zh']): continue
            if live[name]['category'] in (0,7,5,14,12,15) or query.strip()==core:
                groups.setdefault(core,[]).append(name)
        selected=[]
        for core in sorted(groups,key=lambda c:(-len(c),query.find(c),c)):
            start=query.find(core);end=start+len(core)
            if any(start<prior[1] and end>prior[0] for prior in selected): continue
            names=groups[core]
            # Same wording can label unrelated entities. Prefer ordinary tags
            # for an ambiguous shared visual core, retaining exact-name search.
            visual=[n for n in names if live[n]['category'] in (0,7)]
            choices=sorted(visual or names,key=lambda n:(-live[n]['post_count'],n))[:8]
            selected.append((start,end,choices))
            if len(selected)>=limit: break
        return [names for _,_,names in sorted(selected)]

    def ordered_names(self):
        # Sort once per pass, rather than sorting the entire catalogue again
        # for every 32 vectors. Keep only names in memory, not a long-lived
        # source transaction that would pin the runtime database's WAL.
        db, union = self.connect(details=False)
        try:
            return [r[0] for r in db.execute('SELECT name FROM (' + union + ') ORDER BY post_count DESC, name')]
        finally: db.close()


def category_name(category):
    return {0:'general visual tag',7:'general visual tag',1:'artist',8:'artist',
        3:'copyright / work',10:'copyright / work',4:'character',11:'character',
        5:'meta',14:'meta',9:'contributor',12:'species',15:'lore'}.get(category,'unknown')


class Engine:
    batch_size = 32
    def __init__(self, directory, models, sources, *, pool=None, collection='tags'):
        self.models = models; self.sources = sources
        self.root = Path(directory).resolve()
        self.pool = pool or VectorPool(self.root,models.fingerprint)
        self._owns_pool = pool is None; self.collection = collection
        self.folder = self.pool.folder
        self.db,self.ann = self.pool.collection(collection,self.root/models.fingerprint)
        self.plan = None; self.active = False; self.writing = False; self._ann_generation = 0; self._closed = False

    def _load_ann(self):
        self.pool.reload()
        self.ann = self.pool.views[self.collection]

    def _checkpoint(self): self.pool.checkpoint()

    def status(self):
        count = len(self.ann)
        total = self.sources.count()
        row = self.db.execute("SELECT value FROM metadata WHERE key='complete_signature'").fetchone()
        complete = bool(row and row[0] == self.sources.signature())
        size = self.pool.collection_bytes(self.collection)
        metadata = dict(self.db.execute('SELECT key,value FROM metadata'))
        return {'indexed': count, 'total': total, 'complete': complete,
                'auto_update_allowed': metadata.get('consented') == '1' and metadata.get('paused') != '1',
                'partial': bool(count and not complete), 'bytes': size,
                'building': self.active and self.writing, 'checking': self.active and not self.writing,
                'paused': metadata.get('paused') == '1', 'skipped': int(metadata.get('skipped','0'))}

    def preview(self):
        self.plan = {'source_signature': self.sources.signature(),
                     'model_fingerprint': self.models.fingerprint,
                     'total': self.sources.count(), 'expires': time.monotonic() + 1800}
        if isinstance(self.sources,Sources):
            changes = self.sources.changed_names(dict(self.db.execute('SELECT key,value FROM metadata')))
            if changes is not None: self.plan['incremental_names'] = changes
        self.plan['plan_id'] = hashlib.sha256(json.dumps(self.plan, sort_keys=True).encode()).hexdigest()
        return {k: v for k, v in self.plan.items() if k not in ('expires','incremental_names')}

    def embed_rows(self, rows):
        return self.models.embed([item['text'] for item in rows])

    def set_paused(self, paused):
        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('paused',?)", ('1' if paused else '0',))
        self.db.commit()

    def validate_plan(self, plan_id):
        if not self.plan or self.plan['plan_id'] != plan_id or self.plan['expires'] < time.monotonic():
            raise ValueError('invalid_plan')
        signature = self.sources.signature()
        if signature != self.plan['source_signature']: raise ValueError('source_changed')

    def build(self, plan_id, cancelled, progress=None):
        if self.active: raise ValueError('index_busy')
        self.validate_plan(plan_id)
        signature = self.plan['source_signature']
        plan = self.plan; self.plan = None; self.active = True; self.writing = False
        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('consented','1')")
        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('paused','0')")
        self.db.commit()
        processed = 0; skipped = 0; closing = False
        self.pool.begin_build()
        try:
            incremental = 'incremental_names' in plan
            names = plan['incremental_names'] if incremental else self.sources.ordered_names()
            work_total = len(names) if incremental else plan['total']
            while processed < work_total:
                if cancelled(): break
                if self.sources.signature() != signature: raise ValueError('source_changed')
                batch = names[processed:processed+self.batch_size]
                rows = self.sources.rows(names=batch, limit=self.batch_size)
                if len(rows) != len(batch) or not rows: raise ValueError('source_changed')
                pending = []
                for item in rows:
                    old = self.db.execute('SELECT digest FROM documents WHERE name=?', (item['name'],)).fetchone()
                    if not old or old[0] != item['digest']: pending.append(item)
                    else: self.db.execute('UPDATE documents SET seen=?, post_count=? WHERE name=?', (signature, item['post_count'], item['name']))
                self.writing = bool(pending)
                if pending:
                    if progress: progress({'processed':plan['total']-work_total+processed, **self.status()})
                    vectors = self.embed_rows(pending)
                    if cancelled(): break
                    for item, vector in zip(pending, vectors):
                        if vector is None:
                            skipped += 1
                            continue
                        old = self.db.execute('SELECT id FROM documents WHERE name=?', (item['name'],)).fetchone()
                        self.db.execute('INSERT INTO documents(name,category,post_count,aliases,text,digest,vector,seen) VALUES(?,?,?,?,?,?,?,?)',
                            (item['name'], item['category'], item['post_count'], json.dumps(item['aliases']), item['text'], item['digest'], vector.tobytes(), signature))
                        key = old[0] if old else self.db.execute('SELECT id FROM documents WHERE name=?', (item['name'],)).fetchone()[0]
                        if old and key in self.ann: self.ann.remove(key)
                        self.ann.add(key, vector)
                self._ann_generation += 1
                self.db.execute("INSERT OR REPLACE INTO metadata VALUES('ann_generation',?)",(str(self._ann_generation),))
                self.db.execute("INSERT OR REPLACE INTO metadata VALUES('skipped',?)", (str(skipped),))
                self.db.commit(); processed += len(rows)
                if processed % 32768 == 0: self._checkpoint()
                yield {'processed': plan['total']-work_total+processed, 'total': plan['total'], **self.status()}
            if not cancelled() and processed == work_total:
                if self.sources.signature() != signature: raise ValueError('source_changed')
                stale = [] if incremental else [r[0] for r in self.db.execute('SELECT id FROM documents WHERE seen != ?', (signature,))]
                if stale:
                    self.writing = True
                    if progress: progress({'processed':plan['total'], **self.status()})
                for key in stale:
                    if key in self.ann: self.ann.remove(key)
                if not incremental: self.db.execute('DELETE FROM documents WHERE seen != ?', (signature,))
                if stale:
                    # Invalidate a checkpoint saved just before final cleanup;
                    # a crash must not reload deleted IDs from that older ANN.
                    self._ann_generation += 1
                    self.db.execute("INSERT OR REPLACE INTO metadata VALUES('ann_generation',?)",(str(self._ann_generation),))
                self.db.execute("INSERT OR REPLACE INTO metadata VALUES('complete_signature',?)", (signature,))
                if isinstance(self.sources,Sources):
                    state = self.sources.change_state()
                    self.db.execute("INSERT OR REPLACE INTO metadata VALUES('source_base',?)", (state['base'],))
                    if state['revision'] is not None:
                        self.db.execute("INSERT OR REPLACE INTO metadata VALUES('semantic_revision',?)", (str(state['revision']),))
                self.db.commit()
        except GeneratorExit:
            # close() can only interrupt a suspended yield: both SQLite and
            # ANN already contain the committed batch. The pool owner saves
            # once after all builders/connections have been closed.
            closing = True
            raise
        except BaseException:
            self.db.rollback(); self._load_ann()
            raise
        finally:
            self.db.rollback(); self.active = False; self.writing = False
            self.pool.end_build()
            if not closing: self._checkpoint()

    def search(self, text, cursor, mode, existing, lexical, negative, limit=40, cancelled=lambda: False, keyword=''):
        original = self.sources
        self.sources = Sources(*original.paths, optional_supplements=True)
        try:
            result = self._search(text, cursor, mode, existing, lexical, negative, limit, cancelled, keyword)
            if self.sources.degraded: result['degraded'] = ['supplements_unavailable']
            return result
        finally: self.sources = original

    def _search(self, text, cursor, mode, existing, lexical, negative, limit=40, cancelled=lambda: False, keyword=''):
        import numpy as np
        if mode not in ('before','around'): raise ValueError('invalid_context_mode')
        if not len(self.ann): return {'items': [], 'context_tokens':0}
        manual = bool(keyword.strip())
        keyword = clean_tag(keyword[:1024])
        # A typed search is its own query. Prompt context is only used for
        # idle recommendations, including the existing 120-token window.
        window = ({'text':keyword,'tokens':self.models.count(keyword),'mode':'query'} if manual else
                  context_window(text, cursor, mode, self.models.count))
        if not window['text']: return {'items': [], 'context_tokens': window['tokens']}
        if cancelled(): raise ValueError('cancelled')
        query_text = window['text']
        limit = max(1, min(limit, 80))
        budget = max(80, limit * 2)
        # Recall broadly; rank the requested count plus a small, batched margin.
        # Showing 80 must not inherit the previous hidden 32-item ceiling.
        rank_budget = min(budget, ((limit*6//5+7)//8)*8)
        exact = self.sources.exact_names(query_text) if manual else []
        concepts = self.sources.core_concepts(query_text) if manual else []
        concept_names = {name for group in concepts for name in group}
        direct = self.sources.rows(names=exact, limit=80)
        entity_query = any(r['category'] in (1,3,4,8,9,10,11) for r in direct)
        keys = []
        popularity = {}; semantic_scores = {}
        if len(self.ann):
            query = self.models.embed([query_text], query=True)[0]
            # Reserve recall inside visual categories instead of filtering a
            # small global top-k after artist/character names have filled it.
            if not entity_query:
                # Manual queries can use a near-full first recall instead of
                # expanding the ANN solely to fill the last few candidates.
                recall = self.ann.search(query, max(1000,budget) if manual else budget,
                    categories=(0,7,5,14,12,15), min_count=800 if manual else None)
                visual = list(recall.keys)
                if manual:
                    names_by_id = {int(key):self.db.execute('SELECT name FROM documents WHERE id=?',(int(key),)).fetchone()[0] for key in visual}
                    counts = self.sources.danbooru_counts(list(names_by_id.values()))
                    popularity = {name:math.log10(max(0,count)+1) for name,count in counts.items()}
                    weights = {int(key):1-distance+0.04*popularity.get(names_by_id[int(key)],0)
                        for key,distance in zip(recall.keys,recall.distances)}
                    semantic_scores.update({names_by_id[key]:value for key,value in weights.items()})
                    visual.sort(key=lambda key:-weights[int(key)])
                    visual=visual[:budget]
                name_recall = self.ann.search(query, max(budget//4,budget-len(visual)),categories=(1,3,4,8,9,10,11))
                names = list(name_recall.keys)
                if manual:
                    for key,distance in zip(name_recall.keys,name_recall.distances):
                        name=self.db.execute('SELECT name FROM documents WHERE id=?',(int(key),)).fetchone()[0]
                        semantic_scores[name]=1-distance
                visual = visual[:budget-len(names)]
                # Preserve a name lane for descriptive character/work queries.
                # A scene must not silently turn into an absolute class filter.
                while visual or names:
                    keys.extend(visual[:3]); visual = visual[3:]
                    keys.extend(names[:1]); names = names[1:]
            else:
                keys.extend(self.ann.search(query,budget).keys)
        candidates = {}
        ranks = {}
        origins = {}
        for rank, key in enumerate(dict.fromkeys(keys)):
            row = self.db.execute('SELECT name,category,post_count,aliases,text,digest FROM documents WHERE id=?', (int(key),)).fetchone()
            if row:
                candidates[row[0]] = row; ranks[row[0]] = 1/(60+rank+1)
                origins.setdefault(row[0],set()).add('semantic')
        # Cooccurrence and ordinary matches participate without becoming vectors
        # or requiring a complete index. Recheck all candidates against live data.
        names = list(dict.fromkeys([*exact, *sorted(concept_names), *lexical, *candidates]))[:320]
        live = {r['name']:r for r in self.sources.rows(names=names, limit=320)}
        # A locked overlay may have contributed to saved vectors. Trust those
        # vectors only while all non-overlay source files still match the build.
        base = self.db.execute("SELECT value FROM metadata WHERE key='source_base'").fetchone()
        retained_overlay = self.sources.degraded and base and base[0] == self.sources._file_signature(self.sources.paths[:4])
        excluded = {clean_tag(t).lower() for t in existing}
        valid = []
        for name in names:
            item = live.get(name)
            if not item or clean_tag(name).lower() in excluded: continue
            if any(clean_tag(a).lower() in excluded for a in item['aliases']): continue
            if (name in candidates and candidates[name][5] != item['digest'] and
                not (retained_overlay and candidates[name][1] == item['category']) and
                name not in lexical and name not in exact and name not in concept_names): continue
            valid.append(item)
        for rank, name in enumerate(lexical):
            ranks[name] = ranks.get(name, 0)+1/(60+rank+1)
            origins.setdefault(name,set()).add('lexical' if manual else 'cooccurrence')
        for name in exact:
            ranks[name] = ranks.get(name, 0)+1
            origins.setdefault(name,set()).add('exact')
        for name in concept_names: origins.setdefault(name,set()).add('concept')
        valid.sort(key=lambda r:(r['name'] not in exact,r['name'] not in concept_names,-ranks.get(r['name'],0), -r['post_count'], r['name']))
        valid = valid[:rank_budget]
        if cancelled(): raise ValueError('cancelled')
        if not valid: return {'items': [], 'context_tokens':window['tokens'], 'context_mode':mode}
        documents = ['Category: '+category_name(r['category'])+'\n'+r['text'] for r in valid]
        scores = ([semantic_scores.get(row['name'],0) for row in valid] if manual and not entity_query else
                  self.models.rerank(query_text, documents, negative, purpose='tag_search') if manual else
                  self.models.rerank(query_text, documents, negative))
        if cancelled(): raise ValueError('cancelled')
        order = sorted(range(len(valid)), key=lambda i: (valid[i]['name'] not in exact,
            -scores[i],
            -ranks.get(valid[i]['name'],0), -valid[i]['post_count'], valid[i]['name']))
        pinned=[i for i in order if valid[i]['name'] in exact]
        for group in concepts:
            choices=[i for i in order if valid[i]['name'] in group]
            if choices and choices[0] not in pinned: pinned.append(choices[0])
        order=[*pinned,*[i for i in order if i not in pinned]]
        return {'items':[{**{k:v for k,v in valid[i].items() if k in ('name','category','post_count','aliases','core_zh')},
                'score':float(scores[i]), 'origins':sorted(origins.get(valid[i]['name'],set()))} for i in order[:limit]],
                'context_tokens': window['tokens'], 'context_mode': mode}

    def clear(self):
        if self.active: raise ValueError('index_busy')
        self.db.execute('DELETE FROM documents'); self.db.execute('DELETE FROM metadata'); self.db.commit()
        self._load_ann(); self._checkpoint(); self.db.execute('VACUUM')

    def close(self):
        if self._closed: return
        self.db.close(); self._closed = True
        if self._owns_pool: self.pool.close()
