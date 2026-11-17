"""Reference tag data plus the launcher's complete catalog and semantic overlays."""
import csv
import hashlib
import io
import json
import math
from pathlib import Path

from engine import Sources
from tag_query import prepare_query

VIEWS = {'name': -1, 'synonyms': -3, 'meaning': -4, 'core': -2}
FILTER_CATEGORIES = {0:'General',1:'Artist',3:'Copyright',4:'Character',5:'Meta',
                     7:'General',8:'Artist',9:'Artist',10:'Copyright',11:'Character',
                     12:'General',14:'Meta',15:'Copyright'}


def view_texts(profile):
    return {'name':profile['name'].replace('_',' '),'synonyms':profile['cn_name'],
            'meaning':profile['wiki'],'core':profile['core_zh']}


def views_for(profile):
    return tuple(VIEWS) if profile.get('_reference') else tuple(
        view for view,text in view_texts(profile).items() if view=='name' or text.strip())


def view_row(profile, view):
    text = view_texts(profile)[view]
    return dict(name=json.dumps([profile['name'],view],ensure_ascii=False,separators=(',',':')),
                category=VIEWS[view],post_count=profile['post_count'],aliases=[],text=text,
                digest=hashlib.sha256((TagSources.representation_version+'\n'+text).encode()).hexdigest())


class TagSources(Sources):
    representation_version = 'danbooru-search-f50d563-v1'
    sparse_views = True

    def __init__(self, corpus=None, *, catalog='', runtime='', wiki='', semantics='', supplements='', optional_supplements=False):
        self.path = Path(corpus) if corpus else Path(__file__).with_name('danbooru_tags.csv')
        self.paths = tuple(str(Path(path).resolve()) if path else '' for path in (catalog,runtime,wiki,semantics,supplements))
        self.optional_supplements = optional_supplements
        self._runtime_reader = Sources(catalog,runtime) if catalog else None
        self._stamp = self._base_stamp = None
        self.degraded = False
        # The pinned Space provides no official Alias snapshot or group file.
        self.aliases = {}; self.groups = {}

    def _reference(self):
        raw = self.path.read_bytes()
        reader = csv.DictReader(io.StringIO(raw.decode('utf-8-sig')))
        if not {'name','cn_name','wiki','post_count','category','nsfw'} <= set(reader.fieldnames or ()):
            raise ValueError('invalid_source')
        records = {}
        for row in reader:
            name = row['name']
            if not name.strip() or name in records:
                continue
            chinese = row['cn_name']
            for separator in ('，','|','、'):
                chinese = chinese.replace(separator,',')
            records[name] = dict(name=name,cn_name=chinese,core_zh=chinese.split(',',1)[0].strip(),
                                 wiki=row['wiki'],post_count=int(row['post_count'] or 0),
                                 category=int(row['category'] or 0),nsfw=row['nsfw'] or '0',aliases=[],_reference=True)
        return records

    def _base(self, reader):
        records = self._reference()
        if reader is None:
            return records
        db,union = reader.connect()
        try:
            for name,category,count in db.execute('SELECT name,category,post_count FROM ('+union+') ORDER BY name'):
                if name not in records:
                    records[name] = dict(name=name,cn_name='',core_zh='',wiki='',nsfw='0',aliases=[])
                records[name].update(category=category,post_count=count,_category=FILTER_CATEGORIES.get(category,'Other'))
            if reader.paths[2]:
                for name,body in db.execute('SELECT tag,substr(body,1,500) FROM wiki.wiki_pages'):
                    row = records.get(name)
                    if row is not None and not row.get('_reference') and body:
                        row['wiki'] = body
            if reader.paths[3]:
                for name,core,synonyms,summary in db.execute('SELECT tag,core_zh,synonyms_zh,summary_zh FROM semantics.tag_semantics'):
                    row = records.get(name)
                    if row is None or row.get('_reference'):
                        continue
                    chinese = ','.join(dict.fromkeys(word for word in [core,*json.loads(synonyms)] if word))
                    if chinese:
                        row.update(cn_name=chinese,core_zh=chinese.split(',',1)[0].strip())
                    if summary:
                        row['wiki'] = summary
        finally:
            db.close()
        return records

    def _load(self):
        stat = self.path.stat()
        runtime = self._runtime_reader._runtime_signature() if self.paths[1] else None
        base_stamp = (stat.st_size,stat.st_mtime_ns,self._file_stamp([self.paths[i] for i in (0,2,3)]),runtime)
        stamp = base_stamp,self._file_stamp(self.paths[4:])
        if stamp == self._stamp and not self.degraded:
            return
        active = (*self.paths[:3],*[path if path and Path(path).is_file() else '' for path in self.paths[3:]])
        reader = Sources(*active,optional_supplements=self.optional_supplements) if self.paths[0] else None
        if base_stamp != self._base_stamp:
            self._base_records = self._base(reader)
            self._base_total = sum(len(views_for(row)) for row in self._base_records.values())
            self._base_max_log = max((math.log1p(row['post_count']) for row in self._base_records.values()),default=0)
            self._base_signature = hashlib.sha256(json.dumps(base_stamp).encode()).hexdigest()
            self._base_stamp = base_stamp
        records = self._base_records
        applied = []
        total = self._base_total
        self._revision = None
        if reader and reader.paths[4]:
            db,_ = reader.connect()
            try:
                if reader.paths[4]:
                    names = [row[0] for row in db.execute('SELECT tag FROM supplements.tag_semantics ORDER BY tag')]
                    state = db.execute("SELECT 1 FROM supplements.sqlite_master WHERE name='semantic_state'").fetchone()
                    revision = db.execute('SELECT revision FROM supplements.semantic_state').fetchone() if state else None
                    self._revision = revision[0] if revision else None
                else:
                    names = []
            finally:
                db.close()
            records = dict(records)
            for offset in range(0,len(names),256):
                for profile in reader.rows(names=names[offset:offset+256],limit=256):
                    if not (profile['core_zh'] or profile['synonyms_zh'] or profile['summary_zh']):
                        continue
                    name = profile['name']; previous = records.get(name)
                    words = [profile['core_zh'],*profile['synonyms_zh']]
                    if previous: words.extend(previous['cn_name'].split(','))
                    chinese = ','.join(dict.fromkeys(word for word in words if word))
                    row = dict(name=name,cn_name=chinese,core_zh=chinese.split(',',1)[0].strip(),
                               wiki=profile['summary_zh'] or (previous['wiki'] if previous else profile['wiki']),
                               post_count=profile['post_count'],category=profile['category'],
                               _category=FILTER_CATEGORIES.get(profile['category'],'Other'),
                               nsfw=previous['nsfw'] if previous else '0',aliases=[])
                    if previous and previous.get('_reference'): row['_reference'] = True
                    total += len(views_for(row))-(len(views_for(previous)) if previous else 0)
                    records[name] = row; applied.append(row)
        self.degraded = reader.degraded if reader else False
        signature = hashlib.sha256((self._base_signature+json.dumps(applied,ensure_ascii=False,sort_keys=True)).encode()).hexdigest()
        self._stamp = stamp
        if signature == getattr(self,'_signature',None):
            return
        self.records = records; self._total = total; self._signature = signature
        self.max_log_count = max(self._base_max_log,max((math.log1p(row['post_count']) for row in applied),default=0)) or 1.
        self._names = None; self._tokenizer = None

    def signature(self, state=None):
        self._load()
        return self._signature

    def change_state(self):
        self._load()
        return {'base':self._base_signature,'revision':self._revision}

    def changed_names(self, metadata):
        self._load()
        if self._revision is None or metadata.get('source_base')!=self._base_signature or 'semantic_revision' not in metadata:
            return None
        reader = Sources(*self.paths)
        db,_ = reader.connect()
        try:
            names = [row[0] for row in db.execute('SELECT tag FROM supplements.semantic_changes WHERE revision>? ORDER BY revision,tag',(int(metadata['semantic_revision']),))]
        finally:
            db.close()
        return [json.dumps([name,view],ensure_ascii=False,separators=(',',':')) for name in names for view in VIEWS]

    def count(self):
        self._load()
        return self._total

    def ordered_names(self):
        self._load()
        if self._names is None:
            self._names = [json.dumps([name,view],ensure_ascii=False,separators=(',',':'))
                           for name,row in self.records.items() for view in views_for(row)]
        return self._names

    def profiles(self, names):
        self._load()
        return [self.records[name] for name in dict.fromkeys(names) if name in self.records]

    def rows(self, offset=0, limit=64, names=None):
        self._load()
        selected = self.ordered_names()[offset:offset+limit] if names is None else names[:limit]
        return [view_row(self.records[name],view) for name,view in map(json.loads,selected)
                if name in self.records and view in views_for(self.records[name])]

    def query(self, text, segmentation):
        self._load()
        if self._tokenizer is None:
            import jieba
            self._tokenizer = jieba.Tokenizer()
            for row in self.records.values():
                for word in row['cn_name'].replace(',',' ').split():
                    if len(word.strip())>1: self._tokenizer.add_word(word.strip(),2000)
        return prepare_query(text,self.records.keys(),self._tokenizer,segmentation)
