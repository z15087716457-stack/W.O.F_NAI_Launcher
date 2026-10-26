import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_scope.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_popovers.dart';
import 'agent_test_harness.dart';
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets(
    'deletion completed after panel disposal does not update the old view',
    (tester) async {
      final deletion = Completer<String?>();
      final base = AgentFixture.actions();
      final actions = AgentActions(
        onClose: base.onClose,
        onNewChat: base.onNewChat,
        onSelectChat: base.onSelectChat,
        onRenameChat: base.onRenameChat,
        onSelectWorkspace: base.onSelectWorkspace,
        onCreateWorkspace: base.onCreateWorkspace,
        onRenameWorkspace: base.onRenameWorkspace,
        onOpenWorkspaceFolder: base.onOpenWorkspaceFolder,
        onCompact: base.onCompact,
        onExport: base.onExport,
        onOpenSettings: base.onOpenSettings,
        onComposerChanged: base.onComposerChanged,
        onSend: base.onSend,
        onStop: base.onStop,
        onPickImages: base.onPickImages,
        onAttachCanvas: base.onAttachCanvas,
        onAttachImage: base.onAttachImage,
        onPaste: base.onPaste,
        onRemoveAttachment: base.onRemoveAttachment,
        onEditQueued: base.onEditQueued,
        onSteerQueued: base.onSteerQueued,
        onWithdrawQueued: base.onWithdrawQueued,
        onRestoreQueued: base.onRestoreQueued,
        onResendFrom: base.onResendFrom,
        onRegenerate: base.onRegenerate,
        onAnswer: base.onAnswer,
        onCancelAsk: base.onCancelAsk,
        onApprove: base.onApprove,
        onCancelApproval: base.onCancelApproval,
        onDecideGate: base.onDecideGate,
        onUndoDiff: base.onUndoDiff,
        onUndoDiffs: base.onUndoDiffs,
        onRevealImage: base.onRevealImage,
        onOpenFile: base.onOpenFile,
        onOpenLink: base.onOpenLink,
        onSelectModel: base.onSelectModel,
        onOpenModelSettings: base.onOpenModelSettings,
        onThinking: base.onThinking,
        onPermission: base.onPermission,
        onRefreshUsage: base.onRefreshUsage,
        onDismissNotices: base.onDismissNotices,
        onRetryInit: base.onRetryInit,
        onEditMemory: base.onEditMemory,
        onDeleteChat: (_) => deletion.future,
        onDeleteWorkspace: base.onDeleteWorkspace,
        onUndoDelete: base.onUndoDelete,
        onSearchChats: base.onSearchChats,
        onImageAction: base.onImageAction,
        onSilenceBypass: base.onSilenceBypass,
        onContinue: base.onContinue,
        onAdjustLimit: base.onAdjustLimit,
        onOpenSettingAt: base.onOpenSettingAt,
        onPromptSetAction: base.onPromptSetAction,
      );
      await pumpAgent(tester, actions: actions);
      final scope = tester.widget<AgentScope>(find.byType(AgentScope));
      final context = tester.element(find.byKey(const Key('agent-thread')));
      final task = agentDeleteChat(context, scope.data.chats.first);
      final observed = expectLater(task, completes);
      await tester.pumpWidget(const SizedBox());
      deletion.complete('fixture-trash-token');
      await observed;
    },
  );
  testWidgets(
    'pending confirmation completes as cancelled when panel is disposed',
    (tester) async {
      await pumpAgent(tester);
      final scope = tester.widget<AgentScope>(find.byType(AgentScope));
      var finished = false;
      scope
          .confirm(
            title: 'fixture',
            message: 'fixture',
            confirm: 'yes',
            danger: false,
          )
          .then((_) => finished = true);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
      expect(finished, isTrue);
    },
  );
  testWidgets('opening a replacement confirmation cancels the old request', (
    tester,
  ) async {
    await pumpAgent(tester);
    final scope = tester.widget<AgentScope>(find.byType(AgentScope));
    final first = scope.confirm(
      title: 'first',
      message: 'first',
      confirm: 'yes',
      danger: false,
    );
    final second = scope.confirm(
      title: 'second',
      message: 'second',
      confirm: 'yes',
      danger: false,
    );
    expect(await first, isNull);
    await tester.pumpWidget(const SizedBox());
    expect(await second, isNull);
    expect(tester.takeException(), isNull);
  });
}
