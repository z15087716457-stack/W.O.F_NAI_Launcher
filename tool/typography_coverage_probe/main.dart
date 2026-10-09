import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'text_coverage.dart';

const _output = String.fromEnvironment('PROBE_OUTPUT');
const _fallback = ['HarmonyOS Sans SC', 'Pretendard'];
const _exponents = [1.0, .9, .8, .7];
const _names = ['原始', '轻微补偿', '中等补偿', '较强补偿'];
late ui.FragmentProgram _program;
final _captureKey = GlobalKey();
bool _dark = false;
bool _identity = false;
double _scale = 1;
String _case = 'light';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  _dark = args.contains('--dark');
  _identity = args.contains('--identity');
  for (final arg in args) {
    if (arg.startsWith('--case=')) _case = arg.substring(7);
    if (arg.startsWith('--scale=')) _scale = double.parse(arg.substring(8));
  }
  _program = await ui.FragmentProgram.fromAsset('shaders/text_coverage.frag');
  runApp(const CoverageProbe());
  WidgetsBinding.instance.addPostFrameCallback((_) => _writeReady());
  Timer(const Duration(minutes: 45), () => exit(0));
}

Future<void> _writeReady() async {
  await Future<void>.delayed(const Duration(seconds: 1));
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  if (_output.isNotEmpty) {
    await Directory(_output).create(recursive: true);
    final boundary =
        _captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: view.devicePixelRatio);
    try {
      final pixels = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$_output/$_case-gpu.png',
      ).writeAsBytes(pixels!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
    await File('$_output/$_case-ready.json').writeAsString(
      jsonEncode({
        'pid': pid,
        'case': _case,
        'dark': _dark,
        'identity': _identity,
        'textScale': _scale,
        'physicalSize': [view.physicalSize.width, view.physicalSize.height],
        'devicePixelRatio': view.devicePixelRatio,
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'losslessImageSource':
            'native Windows process RepaintBoundary snapshot, not a desktop screen capture',
        'exponents': _dark || _identity ? [1, 1, 1, 1] : _exponents,
      }),
    );
  }
}

class CoverageProbe extends StatefulWidget {
  const CoverageProbe({super.key});

  @override
  State<CoverageProbe> createState() => _CoverageProbeState();
}

class _CoverageProbeState extends State<CoverageProbe> {
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: _dark ? Brightness.dark : Brightness.light,
      fontFamily: 'HarmonyOS Sans SC',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontFamily: 'HarmonyOS Sans SC',
          fontFamilyFallback: _fallback,
          fontSize: 13,
          height: 1.45,
          leadingDistribution: TextLeadingDistribution.even,
          letterSpacing: 0,
          wordSpacing: 0,
        ),
      ),
    ),
    home: Scaffold(
      backgroundColor: _dark
          ? const Color(0xff111111)
          : const Color(0xffeeeeee),
      body: RepaintBoundary(
        key: _captureKey,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(_scale)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '浅色文字字缘补偿 · 原生窗口试验',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _dark = !_dark;
                            _identity = false;
                            _case = _dark ? 'dark' : 'light';
                          });
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _writeReady(),
                          );
                        },
                        child: const Text('切换明暗'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _dark = false;
                            _identity = !_identity;
                            _case = _identity ? 'identity' : 'light';
                          });
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _writeReady(),
                          );
                        },
                        child: const Text('恒等滤镜'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_dark ? '深色：所有列保持原始文字' : '浅色：只补偿半透明字缘'} · 字体 / 字号 / 字重 / 间距保持 · ${ui.ImageFilter.isShaderFilterSupported ? 'Impeller 滤镜可用' : 'Skia：自动回退原始文字'}',
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: _SampleColumn(index: i)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '独立样例：背景、边框与图标不进入滤镜；深色及不支持滤镜的后端直接返回原始控件。',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SampleColumn extends StatelessWidget {
  const _SampleColumn({required this.index});
  final int index;
  Color get ink => _dark ? const Color(0xffededed) : const Color(0xff171717);
  Color get muted => _dark ? const Color(0xffa1a1a1) : const Color(0xff666666);
  Color get faint => _dark ? const Color(0xff7a7a7a) : const Color(0xff8f8f8f);
  double get exponent => _dark || _identity ? 1 : _exponents[index];

  Widget _filter(Widget child) => TextCoverage(
    program: _program,
    exponent: exponent,
    forceIdentityLayer: _identity && index > 0 && !_dark,
    child: child,
  );

  Widget _text(
    String text, {
    String family = 'HarmonyOS Sans SC',
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) => _filter(
    Text(
      text,
      maxLines: 1,
      style: TextStyle(
        fontFamily: family,
        fontFamilyFallback: _fallback,
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
        height: 1.45,
        leadingDistribution: TextLeadingDistribution.even,
        letterSpacing: 0,
        wordSpacing: 0,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${_names[index]} · γ=${exponent.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: _dark ? const Color(0xff161616) : const Color(0xfffafafa),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _dark ? const Color(0xff2e2e2e) : const Color(0xffe6e6e6),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final weight in [
                  FontWeight.w400,
                  FontWeight.w500,
                  FontWeight.w600,
                  FontWeight.w700,
                ]) ...[
                  _text('本地画廊　画风探索　${weight.value}', size: 13, weight: weight),
                  _text(
                    'NovelAI Studio 3274348526',
                    family: 'Geist',
                    size: 12,
                    weight: weight,
                  ),
                  const SizedBox(height: 7),
                ],
                _text(
                  '832×1216 · 28 步 · 5.0',
                  family: 'Geist Mono',
                  color: ink,
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: _dark
                      ? const Color(0xff2e2e2e)
                      : const Color(0xffe6e6e6),
                ),
                const SizedBox(height: 12),
                _text(
                  '已收藏',
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: _dark
                      ? const Color(0xffff6369)
                      : const Color(0xffe5484d),
                ),
                const SizedBox(height: 3),
                _text(
                  '加入进化　套用到编辑区',
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: _dark
                      ? const Color(0xff9e8cfc)
                      : const Color(0xff6e56cf),
                ),
                const SizedBox(height: 12),
                _text('分组', color: muted),
                _text('按 1–9 快速归组', size: 11, color: faint),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.check, size: 12),
                    const SizedBox(width: 4),
                    _text(
                      '冷色调',
                      weight: FontWeight.w600,
                      color: _dark
                          ? const Color(0xff50a8ff)
                          : const Color(0xff0064e2),
                    ),
                    const SizedBox(width: 9),
                    _text('厚涂　＋ 新分组', color: muted),
                  ],
                ),
                const SizedBox(height: 12),
                for (final pair in [
                  ('种子', '3274348526'),
                  ('耗时', '14.8 s'),
                  ('参数', '832×1216 · 28 · 5.0'),
                ])
                  Row(
                    children: [
                      SizedBox(width: 36, child: _text(pair.$1, color: muted)),
                      Expanded(child: _text(pair.$2, family: 'Geist Mono')),
                    ],
                  ),
                const SizedBox(height: 10),
                _filter(
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '富文本 ',
                          style: TextStyle(color: muted),
                        ),
                        TextSpan(
                          text: '冷色调 ',
                          style: TextStyle(
                            color: _dark
                                ? const Color(0xff50a8ff)
                                : const Color(0xff0064e2),
                          ),
                        ),
                        TextSpan(
                          text: '14.8 s',
                          style: TextStyle(
                            color: ink,
                            fontFamily: 'Geist Mono',
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamilyFallback: _fallback,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(opacity: .6, child: _text('外层透明度 60% 保持', color: ink)),
                const SizedBox(height: 10),
                _text('编辑控件：仅试验文字和光标', size: 11, color: faint),
                SizedBox(
                  height: 32,
                  child: _filter(
                    TextFormField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      initialValue: '套用到编辑区',
                      cursorColor: ink,
                      style: TextStyle(
                        fontFamily: 'HarmonyOS Sans SC',
                        fontSize: 12,
                        height: 1.45,
                        letterSpacing: 0,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
