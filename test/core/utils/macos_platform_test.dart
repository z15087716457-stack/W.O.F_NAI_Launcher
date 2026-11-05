import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/proxy_service.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/utils/primary_activator.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';
import 'package:nai_launcher/presentation/utils/control_click.dart';

void main() {
  testWidgets(
    'fixed and configurable shortcuts use the desktop modifier',
    (tester) async {
      var calls = 0;
      final mac = defaultTargetPlatform == TargetPlatform.macOS;
      await tester.pumpWidget(
        CallbackShortcuts(
          bindings: {
            const PrimaryActivator(LogicalKeyboardKey.keyS): () => calls++,
          },
          child: const Focus(autofocus: true, child: SizedBox()),
        ),
      );
      await tester.pump();

      expect(
        DefaultShortcuts.all[ShortcutIds.generateImage],
        mac ? 'cmd+enter' : 'ctrl+enter',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(calls, mac ? 0 : 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      expect(calls, 1);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  test('Mac Control-click keeps the pointer secondary until release', () {
    final mapper = ControlClickMapper();
    const down = PointerDownEvent(
      pointer: 5,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryButton,
    );
    expect(
      mapper.map(down, macOS: true, control: true, command: false).buttons,
      kSecondaryButton,
    );
    const move = PointerMoveEvent(pointer: 5, buttons: kPrimaryButton);
    expect(
      mapper.map(move, macOS: true, control: false, command: false).buttons,
      kSecondaryButton,
    );
    mapper.map(
      const PointerUpEvent(pointer: 5),
      macOS: true,
      control: false,
      command: false,
    );
    expect(mapper.map(move, macOS: true, control: false, command: false), move);
    expect(mapper.map(down, macOS: false, control: true, command: false), down);
  });

  test('the Mac ZIP has its own update type', () {
    final mac = ReleaseAssetInfo.fromGitHubAsset({
      'name': 'WOF_NAI_Studio_macOS_2.2.7_Portable.zip',
      'browser_download_url': 'https://example.test/mac.zip',
    });
    expect(mac.type, ReleaseAssetType.macosPortable);
    expect(mac.platform, 'macos');
    expect(mac.requiresManualReplace, isTrue);
    expect(
      ReleaseAssetInfo.inferType(
        fileName: 'WOF_NAI_Studio_Windows_2.2.7_Portable.zip',
      ),
      ReleaseAssetType.windowsPortable,
    );
  });

  test('static macOS proxy prefers enabled HTTPS and brackets IPv6', () {
    expect(
      ProxyService.parseMacProxy('''
  HTTPEnable : 1
  HTTPProxy : http-proxy
  HTTPPort : 3128
  HTTPSEnable : 1
  HTTPSProxy : ::1
  HTTPSPort : 8443
'''),
      '[::1]:8443',
    );
    expect(
      ProxyService.parseMacProxy('HTTPSEnable : 0\nHTTPSPort : 443'),
      isNull,
    );
  });
}
