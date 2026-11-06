import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/common/studio_material.dart';
import '../../../../core/auth/chatgpt_auth_service.dart';
import '../../../../core/utils/localization_extension.dart';

class ChatGptConnectionCard extends ConsumerStatefulWidget {
  const ChatGptConnectionCard({
    super.key,
    required this.providerId,
    required this.onConnected,
  });
  final String? providerId;
  final VoidCallback onConnected;
  @override
  ConsumerState<ChatGptConnectionCard> createState() =>
      _ChatGptConnectionCardState();
}

class _ChatGptConnectionCardState extends ConsumerState<ChatGptConnectionCard> {
  ChatGptAccount? _account;
  CancelToken? _cancellation;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ChatGptConnectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providerId != widget.providerId) _load();
  }

  Future<void> _load() async {
    final id = widget.providerId;
    try {
      final account = id == null
          ? null
          : await ref.read(chatGptAuthServiceProvider).account(id);
      if (mounted && id == widget.providerId) {
        setState(() => _account = account);
      }
    } catch (_) {
      if (mounted && id == widget.providerId) {
        setState(() {
          _account = null;
          _message = context.l10n.chatGpt_authFailed('storage_read_failed');
        });
      }
    }
  }

  @override
  void dispose() {
    _cancellation?.cancel();
    super.dispose();
  }

  Future<void> _connect() async {
    final id = widget.providerId!;
    final cancellation = CancelToken();
    setState(() {
      _busy = true;
      _message = null;
      _cancellation = cancellation;
    });
    try {
      await ref.read(chatGptAuthServiceProvider).signIn(id, cancellation);
      await _load();
      if (mounted && _account?.planEnabled == true) widget.onConnected();
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is ChatGptAuthException
              ? error.toString()
              : context.l10n.chatGpt_authFailed('sign_in_failed'),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _cancellation = null;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final revoked = await ref
          .read(chatGptAuthServiceProvider)
          .signOut(widget.providerId!);
      await _load();
      if (mounted && !revoked) {
        setState(() => _message = context.l10n.chatGpt_revokeUnconfirmed);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = context.l10n.chatGpt_authFailed('sign_out_failed'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.chatGpt_connectionHint),
        const SizedBox(height: 8),
        if (_account case final account?) ...[
          Text(account.email ?? 'ChatGPT'),
          Text(
            account.signedIn
                ? account.planEnabled
                      ? l10n.chatGpt_usingPlan
                      : l10n.chatGpt_planDisabled
                : l10n.chatGpt_signedOut,
          ),
        ],
        if (widget.providerId == null) Text(l10n.chatGpt_saveFirst),
        if (_message != null)
          Text(
            _message!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (_busy) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          Text(l10n.chatGpt_waiting),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: widget.providerId != null && !_busy ? _connect : null,
              child: Text(l10n.chatGpt_continue),
            ),
            if (_cancellation != null)
              TextButton(
                onPressed: () => _cancellation?.cancel(),
                child: Text(l10n.chatGpt_cancel),
              ),
            if (_account?.signedIn == true)
              TextButton(
                onPressed: _busy ? null : _disconnect,
                child: Text(l10n.chatGpt_signOut),
              ),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://chatgpt.com/settings/usage'),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(l10n.chatGpt_manageUsage),
            ),
          ],
        ),
      ],
    );
  }
}
