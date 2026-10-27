import 'package:flutter/widgets.dart';

import '../kit/ui_glyph.dart';
import '../kit/ui_resource_kind.dart';
import 'resource_window_contract.dart';

/// 资源窗口夹具（预览 / 测试 / 截图）。文案按原型写死中文，只用于夹具。
abstract final class ResourceWindowFixture {
  static const _prompts = [
    '1girl, solo, raincoat, hood up, neon lights, rain, night city, vending machine',
    '1girl, silver hair, twintails, school uniform, park bench, depth of field',
    'scenery, starry sky, milky way, glowing flowers, from behind, wide shot',
    '1girl, kimono, cherry blossoms, petals, wind, looking at viewer, smile',
    '1girl, maid, holding tray, café interior, warm lighting, bokeh',
  ];
  static const _vibes = ['雨夜霓虹', '厚涂暖光', '水彩洗色', '赛博蓝', '逆光剪影', '胶片颗粒'];
  static const _people = ['银发少女', '雨衣女孩', '女仆', '和服', '星空', '猫耳'];

  static ResourceWindowViewData view(
    FloatingResourceKind kind, {
    ImageProvider Function(int i)? image,
    ResourceLayout? layout,
    DateTime? now,
    bool connected = true,
  }) {
    final today = now ?? DateTime(2026, 10, 27, 16, 30);
    return switch (kind) {
      FloatingResourceKind.gallery => _gallery(image, layout, today, connected),
      FloatingResourceKind.blocks => _blocks(layout, connected),
      FloatingResourceKind.vibe => _refs(kind, image, layout, connected),
      FloatingResourceKind.precise => _refs(kind, image, layout, connected),
    };
  }

  static const _counts = {
    FloatingResourceKind.gallery: 1284,
    FloatingResourceKind.blocks: 86,
    FloatingResourceKind.vibe: 42,
    FloatingResourceKind.precise: 17,
  };

  static ResourceWindowViewData _gallery(
    ImageProvider Function(int)? image,
    ResourceLayout? layout,
    DateTime now,
    bool connected,
  ) {
    const aspects = <double>[
      2 / 3,
      832 / 1216,
      3 / 2,
      1,
      2 / 3,
      1216 / 832,
      2 / 3,
    ];
    final items = <ResourceItem>[
      for (var j = 0; j < 30; j++)
        ResourceItem(
          id: 'g$j',
          title:
              '${(16 - j % 9).toString().padLeft(2, '0')}:${(j * 7 % 60).toString().padLeft(2, '0')}',
          meta: '832×1216',
          thumb: image?.call(j),
          aspect: aspects[j % aspects.length],
          badge: j % 5 == 3 ? 'V4' : null,
          favorite: const {1, 4, 9, 15}.contains(j),
          positive: _prompts[j % _prompts.length],
          date: now.subtract(Duration(days: j < 8 ? 0 : (j < 18 ? 1 : 3))),
        ),
    ];
    final sel = items[2];
    return ResourceWindowViewData(
      kind: FloatingResourceKind.gallery,
      counts: _counts,
      sections: const [
        ResourceGroupSection(
          title: '资料库',
          groups: [
            ResourceGroup(
              id: 'all',
              label: '全部图片',
              count: 1284,
              glyph: UiGlyphs.clock,
            ),
            ResourceGroup(
              id: 'today',
              label: '今天',
              count: 24,
              glyph: UiGlyphs.calendar,
            ),
            ResourceGroup(
              id: 'fav',
              label: '收藏',
              count: 186,
              glyph: UiGlyphs.heart,
            ),
          ],
        ),
        ResourceGroupSection(
          title: '文件夹',
          groups: [
            ResourceGroup(id: 'f1', label: 'outputs', count: 9840),
            ResourceGroup(id: 'f2', label: 'Pixiv 收藏', count: 1962),
            ResourceGroup(id: 'f3', label: '临时存图', count: 606),
          ],
        ),
        ResourceGroupSection(
          title: '收藏集',
          groups: [
            ResourceGroup(
              id: 'c1',
              label: '雨夜系列',
              count: 38,
              glyph: UiGlyphs.star,
            ),
            ResourceGroup(
              id: 'c2',
              label: '角色设定',
              count: 121,
              glyph: UiGlyphs.star,
            ),
          ],
        ),
      ],
      groupId: 'all',
      queryHint: '搜索提示词（整段 / 完整标签），例如 raincoat, hood up',
      chips: const [
        ResourceChip(id: 'nai', label: '仅 NAI', on: true, glyph: UiGlyphs.bolt),
        ResourceChip(id: 'fav', label: '收藏', glyph: UiGlyphs.heart),
      ],
      sorts: const [
        ResourceOption(id: 'new', label: '最新'),
        ResourceOption(id: 'old', label: '最早'),
      ],
      sortId: 'new',
      layouts: const [
        ResourceLayout.justified,
        ResourceLayout.masonry,
        ResourceLayout.grid,
      ],
      layout: layout ?? ResourceLayout.justified,
      cellSize: layout == null || layout == ResourceLayout.justified
          ? 170
          : 132,
      items: items,
      total: 1284,
      hasMore: true,
      selectedId: sel.id,
      detail: ResourceDetail(
        itemId: sel.id,
        title: '${sel.title} · 832×1216',
        subtitle: 'V4.5 Full · 28 步 · 引导 5.0 · 种子 3274348526',
        body: sel.positive,
        actions: const [
          ResourceActionSpec(id: 'copy', label: '复制图片', glyph: UiGlyphs.copy),
          ResourceActionSpec(
            id: 'vibe',
            label: '加到 Vibe',
            glyph: UiGlyphs.spark,
          ),
          ResourceActionSpec(id: 'i2i', label: '设为图生图'),
          ResourceActionSpec(
            id: 'reuse',
            label: '复用参数',
            glyph: UiGlyphs.send,
            primary: true,
          ),
        ],
      ),
      connected: connected,
      statusNote: '索引最新 · 2 分钟前',
      now: now,
    );
  }

  static ResourceWindowViewData _blocks(
    ResourceLayout? layout,
    bool connected,
  ) {
    const raw = [
      (
        0xFFF59E0B,
        'palette',
        '厚涂画风',
        'thick painting, impasto, painterly, oil painting (medium), canvas texture',
        '',
        '画风',
      ),
      (
        0xFF3B82F6,
        'person',
        '银发双马尾',
        '1girl, silver hair, twintails, hair ribbon, blue eyes, ahoge',
        'eyes closed',
        '角色',
      ),
      (
        0xFF22C55E,
        'park',
        '雨夜街道',
        'night, rain, wet street, neon lights, reflection, puddle, city',
        '',
        '场景',
      ),
      (
        0xFFA855F7,
        'dress',
        '雨衣',
        'raincoat, hood up, yellow raincoat, transparent raincoat',
        '',
        '服装',
      ),
      (
        0xFFE5484D,
        'shield',
        '通用负面',
        '',
        'lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit',
        '负面',
      ),
      (
        0xFFF59E0B,
        'color_lens',
        '水彩洗色',
        'watercolor (medium), wash, soft edges, paper texture, muted colors',
        '',
        '画风',
      ),
      (
        0xFF3B82F6,
        'person',
        '女仆',
        'maid, maid headdress, apron, frills, black dress, white thighhighs',
        '',
        '角色',
      ),
      (
        0xFF22C55E,
        'moon',
        '星空花田',
        'starry sky, milky way, glowing flowers, field, night, wide shot',
        '',
        '场景',
      ),
      (
        0xFFA855F7,
        'dress',
        '和服',
        'kimono, obi, floral print, wide sleeves, hair flower',
        '',
        '服装',
      ),
    ];
    final items = [
      for (final (i, (color, icon, title, pos, neg, folder)) in raw.indexed)
        ResourceItem(
          id: 'b$i',
          title: title,
          color: Color(color),
          iconKey: icon,
          positive: pos.isEmpty ? null : pos,
          negative: neg.isEmpty ? null : neg,
          folder: folder,
          favorite: i % 4 == 1,
          meta:
              '${'$pos,$neg'.split(',').where((s) => s.trim().isNotEmpty).length} 词',
        ),
    ];
    return ResourceWindowViewData(
      kind: FloatingResourceKind.blocks,
      counts: _counts,
      sections: const [
        ResourceGroupSection(
          title: '分组',
          groups: [
            ResourceGroup(
              id: 'all',
              label: '全部块',
              count: 86,
              glyph: UiGlyphs.layers,
            ),
            ResourceGroup(
              id: 'fav',
              label: '收藏',
              count: 14,
              glyph: UiGlyphs.star,
            ),
          ],
        ),
        ResourceGroupSection(
          title: '文件夹',
          groups: [
            ResourceGroup(
              id: 'style',
              label: '画风',
              count: 18,
              color: Color(0xFFF59E0B),
            ),
            ResourceGroup(
              id: 'char',
              label: '角色',
              count: 23,
              color: Color(0xFF3B82F6),
            ),
            ResourceGroup(
              id: 'scene',
              label: '场景',
              count: 15,
              color: Color(0xFF22C55E),
            ),
            ResourceGroup(
              id: 'wear',
              label: '服装',
              count: 19,
              color: Color(0xFFA855F7),
            ),
            ResourceGroup(
              id: 'neg',
              label: '负面',
              count: 11,
              color: Color(0xFFE5484D),
            ),
          ],
        ),
      ],
      groupId: 'all',
      queryHint: '搜索块名、内容或 #文件夹',
      chips: const [
        ResourceChip(id: 'pos', label: '正面', on: true),
        ResourceChip(id: 'neg', label: '负面'),
        ResourceChip(id: 'fav', label: '收藏', glyph: UiGlyphs.star),
      ],
      sorts: const [ResourceOption(id: 'recent', label: '最近使用')],
      sortId: 'recent',
      layouts: const [
        ResourceLayout.masonry,
        ResourceLayout.grid,
        ResourceLayout.list,
      ],
      layout: layout ?? ResourceLayout.masonry,
      items: items,
      total: 86,
      selectedId: 'b1',
      detail: ResourceDetail(
        itemId: 'b1',
        title: '银发双马尾',
        subtitle: '角色 · 6 词 · 用过 41 次',
        body: items[1].positive,
        negative: items[1].negative,
        actions: const [
          ResourceActionSpec(id: 'edit', label: '编辑', glyph: UiGlyphs.pencil),
          ResourceActionSpec(id: 'neg', label: '插入负面'),
          ResourceActionSpec(
            id: 'pos',
            label: '插入正面',
            glyph: UiGlyphs.plus,
            primary: true,
          ),
        ],
      ),
      connected: connected,
      statusNote: '已同步',
    );
  }

  static ResourceWindowViewData _refs(
    FloatingResourceKind kind,
    ImageProvider Function(int)? image,
    ResourceLayout? layout,
    bool connected,
  ) {
    final vibe = kind == FloatingResourceKind.vibe;
    final n = vibe ? 18 : 12;
    final off = vibe ? 7 : 19;
    final items = [
      for (var j = 0; j < n; j++)
        ResourceItem(
          id: 'r$j',
          title: vibe ? _vibes[j % 6] : _people[j % 6],
          meta: vibe ? '0.6 · 1.0' : '1.0',
          thumb: image?.call(j + off),
          badge: vibe
              ? (j % 4 == 2 ? '需编码' : 'V4.5')
              : ['角色', '风格', '角色+风格'][j % 3],
          badgeTone: vibe
              ? (j % 4 == 2 ? ResourceBadgeTone.warn : ResourceBadgeTone.ok)
              : ResourceBadgeTone.plain,
          favorite: j % 5 == 1,
          positive: vibe ? '光影, 霓虹, 夜景' : null,
        ),
    ];
    return ResourceWindowViewData(
      kind: kind,
      counts: _counts,
      sections: vibe
          ? const [
              ResourceGroupSection(
                title: '分组',
                groups: [
                  ResourceGroup(
                    id: 'all',
                    label: '全部 Vibe',
                    count: 42,
                    glyph: UiGlyphs.spark,
                  ),
                  ResourceGroup(
                    id: 'fav',
                    label: '收藏',
                    count: 9,
                    glyph: UiGlyphs.star,
                  ),
                ],
              ),
              ResourceGroupSection(
                title: '分类',
                groups: [
                  ResourceGroup(
                    id: 'light',
                    label: '光影',
                    count: 12,
                    color: Color(0xFF3B82F6),
                  ),
                  ResourceGroup(
                    id: 'tone',
                    label: '色调',
                    count: 10,
                    color: Color(0xFFF59E0B),
                  ),
                  ResourceGroup(
                    id: 'comp',
                    label: '构图',
                    count: 8,
                    color: Color(0xFF22C55E),
                  ),
                ],
              ),
            ]
          : const [
              ResourceGroupSection(
                title: '分组',
                groups: [
                  ResourceGroup(
                    id: 'all',
                    label: '全部参考',
                    count: 17,
                    glyph: UiGlyphs.personStar,
                  ),
                  ResourceGroup(
                    id: 'fav',
                    label: '收藏',
                    count: 5,
                    glyph: UiGlyphs.star,
                  ),
                ],
              ),
            ],
      groupId: 'all',
      queryHint: vibe ? '搜索名称或标签' : '搜索名称',
      chips: vibe
          ? const [
              ResourceChip(id: 'fav', label: '收藏', glyph: UiGlyphs.star),
              ResourceChip(id: 'usable', label: '当前模型可用', on: true),
            ]
          : const [ResourceChip(id: 'fav', label: '收藏', glyph: UiGlyphs.star)],
      sorts: const [ResourceOption(id: 'recent', label: '最近使用')],
      sortId: 'recent',
      layouts: const [ResourceLayout.grid, ResourceLayout.list],
      layout: layout ?? ResourceLayout.grid,
      items: items,
      total: n,
      selectedId: 'r2',
      detail: ResourceDetail(
        itemId: 'r2',
        title: items[2].title,
        subtitle: vibe
            ? 'V4.5 已编码 · 信息提取 0.6 · 强度 1.0 · 用过 12 次'
            : '角色+风格 · 强度 1.0 · 保真 0.0',
        body: vibe ? '标签：光影, 霓虹, 夜景' : null,
        actions: [
          const ResourceActionSpec(
            id: 'edit',
            label: '编辑',
            glyph: UiGlyphs.pencil,
          ),
          ResourceActionSpec(
            id: 'add',
            label: vibe ? '添加到生成' : '添加到精准参考',
            glyph: UiGlyphs.plus,
            primary: true,
          ),
        ],
      ),
      connected: connected,
      statusNote: '已同步',
    );
  }
}
