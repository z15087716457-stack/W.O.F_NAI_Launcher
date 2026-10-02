"""Build offline model facts from pinned models.dev Git objects.

Reads Git objects, so provider IDs containing ':' also work on Windows.
Usage: python tool/model_catalog/build_model_catalog.py PATH_TO_REPOSITORY
No source code from that repository is executed.
"""
import argparse
import copy
import datetime
import json
import posixpath
import subprocess
import tomllib
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('repository', type=Path)
parser.add_argument('--ref', default='HEAD', help='Commit or fetched ref to read without checking out')
parser.add_argument('--date', default=datetime.date.today().isoformat())
args = parser.parse_args()
repo = args.repository.resolve()
root = Path(__file__).resolve().parents[2]


def git(*arguments):
    return subprocess.check_output(['git', '-C', str(repo), *arguments])


revision = git('rev-parse', args.ref).decode().strip()
tree = git('ls-tree', '-r', revision).decode('utf-8').splitlines()
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
             for path, data in documents.items() if path.startswith('models/') and data}
def merge(base, override):
    result = copy.deepcopy(base)
    for key, value in override.items():
        result[key] = merge(result[key], value) if isinstance(result.get(key), dict) and isinstance(value, dict) else copy.deepcopy(value)
    return result


def apply_omit(target, paths):
    for path in paths:
        parts = path.split('.')
        current = target
        parents = []
        for part in parts[:-1]:
            if not isinstance(current.get(part), dict):
                break
            parents.append((current, part))
            current = current[part]
        else:
            current.pop(parts[-1], None)
            for parent, key in reversed(parents):
                if parent[key]:
                    break
                del parent[key]


def chat_model(data):
    return 'text' in data.get('modalities', {}).get('output', ['text']) and data.get('limit', {}).get('output', 1) != 0 and not data.get('type')


native = {}
bindings = {}
vendor_models = {}
provider_facts = {}
for path, data in documents.items():
    parts = path.split('/')
    if len(parts) < 4 or parts[0] != 'providers' or parts[2] != 'models':
        continue
    vendor = parts[1]
    name = '/'.join(parts[3:]).removesuffix('.toml')
    if not data:
        continue
    base = data.get('base_model')
    if base is not None and base not in canonical:
        # Missing or specialized base metadata is not an invented chat model.
        omitted.add(path)
        continue
    inherited = {key: value for key, value in canonical.get(base, {}).items()
                 if key not in {'id', 'benchmarks', 'license', 'links', 'weights'}}
    resolved = merge(inherited, {key: value for key, value in data.items()
                               if key not in {'base_model', 'base_model_omit'}})
    apply_omit(resolved, data.get('base_model_omit', []))
    if not chat_model(resolved):
        continue
    provider_facts[f'{vendor}/{name}'] = (vendor, base, resolved)
    if base is not None and chat_model(canonical[base]):
        bindings[f'{vendor}/{name}'.lower()] = base
    vendor_models.setdefault(vendor, []).append(name)
    native_id = base or f'{vendor}/{name}'
    if native_id in canonical and native_id.split('/')[0] == vendor:
        previous = native.get(native_id, {})
        if not previous or len(data.get('reasoning_options', [])) > len(previous.get('reasoning_options', [])):
            native[native_id] = resolved

def project(model_id, vendor, data, serving=None, base=None):
    short_id = (base or model_id).split('/', 1)[-1]
    serving = serving or {}
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
    # Some providers use zero as an unknown/not-applicable capacity. Never seed
    # the editable request settings with an invalid zero-token limit.
    entry = {'id': model_id, 'vendor': vendor, 'name': data.get('name', short_id),
             'context': limits.get('context') if limits.get('context', 0) > 0 else None,
             'output': limits.get('output') if limits.get('output', 0) > 0 else None,
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
    facts = merge(data, serving)
    entry.update({
        'canonicalId': base,
        'input': limits.get('input') if limits.get('input', 0) > 0 else None,
        'inputModalities': facts.get('modalities', {}).get('input'),
        'outputModalities': facts.get('modalities', {}).get('output'),
        'reasoning': facts.get('reasoning'),
        'reasoningOptions': options,
        'toolCall': facts.get('tool_call'),
        'structuredOutput': facts.get('structured_output'),
        'family': facts.get('family'),
        'knowledge': facts.get('knowledge'),
        'released': facts.get('release_date'),
        'status': facts.get('status'),
        'cost': facts.get('cost'),
    })
    return {key: value for key, value in entry.items() if value is not None}


entries = [project(model_id, model_id.split('/')[0], data, native.get(model_id))
           for model_id, data in sorted(canonical.items()) if chat_model(data)]
profiles = {model_id.lower(): project(model_id, vendor, data, base=base)
            for model_id, (vendor, base, data) in sorted(provider_facts.items())}
assert len(profiles) == len(provider_facts), 'Case-folded provider/model IDs must be unique'

destination = root / 'assets/data/model_catalog.json'
snapshot = {'schemaVersion': 2, 'date': args.date,
            'source': 'https://github.com/anomalyco/models.dev',
            'revision': revision,
            'omittedFiles': sorted(omitted),
            'models': entries, 'providerModels': profiles, 'bindings': dict(sorted(bindings.items())),
            'providers': {key: sorted(set(value)) for key, value in sorted(vendor_models.items())}}
destination.write_text(json.dumps(snapshot, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
(root / 'assets/data/model_catalog.LICENSE').write_bytes(git('show', f'{revision}:LICENSE'))
print(json.dumps({'models': len(entries), 'bindings': len(bindings),
                  'providers': len(vendor_models), 'providerModels': len(profiles), 'bytes': destination.stat().st_size,
                  'revision': snapshot['revision'], 'omitted': sorted(omitted)}, indent=2))
