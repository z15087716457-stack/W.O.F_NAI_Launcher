import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Application text coverage. Dialog routes capture this InheritedTheme too.
/// The application's typography root enables it for light Impeller rendering.
class StudioTextCoverageScope extends InheritedTheme {
  const StudioTextCoverageScope({
    super.key,
    required this.enabled,
    required super.child,
  });
  final bool enabled;
  static bool activeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<StudioTextCoverageScope>()
          ?.enabled ??
      false;
  @override
  bool updateShouldNotify(StudioTextCoverageScope old) =>
      old.enabled != enabled;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      StudioTextCoverageScope(enabled: enabled, child: child);
}

class StudioTextCoverage {
  StudioTextCoverage._();
  static final exponent =
      double.tryParse(
        const String.fromEnvironment(
          'EXPLORE_TEXT_COVERAGE',
          defaultValue: '0.70',
        ),
      ) ??
      .70;
  static Future<void>? _loading;
  static ui.FragmentProgram? program;
  // The shader/filter pairs are shared immutable application resources. The
  // coverage depends on opacity; at most 256 filters serve every ink color.
  static final _inkFilters = <int, ui.ImageFilter>{};
  static final _inkShaders = <ui.FragmentShader>[];
  static Future<void> preload() => _loading ??= _load();
  static Future<void> _load() async {
    if (!ui.ImageFilter.isShaderFilterSupported || exponent == 1) return;
    try {
      program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/explore_text_coverage.frag',
      );
    } catch (error) {
      debugPrint('Text coverage unavailable: $error');
    }
  }

  static bool supported(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light &&
      ui.ImageFilter.isShaderFilterSupported &&
      exponent != 1 &&
      program != null;

  /// Paint filters affect glyphs only. Selection, composing highlights,
  /// WidgetSpan backgrounds, carets and input decorations are separate paints.
  static TextStyle glyphStyle(BuildContext context, TextStyle style) {
    if (!StudioTextCoverageScope.activeOf(context) || !supported(context)) {
      return style;
    }
    final ink =
        style.color ??
        style.foreground?.color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;
    final key = ink.toARGB32() >> 24;
    final filter = _inkFilters.putIfAbsent(key, () {
      final shader = program!.fragmentShader()
        ..setFloat(2, exponent)
        ..setFloat(3, ink.a);
      _inkShaders.add(shader);
      return ui.ImageFilter.shader(shader);
    });
    return style.copyWith(
      foreground: Paint()
        ..color = ink
        ..imageFilter = filter,
    );
  }

  /// Syntax controllers must resolve each span's color before adding a paint.
  /// An inherited foreground paint otherwise wins over TextStyle.copyWith(color).
  static TextStyle withoutCoverage(TextStyle style) {
    final foreground = style.foreground;
    if (foreground == null ||
        !_inkFilters.containsValue(foreground.imageFilter)) {
      return style;
    }
    return TextStyle(
      inherit: style.inherit,
      color: foreground.color,
      backgroundColor: style.backgroundColor,
      background: style.background,
      fontFamily: style.fontFamily,
      fontFamilyFallback: style.fontFamilyFallback,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      letterSpacing: style.letterSpacing,
      wordSpacing: style.wordSpacing,
      textBaseline: style.textBaseline,
      height: style.height,
      leadingDistribution: style.leadingDistribution,
      locale: style.locale,
      shadows: style.shadows,
      fontFeatures: style.fontFeatures,
      fontVariations: style.fontVariations,
      decoration: style.decoration,
      decorationColor: style.decorationColor,
      decorationStyle: style.decorationStyle,
      decorationThickness: style.decorationThickness,
      debugLabel: style.debugLabel,
      overflow: style.overflow,
    );
  }

  static InlineSpan glyphSpan(
    BuildContext context,
    InlineSpan span, {
    TextStyle inherited = const TextStyle(),
  }) {
    if (span is! TextSpan) return span;
    final resolved = withoutCoverage(inherited).merge(
      span.style == null ? null : withoutCoverage(span.style!),
    );
    return TextSpan(
      text: span.text,
      style: glyphStyle(context, resolved),
      children: span.children
          ?.map((s) => glyphSpan(context, s, inherited: resolved))
          .toList(),
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      semanticsIdentifier: span.semanticsIdentifier,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
}

/// Shared controls use the application's glyph paint without changing metrics.
class StudioText extends Text {
  const StudioText(
    super.data, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  });
  const StudioText.rich(
    super.textSpan, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  }) : super.rich();

  @override
  Widget build(BuildContext context) {
    if (!StudioTextCoverageScope.activeOf(context) ||
        !StudioTextCoverage.supported(context)) {
      return super.build(context);
    }
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final span = textSpan ?? TextSpan(text: data);
    // Reuse Text's own selection, semantics, scaler and layout implementation.
    // Calling its stateless build returns the paragraph rather than introducing
    // a second Text widget with the same label into the semantics/widget tree.
    return Text.rich(
      StudioTextCoverage.glyphSpan(context, span, inherited: resolved),
      style: StudioTextCoverage.glyphStyle(context, resolved),
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    ).build(context);
  }
}

/// Rebuilds opted-in input styles after the asynchronous shader load. Its
/// ancestry stays stable when toggling theme, preserving focus and drafts.
class StudioTextCoverageRegion extends StatefulWidget {
  const StudioTextCoverageRegion({super.key, required this.child});
  final Widget child;
  @override
  State<StudioTextCoverageRegion> createState() => _CoverageRegionState();
}

class _CoverageRegionState extends State<StudioTextCoverageRegion> {
  @override
  void initState() {
    super.initState();
    StudioTextCoverage.preload().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => StudioTextCoverageScope(
    enabled: StudioTextCoverage.supported(context),
    child: widget.child,
  );
}
