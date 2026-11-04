// 画布工具条（磨砂玻璃）的重绘隔离：工具条里一个按钮重画（悬停、价格变化），
// 不连累背后的画布那一层重录，也不重录玻璃自己的颗粒和边缘高光；样子不变。
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_parts.dart';

class _Dot extends CustomPainter {
  _Dot(this.color) : super(repaint: color);
  final ValueNotifier<Color> color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(
    size.center(Offset.zero),
    6,
    Paint()..color = color.value,
  );

  @override
  bool shouldRepaint(_Dot old) => false;
}

class _Stripes extends CustomPainter {
  const _Stripes();

  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 4, size.height),
        Paint()..color = (x ~/ 4).isEven ? Colors.black : Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_Stripes old) => false;
}

/// [root] 下面按顺序列出所有 PictureLayer。
List<PictureLayer> _pictures(Layer root) {
  final out = <PictureLayer>[];
  void walk(Layer layer) {
    if (layer is PictureLayer) out.add(layer);
    if (layer is ContainerLayer) {
      for (var c = layer.firstChild; c != null; c = c.nextSibling) {
        walk(c);
      }
    }
  }

  walk(root);
  return out;
}

void main() {
  testWidgets('工具条里一个按钮重画，背后的画布和玻璃的颗粒、边缘都不重录', (tester) async {
    final color = ValueNotifier<Color>(Colors.blue);
    addTearDown(color.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: GeistTheme.light,
        home: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                key: Key('canvas-behind'),
                painter: _Stripes(),
              ),
            ),
            Positioned(
              left: 40,
              top: 30,
              child: GenFloat(
                children: [
                  CustomPaint(
                    key: const Key('button'),
                    size: const Size(120, 30),
                    painter: _Dot(color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final all = tester.layers.whereType<PictureLayer>().toList();
    final glassBefore = _pictures(
      tester.layers.whereType<BackdropFilterLayer>().single,
    );
    // 颗粒（玻璃底）、按钮、边缘高光分在三张图层里
    expect(glassBefore.length, 3);

    color.value = Colors.red;
    await tester.pump();

    final glassAfter = _pictures(
      tester.layers.whereType<BackdropFilterLayer>().single,
    );
    expect(glassAfter.first, same(glassBefore.first), reason: '颗粒没重录');
    expect(glassAfter.last, same(glassBefore.last), reason: '边缘高光没重录');
    final redrawn = [
      for (final layer in tester.layers.whereType<PictureLayer>())
        if (!all.any((old) => identical(old, layer))) layer,
    ];
    expect(redrawn, [same(glassAfter[1])], reason: '整棵树只重录了按钮那一张');
    expect(tester.takeException(), isNull);
  });
}
