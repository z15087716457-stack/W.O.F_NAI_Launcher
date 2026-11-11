import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/navigation/retained_branch_viewport.dart';

class _Probe extends StatefulWidget {
  const _Probe({super.key});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int builds = 0, layouts = 0;
  late MediaQueryData media;
  Size? viewport;
  final text = TextEditingController(text: 'retained draft');
  final scroll = ScrollController();

  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    builds++;
    media = MediaQuery.of(context);
    return _LayoutProbe(
      onLayout: (size) {
        layouts++;
        viewport = size;
      },
      child: Material(
        child: ListView(
          controller: scroll,
          children: [
            TextField(controller: text),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    );
  }
}

class _LayoutProbe extends SingleChildRenderObjectWidget {
  const _LayoutProbe({required this.onLayout, required super.child});
  final ValueChanged<Size> onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderProbe(onLayout);
}

class _RenderProbe extends RenderProxyBox {
  _RenderProbe(this.onLayout);
  final ValueChanged<Size> onLayout;
  @override
  void performLayout() {
    super.performLayout();
    onLayout(size);
  }
}

void main() {
  testWidgets('inactive branch skips window resize builds and layouts', (
    tester,
  ) async {
    final key = GlobalKey<_ProbeState>();
    final page = _Probe(key: key);
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;

    Future<void> show(int index, Size size, {double dpr = 1}) async {
      tester.view.physicalSize = size * dpr;
      tester.view.devicePixelRatio = dpr;
      await tester.pumpWidget(
        MaterialApp(
          home: IndexedStack(
            index: index,
            sizing: StackFit.expand,
            children: [
              const SizedBox.expand(),
              RetainedBranchViewport(active: index == 1, child: page),
            ],
          ),
        ),
      );
      await tester.pump();
    }

    await show(1, const Size(1200, 800));
    final state = key.currentState!;
    state.text.text = 'latest draft';
    state.scroll.jumpTo(180);
    await show(0, const Size(1200, 800));
    final builds = state.builds;
    final layouts = state.layouts;
    for (var i = 0; i < 12; i++) {
      await show(0, Size(1220 + i * 12, 810 + i * 4));
    }
    await show(0, const Size(1000, 700), dpr: 1.5);
    expect(state.builds, builds);
    expect(state.layouts, layouts);
    expect(state.viewport, const Size(1200, 800));
    expect(state.media.size, const Size(1200, 800));
    expect(state.media.devicePixelRatio, 1);

    await show(1, const Size(1000, 700), dpr: 1.5);
    expect(key.currentState, same(state));
    expect(state.viewport, const Size(1000, 700));
    expect(state.media.size, const Size(1000, 700));
    expect(state.media.devicePixelRatio, 1.5);
    expect(state.text.text, 'latest draft');
    expect(state.scroll.offset, 180);

    await show(1, const Size(1100, 750), dpr: 1.5);
    expect(state.viewport, const Size(1100, 750));
    expect(state.media.size, const Size(1100, 750));
    expect(tester.takeException(), isNull);
  });
}
