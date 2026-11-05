import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  var menuChannel: FlutterMethodChannel?
  var terminationChannel: FlutterMethodChannel?
  private var terminating = false

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard let channel = terminationChannel else { return .terminateNow }
    if !terminating {
      terminating = true
      DispatchQueue.main.async {
        channel.invokeMethod("System.requestAppExit", arguments: nil) { result in
          self.terminating = false
          let response = (result as? [String: Any])?["response"] as? String
          sender.reply(toApplicationShouldTerminate: response != "cancel")
        }
      }
    }
    return .terminateLater
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if terminating { return false }
    if !flag { mainFlutterWindow?.makeKeyAndOrderFront(nil) }
    return true
  }

  @IBAction func showSettings(_ sender: Any?) {
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
    menuChannel?.invokeMethod("openSettings", arguments: nil)
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
