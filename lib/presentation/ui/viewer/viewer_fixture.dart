import 'package:flutter/widgets.dart';

import '../kit/ui_fixture_image.dart';
import 'viewer_contract.dart';

part 'viewer_fixture_data.dart';

class _Raw {
  const _Raw({
    required this.file,
    required this.folder,
    required this.mtime,
    required this.sizeMb,
    required this.width,
    required this.height,
    this.model,
    this.seed,
    this.sampler,
    this.steps,
    this.scale,
    this.noise,
    this.rescale,
    this.precise = 0,
    this.prompt,
    this.negative = '',
    this.characters = const [],
  });
  final String file;
  final String folder;
  final String mtime;
  final double sizeMb;
  final int width;
  final int height;
  final String? model;
  final int? seed;
  final String? sampler;
  final int? steps;
  final double? scale;
  final String? noise;
  final double? rescale;
  final int precise;
  final String? prompt;
  final String negative;
  final List<ViewerCharacter> characters;
}

/// 图片加载：(key, 是否缩略图)。默认用渐变占位图（基准截图），预览换成原型图。
typedef ViewerFixtureImages = ImageProvider? Function(String key, bool thumb);

/// 大图查看器的假数据：和原型（.devin/mockups/viewer/mock.html）同一批图。
abstract final class ViewerFixture {
  /// 相对时间的基准（原型里最新一张图的修改时间之后）。
  static final now = DateTime(2026, 8, 31, 0, 40);

  static ImageProvider? _gradient(String key, bool thumb) =>
      UiFixtureImage.gradient('v$key');

  /// 本地画廊顺序：V5 图按修改时间倒序（原型 `ORDER`）。
  static List<String> get order => [
    for (final t in [
      for (final t in _thumbs)
        if (t.$4 == 'V5') t,
    ]..sort((a, b) => b.$5.compareTo(a.$5)))
      t.$1,
  ];

  static const nometaList = [
    '36',
    '11',
    '04',
    '24',
    '10',
    '44',
    '31',
    '40',
    '05',
    '14',
    '26',
  ];
  static const batch = ['41', '16', '49', '09'];

  static DateTime _time(String s) => DateTime.parse(s.replaceFirst(' ', 'T'));

  static (String, int, int, String, String) _thumb(String key) => _thumbs
      .firstWhere((t) => t.$1 == key, orElse: () => (key, 1216, 832, 'V5', ''));

  static ViewerItem item(
    String key, {
    ViewerFixtureImages? images,
    bool loading = false,
    bool missing = false,
    bool favorite = false,
    DateTime? date,
    bool saved = false,
  }) {
    final load = images ?? _gradient;
    final t = _thumb(key);
    final raw = _details[key];
    final w = raw?.width ?? t.$2, h = raw?.height ?? t.$3;
    return ViewerItem(
      key: key,
      width: w,
      height: h,
      thumb: load(key, true),
      image: loading ? null : load(key, false),
      date: date ?? (t.$5.isEmpty ? null : _time(t.$5)),
      favorite: favorite,
      missing: missing,
      saved: saved,
      path: raw == null ? null : '${raw.folder}/${raw.file}',
      sizeBytes: raw == null
          ? (w * h * 1.4).round()
          : (raw.sizeMb * 1024 * 1024).round(),
    );
  }

  static ViewerDetail detail(
    String key, {
    ViewerMetaStatus? status,
    bool generation = false,
  }) {
    final t = _thumb(key);
    final raw = _details[key] ?? _borrow(key, t.$4);
    final nai = raw.prompt != null && raw.prompt!.isNotEmpty;
    return ViewerDetail(
      key: key,
      status: status ?? (nai ? ViewerMetaStatus.ready : ViewerMetaStatus.none),
      fileName: generation ? null : raw.file,
      folder: generation ? null : raw.folder,
      model: nai ? raw.model : null,
      seed: raw.seed,
      sampler: raw.sampler,
      steps: raw.steps,
      scale: raw.scale,
      noiseSchedule: raw.noise,
      cfgRescale: raw.rescale,
      preciseCount: raw.precise,
      prompt: raw.prompt ?? '',
      characters: raw.characters,
      negative: raw.negative,
      vibes: key == '41'
          ? [
              ViewerVibe(
                name: '雨夜城市 · 氛围',
                thumb: UiFixtureImage.gradient('vibe-41'),
                strength: .6,
                infoExtracted: 1,
              ),
            ]
          : const [],
    );
  }

  /// 原型只给了 12 张图的元数据；其他图（预览里翻过去时）借一张同版本的。
  static _Raw _borrow(String key, String ver) {
    final t = _thumb(key);
    final file = '$key.png';
    if (ver == 'NAI') {
      return _Raw(
        file: file,
        folder: '01_图库/氛围图',
        mtime: t.$5,
        sizeMb: 1.2,
        width: t.$2,
        height: t.$3,
      );
    }
    final same = _details.values.where((r) => r.model?.endsWith(ver) ?? false);
    final src = same.isEmpty ? _details.values.first : same.first;
    return _Raw(
      file: 'A50F${t.$5.replaceAll(RegExp('[^0-9]'), '')}-$key.png',
      folder: src.folder,
      mtime: t.$5,
      sizeMb: src.sizeMb,
      width: t.$2,
      height: t.$3,
      model: src.model,
      seed: (src.seed ?? 1) + key.hashCode % 9973,
      sampler: src.sampler,
      steps: src.steps,
      scale: src.scale,
      noise: src.noise,
      rescale: src.rescale,
      prompt: src.prompt,
      negative: src.negative,
      characters: src.characters,
    );
  }

  static const _galleryActions = {
    ViewerAction.reuse,
    ViewerAction.img2img,
    ViewerAction.styleTransfer,
    ViewerAction.preciseRef,
    ViewerAction.saveToRefLibrary,
    ViewerAction.krita,
    ViewerAction.upscale,
    ViewerAction.copyImage,
    ViewerAction.copyPath,
    ViewerAction.copyAllPrompts,
    ViewerAction.saveAsBlock,
    ViewerAction.moveTo,
    ViewerAction.copyTo,
    ViewerAction.showInFolder,
  };

  static const _generationActions = {
    ViewerAction.save,
    ViewerAction.copyImage,
    ViewerAction.saveAsBlock,
    ViewerAction.reuse,
    ViewerAction.img2img,
    ViewerAction.preciseRef,
    ViewerAction.upscale,
    ViewerAction.copyAllPrompts,
  };

  static const collections = [
    ViewerCollection(id: 'wof', name: 'W.O.F', member: true),
    ViewerCollection(id: 'artists', name: '画师收藏集'),
    ViewerCollection(id: 'travel', name: '旅行'),
    ViewerCollection(id: 'normal', name: '正常向', member: true),
  ];

  /// 本地画廊大图（原型 `#a`）。
  static ViewerViewData gallery({
    String current = '08',
    List<String>? list,
    int position = 1283,
    int total = 45550,
    ViewerScope scope = const ViewerScope(sort: ViewerSort.modified),
    ViewerFixtureImages? images,
    ViewerMetaStatus? status,
    bool loading = false,
    bool missing = false,
    bool infoOpen = true,
    bool fullscreen = false,
    bool favorite = true,
    ViewerUndo? undo,
    Map<ViewerPart, ViewerTranslation> translations = const {},
    bool zoomHintSeen = false,
  }) {
    final keys = list ?? order;
    return ViewerViewData(
      mode: ViewerMode.gallery,
      items: [
        for (final k in keys)
          item(
            k,
            images: images,
            loading: loading && k == current,
            missing: missing && k == current,
            favorite: favorite && k == current,
          ),
      ],
      currentKey: current,
      now: now,
      position: position,
      total: total,
      scope: scope,
      detail: detail(current, status: status),
      actions: _galleryActions,
      infoOpen: infoOpen,
      fullscreen: fullscreen,
      collections: collections,
      translations: translations,
      undo: undo,
      zoomHintSeen: zoomHintSeen,
    );
  }

  /// 没有生成信息的图（原型 `#nometa`）。
  static ViewerViewData nometa({ViewerFixtureImages? images}) => gallery(
    current: '04',
    list: nometaList,
    position: 38015,
    scope: const ViewerScope(name: '氛围图', sort: ViewerSort.modified),
    images: images,
    favorite: false,
  );

  /// 删除后撤销（原型 `#del`）：08 删掉，16 补位。
  static ViewerViewData deleted({ViewerFixtureImages? images}) => gallery(
    current: '16',
    list: order.where((k) => k != '08').toList(),
    total: 45549,
    images: images,
    favorite: false,
    undo: const ViewerUndo(
      id: 'd1',
      fileName:
          'A50F2026-08-28-181294218-7e97e803fb981cd7804d278371633d5f592f3570d8ec1d87b73b998dda2b3e95.png',
    ),
  );

  /// 从生图页打开（原型 `#hist`）：本批 4 张，第 2 张，还没保存。
  static ViewerViewData generation({
    ViewerFixtureImages? images,
    String current = '16',
    Set<String> saved = const {},
  }) => ViewerViewData(
    mode: ViewerMode.generation,
    items: [
      for (final (i, k) in batch.indexed)
        item(
          k,
          images: images,
          date: now.subtract(Duration(minutes: 2, seconds: i)),
          saved: saved.contains(k),
        ),
    ],
    currentKey: current,
    now: now,
    detail: detail(current, generation: true),
    actions: _generationActions,
  );
}
