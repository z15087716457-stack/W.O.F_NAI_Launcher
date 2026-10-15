"""JSONL local worker; one model owner and resumable, low-priority build steps."""
import importlib.metadata
import json
import os
import queue
import sys
import threading
import time
import uuid

from engine import Engine, Sources
from models import Models

write_lock = threading.Lock()


def emit(value):
    with write_lock:
        sys.stdout.write(json.dumps(value, ensure_ascii=False, allow_nan=False) + '\n')
        sys.stdout.flush()


class Worker:
    def __init__(self):
        self.queue = queue.PriorityQueue()
        self.sequence = 0; self.tokens = {}; self.jobs = {}
        self.engine = None; self.settings = None
        self.last_use = time.monotonic(); self.running = True; self.suspended = False

    def enqueue(self, value, priority=0):
        self.sequence += 1
        self.queue.put((priority, self.sequence, value))

    def _event(self, **values):
        emit({'event': 'index', **values})

    def _step(self, job_id):
        job = self.jobs.get(job_id)
        if job is None or job['paused'] or self.suspended: return
        try:
            progress = next(job['generator'])
            self._event(job_id=job_id, phase='building', **progress)
            self.enqueue({'_step':job_id}, 10)
        except StopIteration:
            self.jobs.pop(job_id, None)
            self._event(job_id=job_id, phase='paused' if job['cancel'].is_set() else 'complete', **self.engine.status())
        except Exception as error:
            self.jobs.pop(job_id, None)
            self._event(job_id=job_id, phase='error', code=self.error_code(error), **self.engine.status())

    @staticmethod
    def error_code(error):
        # Never expose paths, query text, URLs, or raw backend exceptions.
        allowed = {'cancelled','source_changed','invalid_plan','index_busy','cuda_unavailable',
                   'invalid_embeddings','invalid_rerank_scores','invalid_context_mode'}
        code = str(error)
        return code if code in allowed else 'rag_runtime_error'

    def execute(self, op, p, token):
        if op == 'configure':
            for job in self.jobs.values(): job['cancel'].set(); job['generator'].close()
            self.jobs.clear()
            if self.engine: self.engine.models.unload(); self.engine.close()
            self.engine = None
            models = Models(p['embedding'], p['reranker'], p.get('device','auto'))
            self.engine = Engine(p['directory'], models,
                Sources(p['catalog'],p.get('runtime',''),p.get('wiki','')))
            self.settings = p; self.suspended = False
            return self.engine.status()
        if self.engine is None: raise ValueError('not_configured')
        if op == 'status':
            status = self.engine.status()
            paused = status['paused'] or bool(self.jobs and all(j['paused'] for j in self.jobs.values()))
            return {**status, **self.engine.models.status(), 'suspended':self.suspended,
                    'paused':paused,'building':bool(self.jobs and not paused and not self.suspended),
                    'jobs':[{k:v for k,v in j.items() if k in ('id','paused')} for j in self.jobs.values()]}
        if op == 'preview': return self.engine.preview()
        if op == 'start':
            if self.jobs: raise ValueError('index_busy')
            job_id = uuid.uuid4().hex
            cancellation = threading.Event()
            generator = self.engine.build(p['plan_id'], cancellation.is_set)
            # Validate the plan before acknowledging start; first work is queued.
            if not self.engine.plan or self.engine.plan['plan_id'] != p['plan_id']:
                raise ValueError('invalid_plan')
            self.jobs[job_id] = {'id':job_id,'generator':generator,'cancel':cancellation,'paused':False}
            self.enqueue({'_step':job_id},10)
            return {'job_id':job_id}
        if op in ('pause','resume'):
            job = self.jobs.get(p['job_id'])
            if job:
                job['paused'] = op == 'pause'
                if op == 'resume': self.enqueue({'_step':p['job_id']},10)
            self.engine.db.execute("INSERT OR REPLACE INTO metadata VALUES('paused',?)", ('1' if op == 'pause' else '0',))
            self.engine.db.commit()
            return {'job_id':p['job_id'],'paused':op == 'pause',**self.engine.status()}
        if op in ('suspend','unload'):
            self.suspended = op == 'suspend'
            self.engine.models.unload()
            return {'suspended':self.suspended,**self.engine.status()}
        if op == 'release':
            self.suspended = False
            for job_id,j in self.jobs.items():
                if not j['paused']: self.enqueue({'_step':job_id},10)
            return {'suspended':False}
        if op == 'clear':
            for job in self.jobs.values(): job['cancel'].set(); job['generator'].close()
            self.jobs.clear(); self.engine.clear()
            return self.engine.status()
        if op == 'search':
            if self.suspended: return {'items':[],'fallback':'resource_busy'}
            if len(p['text']) > 262144: raise ValueError('input_too_large')
            self.last_use = time.monotonic()
            return self.engine.search(p['text'],p['cursor'],p.get('mode','around'),
                p.get('existing',[])[:20000],p.get('lexical',[])[:80],p.get('negative',False),
                min(80,max(1,p.get('limit',40))),token.is_set,p.get('keyword',''))
        raise ValueError('unknown_operation')

    def run(self):
        while self.running:
            try: _,_,request = self.queue.get(timeout=1)
            except queue.Empty:
                if self.engine and not any(not j['paused'] for j in self.jobs.values()) and time.monotonic()-self.last_use > 120:
                    self.engine.models.unload(); self.last_use = time.monotonic()
                continue
            if '_step' in request:
                self._step(request['_step']); continue
            request_id = request['id']; token = self.tokens.get(request_id,threading.Event())
            try:
                if token.is_set(): raise ValueError('cancelled')
                result = self.execute(request['op'],request.get('params',{}),token)
                if token.is_set(): raise ValueError('cancelled')
                emit({'id':request_id,'result':result})
            except Exception as error:
                emit({'id':request_id,'error':{'code':self.error_code(error)}})
            finally: self.tokens.pop(request_id,None)
        if self.engine:
            for job in self.jobs.values(): job['generator'].close()
            self.engine.models.unload(); self.engine.close()

    def main(self):
        # Load native runtimes on the main thread before it blocks reading stdin.
        # On Windows, first importing NumPy/OpenBLAS from the executor thread
        # while the CRT is reading a pipe can deadlock inside DLL initialization.
        import numpy
        import torch
        import sentence_transformers
        import usearch.index
        thread = threading.Thread(target=self.run,daemon=True); thread.start()
        emit({'event':'ready','protocol':1,'versions':{name:importlib.metadata.version(name)
             for name in ('torch','transformers','sentence-transformers','numpy','usearch')}})
        for line in sys.stdin:
            if len(line) > 4*1024*1024: continue
            try:
                request = json.loads(line)
                if request.get('op') == 'shutdown': break
                if request.get('op') == 'cancel':
                    token = self.tokens.get(request.get('target'))
                    if token: token.set()
                    continue
                if not isinstance(request.get('id'),int) or len(self.tokens) >= 64: continue
                self.tokens[request['id']] = threading.Event()
                self.enqueue(request, -1 if request['op'] in ('pause','suspend','configure') else 0)
            except (ValueError,KeyError,TypeError): continue
        self.running = False
        for token in self.tokens.values(): token.set()
        for job in list(self.jobs.values()): job['cancel'].set()
        thread.join(timeout=15)


if __name__ == '__main__':
    # Library progress belongs on stderr, never on the JSON protocol stream.
    Worker().main()
