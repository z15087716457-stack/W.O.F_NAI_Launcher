// Shared Flutter widget entry for the whole Studio. The widgets retain their
// original state/controllers/layout; only glyph paints change in light Impeller.
// Import this facade for presentation code. It also exports the usual Material
// API, so new pages automatically inherit the application's font coverage.
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart' as fw;
import 'package:flutter/material.dart'
    hide Text, RichText, TextField, TextFormField, SelectableText;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/scheduler.dart';
import 'studio_text_coverage.dart';
export 'package:flutter/material.dart'
    hide Text, RichText, TextField, TextFormField, SelectableText;

class Text extends StudioText {
  const Text(
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
  const Text.rich(
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
}

TextStyle? _inputStyle(
  BuildContext context,
  TextStyle? source,
  Set<WidgetState> states,
) {
  if (!StudioTextCoverageScope.activeOf(context) ||
      !StudioTextCoverage.supported(context)) {
    return source;
  }
  final theme = Theme.of(context);
  final base = theme.useMaterial3
      ? theme.textTheme.bodyLarge!
      : theme.textTheme.titleMedium!;
  final disabled = states.contains(WidgetState.disabled);
  final color = disabled
      ? (theme.useMaterial3
            ? base.color?.withValues(alpha: .38)
            : theme.disabledColor)
      : base.color;
  final resolved = base
      .copyWith(color: color)
      .merge(WidgetStateProperty.resolveAs(source, states));
  return StudioTextCoverage.glyphStyle(context, resolved);
}

InputDecoration? _inputDecoration(
  BuildContext context,
  InputDecoration? source,
  TextStyle? inputStyle,
) {
  if (source == null ||
      !StudioTextCoverageScope.activeOf(context) ||
      !StudioTextCoverage.supported(context)) {
    return source;
  }
  final theme = Theme.of(context), c = theme.colorScheme;
  final decoration = source.applyDefaults(InputDecorationTheme.of(context));
  final base = StudioTextCoverage.withoutCoverage(
    (theme.useMaterial3
            ? theme.textTheme.bodyLarge!
            : theme.textTheme.titleMedium!)
        .merge(inputStyle),
  );
  // Match the pinned SDK's M2/M3 decoration text defaults, then filter only
  // their glyph paints. Borders, fill, caret and selection remain separate.
  TextStyle stateStyle(String role, Set<WidgetState> states) {
    final disabled = states.contains(WidgetState.disabled);
    final small = role == 'helper' || role == 'error';
    var color = theme.useMaterial3 ? c.onSurfaceVariant : theme.hintColor;
    if (disabled && role != 'error') {
      color = theme.useMaterial3
          ? c.onSurface.withValues(alpha: .38)
          : small
          ? Colors.transparent
          : theme.disabledColor;
    } else if (role == 'error' ||
        ((role == 'floating' || (theme.useMaterial3 && role == 'label')) &&
            states.contains(WidgetState.error))) {
      color = !theme.useMaterial3 && disabled
          ? Colors.transparent
          : theme.useMaterial3 &&
                states.contains(WidgetState.hovered) &&
                !states.contains(WidgetState.focused) &&
                role != 'error'
          ? c.onErrorContainer
          : c.error;
    } else if ((role == 'floating' ||
            (theme.useMaterial3 && role == 'label')) &&
        states.contains(WidgetState.focused)) {
      color = c.primary;
    }
    final font = small
        ? theme.textTheme.bodySmall!
        : theme.useMaterial3 && (role == 'label' || role == 'floating')
        ? theme.textTheme.bodyLarge!
        : base;
    return font.copyWith(color: color);
  }

  TextStyle covered(String role, TextStyle? provided) =>
      WidgetStateTextStyle.resolveWith((states) {
        final resolved = stateStyle(
          role,
          states,
        ).merge(WidgetStateProperty.resolveAs(provided, states));
        return StudioTextCoverage.glyphStyle(context, resolved);
      });
  return decoration.copyWith(
    hintStyle: covered('hint', decoration.hintStyle),
    labelStyle: covered('label', decoration.labelStyle),
    floatingLabelStyle: covered(
      'floating',
      decoration.floatingLabelStyle ?? decoration.labelStyle,
    ),
    helperStyle: covered('helper', decoration.helperStyle),
    errorStyle: covered('error', decoration.errorStyle),
    counterStyle: decoration.counterStyle == null
        ? null
        : covered('helper', decoration.counterStyle),
    prefixStyle: decoration.prefixStyle == null
        ? null
        : covered('hint', decoration.prefixStyle),
    suffixStyle: decoration.suffixStyle == null
        ? null
        : covered('hint', decoration.suffixStyle),
  );
}

class TextField extends fw.TextField {
  const TextField({
    super.key,
    super.groupId,
    super.controller,
    super.focusNode,
    super.undoController,
    super.decoration,
    super.keyboardType,
    super.textInputAction,
    super.textCapitalization,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textAlignVertical,
    super.textDirection,
    super.readOnly,
    super.toolbarOptions,
    super.showCursor,
    super.autofocus,
    super.statesController,
    super.obscuringCharacter,
    super.obscureText,
    super.autocorrect,
    super.smartDashesType,
    super.smartQuotesType,
    super.enableSuggestions,
    super.maxLines,
    super.minLines,
    super.expands,
    super.maxLength,
    super.maxLengthEnforcement,
    super.onChanged,
    super.onEditingComplete,
    super.onSubmitted,
    super.onAppPrivateCommand,
    super.inputFormatters,
    super.enabled,
    super.ignorePointers,
    super.cursorWidth,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorOpacityAnimates,
    super.cursorColor,
    super.cursorErrorColor,
    super.selectionHeightStyle,
    super.selectionWidthStyle,
    super.keyboardAppearance,
    super.scrollPadding,
    super.dragStartBehavior,
    super.enableInteractiveSelection,
    super.selectAllOnFocus,
    super.selectionControls,
    super.onTap,
    super.onTapAlwaysCalled,
    super.onTapOutside,
    super.onTapUpOutside,
    super.mouseCursor,
    super.buildCounter,
    super.scrollController,
    super.scrollPhysics,
    super.autofillHints,
    super.contentInsertionConfiguration,
    super.clipBehavior,
    super.restorationId,
    super.scribbleEnabled,
    super.stylusHandwritingEnabled,
    super.enableIMEPersonalizedLearning,
    super.enableInlinePrediction,
    super.contextMenuBuilder,
    super.canRequestFocus,
    super.spellCheckConfiguration,
    super.magnifierConfiguration,
    super.hintLocales,
  });
  factory TextField.from(fw.TextField source) => TextField(
    key: source.key,
    groupId: source.groupId,
    controller: source.controller,
    focusNode: source.focusNode,
    undoController: source.undoController,
    decoration: source.decoration,
    keyboardType: source.keyboardType,
    textInputAction: source.textInputAction,
    textCapitalization: source.textCapitalization,
    style: source.style,
    strutStyle: source.strutStyle,
    textAlign: source.textAlign,
    textAlignVertical: source.textAlignVertical,
    textDirection: source.textDirection,
    readOnly: source.readOnly,
    toolbarOptions: source.toolbarOptions,
    showCursor: source.showCursor,
    autofocus: source.autofocus,
    statesController: source.statesController,
    obscuringCharacter: source.obscuringCharacter,
    obscureText: source.obscureText,
    autocorrect: source.autocorrect,
    smartDashesType: source.smartDashesType,
    smartQuotesType: source.smartQuotesType,
    enableSuggestions: source.enableSuggestions,
    maxLines: source.maxLines,
    minLines: source.minLines,
    expands: source.expands,
    maxLength: source.maxLength,
    maxLengthEnforcement: source.maxLengthEnforcement,
    onChanged: source.onChanged,
    onEditingComplete: source.onEditingComplete,
    onSubmitted: source.onSubmitted,
    onAppPrivateCommand: source.onAppPrivateCommand,
    inputFormatters: source.inputFormatters,
    enabled: source.enabled,
    ignorePointers: source.ignorePointers,
    cursorWidth: source.cursorWidth,
    cursorHeight: source.cursorHeight,
    cursorRadius: source.cursorRadius,
    cursorOpacityAnimates: source.cursorOpacityAnimates,
    cursorColor: source.cursorColor,
    cursorErrorColor: source.cursorErrorColor,
    selectionHeightStyle: source.selectionHeightStyle,
    selectionWidthStyle: source.selectionWidthStyle,
    keyboardAppearance: source.keyboardAppearance,
    scrollPadding: source.scrollPadding,
    dragStartBehavior: source.dragStartBehavior,
    enableInteractiveSelection: source.enableInteractiveSelection,
    selectAllOnFocus: source.selectAllOnFocus,
    selectionControls: source.selectionControls,
    onTap: source.onTap,
    onTapAlwaysCalled: source.onTapAlwaysCalled,
    onTapOutside: source.onTapOutside,
    onTapUpOutside: source.onTapUpOutside,
    mouseCursor: source.mouseCursor,
    buildCounter: source.buildCounter,
    scrollController: source.scrollController,
    scrollPhysics: source.scrollPhysics,
    autofillHints: source.autofillHints,
    contentInsertionConfiguration: source.contentInsertionConfiguration,
    clipBehavior: source.clipBehavior,
    restorationId: source.restorationId,
    scribbleEnabled: source.scribbleEnabled,
    stylusHandwritingEnabled: source.stylusHandwritingEnabled,
    enableIMEPersonalizedLearning: source.enableIMEPersonalizedLearning,
    enableInlinePrediction: source.enableInlinePrediction,
    contextMenuBuilder: source.contextMenuBuilder,
    canRequestFocus: source.canRequestFocus,
    spellCheckConfiguration: source.spellCheckConfiguration,
    magnifierConfiguration: source.magnifierConfiguration,
    hintLocales: source.hintLocales,
  );
  @override
  State<fw.TextField> createState() => _StudioTextFieldState();
}

class _StudioTextFieldState extends State<fw.TextField> {
  late WidgetStatesController _states;
  bool _queuedStateChange = false;
  bool get _ownsStates => widget.statesController == null;

  @override
  void initState() {
    super.initState();
    _states = widget.statesController ?? WidgetStatesController();
    _states.addListener(_stateChanged);
  }

  void _stateChanged() {
    if (!mounted) return;
    // TextField updates disabled/focus states while its child is building.
    // Refresh the glyph paint after that frame without rebuilding its editor.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_queuedStateChange) return;
      _queuedStateChange = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _queuedStateChange = false;
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant fw.TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statesController != widget.statesController) {
      _states.removeListener(_stateChanged);
      if (oldWidget.statesController == null) _states.dispose();
      _states = widget.statesController ?? WidgetStatesController();
      _states.addListener(_stateChanged);
    }
  }

  @override
  void dispose() {
    _states.removeListener(_stateChanged);
    if (_ownsStates) _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final states = {..._states.value};
    if (!(widget.enabled ?? widget.decoration?.enabled ?? true)) {
      states.add(WidgetState.disabled);
    }
    final effectiveStyle = _inputStyle(context, widget.style, states);
    return fw.TextField(
      groupId: widget.groupId,
      controller: widget.controller,
      focusNode: widget.focusNode,
      undoController: widget.undoController,
      decoration: _inputDecoration(context, widget.decoration, widget.style),
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      style: effectiveStyle,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      textDirection: widget.textDirection,
      readOnly: widget.readOnly,
      toolbarOptions: widget.toolbarOptions,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      statesController: _states,
      obscuringCharacter: widget.obscuringCharacter,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      onAppPrivateCommand: widget.onAppPrivateCommand,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      ignorePointers: widget.ignorePointers,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorOpacityAnimates: widget.cursorOpacityAnimates,
      cursorColor: widget.cursorColor,
      cursorErrorColor: widget.cursorErrorColor,
      selectionHeightStyle: widget.selectionHeightStyle,
      selectionWidthStyle: widget.selectionWidthStyle,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      dragStartBehavior: widget.dragStartBehavior,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectAllOnFocus: widget.selectAllOnFocus,
      selectionControls: widget.selectionControls,
      onTap: widget.onTap,
      onTapAlwaysCalled: widget.onTapAlwaysCalled,
      onTapOutside: widget.onTapOutside,
      onTapUpOutside: widget.onTapUpOutside,
      mouseCursor: widget.mouseCursor,
      buildCounter: widget.buildCounter,
      scrollController: widget.scrollController,
      scrollPhysics: widget.scrollPhysics,
      autofillHints: widget.autofillHints,
      contentInsertionConfiguration: widget.contentInsertionConfiguration,
      clipBehavior: widget.clipBehavior,
      restorationId: widget.restorationId,
      scribbleEnabled: widget.scribbleEnabled,
      stylusHandwritingEnabled: widget.stylusHandwritingEnabled,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      enableInlinePrediction: widget.enableInlinePrediction,
      contextMenuBuilder: widget.contextMenuBuilder,
      canRequestFocus: widget.canRequestFocus,
      spellCheckConfiguration: widget.spellCheckConfiguration,
      magnifierConfiguration: widget.magnifierConfiguration,
      hintLocales: widget.hintLocales,
    );
  }
}

class SelectableText extends fw.SelectableText {
  const SelectableText(
    super.data, {
    super.key,
    super.focusNode,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.textScaleFactor,
    super.textScaler,
    super.showCursor,
    super.autofocus,
    super.toolbarOptions,
    super.minLines,
    super.maxLines,
    super.cursorWidth,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorColor,
    super.selectionColor,
    super.selectionHeightStyle,
    super.selectionWidthStyle,
    super.dragStartBehavior,
    super.enableInteractiveSelection,
    super.selectionControls,
    super.onTap,
    super.scrollPhysics,
    super.scrollBehavior,
    super.semanticsLabel,
    super.textHeightBehavior,
    super.textWidthBasis,
    super.onSelectionChanged,
    super.contextMenuBuilder,
    super.magnifierConfiguration,
  });
  const SelectableText.rich(
    super.textSpan, {
    super.key,
    super.focusNode,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.textScaleFactor,
    super.textScaler,
    super.showCursor,
    super.autofocus,
    super.toolbarOptions,
    super.minLines,
    super.maxLines,
    super.cursorWidth,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorColor,
    super.selectionColor,
    super.selectionHeightStyle,
    super.selectionWidthStyle,
    super.dragStartBehavior,
    super.enableInteractiveSelection,
    super.selectionControls,
    super.onTap,
    super.scrollPhysics,
    super.scrollBehavior,
    super.semanticsLabel,
    super.textHeightBehavior,
    super.textWidthBasis,
    super.onSelectionChanged,
    super.contextMenuBuilder,
    super.magnifierConfiguration,
  }) : super.rich();
  @override
  State<fw.SelectableText> createState() => _StudioSelectableState();
}

class _StudioSelectableState extends State<fw.SelectableText> {
  @override
  Widget build(BuildContext context) {
    final enabled =
        StudioTextCoverageScope.activeOf(context) &&
        StudioTextCoverage.supported(context);
    final resolved = DefaultTextStyle.of(context).style.merge(widget.style);
    final effectiveStyle = enabled
        ? StudioTextCoverage.glyphStyle(context, resolved)
        : widget.style;
    if (widget.textSpan != null) {
      return fw.SelectableText.rich(
        enabled
            ? StudioTextCoverage.glyphSpan(
                    context,
                    widget.textSpan!,
                    inherited: resolved,
                  )
                  as TextSpan
            : widget.textSpan!,
        focusNode: widget.focusNode,
        style: effectiveStyle,
        strutStyle: widget.strutStyle,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
        textScaleFactor: widget.textScaleFactor,
        textScaler: widget.textScaler,
        showCursor: widget.showCursor,
        autofocus: widget.autofocus,
        toolbarOptions: widget.toolbarOptions,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        cursorWidth: widget.cursorWidth,
        cursorHeight: widget.cursorHeight,
        cursorRadius: widget.cursorRadius,
        cursorColor: widget.cursorColor,
        selectionColor: widget.selectionColor,
        selectionHeightStyle: widget.selectionHeightStyle,
        selectionWidthStyle: widget.selectionWidthStyle,
        dragStartBehavior: widget.dragStartBehavior,
        enableInteractiveSelection: widget.enableInteractiveSelection,
        selectionControls: widget.selectionControls,
        onTap: widget.onTap,
        scrollPhysics: widget.scrollPhysics,
        scrollBehavior: widget.scrollBehavior,
        semanticsLabel: widget.semanticsLabel,
        textHeightBehavior: widget.textHeightBehavior,
        textWidthBasis: widget.textWidthBasis,
        onSelectionChanged: widget.onSelectionChanged,
        contextMenuBuilder: widget.contextMenuBuilder,
        magnifierConfiguration: widget.magnifierConfiguration,
      );
    }
    return fw.SelectableText(
      widget.data!,
      focusNode: widget.focusNode,
      style: effectiveStyle,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      textScaleFactor: widget.textScaleFactor,
      textScaler: widget.textScaler,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      toolbarOptions: widget.toolbarOptions,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      selectionColor: widget.selectionColor,
      selectionHeightStyle: widget.selectionHeightStyle,
      selectionWidthStyle: widget.selectionWidthStyle,
      dragStartBehavior: widget.dragStartBehavior,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectionControls: widget.selectionControls,
      onTap: widget.onTap,
      scrollPhysics: widget.scrollPhysics,
      scrollBehavior: widget.scrollBehavior,
      semanticsLabel: widget.semanticsLabel,
      textHeightBehavior: widget.textHeightBehavior,
      textWidthBasis: widget.textWidthBasis,
      onSelectionChanged: widget.onSelectionChanged,
      contextMenuBuilder: widget.contextMenuBuilder,
      magnifierConfiguration: widget.magnifierConfiguration,
    );
  }
}

class RichText extends fw.RichText {
  RichText({
    super.key,
    required super.text,
    super.textAlign,
    super.textDirection,
    super.softWrap,
    super.overflow,
    super.textScaleFactor,
    super.textScaler,
    super.maxLines,
    super.locale,
    super.strutStyle,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionRegistrar,
    super.selectionColor,
  });
  InlineSpan _paintSpan(BuildContext context) =>
      StudioTextCoverage.glyphSpan(context, text);
  @override
  RenderParagraph createRenderObject(BuildContext context) =>
      super.createRenderObject(context)..text = _paintSpan(context);
  @override
  void updateRenderObject(BuildContext context, RenderParagraph renderObject) {
    super.updateRenderObject(context, renderObject);
    renderObject.text = _paintSpan(context);
  }
}

class TextFormField extends fw.TextFormField {
  TextFormField({
    super.key,
    super.groupId,
    super.controller,
    super.initialValue,
    super.focusNode,
    super.forceErrorText,
    super.decoration,
    super.keyboardType,
    super.textCapitalization,
    super.textInputAction,
    super.style,
    super.strutStyle,
    super.textDirection,
    super.textAlign,
    super.textAlignVertical,
    super.autofocus,
    super.readOnly,
    super.toolbarOptions,
    super.showCursor,
    super.obscuringCharacter,
    super.obscureText,
    super.autocorrect,
    super.smartDashesType,
    super.smartQuotesType,
    super.enableSuggestions,
    super.maxLengthEnforcement,
    super.maxLines,
    super.minLines,
    super.expands,
    super.maxLength,
    super.onChanged,
    super.onTap,
    super.onTapAlwaysCalled,
    super.onTapOutside,
    super.onTapUpOutside,
    super.onEditingComplete,
    super.onFieldSubmitted,
    super.onSaved,
    super.validator,
    super.errorBuilder,
    super.inputFormatters,
    super.enabled,
    super.ignorePointers,
    super.cursorWidth,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorColor,
    super.cursorErrorColor,
    super.keyboardAppearance,
    super.scrollPadding,
    super.enableInteractiveSelection,
    super.selectAllOnFocus,
    super.selectionControls,
    super.buildCounter,
    super.scrollPhysics,
    super.autofillHints,
    super.autovalidateMode,
    super.scrollController,
    super.restorationId,
    super.enableIMEPersonalizedLearning,
    super.mouseCursor,
    super.contextMenuBuilder,
    super.spellCheckConfiguration,
    super.magnifierConfiguration,
    super.undoController,
    super.onAppPrivateCommand,
    super.cursorOpacityAnimates,
    super.selectionHeightStyle,
    super.selectionWidthStyle,
    super.dragStartBehavior,
    super.contentInsertionConfiguration,
    super.statesController,
    super.clipBehavior,
    super.scribbleEnabled,
    super.stylusHandwritingEnabled,
    super.canRequestFocus,
    super.hintLocales,
  });
  // Preserve Flutter's own FormFieldState: validators, save/reset, restoration,
  // autofill, controllers and GlobalKey<FormFieldState> remain unchanged.
  @override
  FormFieldBuilder<String> get builder =>
      (field) => _coveredFormInput(super.builder(field));
}

Widget _coveredFormInput(Widget widget) {
  if (widget is fw.TextField) return TextField.from(widget);
  if (widget is UnmanagedRestorationScope) {
    return UnmanagedRestorationScope(
      bucket: widget.bucket,
      child: _coveredFormInput(widget.child),
    );
  }
  return widget;
}
