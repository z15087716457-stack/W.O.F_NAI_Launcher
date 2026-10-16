"""Read CPU samples only from the independent probe's loopback VM service."""
import collections
import json
from pathlib import Path
import re
import sys
import urllib.parse
import urllib.request

log = Path(sys.argv[1])
text = log.read_text(encoding='utf-8', errors='replace')
uri = re.findall(r'The Dart VM service is listening on (http://127\.0\.0\.1:\d+/[^\s]+/)', text)[-1]
def rpc(method, **params):
    with urllib.request.urlopen(uri + method + '?' + urllib.parse.urlencode(params), timeout=10) as response:
        payload = json.load(response)
    if 'error' in payload:
        raise RuntimeError(payload['error'])
    return payload['result']
vm = rpc('getVM')
isolate = next(i for i in vm['isolates'] if i['name'] == 'main')
if '--enable' in sys.argv:
    print(rpc('setFlag', name='profiler', value='true'))
    raise SystemExit(0)
profile = rpc('getCpuSamples', isolateId=isolate['id'], timeOriginMicros=0, timeExtentMicros=10**18)
log.with_suffix('.cpu.json').write_text(json.dumps(profile), encoding='utf-8')
hits = collections.Counter()
table = profile['functions']
for sample in profile['samples']:
    seen = set()
    for entry in sample.get('stack', []):
        item = table[entry]
        name = item['function']['name']
        if name not in seen:
            hits[name] += 1
            seen.add(name)
print(json.dumps({'samples': len(profile['samples']), 'top_inclusive': hits.most_common(35)}, indent=2))
