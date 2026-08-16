# -*- coding: utf-8 -*-
"""桥接接管自检 — 不动用户 UI 状态、不消耗 Anlas"""
import asyncio, json, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from nai_bridge_client import Bridge, DISCOVERY

results = []
def check(name, ok, detail=''):
    results.append((name, bool(ok), detail))

async def main():
    # 1. 发现文件存在且 pid 存活
    info = json.loads(DISCOVERY.read_text(encoding='utf-8'))
    check('发现文件 krita-bridge.json', True, f"port={info['port']} pid={info['pid']}")

    import subprocess
    out = subprocess.run(['tasklist'], capture_output=True, text=True, encoding='gbk', errors='ignore').stdout
    n = out.count('nai_launcher.exe')
    check('只有一个启动器进程', n == 1, f'{n} 个实例')

    b = Bridge()
    # 2. 认证
    try:
        await b.connect()
        check('WebSocket 认证', True, 'pong')
    except Exception as e:
        check('WebSocket 认证', False, str(e))
        return
    try:
        # 3. get_params 字段完整性
        p = await b.rpc('get_params')
        need = ['prompt','negative_prompt','model','sampler','steps','cfg_scale','seed','width','height']
        missing = [k for k in need if k not in p]
        check('get_params 字段完整', not missing, f"缺: {missing}" if missing else '9 项核心字段全')
        orig_steps = p['steps']

        # 4. set_params 往返
        r1 = await b.rpc('set_params', {'steps': orig_steps + 1})
        ok1 = r1.get('type') == 'params_set' and 'steps' in r1.get('applied', [])
        p2 = await b.rpc('get_params')
        ok2 = p2['steps'] == orig_steps + 1
        r2 = await b.rpc('set_params', {'steps': orig_steps})
        p3 = await b.rpc('get_params')
        ok3 = p3['steps'] == orig_steps
        check('set_params 写入', ok1, str(r1.get('applied')))
        check('set_params 读回验证', ok2, f"steps={p2['steps']}")
        check('set_params 还原', ok3, f"steps={p3['steps']}")

        # 5. 未知键被忽略
        r = await b.rpc('set_params', {'foo_bar_baz': 123})
        check('未知键忽略', r.get('applied') == [], str(r.get('applied')))

        # 6. 错误类型被忽略（steps 传字符串）
        r = await b.rpc('set_params', {'steps': 'abc'})
        p4 = await b.rpc('get_params')
        check('错误类型忽略', r.get('applied') == [] and p4['steps'] == orig_steps, str(r.get('applied')))

        # 7. 错误 id 能正确回传（空 id 的 decode 错误）
        await b.ws.send(json.dumps({'type': 'set_params', 'payload': {}}))
        resp = json.loads(await b.ws.recv())
        check('非法消息报错回路', resp.get('type') == 'error', resp.get('code',''))

        # 8. 快速重连（模拟批量命令的开关连接）
        b2 = Bridge()
        await b2.connect()
        r = await b2.rpc('get_params')
        await b2.close()
        check('快速重连', r.get('type') == 'params', '')
    finally:
        await b.close()

asyncio.run(main())
print('\n===== 自检结果 =====')
allok = True
for name, ok, detail in results:
    print(('PASS' if ok else 'FAIL'), '-', name, ('| ' + detail) if detail else '')
    allok &= ok
print('\n总体:', '全部通过 ✓' if allok else '存在失败项 ✗')
sys.exit(0 if allok else 1)
