import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/justified_layout.dart';

void main() {
  // 通用参数：1000px 可用宽、目标边长 200（h0 钳带 [100, 700]）、间距 12
  const width = 1000.0;
  const target = 200.0;
  const spacing = 12.0;

  List<JustifiedRow> layout(
    List<double> aspects, {
    double w = width,
    double t = target,
  }) {
    return computeJustifiedRows(
      aspectRatios: aspects,
      availableWidth: w,
      targetHeight: t,
      spacing: spacing,
    );
  }

  double sumAspect(List<double> aspects, JustifiedRow row) {
    var sum = 0.0;
    for (var k = row.startIndex; k <= row.endIndex; k++) {
      sum += aspects[k];
    }
    return sum;
  }

  /// 图片可用宽 Wa = W − spacing×(k−1)
  double imageW(JustifiedRow row, {double w = width}) {
    return w - spacing * (row.endIndex - row.startIndex);
  }

  /// r = 图片可用宽 / 锚定行内容宽（h0·Σa）
  double ratioOf(
    List<double> aspects,
    JustifiedRow row,
    double t, {
    double w = width,
  }) {
    final sumA = sumAspect(aspects, row);
    final count = row.endIndex - row.startIndex + 1;
    final h0 = (t / math.sqrt(sumA / count)).clamp(
      t * justifiedMinHeightFactor,
      t * justifiedMaxHeightFactor,
    );
    return imageW(row, w: w) / (h0 * sumA);
  }

  /// 行高锚 h0 = t/√mean_a（钳带内）
  double h0Of(List<double> aspects, JustifiedRow row, double t) {
    final sumA = sumAspect(aspects, row);
    final count = row.endIndex - row.startIndex + 1;
    return (t / math.sqrt(sumA / count)).clamp(
      t * justifiedMinHeightFactor,
      t * justifiedMaxHeightFactor,
    );
  }

  /// 行渲染内容宽（height×Σa + spacing×(k−1)）
  double rowContentWidth(List<double> aspects, JustifiedRow row) {
    return row.height * sumAspect(aspects, row) +
        spacing * (row.endIndex - row.startIndex);
  }

  group('行高锚定（V2 验收性质回归：行高与窗宽解耦）', () {
    test('同一序列不同 W：纯竖图行行高偏差 <5%，且 ≈ t/√0.7', () {
      final aspects = List<double>.filled(6, 0.7);
      // w=1150 下 3 张/行 r·h0=2.06t > 2t 高度门控拦截落欠填 h0；
      // w=1400 下 6 张/行 justify 微调到 319；实测偏差 ≈2.7%
      final rowsNarrow = layout(aspects, w: 1150, t: 260);
      final rowsWide = layout(aspects, w: 1400, t: 260);
      final hNarrow = rowsNarrow.firstWhere((r) => r.endIndex <= 5).height;
      final hWide = rowsWide.firstWhere((r) => r.endIndex <= 5).height;
      final expected = 260 / math.sqrt(0.7); // ≈310.7
      final drift = (hWide - hNarrow).abs() / hNarrow;
      // ignore: avoid_print
      print(
        'justified anchor: w=1150 h=$hNarrow, w=1400 h=$hWide, '
        'drift=${(drift * 100).toStringAsFixed(2)}%',
      );
      expect(drift, lessThan(0.05));
      expect(hNarrow, closeTo(expected, expected * 0.05));
      expect(hWide, closeTo(expected, expected * 0.05));
    });

    test('双横图宽窗行不再顶成巨块：行高 = 面积锚 ≈0.745t', () {
      // V3a 病灶：exact h=W/Σa → 469px(≈1.8t)；重锚定后欠填 @h0
      final rows = layout([1.8, 1.8], w: 1700, t: 260);
      expect(rows, hasLength(1));
      expect(rows.single.fill, JustifiedFill.underfilled);
      expect(rows.single.height, closeTo(260 / math.sqrt(1.8), 0.5));
    });
  });

  group('分派边界数值', () {
    test('r=0.939 → justify（0.92 带上侧）/ r=0.909 → crop（带下侧）', () {
      final justify = layout([3.0, 3.0, 3.0]);
      expect(justify.single.fill, JustifiedFill.exact);
      expect(
        ratioOf([3.0, 3.0, 3.0], justify.single, target),
        inInclusiveRange(0.92, 1.08),
      );

      final crop = layout([3.2, 3.2, 3.2]);
      expect(crop.single.fill, JustifiedFill.crop);
      expect(
        ratioOf([3.2, 3.2, 3.2], crop.single, target),
        inInclusiveRange(0.88, 0.92),
      );
    });

    test('r=1.029 → justify（1.08 带下侧）/ r=1.097 → upscale（带上侧）', () {
      final justify = layout([2.5, 2.5, 2.5]);
      expect(justify.single.fill, JustifiedFill.exact);
      expect(
        ratioOf([2.5, 2.5, 2.5], justify.single, target),
        inInclusiveRange(0.92, 1.08),
      );

      // r>1 侧原 crop 层退役：1.097 进放大带而非裁剪
      final upscale = layout([2.2, 2.2, 2.2]);
      expect(upscale.single.fill, JustifiedFill.upscale);
      expect(
        ratioOf([2.2, 2.2, 2.2], upscale.single, target),
        inInclusiveRange(1.08, justifiedUpscaleCap),
      );
    });

    test('upscale 分派：r=1.229 → upscale / r=1.452 → 高度门控拦截欠填', () {
      final upscale = layout(List<double>.filled(5, 0.6));
      expect(upscale.single.fill, JustifiedFill.upscale);
      expect(
        ratioOf(List<double>.filled(5, 0.6), upscale.single, target),
        inInclusiveRange(1.08, justifiedUpscaleCap),
      );

      // 5 张 0.43 竖图：r=1.452 虽然 ≤ 2.0，但 r·h0 = 2.214t > 2.0t
      // → 被高度门控拦截（拦截原因从 cap 变高度门控），断言不变，维持欠填左对齐
      final underfilled = layout(List<double>.filled(5, 0.43));
      expect(underfilled.single.fill, JustifiedFill.underfilled);
      expect(
        ratioOf(List<double>.filled(5, 0.43), underfilled.single, target),
        greaterThan(justifiedUpscaleCap),
      );
    });

    test('多图横排纸条行结构性不可能（r<0.88 多图不可行）', () {
      // 8 张 1.8 横图宽窗：整行 r 远低于 0.88 → 强制细分为 4 张/行；
      // 细分后 r=1.19 进放大带，行高钉 h0×1.19≈231（放大层正常工作），
      // 有上界无巨块（≤ h0×cap），无纸条
      final aspects = List<double>.filled(8, 1.8);
      final rows = layout(aspects, w: 1700, t: 260);
      final h0 = 260 / math.sqrt(1.8); // ≈193.8
      expect(rows.length, greaterThan(1));
      for (final row in rows) {
        expect(row.height, greaterThanOrEqualTo(h0 * (1 - justifiedCropCap)));
        expect(row.height, lessThanOrEqualTo(h0 * justifiedUpscaleCap + 0.5));
        expect(row.height, lessThanOrEqualTo(260 * 3.5));
      }
    });
  });

  group('justify 行零裁剪精确填满', () {
    test('height = Wa/Σa 且 height×Σa == 图片可用宽', () {
      final rows = layout([2.5, 2.5, 2.5]);
      final row = rows.single;
      expect(row.fill, JustifiedFill.exact);
      expect(row.height, closeTo(imageW(row) / 7.5, 0.01));
      expect(row.height * 7.5, closeTo(imageW(row), 0.01));
    });
  });

  group('upscale 放大层', () {
    test('放大行高 = r·h0，自然宽精确填满零裁剪', () {
      // 5 张 0.6 竖图：r=1.229 ≤ cap → 整行等比放大填满
      final aspects = List<double>.filled(5, 0.6);
      final rows = layout(aspects);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.fill, JustifiedFill.upscale);
      final r = ratioOf(aspects, row, target);
      expect(row.height, closeTo(r * h0Of(aspects, row, target), 0.01));
      // r·h0 ≡ Wa/Σa：自然宽之和恰为图片可用宽（零裁剪，无需 cover）
      expect(row.height * sumAspect(aspects, row), closeTo(imageW(row), 0.01));
    });

    test('高带钳制：r·h0 > 3.5t 时放大率被钳，带顶欠填左对齐', () {
      // 11 张 1/9 竖图：h0=600，r=1.2 ≤ cap 但 r·h0=720 > 700=3.5t
      // → 放大率钳到 3.5t/h0≈1.1667，钳后保持带顶高度左对齐（不裁）
      final aspects = List<double>.filled(11, 1 / 9);
      final rows = layout(aspects);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.fill, JustifiedFill.underfilled);
      expect(row.height, closeTo(target * justifiedMaxHeightFactor, 0.01));
      // 钳后宽度 = 3.5t×Σa（> h0×Σa，比不放大更满），仍 ≤ W×1.08 守卫内
      final contentW = rowContentWidth(aspects, row);
      expect(
        contentW,
        greaterThan(h0Of(aspects, row, target) * sumAspect(aspects, row)),
      );
      expect(
        contentW,
        lessThanOrEqualTo(width * (1 + justifiedJustifyTolerance) + 1),
      );
    });

    test('DP 仲裁场景 1：小空洞（r≤1.15 级）放大本行优于欠填留空', () {
      // r=1.138：upscale 罚 (0.138)²×0.9≈0.0171 < 欠填 gap²×1.5+0.05≈0.066
      final rows = layout(List<double>.filled(5, 0.7));
      expect(rows.single.fill, JustifiedFill.upscale);
    });

    test('DP 仲裁场景 2：多拉一张细分 + 小放大 优于 少图硬放大', () {
      // 静圈案例结构：12 张 0.75 竖图 @t=163——5 张/行 r≈1.35（放大罚
      // (0.35)²×0.9≈0.11/行），DP 应重排成 6 张/行（r≈1.11，
      // 罚 ≈0.011/行）——超线性放大罚使细分方案十倍胜出
      final aspects = List<double>.filled(12, 0.75);
      final rows = layout(aspects, t: 163);
      expect(rows, hasLength(2));
      for (final row in rows) {
        expect(row.endIndex - row.startIndex + 1, 6, reason: '应重排成 6 张/行');
        expect(row.fill, isNot(JustifiedFill.underfilled));
        expect(ratioOf(aspects, row, 163), inInclusiveRange(1.0, 1.15));
      }
    });

    test('DP 仲裁场景 3：真稀疏区 cap 内硬放大、超门控才欠填', () {
      // 页尾无可拉之图：r=1.229 ≤ cap → 硬放大填满（非欠填）
      expect(
        layout(List<double>.filled(5, 0.6)).single.fill,
        JustifiedFill.upscale,
      );
      // 5 张 0.43：r=1.452 拦截原因从 cap 变高度门控（r·h0=2.21t > 2.0t）→ 退回欠填
      expect(
        layout(List<double>.filled(5, 0.43)).single.fill,
        JustifiedFill.underfilled,
      );
    });
  });

  group('crop 行钉 h0 微裁（仅 r<1 过满侧）', () {
    test('行高 = 面积锚 h0，裁量 1−r ≤ cap', () {
      final aspects = [3.2, 3.2, 3.2]; // r=0.909（低侧）
      final rows = layout(aspects);
      final row = rows.single;
      expect(row.fill, JustifiedFill.crop);
      expect(row.height, closeTo(h0Of(aspects, row, target), 0.01));
      expect(
        1 - ratioOf(aspects, row, target),
        lessThanOrEqualTo(justifiedCropCap + 1e-9),
      );
    });
  });

  group('超 cap 欠填左对齐', () {
    test('欠填行 height = h0 不裁，自然宽左对齐留空', () {
      final rows = layout([0.5, 0.5]);
      final row = rows.single;
      expect(row.fill, JustifiedFill.underfilled);
      expect(row.height, closeTo(target / math.sqrt(0.5), 0.01));
      expect(
        rowContentWidth([0.5, 0.5], row),
        lessThan(width * (1 - justifiedJustifyTolerance)),
      );
    });

    test('欠填行面积锚语义保持：行内每图面积 ≈ t²', () {
      final rows = layout([0.5, 0.5]);
      final row = rows.single;
      final area = row.height * row.height * 0.5;
      expect(area, closeTo(target * target, target * target * 0.05));
    });

    test('多图 r=1.427 > 1.4 在双门控内放大填满（r·h0=1.25t ≤ 2t）', () {
      final rows = layout([1.3, 1.3, 1.3]);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.fill, JustifiedFill.upscale);
      final r = ratioOf([1.3, 1.3, 1.3], row, target);
      expect(
        r,
        inInclusiveRange(justifiedUpscaleCap, justifiedUpscaleMaxRatio),
      );
      expect(row.height, closeTo(r * h0Of([1.3, 1.3, 1.3], row, target), 0.01));
      expect(
        row.height,
        lessThanOrEqualTo(target * justifiedUpscaleHeightGateT),
      );
    });
  });

  group('双门控放大与竖裁兜底（方案 B+C）', () {
    test('双门控内放大：2×a=2 @1200/1600 填满、行高 ≤1.41t', () {
      const t = 283.0;
      // @1200: r≈1.484 ∈ (1.4, 2.0], r·h0≈1.05t ≤ 2t → 满宽放大填满
      final rows1200 = layout([2.0, 2.0], w: 1200, t: t);
      expect(rows1200, hasLength(1));
      expect(rows1200.single.fill, JustifiedFill.upscale);
      expect(rows1200.single.height, lessThanOrEqualTo(t * 1.41));
      expect(rows1200.single.isUnderfilled, isFalse);

      // @1600: r≈1.984 ∈ (1.4, 2.0], r·h0≈1.40t ≤ 2t → 满宽放大填满
      final rows1600 = layout([2.0, 2.0], w: 1600, t: t);
      expect(rows1600, hasLength(1));
      expect(rows1600.single.fill, JustifiedFill.upscale);
      expect(rows1600.single.height, lessThanOrEqualTo(t * 1.41));
      expect(rows1600.single.isUnderfilled, isFalse);
    });

    test('高度门控拦截：4×a=0.6 @1600 需放大到 2.31t > 2t，仍欠填', () {
      const t = 283.0;
      final rows = layout([0.6, 0.6, 0.6, 0.6], w: 1600, t: t);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.fill, JustifiedFill.underfilled);
      expect(row.isUnderfilled, isTrue);
      final r = ratioOf([0.6, 0.6, 0.6, 0.6], row, t, w: 1600);
      expect(r, lessThanOrEqualTo(justifiedUpscaleMaxRatio)); // r≈1.78 比率未超
      final h0 = h0Of([0.6, 0.6, 0.6, 0.6], row, t);
      expect(
        r * h0,
        greaterThan(t * justifiedUpscaleHeightGateT),
      ); // 高度超 2.0t 门控
    });

    test('比率门控拦截：2×a=2 @1920 r=2.38 > 2.0 且超 2.27，仍欠填', () {
      const t = 283.0;
      final rows = layout([2.0, 2.0], w: 1920, t: t);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.fill, JustifiedFill.underfilled);
      expect(row.isUnderfilled, isTrue);
      final r = ratioOf([2.0, 2.0], row, t, w: 1920);
      expect(r, greaterThan(justifiedUpscaleMaxRatio));
      expect(r, greaterThan(justifiedUpscaleMaxRatio / (1 - justifiedCropCap)));
    });

    test('竖裁兜底救活：构造 r≈2.1 且裁量 ≤12% 的行 → 满宽 cover、height=2t', () {
      // 4 张方图 a=1.0 @W=1716, t=200: Wa=1680, h0=200, r=2.10 ∈ (2.0, 2.27]
      // 等比高度 r·h0=420=2.1t > 2t，钉 gateH=2t 后 cropFrac=4.76% ≤ 12%
      final aspects = [1.0, 1.0, 1.0, 1.0];
      final rows = layout(aspects, w: 1716, t: 200);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.fill, JustifiedFill.crop);
      expect(row.isUnderfilled, isFalse);
      expect(row.height, closeTo(200.0 * justifiedUpscaleHeightGateT, 0.01));
    });

    test('竖裁超预算退回欠填：r·h0=2.415t 钉 2t 裁量 17.2% > 12% → 维持欠填', () {
      // 4 张 a=0.756 竖图 @t=200: h0≈230=1.15t
      // 构造 r≈2.10: Wa = 2.10 * (230 * 4 * 0.756) ≈ 2.10 * 695.5 = 1460.5
      // W = 1460.5 + 36 = 1496.5
      // r·h0 = 2.10 * 230 = 483 = 2.415t，cropFrac = 1 - 400/483 ≈ 17.2% > 12%
      const a = 1.0 / (1.15 * 1.15); // ≈ 0.75614
      final aspects = [a, a, a, a];
      const w = 1496.5;
      final rows = layout(aspects, w: w, t: 200);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.fill, JustifiedFill.underfilled);
      expect(row.isUnderfilled, isTrue);
    });
  });

  group('单图全景满宽条带（原 contain 收编进 exact）', () {
    test('a=16：height=Wa/a 满宽不裁、走 Expanded 侧（非欠填归并）', () {
      final rows = layout([16.0]);
      expect(rows.single.fill, JustifiedFill.exact);
      expect(rows.single.isUnderfilled, isFalse);
      expect(rows.single.height, closeTo(width / 16, 0.01));
    });

    test('带内全景 height = Wa/a（a=8, t=260 → 125）', () {
      final rows = layout([8.0], t: 260);
      expect(rows.single.fill, JustifiedFill.exact);
      expect(rows.single.height, closeTo(width / 8, 0.01));
    });

    test('单张超高图（a=0.05）：退回欠填，height 钳 h0 带顶', () {
      final rows = layout([0.05]);
      expect(rows.single.fill, JustifiedFill.underfilled);
      expect(rows.single.height, closeTo(target * 3.5, 0.01));
    });
  });

  group('单图行长图满宽分派（留洞修复）', () {
    test('中宽长图（a=2）：h0 < hFull ≤ maxH → 满宽放大零裁剪', () {
      // 修复前病灶：h0 = t/√2 ≈ 141，锚高下行宽 ≈283 仅为窗宽 28%，
      // r ≈ 3.5 远超 upscaleCap → 欠填左对齐留大空洞；
      // 修复后 hFull = Wa/a = 500 ≤ 700=3.5t → 满宽放大、height = Wa/a
      final rows = layout([2.0]);
      final row = rows.single;
      expect(row.fill, JustifiedFill.exact);
      expect(row.isUnderfilled, isFalse, reason: '满宽行必须走 Expanded 顶格侧');
      expect(row.height, closeTo(width / 2.0, 0.01));
      expect(row.height * 2.0, closeTo(width, 0.01), reason: '零裁剪精确填满');
      expect(row.height, greaterThan(h0Of([2.0], row, target)));
    });

    test('hFull 略超 maxH（a=1.3）：满宽 cover 裁上下，height 钉 maxH', () {
      // hFull = 1000/1.3 ≈ 769 > 700=3.5t，裁量 1−700/769 ≈ 9% ≤ cap(12%)
      final rows = layout([1.3]);
      final row = rows.single;
      expect(row.fill, JustifiedFill.crop);
      expect(row.isUnderfilled, isFalse);
      expect(row.height, closeTo(target * justifiedMaxHeightFactor, 0.01));
      final cropRatio = 1 - row.height / (width / 1.3);
      expect(cropRatio, lessThanOrEqualTo(justifiedCropCap + 1e-9));
      expect(cropRatio, greaterThan(0));
    });

    test('回归：超宽全景（a=35）仍是满宽条带，height = Wa/a', () {
      final rows = layout([35.0]);
      final row = rows.single;
      expect(row.fill, JustifiedFill.exact);
      expect(row.isUnderfilled, isFalse);
      expect(row.height, closeTo(width / 35.0, 0.01));
    });

    test('回归：方图单行（a=1）仍欠填——满宽裁量超预算', () {
      // hFull = 1000 > 700=3.5t 且 700/1000 = 0.7 < 1−cap → 不裁，欠填 h0
      final rows = layout([1.0]);
      final row = rows.single;
      expect(row.fill, JustifiedFill.underfilled);
      expect(row.height, closeTo(target, 0.01));
    });

    test('回归：竖图单行（a=0.7）仍欠填', () {
      final rows = layout([0.7]);
      expect(rows.single.fill, JustifiedFill.underfilled);
      expect(rows.single.height, closeTo(target / math.sqrt(0.7), 0.01));
    });
  });

  group('面积均衡语义保持', () {
    test('方差罚生效：强对比序列断行不混行', () {
      final aspects = [
        ...List<double>.filled(6, 0.7),
        ...List<double>.filled(6, 1.8),
      ];
      final rows = layout(aspects);
      expect(rows, isNotEmpty);
      for (final row in rows) {
        final first = aspects[row.startIndex];
        for (var k = row.startIndex + 1; k <= row.endIndex; k++) {
          expect(
            aspects[k],
            first,
            reason: '行 ${row.startIndex}-${row.endIndex} 混入了不同宽高比',
          );
        }
      }
    });
  });

  group('实景复现（静复验案例，W=1580 合成）', () {
    /// 行填充率 = 渲染内容宽 / W
    double fillPct(List<double> aspects, JustifiedRow row, double w) {
      return rowContentWidth(aspects, row) / w;
    }

    test('案例A：横+竖+方图重排为 5 张混合 upscale 行填满（非稀疏欠填）', () {
      // [横 1.7 + 竖 0.75 + 方 1.0×3] @t=226：改前该行 r=1.299 超旧 cap
      // （1.25）欠填留空 22%；cap 放宽 1.4 后整行放大填满
      final aspects = [1.7, 0.75, 1.0, 1.0, 1.0];
      final rows = layout(aspects, w: 1580, t: 226);
      expect(rows, hasLength(1), reason: '应重排成单个 5 张混合行');
      final row = rows.single;
      expect(row.fill, JustifiedFill.upscale);
      // 横竖混行（含 1.7 与 0.75）且落差 0.82 在硬上限 1.2 内
      expect(row.startIndex, 0);
      expect(row.endIndex, 4);
      expect(fillPct(aspects, row, 1580), closeTo(1.0, 0.01));
    });

    test('案例B：[0.85, 1.0, 1.3, 1.45] r≈1.38 → upscale 填满非欠填', () {
      // 改前 r=1.384 超旧 cap（1.25）欠填留空 27%；cap 放宽后放大填满
      final aspects = [0.85, 1.0, 1.3, 1.45];
      final rows = layout(aspects, w: 1580, t: 260);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.fill, JustifiedFill.upscale);
      expect(
        ratioOf(aspects, row, 260, w: 1580),
        inInclusiveRange(1.25, justifiedUpscaleCap),
      );
      expect(fillPct(aspects, row, 1580), closeTo(1.0, 0.01));
    });

    test('案例C：3 横 + 4 竖重排为单个 7 张混合 upscale 行填满', () {
      // [1.55×3 + 0.75×4] @W=1580/t=179：混合行 mean_a≈1.09、
      // spread ln(1.55/0.75)≈0.73 在硬上限 1.2 内；改前探针即已自然选中
      // （upscale r≈1.15），此处固化为断言。对照组：3 横自行 r≈2.3 超 cap
      // 只能欠填留空 ~44%（t=283 下为 spec 所述 ~32% 形态）
      final aspects = [1.55, 1.55, 1.55, 0.75, 0.75, 0.75, 0.75];
      final rows = layout(aspects, w: 1580, t: 179);
      expect(rows, hasLength(1), reason: '应重排成单个 7 张混合行');
      final row = rows.single;
      expect(row.fill, JustifiedFill.upscale);
      expect(row.startIndex, 0);
      expect(row.endIndex, 6);
      expect(
        ratioOf(aspects, row, 179, w: 1580),
        inInclusiveRange(1.08, justifiedUpscaleCap),
      );
      expect(fillPct(aspects, row, 1580), closeTo(1.0, 0.01));
    });

    test('反例：0.5 与 2.0 相邻混流不混行（落差 1.39 > 硬上限 1.2）', () {
      final aspects = [0.5, 2.0, 0.5, 2.0];
      final rows = layout(aspects, w: 1580);
      for (final row in rows) {
        final first = aspects[row.startIndex];
        for (var k = row.startIndex + 1; k <= row.endIndex; k++) {
          expect(aspects[k], first, reason: '落差超硬上限仍混行');
        }
      }
    });
  });

  group('守恒与无挤压', () {
    List<double> randomAspects(int seed, int count) {
      var s = seed;
      double rnd() {
        s = (s * 1103515245 + 12345) & 0x7fffffff;
        return s / 0x7fffffff;
      }

      return [for (var k = 0; k < count; k++) 0.4 + rnd() * 2.2];
    }

    test('多组固定种子随机序列：图数守恒 + 索引连续 + 行宽不越界', () {
      for (final seed in [1, 42, 777, 20240908]) {
        for (final count in [1, 2, 3, 5, 17, 50]) {
          final aspects = randomAspects(seed, count);
          final rows = layout(aspects);
          final total = rows.fold<int>(
            0,
            (sum, r) => sum + r.endIndex - r.startIndex + 1,
          );
          expect(total, aspects.length, reason: 'seed=$seed count=$count');
          if (rows.isEmpty) continue;
          expect(rows.first.startIndex, 0);
          expect(rows.last.endIndex, aspects.length - 1);
          for (var k = 1; k < rows.length; k++) {
            expect(rows[k].startIndex, rows[k - 1].endIndex + 1);
          }
          for (final row in rows) {
            final sumA = sumAspect(aspects, row);
            switch (row.fill) {
              case JustifiedFill.exact:
                // justify 零裁剪：行高×Σa == 图片可用宽
                expect(row.height * sumA, closeTo(imageW(row), 0.01));
              case JustifiedFill.upscale:
                // upscale 零裁剪：行高×Σa == 图片可用宽（r·h0 ≡ Wa/Σa），
                // 且放大率在门控比率内
                expect(row.height * sumA, closeTo(imageW(row), 0.01));
                expect(
                  ratioOf(aspects, row, target),
                  inInclusiveRange(1.0, justifiedUpscaleMaxRatio + 1e-9),
                );
              case JustifiedFill.crop:
                // 裁量 1−r ≤ cap（仅 r<1 过满侧），行高 = 面积锚
                expect(
                  1 - ratioOf(aspects, row, target),
                  lessThanOrEqualTo(justifiedCropCap + 1e-9),
                );
              case JustifiedFill.underfilled:
                // 欠填自然内容宽 ≤ W×1.08（左对齐不压扁/无纸条）
                expect(
                  rowContentWidth(aspects, row),
                  lessThanOrEqualTo(
                    width * (1 + justifiedJustifyTolerance) + 1,
                  ),
                );
              case JustifiedFill.contain:
                expect(row.height * sumA, closeTo(imageW(row), 0.01));
            }
          }
        }
      }
    });
  });

  group('极端边界不抛异常', () {
    test('空列表返回空', () {
      expect(layout(const []), isEmpty);
    });

    test('单张图', () {
      final rows = layout([1.0]);
      expect(rows, hasLength(1));
      expect(rows.single.startIndex, 0);
      expect(rows.single.endIndex, 0);
    });

    test('非法宽高比（0 / 负 / NaN）占位 1.0 不抛异常', () {
      final rows = layout([0.0, -1.0, double.nan, 1.0]);
      final total = rows.fold<int>(
        0,
        (sum, r) => sum + r.endIndex - r.startIndex + 1,
      );
      expect(total, 4);
      for (final row in rows) {
        expect(row.height.isFinite, isTrue);
      }
    });

    test('极端全景与极端竖图混合守恒', () {
      final rows = layout([8.0, 0.05, 1.5]);
      expect(
        rows.fold<int>(0, (sum, r) => sum + r.endIndex - r.startIndex + 1),
        3,
      );
      for (final row in rows) {
        expect(row.height.isFinite, isTrue);
        expect(row.height, greaterThan(0));
      }
    });
  });
}
