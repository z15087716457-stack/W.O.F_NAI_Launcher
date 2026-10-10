import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/config/auth_feature_flags.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

import '../../providers/auth_mode_provider.dart';
import 'entry_controls.dart';

/// 登录方式分段切换：一条浅灰轨道，选中项浮起成白 / 炭灰小块。
class AuthModeSwitcher extends ConsumerWidget {
  const AuthModeSwitcher({super.key, this.compact = false});

  /// 保留旧参数：登录页与添加账号对话框现在共用同一种分段样式。
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(authModeProvider);
    const credentialsEnabled = AuthFeatureFlags.credentialsLoginEnabled;
    final effectiveMode =
        !credentialsEnabled && currentMode == AuthMode.credentials
        ? AuthMode.token
        : currentMode;
    final palette = EntryPalette.of(context);
    final l10n = context.l10n;

    void select(AuthMode mode) {
      ref.read(authModeNotifierProvider.notifier).switchMode(mode);
    }

    return Container(
      key: const Key('auth_mode_switcher'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.control,
        borderRadius: BorderRadius.circular(9),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Segment(
                key: const Key('auth_mode_token'),
                label: 'API Token',
                badge: l10n.auth_recommended,
                tooltip: l10n.auth_tokenLoginRecommended,
                selected: effectiveMode == AuthMode.token,
                onTap: () => select(AuthMode.token),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: _Segment(
                key: const Key('auth_mode_credentials'),
                label: l10n.auth_credentialsLogin,
                tooltip: credentialsEnabled
                    ? l10n.auth_credentialsLogin
                    : l10n.auth_credentialsLoginUnavailable,
                selected: effectiveMode == AuthMode.credentials,
                enabled: credentialsEnabled,
                onTap: () => select(AuthMode.credentials),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: _Segment(
                key: const Key('auth_mode_third_party'),
                label: l10n.auth_thirdPartyLogin,
                tooltip: l10n.auth_thirdPartyLogin,
                selected: effectiveMode == AuthMode.thirdParty,
                onTap: () => select(AuthMode.thirdParty),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    this.badge,
    this.enabled = true,
  });

  final String label;
  final String tooltip;
  final String? badge;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    final color = !widget.enabled
        ? palette.faint
        : widget.selected || _hover
        ? palette.ink
        : palette.muted;
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        selected: widget.selected,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onTap : null,
          child: MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 28),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                color: widget.selected ? palette.segment : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: widget.selected ? palette.segmentShadow : null,
              ),
              alignment: Alignment.center,
              child: Text.rich(
                TextSpan(
                  text: widget.label,
                  children: [
                    if (widget.badge != null)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.top,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Text(
                            widget.badge!,
                            style: TextStyle(
                              fontSize: 9,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              color: palette.blue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  color: color,
                  fontWeight: widget.selected
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
