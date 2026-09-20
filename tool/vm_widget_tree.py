import websocket, json, sys

ws = websocket.create_connection('ws://127.0.0.1:1939/06_GcT0zE94=/ws', timeout=15)

def call(method, params=None, i=[0]):
    i[0] += 1
    wid = str(i[0])
    ws.send(json.dumps({'jsonrpc': '2.0', 'id': wid, 'method': method, 'params': params or {}}))
    while True:
        msg = json.loads(ws.recv())
        if msg.get('id') == wid:
            return msg

iso = 'isolates/2092324384236839'

def walk(node, depth=0, out=None, path=None, maxdepth=80):
    if out is None:
        out = []
    if path is None:
        path = []
    if depth > maxdepth or node is None:
        return out
    desc = node.get('description', '?') if isinstance(node, dict) else str(node)
    path.append(desc)
    if any(k in desc for k in (
        'WebStyleGenerationLayout', 'ImagePreview', 'HistoryPanel',
        'GenerationCanvasView', '_CanvasEmptyState', 'CanvasTile',
        'SelectableImageCard', 'AspectRatio', 'HistoryThumbnail',
        '_Prompt', 'PromptPanel', 'GenerationPanel', 'LeftPanel',
    )):
        out.append('  ' * depth + desc)
    for c in node.get('children', []) if isinstance(node, dict) else []:
        walk(c, depth + 1, out, path, maxdepth)
    path.pop()
    return out

r = call('ext.flutter.inspector.getRootWidgetSummaryTree', {
    'isolateId': iso,
    'objectGroup': 'mavis-check',
})
tree = r.get('result', {}).get('result', {})
lines = walk(tree)
for l in lines:
    sys.stdout.write(l + '\n')
sys.stdout.write(f'\n--- {len(lines)} matched nodes ---\n')
ws.close()
