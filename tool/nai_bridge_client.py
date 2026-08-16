#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""nai_bridge_client.py — NAI Launcher 魔改桥接控制客户端

通过 Krita Bridge（含 set_params/generate 扩展）接管启动器。
发现文件: %APPDATA%/nai-launcher/krita-bridge.json （端口+密钥，每次启动变化）

用法:
  python nai_bridge_client.py get                          # 读当前参数
  python nai_bridge_client.py set steps=32 seed=12345      # 写入 UI 参数（界面实时可见）
  python nai_bridge_client.py set-json '{"prompt":"1girl"}' # 复杂参数（含角色框 characters）
  python nai_bridge_client.py gen [payload.json]           # 静默生成（不改 UI），图存图库并回传路径
  python nai_bridge_client.py ui-gen                       # 远程点 Generate（用 UI 当前参数）

支持的 set/gen 键（均为可选，未传保持原值）:
  prompt, negative_prompt, model, width, height, steps, cfg_scale, sampler,
  seed, n_samples, uc_preset, quality_toggle, cfg_rescale, noise_schedule,
  variety_plus, smea_auto, smea, smea_dyn, use_coords,
  characters=[{"prompt":..., "uc":..., "position":"B2"}], clear_characters=true
"""
import asyncio
import base64
import json
import sys
import time
from pathlib import Path

DISCOVERY = Path.home() / 'AppData' / 'Roaming' / 'nai-launcher' / 'krita-bridge.json'


class Bridge:
    def __init__(self):
        self.ws = None

    async def connect(self):
        import websockets
        info = json.loads(DISCOVERY.read_text(encoding='utf-8'))
        self.ws = await websockets.connect(
            f"ws://127.0.0.1:{info['port']}/krita",
            max_size=64 * 1024 * 1024,
        )
        await self.ws.send(json.dumps({
            'type': 'ping', 'version': 1, 'secret': info['secret'],
        }))
        resp = json.loads(await self.ws.recv())
        if resp.get('type') != 'pong':
            raise RuntimeError(f'桥接认证失败: {resp}')
        return info

    async def rpc(self, type_, payload=None, on_progress=None):
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
            payload = json.loads(sys.argv[2])
            resp = await b.rpc('set_params', payload)
            print(json.dumps(resp, ensure_ascii=False))
        elif cmd == 'gen':
            payload = json.loads(Path(sys.argv[2]).read_text(encoding='utf-8')) \
                if len(sys.argv) > 2 else {}
            def prog(r):
                print(f"  生成中 {r.get('step')}/{r.get('total_steps')}", flush=True)
            resp = await b.rpc('generate', payload, on_progress=prog)
            if resp.get('type') == 'result':
                img = base64.b64decode(resp['image'])
                out = Path(f"bridge_result_{int(time.time())}.png")
                out.write_bytes(img)
                print(json.dumps({
                    'saved_path': resp.get('saved_path'),
                    'local_copy': str(out.resolve()),
                    'params': resp.get('params'),
                }, ensure_ascii=False, indent=2))
            else:
                print(json.dumps(resp, ensure_ascii=False))
        elif cmd == 'ui-gen':
            resp = await b.rpc('generate', {}, on_progress=lambda r: None)
            print(json.dumps({k: v for k, v in resp.items() if k != 'image'},
                             ensure_ascii=False))
        else:
            print(f'未知命令: {cmd}')
            return 1
    finally:
        await b.close()
    return 0


if __name__ == '__main__':
    sys.exit(asyncio.run(main()))
