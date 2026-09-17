/// 生成按钮文案池（三语，全球通用梗路线）
///
/// 文案由 [pick] 用确定性种子选取：数量变化或一次生成结束时
/// 外层推进种子，按钮即换上新文案；同一种子在 build 间结果稳定。
/// 约 80% 种子回退 [normal] 官方式文案；约 20% 进彩蛋池，
/// 其中 seed % 20 == 0（约 5%）进稀有池，其余先特殊数字再分档池。
class GenerateButtonCopy {
  GenerateButtonCopy._();

  /// 彩蛋池命中步长：seed % 5 == 0 → 约 20%
  static const int _funnyModulo = 5;

  /// 稀有池命中步长：seed % 20 == 0 → 约 5%（彩蛋档内的四分之一）
  static const int _rareModulo = 20;

  /// 按种子与总张数挑选一条文案。
  ///
  /// [count] 是最终生成总张数（请求次数 × 每次张数）。
  /// [languageCode] 只取前两位语言码，未知语言回退英文。
  static String pick({
    required int seed,
    required int count,
    required String languageCode,
  }) {
    final lang = _normalize(languageCode);
    if (seed % _funnyModulo != 0) {
      return normal(count: count, languageCode: lang);
    }
    final rare = _rarePool[lang]!;
    if (seed % _rareModulo == 0) {
      return _format(rare[(seed ~/ _rareModulo) % rare.length], count);
    }
    final special = _specialPool[lang]![count];
    if (special != null) {
      return _format(special[seed % special.length], count);
    }
    final pool = _bucketPool(lang, count);
    return _format(pool[seed % pool.length], count);
  }

  /// 官方式默认文案（约 80% 显示）：英文随数量切换单复数，
  /// 中/日无复数变化。
  static String normal({required int count, required String languageCode}) {
    switch (_normalize(languageCode)) {
      case 'zh':
        return '生成 $count 张图片';
      case 'ja':
        return '$count 枚生成';
      default:
        return count == 1 ? 'Generate 1 Image' : 'Generate $count Images';
    }
  }

  static String _normalize(String languageCode) {
    final code = languageCode.toLowerCase();
    if (code.startsWith('zh')) return 'zh';
    if (code.startsWith('ja')) return 'ja';
    return 'en';
  }

  static String _format(String template, int count) =>
      template.replaceAll('{count}', '$count');

  /// 常规分档：1–9 逐张一池，之后按区间分池
  static List<String> _bucketPool(String lang, int count) {
    if (count <= 9) {
      return _smallPools[lang]![count]!;
    }
    final index = count < 20 ? 0 : count < 50 ? 1 : count < 100 ? 2 : 3;
    return _bigPools[lang]![index];
  }

  /// 供测试读取池内容
  static List<String> debugPoolFor({
    required String languageCode,
    required int count,
  }) => _bucketPool(_normalize(languageCode), count);

  /// 供测试读取特殊数字池
  static List<String>? debugSpecialFor({
    required String languageCode,
    required int count,
  }) => _specialPool[_normalize(languageCode)]![count];

  // ------------------------------------------------------------------
  // 中文池：单张池大、随数量递减；10+ 稀疏分档
  // ------------------------------------------------------------------

  static const Map<int, List<String>> _zhSmall = {
    1: [
      '就来一张',
      '单抽出奇迹',
      '一张，就一张',
      '整一张看看',
      '一张定胜负',
      '摸一张试试水',
      '先来一张开开胃',
      '就一张，不贪心',
      '单抽，重在参与',
      '一张精品谢谢',
      '单发，信仰射击',
      '来一张压压惊',
      '生一张解解馋',
      '一张就好，真的',
      '就一张，我发誓',
      '来张好的求求了',
      '一张也是爱',
      '先整一张再说',
      '今晚就这一张',
      '一张，谢谢茄子',
      '新头像就决定是你了',
      '来一张，别问为什么',
      '生成一张小惊喜',
      '一张，最后一赌',
      '让我看看成色',
      '就一张，很快的',
      '来张能当壁纸的',
      '一张，不许摆烂',
      '给我来张硬的',
      '摸一张就跑',
    ],
    2: [
      '复制粘贴模式',
      '两张，择优录取',
      '左右开弓来两张',
      '二选一挑战赛',
      '翻倍快乐启动',
      '两张，不准都一样',
      '双人成行',
      '来双筷子好夹菜',
      '一组对比图安排',
      '买一送一模式',
      '两个里挑个好的',
    ],
    3: [
      '三连抽',
      '三张小确幸',
      '集齐三张召唤…',
      '三份快乐打包',
      '三选一，经典局',
      '三张大放送',
      '凑个三张套餐',
      '三份灵感已到',
      '抽三次过过瘾',
    ],
    4: [
      '四连出击',
      '四人小队集结',
      '四张，铺满屏幕',
      '4 宫格预备',
      '四张一起上',
      '四倍快乐',
      '连开四张',
    ],
    5: [
      '五连发',
      '五张，一手牌',
      '半打套餐还差一',
      '五张走起',
      '五连，上菜',
      '一只手刚好数完',
      '五张，开始上头了',
    ],
    6: [
      '六连击',
      '六张，排面有了',
      '六张一起梭哈',
      '来六张稳一手',
      '图库 +6',
      '六张，起飞',
    ],
    7: [
      '七张排排坐',
      '一周壁纸不重样',
      'Lucky Seven ×7',
      '七张，有点贪了',
      '七连击预备',
      '七张连开',
    ],
    8: [
      '章鱼模式八连拍',
      '图库爆仓预警',
      '八张，要溢出了',
      '八连发突突突',
      '八张排排站',
      '凑八张看大场面',
    ],
    9: [
      '九宫格一次集齐',
      '九图朋友圈稳了',
      '九张，就差一张整十',
      '九连，完美收官',
      '朋友圈素材×9',
      '九张全都要',
    ],
  };

  /// 10+ 分档池：0=10-19 1=20-49 2=50-99 3=100+
  static const List<List<String>> _zhBig = [
    [
      '{count} 张，上强度了',
      '显卡开始冒汗',
      '这是要日更吗',
      '{count} 张连开',
      '开始囤货模式',
      '{count} 张，有点野',
    ],
    [
      '量产车间开工',
      '{count} 张，工厂模式',
      'Anlas 在燃烧',
      '硬盘瑟瑟发抖',
      '{count} 张批处理',
      '挂机流水线启动',
    ],
    [
      '批发 {count} 张',
      '工业革命了属于是',
      '这已经不是摸鱼了',
      '{count} 张，矿机启动',
      '流水线火力全开',
      '{count} 张，打印店开张',
    ],
    [
      '{count} 张？！开画廊是吧',
      '图库の浩劫',
      '您这是要印画册？',
      '{count} 张，服务器沉默',
      '先冷静一下好吗',
      '{count} 张，存得下吗',
    ],
  ];

  static const Map<int, List<String>> _zhSpecial = {
    42: ['生命、宇宙与 42 张图', '终极答案是 {count}'],
    64: ['8² = {count}，数学之美'],
    69: ['{count} 张，数不错'],
    99: ['{count} 张，差一步破百'],
    100: ['整 {count} 张，完美主义'],
  };

  static const List<String> _zhRare = [
    '这发必出 SSR',
    'AI 说它今天手感不错',
    '今日玄学指数：MAX',
    '按下此键即信玄学',
    '据说这个按钮旺你',
  ];

  // ------------------------------------------------------------------
  // English pool
  // ------------------------------------------------------------------

  static const Map<int, List<String>> _enSmall = {
    1: [
      'Generate 1 image',
      'Just one. Promise.',
      'Single pull, big luck',
      'One pic please',
      'A lone masterpiece',
      'Solo queue',
      'One for the road',
      'Gacha: single pull',
      'One shot, one pic',
      'Quality over quantity',
      'Just a little treat',
      'The chosen one',
      'Generate exactly 1',
      'Minimalist mode',
      'One. Final answer.',
    ],
    2: [
      'Double trouble',
      '2 picks, choose wisely',
      'A matching pair',
      'Twins, please',
      'Generate 2 images',
      'Two is company',
      'Buy one get one',
      'Duo queue',
      'A/B testing, art edition',
    ],
    3: [
      'Triple pull',
      'The classic trio',
      '3 wishes granted',
      'Three’s a crowd',
      'Triple threat',
      'Generate 3 images',
      'Small combo meal',
    ],
    4: [
      'Quad squad',
      'Generate 4 images',
      'A full row',
      'Four of a kind',
      'Grid of 4, go',
      'Party of four',
    ],
    5: [
      'High five ×5',
      'Full hand of pics',
      'Generate 5 images',
      'Five-pack',
      'Half a dozen, minus one',
      '5 pulls, no mercy',
    ],
    6: [
      'Half dozen incoming',
      'Generate 6 images',
      'Gallery +6',
      'Six-pack of art',
      'Roll for six',
    ],
    7: [
      'Lucky seven',
      'A pic a day for a week',
      'Generate 7 images',
      'Seven straight pulls',
      'Week’s worth of art',
    ],
    8: [
      'Full octet',
      'Generate 8 images',
      'Storage warning: +8',
      'Eight at once',
      'Octo-pull',
    ],
    9: [
      'Full 3×3 grid',
      'One short of ten',
      'Generate 9 images',
      'Feed-ready nine',
      'Nine neat squares',
    ],
  };

  static const List<List<String>> _enBig = [
    [
      '{count} images, stepping it up',
      'GPU warming up',
      'Stockpiling {count}',
      'Double digits now',
      '{count} pulls, getting serious',
    ],
    [
      'Mass production: on',
      'Anlas burning bright',
      '{count} images, factory mode',
      'Batch mode engaged',
      'Hard drive shivers',
    ],
    [
      'Wholesale: {count} images',
      'Industrial revolution',
      'This is beyond casual',
      '{count} images, no chill',
      'Printer go brrr',
    ],
    [
      '{count}?! Opening a gallery?',
      'A library of {count}',
      'Maybe pace yourself',
      '{count} images, godspeed',
      'Storage says hi',
    ],
  ];

  static const Map<int, List<String>> _enSpecial = {
    42: ['{count}: the answer to everything'],
    64: ['8² = {count}, beautiful'],
    69: ['{count}. Nice.'],
    99: ['{count}, so close to triple digits'],
    100: ['A clean {count}'],
  };

  static const List<String> _enRare = [
    'SSR guaranteed',
    'The AI feels lucky today',
    'RNGesus, take the wheel',
    'This button believes in you',
    'Gacha gods, hear me',
  ];

  // ------------------------------------------------------------------
  // 日本語プール
  // ------------------------------------------------------------------

  static const Map<int, List<String>> _jaSmall = {
    1: [
      '1 枚だけ生成',
      '単発ガチャ、勝負',
      'まずは 1 枚',
      '1 枚で決める',
      '控えめに 1 枚',
      '1 枚ください',
      'お試し 1 枚',
      '今宵は 1 枚だけ',
      '渾身の 1 枚',
      '1 枚、お手柔らかに',
    ],
    2: ['2 枚、厳選します', '良い方を採用', 'ダブルでお願い', '2 枚同時召喚', 'ふたつで比較祭り'],
    3: ['3 連ガチャ', '三枚おろし', '3 枚まとめて', 'トリプルでいこう', '3 枚パック'],
    4: ['4 枚一気に', 'クアッド召喚', '4 枚で全画面', '四連続生成'],
    5: ['5 連続でいこう', '5 枚パック', '半ダースあと一歩', '5 枚ください'],
    6: ['6 枚まとめて', 'ギャラリー +6', 'ハーフダース', '6 連続'],
    7: ['ラッキー 7', '1 週間分の壁紙', '7 枚フルコンボ', '7 連続生成'],
    8: ['8 枚で限界突破', '容量注意：+8', '8 連発', 'オクトで一気に'],
    9: ['3×3 グリッド完成', 'あと 1 枚で 10', '9 枚まとめて', '9 連続、ほぼ満タン'],
  };

  static const List<List<String>> _jaBig = [
    ['{count} 枚、本気モード', 'GPU が汗をかく', '{count} 枚連続生成', '二桁突入', '量産準備 OK'],
    ['量産工場フル稼働', 'Anlas 消費注意報', '{count} 枚、工場モード', 'バッチ処理ゴー'],
    ['{count} 枚、卸売りです', '産業革命レベル', 'もはや遊びではない', '{count} 枚、容赦なし'],
    ['{count} 枚?! 画廊でも開く？', 'ストレージさんこんにちは', '{count} 枚、図鑑になる', 'さすがに {count} 枚？'],
  ];

  static const Map<int, List<String>> _jaSpecial = {
    42: ['{count}：すべての答え'],
    69: ['{count} 枚、いい数字'],
    99: ['{count} 枚、あと 1 枚で三桁'],
    100: ['ちょうど {count} 枚、潔い'],
  };

  static const List<String> _jaRare = [
    'SSR 確定演出',
    'AI の調子が良いらしい',
    'ガチャの神に祈れ',
    '今日の運勢：大吉',
  ];

  static const Map<String, Map<int, List<String>>> _smallPools = {
    'zh': _zhSmall,
    'en': _enSmall,
    'ja': _jaSmall,
  };

  static const Map<String, List<List<String>>> _bigPools = {
    'zh': _zhBig,
    'en': _enBig,
    'ja': _jaBig,
  };

  static const Map<String, Map<int, List<String>>> _specialPool = {
    'zh': _zhSpecial,
    'en': _enSpecial,
    'ja': _jaSpecial,
  };

  static const Map<String, List<String>> _rarePool = {
    'zh': _zhRare,
    'en': _enRare,
    'ja': _jaRare,
  };
}
