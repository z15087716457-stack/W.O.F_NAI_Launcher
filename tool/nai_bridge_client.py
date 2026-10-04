#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""nai_bridge_client.py — NAI Launcher 魔改桥接控制客户端

通过 Krita Bridge（含 set_params/generate 扩展）接管启动器。
发现文件: %APPDATA%/nai-launcher/krita-bridge.json （端口+密钥，每次启动变化）

用法:
  python nai_bridge_client.py get                          # 读当前参数
  python nai_bridge_client.py set steps=32 seed=12345      # 写入 UI 参数（界面实时可见）
  python nai_bridge_client.py set-json '{"prompt":"1girl"}' # 复杂参数（含角色框 characters）
  生图使用安装包 tools/studio-bridge.exe：先 quote，再 gen --quote FILE --authorized。

支持的 set 键（均为可选，未传保持原值）:
  prompt, negative_prompt, model, width, height, steps, cfg_scale, sampler,
  seed, n_samples, uc_preset, quality_preset=standard|light|none,
  quality_toggle, cfg_rescale, noise_schedule, variety_plus, smea_auto, smea,
  smea_dyn, use_coords,
  characters=[{"prompt":..., "uc":..., "position":"B2"}], clear_characters=true

quality_preset 与 quality_toggle 同时出现时新键优先；旧布尔键仍映射 Standard/None。
"""
import asyncio
import json
import sys
import time
from pathlib import Path

DISCOVERY = Path.home() / 'AppData' / 'Roaming' / 'nai-launcher' / 'krita-bridge.json'


class Bridge:
    def __init__(self):
        self.ws = None
        self.last_params = None

    async def connect(self):
        import websockets
        info = json.loads(DISCOVERY.read_text(encoding='utf-8'))
        self.ws = await websockets.connect(
            f"ws://127.0.0.1:{info['port']}/krita",
            max_size=64 * 1024 * 1024,
        )
        await self.ws.send(json.dumps({
            'type': 'ping', 'version': 1, 'secret': info['secret'],
            'client': {'kind': 'agent', 'name': 'Python bridge'},
        }))
        resp = json.loads(await self.ws.recv())
        if resp.get('type') != 'pong':
            raise RuntimeError(f'桥接认证失败: {resp}')
        return info

    async def rpc(self, type_, payload=None, on_progress=None):
        payload = dict(payload or {})
        if type_ == 'set_params' and '_expected' not in payload:
            baseline = self.last_params or await self.rpc('get_params')
            draft = baseline.get('_draft')
            if not isinstance(draft, dict) or not isinstance(draft.get('field_versions'), dict):
                raise RuntimeError('Studio does not support protected Agent writes; update Studio.')
            payload['_expected'] = draft['field_versions']
        rid = f'{type_}-{int(time.time() * 1000)}'
        await self.ws.send(json.dumps({
            'type': type_, 'id': rid, 'payload': payload or {},
        }))
        while True:
            resp = json.loads(await self.ws.recv())
            rtype = resp.get('type')
            if rtype == 'progress':
                if on_progress:
                    on_progress(resp)
                continue
            if resp.get('id') == rid or rtype == 'error' and resp.get('id') == rid:
                if rtype == 'params':
                    self.last_params = resp
                return resp

    async def close(self):
        if self.ws:
            await self.ws.close()


def _parse_kv(args):
    payload = {}
    for a in args:
        if '=' not in a:
            raise SystemExit(f'参数格式错误（需要 key=value）: {a}')
        k, v = a.split('=', 1)
        if v.lower() in ('true', 'false'):
            v = v.lower() == 'true'
        else:
            try:
                v = int(v)
            except ValueError:
                try:
                    v = float(v)
                except ValueError:
                        pass
        payload[k] = v
    return payload


async def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    cmd = sys.argv[1]
    if cmd in ('gen', 'ui-gen'):
        print('Use tools/studio-bridge.exe: quote first, report price/balance, then gen --quote FILE --authorized.', file=sys.stderr)
        return 2
    b = Bridge()
    info = await b.connect()
    try:
        if cmd == 'get':
            resp = await b.rpc('get_params')
            print(json.dumps(resp, ensure_ascii=False, indent=2))
        elif cmd == 'set':
            payload = _parse_kv(sys.argv[2:])
            resp = await b.rpc('set_params', payload)
            print(json.dumps(resp, ensure_ascii=False))
        elif cmd == 'set-json':
            arg = sys.argv[2]
            # 以 { 开头视为内联 JSON，否则按文件路径读取
            payload = json.loads(arg) if arg.lstrip().startswith('{') else \
                json.loads(Path(arg).read_text(encoding='utf-8'))
            resp = await b.rpc('set_params', payload)
            print(json.dumps(resp, ensure_ascii=False))
        else:
            print(f'未知命令: {cmd}')
            return 1
    finally:
        await b.close()
    return 0


if __name__ == '__main__':
    sys.exit(asyncio.run(main()))
