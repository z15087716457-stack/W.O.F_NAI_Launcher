import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../core/services/mac_legacy_data_import.dart';
import '../../../core/utils/app_language.dart';
import '../../../core/utils/app_support_directory.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../../widgets/auth/entry_controls.dart';
import '../../widgets/branding/brand_logo.dart';
import '../../widgets/branding/entry_field.dart';

/// Shows the first-launch copy of the previous macOS version's data, or a
/// sync, undo or redo requested in Settings (see [MacLegacyDataImport]), in
/// the window before Hive and the databases open. Nothing is shown unless data
/// is copied or switched or the user has to decide; the app replaces this
/// screen with its own once startup continues.
class LegacyDataImportGate implements MacLegacyDataImportPresenter {
  LegacyDataImportGate({
    this.appName = macLegacyAppName,
    void Function(Widget app)? show,
  }) : _show = show ?? runApp;

  /// main() calls this before the data folder is first resolved.
  static void install() {
    macLegacyDataImportPresenter = LegacyDataImportGate();
  }

  final String appName;
  final void Function(Widget app) _show;
  final _view = ValueNotifier<LegacyDataImportView>(
    const LegacyDataImportView(LegacyDataImportStep.copying),
  );
  var _task = MacLegacyDataTask.import;
  var _shown = false;

  void _set(LegacyDataImportView view) {
    _view.value = view;
    if (_shown) return;
    _shown = true;
    _show(LegacyDataImportApp(appName: appName, view: _view));
  }

  @override
  void showCopying(MacLegacyDataTask task) => _set(
    LegacyDataImportView(LegacyDataImportStep.copying, task: _task = task),
  );

  @override
  void showLegacyRunning(
    MacLegacyDataTask task, {
    required void Function() onSkip,
  }) => _set(
    LegacyDataImportView(
      LegacyDataImportStep.waiting,
      task: _task = task,
      onSkip: onSkip,
    ),
  );

  @override
  void showFailed(
    MacLegacyDataTask task,
    Object error, {
    required void Function() onRetry,
    required void Function() onSkip,
  }) => _set(
    LegacyDataImportView(
      LegacyDataImportStep.failed,
      task: _task = task,
      error: error,
      onRetry: onRetry,
      onSkip: onSkip,
    ),
  );

  /// Keeps the task's title while the app takes over.
  @override
  void showStarting() =>
      _set(LegacyDataImportView(LegacyDataImportStep.starting, task: _task));
}

enum LegacyDataImportStep { copying, waiting, failed, starting }

@immutable
class LegacyDataImportView {
  const LegacyDataImportView(
    this.step, {
    this.task = MacLegacyDataTask.import,
    this.error,
    this.onRetry,
    this.onSkip,
  });

  final LegacyDataImportStep step;

  /// First-launch copy, or a sync, undo or redo requested in Settings.
  final MacLegacyDataTask task;
  final Object? error;
  final VoidCallback? onRetry;
  final VoidCallback? onSkip;
}

/// A small app of its own: settings, theme and language are not loaded yet,
/// so it follows the system appearance and language.
class LegacyDataImportApp extends StatelessWidget {
  const LegacyDataImportApp({
    super.key,
    required this.appName,
    required this.view,
    this.locale,
    this.themeMode = ThemeMode.system,
  });

  final String appName;
  final ValueListenable<LegacyDataImportView> view;
  final Locale? locale;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(AppStyle.geist, Brightness.light),
      darkTheme: AppTheme.getTheme(AppStyle.geist, Brightness.dark),
      themeMode: themeMode,
      locale:
          locale ??
          AppLanguage.fromSystemLocales(
            WidgetsBinding.instance.platformDispatcher.locales,
          ).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ValueListenableBuilder<LegacyDataImportView>(
        valueListenable: view,
        builder: (context, value, _) =>
            LegacyDataImportPage(appName: appName, view: value),
      ),
    );
  }
}

class LegacyDataImportPage extends StatefulWidget {
  const LegacyDataImportPage({
    super.key,
    required this.appName,
    required this.view,
  });

  final String appName;
  final LegacyDataImportView view;

  @override
  State<LegacyDataImportPage> createState() => _LegacyDataImportPageState();
}

class _LegacyDataImportPageState extends State<LegacyDataImportPage> {
  /// Logo and card; the background field keeps clear of them, as on the
  /// login page.
  final _hero = GlobalKey();

  String get appName => widget.appName;
  LegacyDataImportView get view => widget.view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = EntryPalette.of(context);
    final (title, body) = switch ((view.step, view.task)) {
      (LegacyDataImportStep.waiting, MacLegacyDataTask.import) => (
        l10n.legacyImport_runningTitle(appName),
        l10n.legacyImport_runningBody,
      ),
      // Only a sync reads the previous version; undo and redo never wait.
      (LegacyDataImportStep.waiting, _) => (
        l10n.legacyImport_runningTitle(appName),
        l10n.legacySync_runningBody,
      ),
      (LegacyDataImportStep.failed, MacLegacyDataTask.import) => (
        l10n.legacyImport_failedTitle(appName),
        l10n.legacyImport_failedBody(appName),
      ),
      (LegacyDataImportStep.failed, MacLegacyDataTask.sync) => (
        l10n.legacySync_failedTitle(appName),
        l10n.legacySync_failedBody,
      ),
      (LegacyDataImportStep.failed, MacLegacyDataTask.undo) => (
        l10n.legacyUndo_failedTitle,
        l10n.legacyUndo_failedBody,
      ),
      // Nothing changed either way, so a redo shares the undo's reassurance.
      (LegacyDataImportStep.failed, MacLegacyDataTask.redo) => (
        l10n.legacyRedo_failedTitle,
        l10n.legacyUndo_failedBody,
      ),
      (_, MacLegacyDataTask.import) => (
        l10n.legacyImport_copyingTitle(appName),
        l10n.legacyImport_copyingBody(appName),
      ),
      (_, MacLegacyDataTask.sync) => (
        l10n.legacySync_title(appName),
        l10n.legacySync_body(appName),
      ),
      (_, MacLegacyDataTask.undo) => (
        l10n.legacyUndo_title,
        l10n.legacyUndo_body,
      ),
      (_, MacLegacyDataTask.redo) => (
        l10n.legacyRedo_title,
        l10n.legacyRedo_body,
      ),
    };
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // The calm login field; the busy dots in the card show progress.
          Positioned.fill(
            child: EntryField(signal: 0, ambient: false, clearKey: _hero),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  key: _hero,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(width: 200),
                    const SizedBox(height: 32),
                    EntryCard(
                      key: const Key('legacy_import_card'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            body,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: palette.muted,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ..._footer(context, palette),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _footer(BuildContext context, EntryPalette palette) {
    final l10n = context.l10n;
    final skip = EntryGhostButton(
      key: const Key('legacy_import_skip'),
      label: switch (view.task) {
        MacLegacyDataTask.import => l10n.legacyImport_startWithout,
        MacLegacyDataTask.sync => l10n.legacySync_startWithout,
        MacLegacyDataTask.undo => l10n.legacyUndo_startWithout,
        MacLegacyDataTask.redo => l10n.legacyRedo_startWithout,
      },
      onPressed: view.onSkip,
    );
    return switch (view.step) {
      LegacyDataImportStep.copying => [_Busy(color: palette.blue)],
      LegacyDataImportStep.starting => [
        _Busy(color: palette.blue, label: l10n.warmup_preparing),
      ],
      LegacyDataImportStep.waiting => [
        _Busy(color: palette.blue, label: l10n.legacyImport_waiting(appName)),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerRight, child: skip),
      ],
      LegacyDataImportStep.failed => [
        EntryAlert(title: describeImportError(view.error)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: skip),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 132,
              child: EntryPrimaryButton(
                key: const Key('legacy_import_retry'),
                label: l10n.common_retry,
                onPressed: view.onRetry,
              ),
            ),
          ],
        ),
      ],
    };
  }
}

/// The system's reason first (for example "No space left on device"); the
/// operation and file only when there is no system reason.
@visibleForTesting
String describeImportError(Object? error) {
  if (error is FileSystemException) {
    final reason = error.osError?.message;
    if (reason != null && reason.isNotEmpty) return reason;
    return error.path == null || error.path!.isEmpty
        ? error.message
        : '${error.message}: ${error.path}';
  }
  return '$error';
}

class _Busy extends StatelessWidget {
  const _Busy({required this.color, this.label});

  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EntryBusyDots(color: color),
        if (label != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 12.5,
                color: EntryPalette.of(context).muted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
