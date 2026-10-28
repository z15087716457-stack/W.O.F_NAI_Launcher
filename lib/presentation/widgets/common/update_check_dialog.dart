import 'package:nai_launcher/presentation/themes/studio_typography.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/byte_format.dart';
import '../../../core/constants/app_version.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/version/version_info.dart';
import '../../providers/update_provider.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/style_explore/explore_run_runner.dart';
import 'app_toast.dart';

/// Installation waits for generation and exploration to be idle. Keeping this
/// projection separate also lets widget tests run without user data or APIs.
final updateTaskBusyProvider = Provider<bool>(
  (ref) =>
      ref.watch(
        imageGenerationNotifierProvider.select((s) => s.isGenerating),
      ) ||
      ref.watch(exploreRunRunnerProvider.select((s) => s.isRunning)),
);

/// Release notes and update actions share one dialog throughout the download.
class UpdateCheckDialog extends ConsumerWidget {
  const UpdateCheckDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateStateProvider);

    final canClose = state.status != UpdateStatus.installing;
    final ready = state.hasDownloadedUpdate;
    final busy = ready && ref.watch(updateTaskBusyProvider);
    return PopScope(
      canPop: canClose,
      child: AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(_getTitle(context, state))),
            IconButton(
              tooltip: context.l10n.common_close,
              onPressed: canClose ? () => Navigator.of(context).pop() : null,
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.versionInfo != null &&
                    state.status != UpdateStatus.available)
                  _buildUpdateAvailableContent(context, state.versionInfo!),
                _buildContent(context, ref, state),
                if (busy)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      context.l10n.updateWaitForTask,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: _buildActions(context, ref, state),
      ),
    );
  }

  /// 获取弹窗标题
  String _getTitle(BuildContext context, UpdateState state) {
    return switch (state.status) {
      UpdateStatus.checking => context.l10n.updateChecking,
      UpdateStatus.available => context.l10n.updateAvailable,
      UpdateStatus.downloading => context.l10n.updateDownloading,
      UpdateStatus.downloaded => context.l10n.updateDownloaded,
      UpdateStatus.installing => context.l10n.updateInstalling,
      UpdateStatus.upToDate => context.l10n.updateUpToDate,
      UpdateStatus.error =>
        state.downloadedUpdate != null
            ? context.l10n.updateInstallFailed
            : state.versionInfo != null
            ? context.l10n.updateDownloadFailed
            : context.l10n.updateError,
      UpdateStatus.idle => context.l10n.updateChecking,
    };
  }

  /// 构建弹窗内容
  Widget _buildContent(BuildContext context, WidgetRef ref, UpdateState state) {
    return switch (state.status) {
      UpdateStatus.checking => _buildLoadingContent(context),
      UpdateStatus.available => _buildUpdateAvailableContent(
        context,
        state.versionInfo!,
      ),
      UpdateStatus.downloading => _buildDownloadContent(context, state),
      UpdateStatus.downloaded => _buildDownloadedContent(context, state),
      UpdateStatus.installing => _buildInstallingContent(context),
      UpdateStatus.upToDate => _buildUpToDateContent(context),
      UpdateStatus.error => _buildErrorContent(context, state.errorMessage),
      UpdateStatus.idle => _buildLoadingContent(context),
    };
  }

  /// 构建加载状态内容
  Widget _buildLoadingContent(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16)],
        ),
      ),
    );
  }

  /// 构建有可用更新内容
  Widget _buildUpdateAvailableContent(
    BuildContext context,
    VersionInfo versionInfo,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 版本信息
          Row(
            children: [
              Expanded(
                child: _buildVersionInfoTile(
                  context,
                  label: context.l10n.currentVersion,
                  value: AppVersion.formatDisplayVersion(
                    versionInfo.currentVersion ?? '',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVersionInfoTile(
                  context,
                  label: context.l10n.latestVersion,
                  value: AppVersion.formatDisplayVersion(versionInfo.version),
                  isHighlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (versionInfo.publishedAt != null) ...[
            Text(
              versionInfo.publishedAt!.split('T').first,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
          ],
          // 更新日志
          if (versionInfo.releaseNotes != null &&
              versionInfo.releaseNotes!.isNotEmpty) ...[
            Text(
              context.l10n.releaseNotes,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 240),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: _buildReleaseNotes(context, versionInfo),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建下载进度内容
  Widget _buildDownloadContent(BuildContext context, UpdateState state) {
    final progress = state.downloadProgress.clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final theme = Theme.of(context);

    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: progress == 0 ? null : progress),
            const SizedBox(height: 16),
            Text(context.l10n.updateDownloadingProgress(percent)),
            if (state.totalBytes > 0) ...[
              const SizedBox(height: 6),
              Text(
                context.l10n.updateDownloadSizeSpeed(
                  formatBytes(state.downloadedBytes),
                  formatBytes(state.totalBytes),
                  formatBytesPerSecond(state.downloadSpeedBytesPerSecond),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建下载完成、等待安装确认的内容
  Widget _buildDownloadedContent(BuildContext context, UpdateState state) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.updateDownloadedHint(state.versionInfo?.version ?? ''),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建安装器启动内容
  Widget _buildInstallingContent(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n.updateInstallingHint),
          ],
        ),
      ),
    );
  }

  /// 构建版本信息卡片
  Widget _buildVersionInfoTile(
    BuildContext context, {
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.endsWith(' Preview') ? value : 'v$value',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isHighlighted ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建发布说明内容
  ///
  /// 完整渲染 GitHub Flavored Markdown：标题、嵌套列表、任务列表、
  /// 表格、引用、分隔线、删除线、行内/围栏代码、链接与远程图片。
  Widget _buildReleaseNotes(BuildContext context, VersionInfo versionInfo) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final versionTag = versionInfo.version.startsWith('v')
        ? versionInfo.version
        : 'v${versionInfo.version}';
    final rawContentBase = Uri.parse(
      'https://raw.githubusercontent.com/z15087716457-stack/'
      'W.O.F_NAI_Launcher/$versionTag/',
    );

    return MarkdownBody(
      data: versionInfo.releaseNotes!,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubWeb,
      imageDirectory: rawContentBase.toString(),
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
        a: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: colorScheme.primary.withValues(alpha: 0.55),
        ),
        h1: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        h2: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        h3: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        h1Padding: const EdgeInsets.only(top: 10, bottom: 6),
        h2Padding: const EdgeInsets.only(top: 9, bottom: 5),
        h3Padding: const EdgeInsets.only(top: 7, bottom: 4),
        blockSpacing: 10,
        listIndent: 22,
        code: theme.textTheme.bodySmall?.copyWith(
          fontFamily: StudioTypography.mono,
          fontFamilyFallback: StudioTypography.fallback,
          color: colorScheme.onSurface,
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
        blockquoteDecoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: colorScheme.primary, width: 3),
          ),
        ),
        tableHead: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        tableBody: theme.textTheme.bodyMedium,
        tableBorder: TableBorder.all(color: colorScheme.outlineVariant),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        tableScrollbarThumbVisibility: true,
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
      ),
      onTapLink: (text, href, title) async {
        if (href == null || href.isEmpty || href.startsWith('#')) return;
        final uri = _resolveReleaseUri(href, versionTag);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          AppToast.error(context, context.l10n.cannotOpenUrl);
        }
      },
    );
  }

  Uri? _resolveReleaseUri(String href, String versionTag) {
    final uri = Uri.tryParse(href);
    if (uri == null) return null;
    if (uri.hasScheme) {
      return const {'http', 'https', 'mailto'}.contains(uri.scheme)
          ? uri
          : null;
    }
    return Uri.parse(
      'https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/blob/'
      '$versionTag/',
    ).resolveUri(uri);
  }

  /// 构建已是最新内容
  Widget _buildUpToDateContent(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.updateUpToDate,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误内容
  Widget _buildErrorContent(BuildContext context, String? errorMessage) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? context.l10n.updateError,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建按钮操作
  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    UpdateState state,
  ) {
    return switch (state.status) {
      UpdateStatus.checking => [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.common_cancel),
        ),
      ],
      UpdateStatus.available => [
        // 稍后提醒
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
          child: Text(context.l10n.updateLater),
        ),
        // 下载并安装 / 前往下载
        FilledButton(
          onPressed: () async {
            final versionInfo = state.versionInfo;
            if (versionInfo?.supportsInAppInstall == true) {
              await ref.read(updateStateProvider.notifier).downloadUpdate();
              return;
            }
            await _openDownloadUrl(context, versionInfo);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(
            state.versionInfo?.supportsInAppInstall == true
                ? context.l10n.updateDownload
                : context.l10n.goToDownload,
          ),
        ),
      ],
      UpdateStatus.downloading => [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.updateInstallLater),
        ),
        TextButton(
          onPressed: () {
            ref.read(updateStateProvider.notifier).cancelDownload();
            AppToast.info(context, context.l10n.updateDownloadCancelled);
          },
          child: Text(context.l10n.common_cancel),
        ),
      ],
      UpdateStatus.downloaded => [
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
          child: Text(context.l10n.updateInstallLater),
        ),
        FilledButton(
          onPressed: ref.watch(updateTaskBusyProvider)
              ? null
              : () => _install(ref),
          child: Text(context.l10n.updateInstallAndRestart),
        ),
      ],
      UpdateStatus.installing => const [],
      UpdateStatus.upToDate => [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.common_ok),
        ),
      ],
      UpdateStatus.error => [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.common_close),
        ),
        // 下载失败时提供浏览器手动下载的退路
        if (state.versionInfo != null)
          TextButton(
            onPressed: () => _openDownloadUrl(context, state.versionInfo),
            child: Text(context.l10n.goToDownload),
          ),
        FilledButton(
          onPressed:
              state.hasDownloadedUpdate && ref.watch(updateTaskBusyProvider)
              ? null
              : () {
                  final notifier = ref.read(updateStateProvider.notifier);
                  // 已有版本信息说明是下载/安装阶段出错，直接重试下载；
                  // 否则重新走检查更新流程。
                  if (state.downloadedUpdate != null) {
                    _install(ref);
                  } else if (state.versionInfo != null &&
                      state.versionInfo!.supportsInAppInstall) {
                    notifier.downloadUpdate();
                  } else {
                    notifier.checkForUpdates(manual: true);
                  }
                },
          child: Text(context.l10n.common_retry),
        ),
      ],
      UpdateStatus.idle => [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.common_cancel),
        ),
      ],
    };
  }

  Future<void> _install(WidgetRef ref) async {
    // Recheck at the click boundary; a task may have started since the render.
    if (ref.read(updateTaskBusyProvider)) return;
    await ref.read(updateStateProvider.notifier).installDownloadedUpdate();
  }

  Future<void> _openDownloadUrl(
    BuildContext context,
    VersionInfo? versionInfo,
  ) async {
    final url = versionInfo?.htmlUrl ?? versionInfo?.downloadUrl;
    if (url == null) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      AppToast.error(context, context.l10n.cannotOpenUrl);
    }
  }

  /// 显示更新检查弹窗
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UpdateCheckDialog(),
    );
  }
}
