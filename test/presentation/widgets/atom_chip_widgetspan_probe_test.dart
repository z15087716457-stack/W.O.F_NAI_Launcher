// TEMPORARY probe for the AtomChip-in-WidgetSpan overlap bug. Not for commit.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/atom_list_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/nai_syntax_controller.dart';

/// Logs the PlaceholderDimensions the engine-side paragraph build hands us.
class _LoggingWidgetSpan extends WidgetSpan {
  const _LoggingWidgetSpan({required super.child, this.tag = '?'})
    : super(alignment: PlaceholderAlignment.top);

  final String tag;

  @override
  void build(
    ui.ParagraphBuilder builder, {
    TextScaler textScaler = TextScaler.noScaling,
    List<PlaceholderDimensions>? dimensions,
  }) {
    debugPrint(
      '[$tag] WidgetSpan.build alignment=$alignment '
      'placeholderCount=${builder.placeholderCount} dims=$dimensions',
    );
    super.build(builder, textScaler: textScaler, dimensions: dimensions);
  }
}

const _marker = '\uE000';
// Long enough to wrap into 3+ lines at ~280px wrap width (14pt bodyMedium).
const _longAtom =
    'masterpiece best quality 1girl solo long hair very long hair silver hair '
    'red eyes looking at viewer detailed background night city lights';

const _chipKey = Key('probe-chip');

Widget _editor(NaiSyntaxController c) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: TextField(
                  controller: c,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 14, height: 1.8),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

InlineSpan _buildChip(BuildContext context, String marker, int occurrence) {
  final theme = Theme.of(context);
  return WidgetSpan(
    alignment: PlaceholderAlignment.top,
    child: AtomChip(key: _chipKey, text: _longAtom, theme: theme),
  );
}

RenderEditable _renderEditableOf(WidgetTester tester) {
  RenderObject? ro = tester.renderObject(find.byKey(_chipKey));
  while (ro != null && ro is! RenderEditable) {
    ro = ro.parent;
  }
  return ro! as RenderEditable;
}

RenderEditable? _maybeRenderEditableOf(WidgetTester tester) {
  RenderObject? ro = tester.renderObject(find.byKey(_chipKey));
  while (ro != null && ro is! RenderEditable) {
    ro = ro.parent;
  }
  return ro as RenderEditable?;
}

void _dump(String tag, WidgetTester tester) {
  final chipSize = tester.getSize(find.byKey(_chipKey));
  final chipTop = tester.getTopLeft(find.byKey(_chipKey));
  debugPrint('[$tag] chip size=$chipSize topLeft=$chipTop');

  final texts = find
      .descendant(of: find.byKey(_chipKey), matching: find.byType(Text))
      .evaluate()
      .toList();
  debugPrint('[$tag] inner Text widgets: ${texts.length}');
  double? prevBottom;
  for (final e in texts) {
    final top = tester.getTopLeft(find.byWidget(e.widget));
    final size = tester.getSize(find.byWidget(e.widget));
    final t = e.widget as Text;
    final overlap = prevBottom != null && top.dy < prevBottom
        ? '  <<< OVERLAP'
        : '';
    debugPrint(
      '[$tag]   Text "${(t.data ?? '').substring(0, (t.data ?? '').length.clamp(0, 24))}..."'
      ' top=${top.dy.toStringAsFixed(2)} h=${size.height.toStringAsFixed(2)}'
      ' w=${size.width.toStringAsFixed(2)}$overlap',
    );
    prevBottom = top.dy + size.height;
  }

  final re = _maybeRenderEditableOf(tester);
  if (re == null) {
    debugPrint('[$tag] no RenderEditable ancestor (non-inline layout)');
  } else {
    debugPrint(
      '[$tag] RenderEditable size=${re.size} constraints=${re.constraints}',
    );
  }
}

void main() {
  setUp(() {
    debugCheckIntrinsicSizes = true;
  });
  tearDown(() {
    debugCheckIntrinsicSizes = false;
  });

  testWidgets('probe: dims reaching WidgetSpan.build', (tester) async {
    final c = NaiSyntaxController(text: _marker);
    c.pillBuilder = (context, marker, occ) => _LoggingWidgetSpan(
      tag: 'dims',
      child: Container(
        key: _chipKey,
        width: 60,
        height: 120,
        decoration: BoxDecoration(border: Border.all()),
      ),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(_editor(c));
    final re = _renderEditableOf(tester);
    debugPrint('[dims] RenderEditable size=${re.size}');
    for (final b in re.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    )) {
      debugPrint('[dims] slot box: $b');
    }
  });

  testWidgets('probe: multi-line AtomChip in WidgetSpan', (tester) async {
    final c = NaiSyntaxController(text: _marker);
    c.pillBuilder = _buildChip;
    addTearDown(c.dispose);

    await tester.pumpWidget(_editor(c));
    _dump('span', tester);

    final re = _renderEditableOf(tester);
    // Boxes covering the marker char = the placeholder slot.
    final boxes = re.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
    for (final b in boxes) {
      debugPrint('[span] selection box: $b');
    }

    // Local (painter-space) placeholder boxes vs chip size.
    final painterBoxes = re.getLocalRectForCaret(const TextPosition(offset: 0));
    debugPrint('[span] caret rect at 0: $painterBoxes');

    debugPrint(
      '[span] preferredLineHeight=${re.preferredLineHeight} '
      'maxScrollExtent=${re.maxScrollExtent}',
    );
    // Second frame: does the placeholder box stay wrong?
    await tester.pump();
    final boxes2 = re.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
    for (final b in boxes2) {
      debugPrint('[span] frame2 selection box: $b');
    }
    final chipSize2 = tester.getSize(find.byKey(_chipKey));
    debugPrint('[span] frame2 chip size=$chipSize2');

    // The chip's render object size (what layoutChild would have reported).
    final chipRO = tester.renderObject<RenderBox>(find.byKey(_chipKey));
    debugPrint(
      '[span] chip render size=${chipRO.size} needsLayout=${chipRO.debugNeedsLayout}',
    );

    // Walk the RenderEditable inline-children chain.
    debugPrint('[span] --- inline children ---');
    var n = 0;
    for (RenderBox? c = re.firstChild; c != null; c = re.childAfter(c)) {
      n++;
      final pd = c.parentData;
      debugPrint(
        '[span] child$n: ${c.runtimeType} size=${c.size} '
        'needsLayout=${c.debugNeedsLayout} '
        'offset=${pd is TextParentData ? pd.offset : '?'} '
        'span=${pd is TextParentData ? pd.span.runtimeType : '?'} '
        'alignment=${pd is TextParentData ? (pd.span as WidgetSpan).alignment : '?'}',
      );
      // getDryLayout on LayoutBuilder throws in debug — skip it deliberately:
      // the dry path is what RenderEditable uses for intrinsic/dry layout and
      // is exactly where a LayoutBuilder subtree can't be measured.
      try {
        final s1 = c.getDryLayout(const BoxConstraints(maxWidth: 300));
        debugPrint('[span] child$n getDryLayout(w=300)=$s1');
      } catch (e) {
        debugPrint('[span] child$n getDryLayout threw: ${e.runtimeType}');
      }
    }
    debugPrint('[span] inline child count=$n');
  });

  Future<void> spanCase(
    WidgetTester tester,
    String tag,
    Widget Function(BuildContext) child,
  ) async {
    final c = NaiSyntaxController(text: '$_marker tail text here');
    c.pillBuilder = (context, marker, occ) => WidgetSpan(
      alignment: PlaceholderAlignment.top,
      child: Builder(builder: child),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(_editor(c));
    final re = _renderEditableOf(tester);
    debugPrint('[$tag] RenderEditable size=${re.size}');
    for (final b in re.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    )) {
      debugPrint('[$tag] slot box: $b');
    }
    for (final b in re.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 8),
    )) {
      debugPrint('[$tag] marker+tail box: $b');
    }
    // Replay what performLayout does and inspect the produced dims.
    final dims = <PlaceholderDimensions>[
      for (
        RenderBox? child = re.firstChild;
        child != null;
        child = re.childAfter(child)
      )
        PlaceholderDimensions(
          size: ChildLayoutHelper.layoutChild(
            child,
            BoxConstraints(maxWidth: re.constraints.maxWidth),
          ),
          alignment: (child.parentData! as TextParentData).span!.alignment,
        ),
    ];
    debugPrint('[$tag] replayed layoutInlineChildren dims=$dims');

    // Dump the actual span tree RenderEditable lays out + painter config.
    void dumpSpan(InlineSpan? s, String indent) {
      if (s == null) return;
      final style = s.style;
      debugPrint(
        '[$tag] $indent${s.runtimeType} text="${(s is TextSpan) ? s.text : ''}" '
        'fontSize=${style?.fontSize} height=${style?.height} '
        'fontFamily=${style?.fontFamily} scaler-in-span? '
        'children=${s is TextSpan ? s.children?.length : 0}',
      );
      if (s is TextSpan) {
        for (final c in s.children ?? const <InlineSpan>[]) {
          dumpSpan(c, '$indent  ');
        }
      }
    }

    dumpSpan(re.text, ' ');
    debugPrint(
      '[$tag] painter cfg: scaler=${re.textScaler} maxLines=${re.maxLines} '
      'strut=${re.strutStyle} heightBehavior=${re.textHeightBehavior} '
      'forceLine=${re.forceLine} expands=${re.expands} '
      'minLines=${re.minLines}',
    );

    // Feed the SAME span tree + dims into a fresh TextPainter.
    final tp2 = TextPainter(
      text: re.text,
      textDirection: re.textDirection,
      textScaler: re.textScaler,
      maxLines: re.maxLines,
      strutStyle: re.strutStyle,
      textHeightBehavior: re.textHeightBehavior,
    )..setPlaceholderDimensions(dims);
    tp2.layout(maxWidth: re.constraints.maxWidth);
    debugPrint(
      '[$tag] fresh TextPainter same tree: size=${tp2.size} '
      'phBoxes=${tp2.inlinePlaceholderBoxes}',
    );
    tp2.dispose();

    var n = 0;
    for (RenderBox? c0 = re.firstChild; c0 != null; c0 = re.childAfter(c0)) {
      n++;
      final pd = c0.parentData;
      final off = pd is TextParentData ? pd.offset : null;
      debugPrint(
        '[$tag] child$n: ${c0.runtimeType} size=${c0.size} offset=$off '
        'span=${pd is TextParentData ? pd.span?.runtimeType : '?'} '
        'align=${(pd is TextParentData && pd.span is WidgetSpan) ? (pd.span as WidgetSpan).alignment : '?'}',
      );
    }
  }

  testWidgets('probe: SizedBox child (no LayoutBuilder)', (tester) async {
    await spanCase(
      tester,
      'sizedbox',
      (context) => Container(
        key: _chipKey,
        width: 60,
        height: 120,
        decoration: BoxDecoration(border: Border.all()),
      ),
    );
  });

  testWidgets('probe: LayoutBuilder + fixed box', (tester) async {
    await spanCase(
      tester,
      'lb-fixed',
      (context) => LayoutBuilder(
        builder: (context, constraints) {
          debugPrint(
            '[lb-fixed] LayoutBuilder saw maxW=${constraints.maxWidth} '
            'maxH=${constraints.maxHeight}',
          );
          return Container(
            key: _chipKey,
            width: 60,
            height: 120,
            decoration: BoxDecoration(border: Border.all()),
          );
        },
      ),
    );
  });

  testWidgets('probe: LayoutBuilder + Column of boxes', (tester) async {
    await spanCase(
      tester,
      'lb-column',
      (context) => LayoutBuilder(
        builder: (context, constraints) {
          debugPrint(
            '[lb-column] LayoutBuilder saw maxW=${constraints.maxWidth} '
            'maxH=${constraints.maxHeight}',
          );
          return Column(
            key: _chipKey,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 100.0 + i * 40,
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(border: Border.all()),
                ),
            ],
          );
        },
      ),
    );
  });

  testWidgets('probe: line after the placeholder lands where?', (tester) async {
    final c = NaiSyntaxController(text: '$_marker\nSECOND');
    c.pillBuilder = (context, marker, occ) => WidgetSpan(
      alignment: PlaceholderAlignment.top,
      child: Container(
        key: _chipKey,
        width: 60,
        height: 120,
        decoration: BoxDecoration(border: Border.all()),
      ),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(_editor(c));
    final re = _renderEditableOf(tester);
    debugPrint('[2line] RenderEditable size=${re.size}');
    for (final b in re.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    )) {
      debugPrint('[2line] marker box: $b');
    }
    for (final b in re.getBoxesForSelection(
      const TextSelection(baseOffset: 2, extentOffset: 8),
    )) {
      debugPrint('[2line] SECOND box: $b');
    }
    debugPrint(
      '[2line] chip top=${tester.getTopLeft(find.byKey(_chipKey))} '
      'size=${tester.getSize(find.byKey(_chipKey))}',
    );
  });

  testWidgets('probe: Text.rich WidgetSpan (RenderParagraph path)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 300,
              child: Text.rich(
                key: const Key('probe-rich'),
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: Builder(
                        builder: (context) => AtomChip(
                          key: _chipKey,
                          text: _longAtom,
                          theme: Theme.of(context),
                        ),
                      ),
                    ),
                    const TextSpan(text: '\nSECOND LINE'),
                  ],
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.8,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final rp = tester.renderObject<RenderParagraph>(
      find.byKey(const Key('probe-rich')),
    );
    debugPrint('[rich] RenderParagraph size=${rp.size}');
    for (final b in rp.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    )) {
      debugPrint('[rich] marker box: $b');
    }
    for (final b in rp.getBoxesForSelection(
      const TextSelection(baseOffset: 2, extentOffset: 13),
    )) {
      debugPrint('[rich] SECOND box: $b');
    }
    debugPrint(
      '[rich] chip top=${tester.getTopLeft(find.byKey(_chipKey))} '
      'size=${tester.getSize(find.byKey(_chipKey))}',
    );
  });

  testWidgets('probe: raw TextPainter with manual placeholder dims', (
    tester,
  ) async {
    // Reproduce what RenderEditable feeds the engine: a TextSpan tree with a
    // WidgetSpan + PlaceholderDimensions(size 60x120, alignment top).
    final tp =
        TextPainter(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, height: 1.8),
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.top,
                child: SizedBox(width: 60, height: 120),
              ),
              TextSpan(text: ' tail text here\nSECOND LINE'),
            ],
          ),
          textDirection: TextDirection.ltr,
        )..setPlaceholderDimensions([
          const PlaceholderDimensions(
            size: Size(60, 120),
            alignment: PlaceholderAlignment.top,
          ),
        ]);
    tp.layout(maxWidth: 300);
    debugPrint('[tp] size=${tp.size}');
    debugPrint('[tp] inlinePlaceholderBoxes=${tp.inlinePlaceholderBoxes}');
    for (final m in tp.computeLineMetrics()) {
      debugPrint(
        '[tp] line ${m.lineNumber}: baseline=${m.baseline} '
        'h=${m.height} top=${m.baseline - m.ascent}',
      );
    }
    for (final b in tp.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    )) {
      debugPrint('[tp] marker box: $b');
    }
    tp.dispose();
  });

  Future<void> strutCase(
    WidgetTester tester,
    String tag,
    StrutStyle strutStyle,
  ) async {
    final c = NaiSyntaxController(text: '$_marker\nSECOND');
    c.pillBuilder = _buildChip;
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 300,
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: c,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      strutStyle: strutStyle,
                      style: const TextStyle(fontSize: 14, height: 1.8),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final re = _renderEditableOf(tester);
    debugPrint('[$tag] RenderEditable size=${re.size}');
    for (final b in re.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    )) {
      debugPrint('[$tag] marker box: $b');
    }
    for (final b in re.getBoxesForSelection(
      const TextSelection(baseOffset: 2, extentOffset: 8),
    )) {
      debugPrint('[$tag] SECOND box: $b');
    }
    debugPrint(
      '[$tag] chip top=${tester.getTopLeft(find.byKey(_chipKey))} '
      'size=${tester.getSize(find.byKey(_chipKey))}',
    );
  }

  testWidgets('probe: StrutStyle.disabled fixes the slot', (tester) async {
    await strutCase(tester, 'fix-disabled', StrutStyle.disabled);
  });

  testWidgets('probe: forceStrutHeight=false fixes the slot', (tester) async {
    await strutCase(tester, 'fix-noforce', const StrutStyle());
  });

  testWidgets('probe: explicit non-forced strut inherits text style', (
    tester,
  ) async {
    await strutCase(
      tester,
      'fix-inherit',
      const StrutStyle(forceStrutHeight: false),
    );
  });

  testWidgets('probe: same chip inside a Wrap (control)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 300,
              child: Wrap(
                children: [
                  Builder(
                    builder: (context) => AtomChip(
                      key: _chipKey,
                      text: _longAtom,
                      theme: Theme.of(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    _dump('wrap', tester);
  });
}
