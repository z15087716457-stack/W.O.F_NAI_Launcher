#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""nai_fill.py — 一键把 NAI 参考图的完整生成设置填入 Aaalice NAI Launcher。

用法:
  python nai_fill.py <图片路径> [--no-lock] [--no-chars] [--gen] [--dry]

流程: nai_read.py --json 解析元数据 -> 组装桥接载荷 -> set_params -> 读回校验。
可选 --gen 填完立即生成（花 Anlas，慎用）。
"""
import argparse
import asyncio
import json
import os
import subprocess
import sys
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOL_DIR))
from nai_bridge_client import Bridge  # noqa: E402

NAI_READ = os.environ.get(
    'NAI_READ',
    r'E:\A.I\NovelAI\nai-workspace\skills\nai-draw\nai_read.py',
)


def read_meta(image: str) -> dict:
    env = dict(os.environ, PYTHONIOENCODING='utf-8')
    p = subprocess.run(
        [sys.executable, NAI_READ, '--json', image],
        capture_output=True, text=True, encoding='utf-8', env=env, timeout=120,
    )
    if p.returncode != 0:
        sys.exit('nai_read 解析失败:\n' + (p.stderr.strip() or p.stdout.strip()))
    try:
        return json.loads(p.stdout)
    except json.JSONDecodeError:
        sys.exit('未能从图片中解析出 NAI 元数据（可能不是 NAI 图或元数据已损坏）')


def build_payload(d: dict, lock: bool = True, with_chars: bool = True) -> dict:
    v4 = d.get('v4_prompt') or {}
    cap = v4.get('caption') or {}
    v4n = d.get('v4_negative_prompt') or {}
    ncap = v4n.get('caption') or {}
    payload = {
        'prompt': d.get('prompt') or cap.get('base_caption') or '',
        'negative_prompt': d.get('uc') or ncap.get('base_caption')
        or d.get('negative_prompt') or '',
        # UC 已按元数据逐字填入 -> 预设设 None，不让服务端再叠加
        'uc_preset': 3,
        # 提示词逐字 -> 不追加质量词
        'quality_toggle': False,
    }
    for src, dst in (('width', 'width'), ('height', 'height'),
                     ('steps', 'steps'), ('seed', 'seed'),
                     ('scale', 'cfg_scale'), ('sampler', 'sampler'),
                     ('noise_schedule', 'noise_schedule'),
                     ('cfg_rescale', 'cfg_rescale')):
        if d.get(src) is not None:
            payload[dst] = d[src]
    payload['seed_lock'] = lock
    # Variety+ 在元数据里体现为 skip_cfg_above_sigma 非空（其值由种子派生）
    if d.get('skip_cfg_above_sigma') is not None:
        payload['variety_plus'] = True
    # V5 透明背景（官方 tag hint；prompt 已含 tag，桥接端拼装会去重）
    if d.get('tag_hint_transparent_background'):
        payload['transparent_background'] = True
    for src, dst in (('sm', 'smea'), ('sm_dyn', 'smea_dyn')):
        if d.get(src) is not None:
            payload[dst] = bool(d[src])
    if v4.get('use_coords') is not None:
        payload['use_coords'] = bool(v4['use_coords'])
    # 角色框（桥接端双写 UI 系统 + 生成参数态）
    if with_chars:
        chars = []
        for c in cap.get('char_captions') or []:
            center = (c.get('centers') or [{}])[0]
            chars.append({
                'prompt': c.get('char_caption') or '',
                'uc': c.get('negative_char_caption') or '',
                'x': center.get('x'),
                'y': center.get('y'),
            })
        # 总是携带：参考图无角色框时顺带清空残留角色
        payload['characters'] = chars
    return payload


# get_params 可回读的键 -> 元数据键
VERIFY_KEYS = {
    'prompt': 'prompt', 'negative_prompt': 'uc', 'width': 'width',
    'height': 'height', 'seed': 'seed', 'steps': 'steps',
    'cfg_scale': 'scale', 'sampler': 'sampler',
}


async def main() -> int:
    ap = argparse.ArgumentParser(description='把 NAI 图片的完整设置一键填入启动器')
    ap.add_argument('image', help='NAI 生成的 PNG（含元数据）')
    ap.add_argument('--no-lock', action='store_true', help='不锁定种子')
    ap.add_argument('--no-chars', action='store_true',
                    help='不动角色框（默认按参考图覆盖/清空）')
    ap.add_argument('--gen', action='store_true',
                    help='填入后立即生成（消耗 Anlas）')
    ap.add_argument('--dry', action='store_true', help='只打印载荷不推送')
    a = ap.parse_args()

    d = read_meta(a.image)
    payload = build_payload(d, lock=not a.no_lock, with_chars=not a.no_chars)
    if a.dry:
        print(json.dumps(payload, ensure_ascii=False, indent=1))
        return 0

    b = Bridge()
    await b.connect()
    try:
        r = await b.rpc('set_params', payload)
        applied = r.get('applied') or []
        print(f"已填入 {len(applied)} 项: {', '.join(applied)}")

        back = await b.rpc('get_params')
        bad = []
        for gk, mk in VERIFY_KEYS.items():
            want = d.get(mk)
            if want is not None and back.get(gk) != want:
                bad.append(f"{gk}: 应用={back.get(gk)!r} 参考={want!r}")
        print('读回校验: ' + ('全部一致' if not bad
                             else '不一致 -> ' + '; '.join(bad)))
        nch = len(payload.get('characters') or [])
        lock = '未锁' if a.no_lock else '锁定'
        print(f"角色框: {nch} | 种子: {d.get('seed')}({lock}) | "
              f"尺寸: {d.get('width')}x{d.get('height')} | "
              f"steps: {d.get('steps')} | {d.get('sampler')}/"
              f"{d.get('noise_schedule')}")
    finally:
        await b.close()

    if a.gen:
        print('--- 开始生成 ---')
        env = dict(os.environ, PYTHONIOENCODING='utf-8')
        subprocess.run([sys.executable, str(TOOL_DIR / 'nai_bridge_client.py'), 'gen'],
                       env=env)
    return 0


if __name__ == '__main__':
    sys.exit(asyncio.run(main()))
