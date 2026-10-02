"""Build a small offline snapshot from a pinned models.dev Git checkout.

Reads Git objects, so provider IDs containing ':' also work on Windows.
Usage: python tool/model_catalog/build_model_catalog.py PATH_TO_REPOSITORY
No source code from that repository is executed.
"""
import argparse
import datetime
import json
import posixpath
import subprocess
import tomllib
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('repository', type=Path)
args = parser.parse_args()
repo = args.repository.resolve()
root = Path(__file__).resolve().parents[2]


def git(*arguments):
    return subprocess.check_output(['git', '-C', str(repo), *arguments])


tree = git('ls-tree', '-r', 'HEAD').decode('utf-8').splitlines()
files = [(line.split()[2], line.split('\t', 1)[1]) for line in tree
         if line.endswith('.toml') and line.split('\t', 1)[1].startswith(('models/', 'providers/'))]
raw = subprocess.run(['git', '-C', str(repo), 'cat-file', '--batch'],
                     input=('\n'.join(sha for sha, _ in files) + '\n').encode(),
                     capture_output=True, check=True).stdout
offset = 0
documents = {}
texts = {}
omitted = set()
symlinks = {line.split('\t', 1)[1] for line in tree if line.startswith('120000')}
for _, path in files:
    end = raw.index(b'\n', offset)
    size = int(raw[offset:end].split()[-1])
    texts[path] = raw[end + 1:end + 1 + size].decode('utf-8-sig')
    offset = end + 2 + size


def document(path, chain=()):
    if path in documents:
        return documents[path]
    if path not in texts or path in chain or len(chain) > 20:
        omitted.add(path)
        return {}
    if path in symlinks:
        target = posixpath.normpath(posixpath.join(posixpath.dirname(path), texts[path].strip()))
        documents[path] = document(target, (*chain, path))
    else:
        documents[path] = tomllib.loads(texts[path])
    return documents[path]


for path in texts:
    document(path)

canonical = {path.removeprefix('models/').removesuffix('.toml'): data
             for path, data in documents.items() if path.startswith('models/') and data
             and 'text' in data.get('modalities', {}).get('output', ['text'])
             and data.get('limit', {}).get('output', 1) != 0}
native = {}
bindings = {}
vendor_models = {}
for path, data in documents.items():
    parts = path.split('/')
    if len(parts) < 4 or parts[0] != 'providers' or parts[2] != 'models':
        continue
    vendor = parts[1]
    name = '/'.join(parts[3:]).removesuffix('.toml')
    base = data.get('base_model') or (f'{vendor}/{name}' if f'{vendor}/{name}' in canonical else None)
    if base not in canonical:
        continue
    bindings[f'{vendor}/{name}'.lower()] = base
    vendor_models.setdefault(vendor, []).append(name)
    if base.split('/')[0] == vendor:
        previous = native.get(base, {})
        if not previous or len(data.get('reasoning_options', [])) > len(previous.get('reasoning_options', [])):
            native[base] = data

entries = []
for model_id, data in sorted(canonical.items()):
    vendor, short_id = model_id.split('/', 1)
    serving = native.get(model_id, {})
    options = serving.get('reasoning_options', data.get('reasoning_options', []))
    types = {option.get('type') for option in options}
    efforts = next((option.get('values') for option in options if option.get('type') == 'effort'), None)
    budget = next((option for option in options if option.get('type') == 'budget_tokens'), None)
    if efforts is not None:
        efforts = [value for value in efforts if value in ['none', 'minimal', 'low', 'medium', 'high', 'xhigh', 'max']]
        if 'toggle' in types and 'none' not in efforts:
            efforts.insert(0, 'none')
    elif budget:
        efforts = (['none'] if 'toggle' in types else []) + ['low', 'medium', 'high']
    elif 'toggle' in types:
        efforts = ['none', 'high']
    elif data.get('reasoning') is False:
        efforts = []
    fmt = None
    protocol = 'standard'
    if efforts:
        if vendor == 'google':
            fmt = 'geminiBudget' if budget else 'geminiLevel'
        elif vendor == 'anthropic':
            fmt = 'anthropicBudget' if budget and 'effort' not in types else 'anthropicEffort'
            if fmt == 'anthropicEffort':
                protocol = 'adaptive'
        elif vendor == 'deepseek':
            fmt = 'deepseek'
        elif 'effort' not in types:
            fmt = 'qwenToggle' if vendor == 'alibaba' else 'thinkingToggle'
    default = None
    if efforts and (not budget or 'effort' in types):
        if vendor == 'openai' and short_id.startswith(('gpt-6', 'gpt-5.6', 'gpt-5.5', 'o1', 'o3', 'o4')):
            default = 'medium' if 'medium' in efforts else None
        elif vendor == 'google':
            default = {
                'gemini-3.8-flash': 'medium', 'gemini-3.7-flash': 'medium',
                'gemini-3.6-flash': 'medium', 'gemini-3.5-flash': 'medium',
                'gemini-3.5-flash-lite': 'minimal', 'gemini-3.1-pro-preview': 'high',
                'gemini-3-flash-preview': 'high', 'gemini-3-pro-preview': 'high',
            }.get(short_id)
        elif vendor in ['anthropic', 'deepseek']:
            default = 'medium' if short_id == 'claude-opus-5-5' else 'high' if 'high' in efforts else None
    limits = {**data.get('limit', {}), **serving.get('limit', {})}
    entry = {'id': model_id, 'vendor': vendor, 'name': data.get('name', short_id),
             'context': limits.get('context'), 'output': limits.get('output'),
             'vision': 'image' in data.get('modalities', {}).get('input', ['text']),
             'temperature': data.get('temperature'), 'efforts': efforts,
             'defaultEffort': default, 'reasoningFormat': fmt,
             'reasoningProtocol': protocol, 'updated': data.get('last_updated')}
    if budget:
        entry['budgetMin'] = budget.get('min', 0)
        entry['budgetMax'] = budget.get('max')
    # Native hosted search is distinct from generic function/tool calling.
    # The client currently declares capability but does not auto-enable search.
    if vendor == 'google' and short_id in {
        'gemini-3.8-flash', 'gemini-3.7-flash', 'gemini-3.6-flash', 'gemini-3.5-flash',
        'gemini-3.5-flash-lite', 'gemini-3.1-pro-preview', 'gemini-3-flash-preview',
        'gemini-3-pro-preview', 'gemini-2.5-pro', 'gemini-2.5-flash', 'gemini-2.5-flash-lite',
    }:
        entry['nativeSearch'] = True
    elif vendor == 'openai' and short_id in {
        'gpt-6-astra', 'gpt-6.1-sol', 'gpt-5.5', 'gpt-5.4', 'gpt-5',
        'gpt-4.1', 'gpt-4.1-mini', 'o3', 'o4-mini', 'gpt-5-search-api',
    }:
        entry['nativeSearch'] = True
    elif vendor == 'anthropic' and short_id == 'claude-opus-5-5':
        entry['nativeSearch'] = True
    entries.append({key: value for key, value in entry.items() if value is not None})

destination = root / 'assets/data/model_catalog.json'
snapshot = {'schemaVersion': 1, 'date': datetime.date.today().isoformat(),
            'source': 'https://github.com/anomalyco/models.dev',
            'revision': git('rev-parse', 'HEAD').decode().strip(),
            'omittedFiles': sorted(omitted),
            'models': entries, 'bindings': dict(sorted(bindings.items())),
            'providers': {key: sorted(set(value)) for key, value in sorted(vendor_models.items())}}
destination.write_text(json.dumps(snapshot, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
(root / 'assets/data/model_catalog.LICENSE').write_bytes(git('show', 'HEAD:LICENSE'))
print(json.dumps({'models': len(entries), 'bindings': len(bindings),
                  'providers': len(vendor_models), 'bytes': destination.stat().st_size,
                  'revision': snapshot['revision'], 'omitted': sorted(omitted)}, indent=2))
