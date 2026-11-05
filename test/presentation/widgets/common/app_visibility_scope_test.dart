import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/presentation/ui/kit/app_visibility_scope.dart';

void main() {
  test(
    'hidden, minimized and lifecycle states must all clear before resuming',
    () {
      final visibility = AppVisibility();
      addTearDown(visibility.dispose);
      visibility.onWindowEvent('blur');
      visibility.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(visibility.value, isTrue);
      visibility.onWindowEvent('hide');
      visibility.onWindowEvent('minimize');
      visibility.didChangeAppLifecycleState(AppLifecycleState.hidden);
      visibility.onWindowEvent('focus');
      expect(visibility.value, isFalse);
      visibility.onWindowEvent('show');
      visibility.onWindowEvent('maximize');
      expect(visibility.value, isFalse);
      visibility.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(visibility.value, isTrue);
    },
  );

  testWidgets('hiding stops drawing and tickers while retaining widget state', (
    tester,
  ) async {
    final visibility = AppVisibility();
    addTearDown(visibility.dispose);
    var paints = 0;
    var ticks = 0;
    final ticker = GlobalKey<_TickerProbeState>();
    await tester.pumpWidget(
      AppVisibilityScope(
        visibility: visibility,
        child: _TickerProbe(
          key: ticker,
          onTick: () => ticks++,
          child: CustomPaint(painter: _PaintProbe(() => paints++)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final original = ticker.currentState;
    visibility.onWindowEvent('hide');
    await tester.pump();
    final hidden = (paints, ticks);
    await tester.pump(const Duration(seconds: 1));
    expect((paints, ticks), hidden);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(ticker.currentState, same(original));
    visibility.onWindowEvent('show');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(paints, greaterThan(hidden.$1));
    expect(ticks, greaterThan(hidden.$2));
    expect(ticker.currentState, same(original));
  });
}

class _TickerProbe extends StatefulWidget {
  const _TickerProbe({super.key, required this.onTick, required this.child});
  final VoidCallback onTick;
  final Widget child;

  @override
  State<_TickerProbe> createState() => _TickerProbeState();
}

class _TickerProbeState extends State<_TickerProbe>
    with SingleTickerProviderStateMixin {
  late final _ticker = createTicker((_) => widget.onTick())..start();

  @override
  void initState() {
    super.initState();
    _ticker;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PaintProbe extends CustomPainter {
  const _PaintProbe(this.onPaint);
  final VoidCallback onPaint;

  @override
  void paint(Canvas canvas, Size size) => onPaint();

  @override
  bool shouldRepaint(_PaintProbe oldDelegate) => false;
}
