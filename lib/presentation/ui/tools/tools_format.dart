import '../../../l10n/app_localizations.dart';
import 'tools_contract.dart';

/// 画布工具的文字格式。
abstract final class ToolsFormat {
  /// `832 × 1216`。
  static String size(int w, int h) => '$w × $h';

  /// 面板里的紧凑写法 `832×1216`。
  static String tight(int w, int h) => '$w×$h';

  /// 千分位：`29,053`。
  static String number(int v) {
    final s = v.abs().toString();
    final b = StringBuffer(v < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// 倍数：`2.00 ×` 用在数字框，`1.5×` 用在分段。
  static String factor(double f) =>
      f == f.roundToDouble() ? '${f.toInt()}×' : '${_trim(f)}×';

  static String _trim(double v) {
    var s = v.toStringAsFixed(2);
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// 有符号整数（`+8`、`−3`、`0`），用真减号。
  static String signed(int v) => v > 0
      ? '+$v'
      : v < 0
      ? '−${-v}'
      : '0';

  /// 相对时间：刚刚 / N 分钟前 / N 小时前 / M 月 D 日。
  static String ago(AppLocalizations l, DateTime t, DateTime now) {
    final d = now.difference(t);
    if (d.inSeconds < 60) return l.tools_justNow;
    if (d.inMinutes < 60) return l.tools_minutesAgo(d.inMinutes);
    if (d.inHours < 24) return l.tools_hoursAgo(d.inHours);
    return l.tools_monthDay(t.month, t.day);
  }

  static String toolName(AppLocalizations l, ToolsDirectorTool t) =>
      switch (t) {
        ToolsDirectorTool.removeBackground => l.tools_dtRemoveBg,
        ToolsDirectorTool.declutter => l.tools_dtDeclutter,
        ToolsDirectorTool.lineArt => l.tools_dtLineArt,
        ToolsDirectorTool.sketch => l.tools_dtSketch,
        ToolsDirectorTool.colorize => l.tools_dtColorize,
        ToolsDirectorTool.emotion => l.tools_dtEmotion,
        ToolsDirectorTool.pixelSnap => l.tools_dtPixelSnap,
      };

  static String toolDesc(AppLocalizations l, ToolsDirectorTool t) =>
      switch (t) {
        ToolsDirectorTool.removeBackground => l.tools_dtRemoveBgDesc,
        ToolsDirectorTool.declutter => l.tools_dtDeclutterDesc,
        ToolsDirectorTool.lineArt => l.tools_dtLineArtDesc,
        ToolsDirectorTool.sketch => l.tools_dtSketchDesc,
        ToolsDirectorTool.colorize => l.tools_dtColorizeDesc,
        ToolsDirectorTool.emotion => l.tools_dtEmotionDesc,
        ToolsDirectorTool.pixelSnap => l.tools_dtPixelSnapDesc,
      };

  static String toolIcon(ToolsDirectorTool t) => switch (t) {
    ToolsDirectorTool.removeBackground => 'director_remove_bg.svg',
    ToolsDirectorTool.declutter => 'director_declutter.svg',
    ToolsDirectorTool.lineArt => 'director_line_art.svg',
    ToolsDirectorTool.sketch => 'director_sketch.svg',
    ToolsDirectorTool.colorize => 'director_colorize.svg',
    ToolsDirectorTool.emotion => 'director_emotion.svg',
    ToolsDirectorTool.pixelSnap => 'director_pixel_snap.svg',
  };

  static String emotion(AppLocalizations l, String mood) => switch (mood) {
    'neutral' => l.tools_emoNeutral,
    'happy' => l.tools_emoHappy,
    'sad' => l.tools_emoSad,
    'angry' => l.tools_emoAngry,
    'scared' => l.tools_emoScared,
    'surprised' => l.tools_emoSurprised,
    'tired' => l.tools_emoTired,
    'excited' => l.tools_emoExcited,
    'nervous' => l.tools_emoNervous,
    'thinking' => l.tools_emoThinking,
    'confused' => l.tools_emoConfused,
    'shy' => l.tools_emoShy,
    'disgusted' => l.tools_emoDisgusted,
    'smug' => l.tools_emoSmug,
    'bored' => l.tools_emoBored,
    'laughing' => l.tools_emoLaughing,
    'irritated' => l.tools_emoIrritated,
    'aroused' => l.tools_emoAroused,
    'embarrassed' => l.tools_emoEmbarrassed,
    'worried' => l.tools_emoWorried,
    'love' => l.tools_emoLove,
    'determined' => l.tools_emoDetermined,
    'hurt' => l.tools_emoHurt,
    'playful' => l.tools_emoPlayful,
    _ => mood,
  };

  /// 强度档 0–5 的名字（正常 / 稍弱 / 弱 / 更弱 / 很弱 / 最弱）。
  static String defry(AppLocalizations l, int v) => switch (v) {
    0 => l.tools_defry0,
    1 => l.tools_defry1,
    2 => l.tools_defry2,
    3 => l.tools_defry3,
    4 => l.tools_defry4,
    _ => l.tools_defry5,
  };

  static String toolLabel(
    AppLocalizations l,
    ToolsTool t, {
    required bool inpaint,
  }) => switch (t) {
    ToolsTool.brush => inpaint ? l.tools_toolMaskBrush : l.tools_toolBrush,
    ToolsTool.eraser => inpaint ? l.tools_toolMaskEraser : l.tools_toolEraser,
    ToolsTool.fill => l.tools_toolFill,
    ToolsTool.blur => l.tools_toolBlur,
    ToolsTool.stamp => l.tools_toolStamp,
    ToolsTool.select => l.tools_toolSelect,
    ToolsTool.lasso => l.tools_toolLasso,
    ToolsTool.picker => l.tools_toolPicker,
    ToolsTool.focus => l.tools_toolFocus,
  };

  static String pattern(AppLocalizations l, ToolsMaskPattern p) => switch (p) {
    ToolsMaskPattern.solid => l.tools_patternSolid,
    ToolsMaskPattern.lines => l.tools_patternLines,
    ToolsMaskPattern.crosshatch => l.tools_patternCrosshatch,
    ToolsMaskPattern.grid => l.tools_patternGrid,
    ToolsMaskPattern.dots => l.tools_patternDots,
    ToolsMaskPattern.checker => l.tools_patternChecker,
    ToolsMaskPattern.hearts => l.tools_patternHearts,
  };
}
