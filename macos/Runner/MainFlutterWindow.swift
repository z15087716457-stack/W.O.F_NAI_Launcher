import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let controller = FlutterViewController()
    let windowFrame = frame
    contentViewController = controller
    setFrame(windowFrame, display: true)
    RegisterGeneratedPlugins(registry: controller)

    let messenger = controller.engine.binaryMessenger
    let delegate = NSApp.delegate as? AppDelegate
    delegate?.menuChannel = FlutterMethodChannel(
      name: "com.nailauncher/app_menu", binaryMessenger: messenger)
    delegate?.menuChannel?.setMethodCallHandler { call, result in
      guard let bundleID = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "isRunning":
        result(!NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty)
      case "importPreferences":
        let defaults = UserDefaults.standard
        for (key, value) in defaults.persistentDomain(forName: bundleID) ?? [:]
          where key.hasPrefix("flutter.") && defaults.object(forKey: key) == nil {
          defaults.set(value, forKey: key)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    delegate?.terminationChannel = FlutterMethodChannel(
      name: "flutter/platform", binaryMessenger: messenger,
      codec: FlutterJSONMethodCodec.sharedInstance())
    FlutterMethodChannel(name: "com.nailauncher/system_fonts", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "getSystemFonts" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(NSFontManager.shared.availableFontFamilies.filter { !$0.hasPrefix(".") }.sorted())
      }
    super.awakeFromNib()
  }
}
