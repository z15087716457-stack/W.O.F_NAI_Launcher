import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // 窗口隐藏到托盘时不自动退出 app（配合 window_manager 的 setPreventClose + hide）
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  // Flutter's default delegate first returns .terminateCancel, which also
  // cancels an in-progress logout. Keep AppKit's original request open while
  // Flutter closes its stores, then reply to that request exactly once.
  var terminationChannel: FlutterMethodChannel?
  private var awaitingTerminationReply = false

  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard let channel = terminationChannel else { return .terminateNow }
    if !awaitingTerminationReply {
      awaitingTerminationReply = true
      DispatchQueue.main.async {
        channel.invokeMethod("System.requestAppExit", arguments: nil) { result in
          self.awaitingTerminationReply = false
          let response = (result as? [String: Any])?["response"] as? String
          sender.reply(toApplicationShouldTerminate: response != "cancel")
        }
      }
    }
    return .terminateLater
  }

  // 点 Dock 图标时，若当前没有可见窗口，显示并激活已有窗口（从托盘/隐藏状态恢复）
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    guard !awaitingTerminationReply else { return false }
    if !flag {
      // NSApplication.windows also includes AppKit's spelling/language panels.
      // Only the launcher window should be restored from the Dock.
      mainFlutterWindow?.makeKeyAndOrderFront(self)
      NSApp.activate(ignoringOtherApps: true)
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // 应用菜单「设置…」（⌘,）交给 Dart 打开设置页。通道在 MainFlutterWindow 里建，
  // Dart 一侧见 lib/presentation/widgets/common/macos_app_integration.dart
  var appMenuChannel: FlutterMethodChannel?

  @IBAction func showSettings(_ sender: Any?) {
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    appMenuChannel?.invokeMethod("openSettings", arguments: nil)
  }
}
