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
      FloatingResourceKind.blocks => _blocks(image, layout, connected),
      FloatingResourceKind.vibe => _refs(kind, image, layout, connected),
      FloatingResourceKind.precise => _refs(kind, image, layout, connected),
    };
  }

  static const _counts = {
    FloatingResourceKind.gallery: 48714,
    FloatingResourceKind.blocks: 704,
    FloatingResourceKind.vibe: 4,
    FloatingResourceKind.precise: 1,
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
          badge: const ['V4.5', 'V4.5', 'V5', null, 'V4'][j % 5],
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
          id: 'library',
          title: '资料库',
          groups: [
            ResourceGroup(
              id: 'all',
              label: '全部图片',
              count: 48714,
              icon: ResourceGroupIcon.all,
            ),
            ResourceGroup(
              id: 'favorites',
              label: '收藏',
              count: 163,
              icon: ResourceGroupIcon.favorite,
            ),
            ResourceGroup(
              id: 'recent',
              label: '最近浏览',
              icon: ResourceGroupIcon.recent,
            ),
            ResourceGroup(
              id: 'trash',
              label: '删除池',
              icon: ResourceGroupIcon.trash,
            ),
          ],
        ),
        ResourceGroupSection(
          id: 'collections',
          title: '收藏集',
          groups: [
            ResourceGroup(
              id: 'collection:wof',
              label: 'W.O.F',
              count: 77,
              icon: ResourceGroupIcon.collectionFolder,
              expanded: true,
            ),
            ResourceGroup(
              id: 'collection:artists',
              parentId: 'collection:wof',
              label: '画师收藏集',
              count: 0,
              icon: ResourceGroupIcon.collection,
            ),
            ResourceGroup(
              id: 'collection:trip',
              parentId: 'collection:wof',
              label: '旅行',
              count: 77,
              icon: ResourceGroupIcon.collection,
            ),
            ResourceGroup(
              id: 'collection:style',
              label: '画风',
              count: 0,
              icon: ResourceGroupIcon.collection,
            ),
            ResourceGroup(
              id: 'collection:interest',
              label: '兴趣点',
              count: 80,
              icon: ResourceGroupIcon.collection,
            ),
          ],
        ),
        ResourceGroupSection(
          id: 'folders',
          title: '文件夹',
          groups: [
            ResourceGroup(
              id: 'folder:lib',
              label: '01_图库',
              count: 49177,
              expanded: true,
            ),
            ResourceGroup(
              id: 'folder:n3',
              parentId: 'folder:lib',
              label: 'NAI 3',
              count: 375,
              expanded: true,
            ),
            ResourceGroup(
              id: 'folder:n3r',
              parentId: 'folder:n3',
              label: 'R18',
              count: 112,
            ),
            ResourceGroup(
              id: 'folder:n3n',
              parentId: 'folder:n3',
              label: '正常向',
              count: 263,
            ),
            ResourceGroup(
              id: 'folder:n4',
              parentId: 'folder:lib',
              label: 'NAI 4',
              count: 749,
            ),
            ResourceGroup(
              id: 'folder:n4r',
              parentId: 'folder:n4',
              label: 'R18',
              count: 126,
            ),
            ResourceGroup(
              id: 'folder:n45',
              parentId: 'folder:lib',
              label: 'NAI 4.5',
              count: 27049,
            ),
            ResourceGroup(
              id: 'folder:n45r',
              parentId: 'folder:n45',
              label: 'R18',
              count: 7217,
            ),
            ResourceGroup(
              id: 'folder:unk',
              parentId: 'folder:lib',
              label: 'NAI未知版本',
              count: 36,
            ),
            ResourceGroup(
              id: 'folder:wof',
              parentId: 'folder:lib',
              label: 'W.O.F 艺术家收藏',
              count: 1373,
            ),
            ResourceGroup(
              id: 'folder:wof1',
              parentId: 'folder:wof',
              label: 'airfish (lefko d)-116',
              count: 5,
            ),
            ResourceGroup(
              id: 'folder:log',
              parentId: 'folder:lib',
              label: '_分类日志',
              count: 0,
              dim: true,
            ),
            ResourceGroup(
              id: 'folder:misc',
              parentId: 'folder:lib',
              label: '_杂物',
              count: 0,
              dim: true,
            ),
            ResourceGroup(id: 'folder:tmp', label: '临时存储栈堆', count: 250),
            ResourceGroup(id: 'folder:ref', label: '参考图', count: 106),
            ResourceGroup(
              id: 'folder:none',
              label: '未分类',
              count: 66,
              icon: ResourceGroupIcon.uncategorized,
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
        ResourceOption(id: 'modifiedAt', label: '修改时间'),
        ResourceOption(id: 'createdAt', label: '创建时间'),
        ResourceOption(id: 'fileName', label: '文件名'),
        ResourceOption(id: 'fileSize', label: '文件大小'),
        ResourceOption(id: 'imageDimensions', label: '尺寸'),
      ],
      sortId: 'modifiedAt',
      descending: true,
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
      total: 48714,
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
    ImageProvider Function(int)? image,
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
          // 一半带预览图（裁切不同），其余画文字封面。
          thumb: i.isEven ? image?.call(i + 3) : null,
          crop: i.isEven
              ? ResourceThumbCrop(offsetY: i % 4 == 0 ? -.4 : .2, scale: 1.2)
              : null,
          itemCount: '$pos,$neg'
              .split(',')
              .where((s) => s.trim().isNotEmpty)
              .length,
          useCount: (i * 13) % 50,
          hasParams: i == 0,
        ),
    ];
    return ResourceWindowViewData(
      kind: FloatingResourceKind.blocks,
      counts: _counts,
      sections: const [
        ResourceGroupSection(
          id: 'library',
          title: '',
          groups: [
            ResourceGroup(
              id: 'all',
              label: '全部块',
              count: 704,
              icon: ResourceGroupIcon.all,
            ),
            ResourceGroup(
              id: 'recent',
              label: '最近使用',
              count: 20,
              icon: ResourceGroupIcon.recent,
            ),
            ResourceGroup(
              id: 'favorites',
              label: '收藏',
              count: 14,
              icon: ResourceGroupIcon.favorite,
            ),
          ],
        ),
        ResourceGroupSection(
          id: 'collections',
          title: '收藏集',
          groups: [
            ResourceGroup(
              id: 'collection:daily',
              label: '日常组合',
              count: 12,
              icon: ResourceGroupIcon.collection,
            ),
          ],
        ),
        ResourceGroupSection(
          id: 'folders',
          title: '文件夹',
          groups: [
            ResourceGroup(
              id: 'uncategorized',
              label: '未分类',
              count: 37,
              icon: ResourceGroupIcon.uncategorized,
            ),
            ResourceGroup(
              id: 'folder:style',
              label: '画风',
              count: 165,
              expanded: true,
            ),
            ResourceGroup(
              id: 'folder:style2',
              parentId: 'folder:style',
              label: '画风',
              count: 164,
            ),
            ResourceGroup(
              id: 'folder:misc',
              parentId: 'folder:style',
              label: '其他',
              count: 1,
            ),
            ResourceGroup(
              id: 'folder:official',
              label: 'NovelAI 官方预设',
              count: 12,
            ),
            ResourceGroup(
              id: 'folder:quality',
              parentId: 'folder:official',
              label: '质量词预设',
              count: 4,
            ),
            ResourceGroup(id: 'folder:char', label: '角色', count: 73),
            ResourceGroup(
              id: 'folder:oc',
              parentId: 'folder:char',
              label: 'OC',
              count: 71,
            ),
            ResourceGroup(id: 'folder:wear', label: '衣柜', count: 171),
            ResourceGroup(
              id: 'folder:wear2',
              parentId: 'folder:wear',
              label: '衣柜',
              count: 171,
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
      sorts: const [
        ResourceOption(id: 'custom', label: '自定义顺序', directional: false),
        ResourceOption(id: 'updated', label: '最近修改'),
        ResourceOption(id: 'title', label: '名称'),
      ],
      sortId: 'updated',
      descending: true,
      layouts: const [
        ResourceLayout.masonry,
        ResourceLayout.grid,
        ResourceLayout.list,
      ],
      layout: layout ?? ResourceLayout.masonry,
      items: items,
      total: 704,
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
          thumb: image?.call(j + off),
          strength: vibe ? .6 : 1,
          secondary: vibe ? 1 : 0,
          inGeneration: j == 0,
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
                id: 'library',
                title: '',
                groups: [
                  ResourceGroup(
                    id: 'all',
                    label: '全部',
                    count: 4,
                    icon: ResourceGroupIcon.all,
                  ),
                  ResourceGroup(
                    id: 'favorites',
                    label: '收藏',
                    count: 1,
                    icon: ResourceGroupIcon.favorite,
                  ),
                  ResourceGroup(
                    id: 'inGeneration',
                    label: '在生图页',
                    count: 1,
                    icon: ResourceGroupIcon.inGeneration,
                  ),
                ],
              ),
              ResourceGroupSection(
                id: 'categories',
                title: '分类',
                groups: [
                  ResourceGroup(
                    id: 'category:light',
                    label: '光影',
                    count: 2,
                    icon: ResourceGroupIcon.category,
                    expanded: true,
                  ),
                  ResourceGroup(
                    id: 'category:neon',
                    parentId: 'category:light',
                    label: '霓虹',
                    count: 1,
                    icon: ResourceGroupIcon.category,
                  ),
                  ResourceGroup(
                    id: 'category:tone',
                    label: '色调',
                    count: 2,
                    icon: ResourceGroupIcon.category,
                  ),
                ],
              ),
            ]
          : const [
              ResourceGroupSection(
                id: 'library',
                title: '',
                groups: [
                  ResourceGroup(
                    id: 'all',
                    label: '全部',
                    count: 1,
                    icon: ResourceGroupIcon.all,
                  ),
                  ResourceGroup(
                    id: 'favorites',
                    label: '收藏',
                    count: 0,
                    icon: ResourceGroupIcon.favorite,
                  ),
                  ResourceGroup(
                    id: 'inGeneration',
                    label: '在生图页',
                    count: 1,
                    icon: ResourceGroupIcon.inGeneration,
                  ),
                ],
              ),
              ResourceGroupSection(
                id: 'types',
                title: '类型',
                groups: [
                  ResourceGroup(
                    id: 'type:character',
                    label: '角色',
                    count: 1,
                    icon: ResourceGroupIcon.typeCharacter,
                  ),
                  ResourceGroup(
                    id: 'type:style',
                    label: '风格',
                    count: 0,
                    icon: ResourceGroupIcon.typeStyle,
                  ),
                  ResourceGroup(
                    id: 'type:both',
                    label: '角色和风格',
                    count: 0,
                    icon: ResourceGroupIcon.typeBoth,
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
      sorts: const [
        ResourceOption(id: 'lastUsed', label: '最近使用'),
        ResourceOption(id: 'createdAt', label: '添加时间'),
        ResourceOption(id: 'usedCount', label: '使用次数'),
        ResourceOption(id: 'name', label: '名称'),
      ],
      sortId: 'lastUsed',
      descending: true,
      cellSize: 180,
      cellRange: const (140.0, 240.0),
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
