import 'package:flutter/material.dart';

import '../../../core/constants/brand.dart';
import '../../../core/services/adjacent_app_data_migration.dart';
import '../../../core/utils/app_language.dart';
import '../../../core/utils/fatal_diagnostics.dart';
import '../../../l10n/app_localizations.dart';

/// Once recovery succeeds, remove its retry controls before services can open.
class StartupDataLoadingApp extends StatelessWidget {
  const StartupDataLoadingApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: CircularProgressIndicator())),
  );
}

/// Deliberately uses no settings, providers or databases: storage is not ready.
class StartupDataRecoveryApp extends StatefulWidget {
  const StartupDataRecoveryApp({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onOpenDirectory,
    required this.onCopy,
    required this.onClose,
    this.locale,
  });

  final Object error;
  final Future<void> Function() onRetry, onClose;
  final Future<void> Function(String path) onOpenDirectory, onCopy;
  final Locale? locale;

  @override
  State<StartupDataRecoveryApp> createState() => _StartupDataRecoveryAppState();
}

class _StartupDataRecoveryAppState extends State<StartupDataRecoveryApp> {
  bool _busy = false;
  String? _actionError;

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => _actionError = _safe(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _safe(Object value) => FatalDiagnostics.redactSensitiveText('$value');

  @override
  Widget build(BuildContext context) {
    final failure = widget.error;
    final paths = failure is AdjacentAppDataException ? failure : null;
    final locale =
        widget.locale ??
        AppLanguage.fromSystemLocales(
          WidgetsBinding.instance.platformDispatcher.locales,
        ).locale;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Brand.name,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'HarmonyOS Sans SC',
        fontFamilyFallback: const ['Pretendard', 'Geist'],
        colorSchemeSeed: const Color(0xff1462ff),
      ),
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(Brand.name),
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(Icons.folder_off_outlined, size: 40),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.startup_dataTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.startup_dataHelp),
                        if (paths != null) ...[
                          const SizedBox(height: 24),
                          Text(l10n.startup_dataCurrent),
                          SelectableText(paths.destinationPath),
                          const SizedBox(height: 16),
                          Text(l10n.startup_dataLegacy),
                          SelectableText(paths.legacyPath),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                key: const Key('startup-open-current'),
                                onPressed: _busy
                                    ? null
                                    : () => _perform(
                                        () => widget.onOpenDirectory(
                                          paths.destinationPath,
                                        ),
                                      ),
                                child: Text(l10n.startup_dataOpenCurrent),
                              ),
                              OutlinedButton(
                                key: const Key('startup-open-legacy'),
                                onPressed: _busy
                                    ? null
                                    : () => _perform(
                                        () => widget.onOpenDirectory(
                                          paths.legacyPath,
                                        ),
                                      ),
                                child: Text(l10n.startup_dataOpenLegacy),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        ExpansionTile(
                          title: Text(l10n.startup_dataDetails),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(_safe(failure)),
                            ),
                          ],
                        ),
                        if (_actionError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              l10n.startup_dataActionFailed(_actionError!),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              key: const Key('startup-retry'),
                              onPressed: _busy
                                  ? null
                                  : () => _perform(widget.onRetry),
                              child: Text(l10n.common_retry),
                            ),
                            OutlinedButton(
                              key: const Key('startup-copy'),
                              onPressed: _busy
                                  ? null
                                  : () => _perform(
                                      () => widget.onCopy(
                                        _safe(
                                          [
                                            Brand.name,
                                            failure,
                                            if (paths != null) ...[
                                              '${l10n.startup_dataCurrent}: ${paths.destinationPath}',
                                              '${l10n.startup_dataLegacy}: ${paths.legacyPath}',
                                            ],
                                          ].join('\n'),
                                        ),
                                      ),
                                    ),
                              child: Text(l10n.common_copy),
                            ),
                            TextButton(
                              key: const Key('startup-close'),
                              onPressed: _busy
                                  ? null
                                  : () => _perform(widget.onClose),
                              child: Text(l10n.common_close),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
