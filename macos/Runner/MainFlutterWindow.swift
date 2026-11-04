import desktop_multi_window
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  // AppKit can return keyboard focus to the window itself. Flutter's wrapper
  // only forwards key equivalents from its rendering view or text input client.
  private var orphanedFlutterKeyboardTarget: NSView? {
    guard firstResponder == nil || firstResponder === self,
          attachedSheet == nil, sheetParent == nil, NSApp.modalWindow == nil,
          let controller = contentViewController as? FlutterViewController,
          controller.isViewLoaded, controller.view.window === self else { return nil }
    let children = controller.view.subviews
    // Flutter attaches its native text client here while a text field is
    // editing. Returning to it also keeps a marked IME composition intact.
    if let editor = children.first(where: { $0 is NSTextView && $0.acceptsFirstResponder }) {
      return editor
    }
    guard let renderView = children.first, renderView.acceptsFirstResponder else { return nil }
    return renderView
  }

  override func becomeKey() {
    super.becomeKey()
    if let target = orphanedFlutterKeyboardTarget { makeFirstResponder(target) }
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    guard event.type == .keyDown, event.window == nil || event.window === self,
          let target = orphanedFlutterKeyboardTarget else {
      return super.performKeyEquivalent(with: event)
    }
    // Preserve native menu equivalents such as Preferences and Close Window
    // before retrying an otherwise undelivered key in Flutter.
    if NSApp.mainMenu?.performKeyEquivalent(with: event) == true { return true }
    makeFirstResponder(target)
    return super.performKeyEquivalent(with: event)
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.title = "W.O.F NAI Studio"

    RegisterGeneratedPlugins(registry: flutterViewController)
    // 应用菜单「设置…」用的通道（见 AppDelegate.showSettings）
    (NSApp.delegate as? AppDelegate)?.appMenuChannel = FlutterMethodChannel(
      name: "com.nailauncher/app_menu",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    (NSApp.delegate as? AppDelegate)?.terminationChannel = FlutterMethodChannel(
      name: "flutter/platform", binaryMessenger: flutterViewController.engine.binaryMessenger,
      codec: FlutterJSONMethodCodec.sharedInstance())
    registerWindowChrome(flutterViewController.engine.binaryMessenger)
    Self.registerCredentialVault(flutterViewController.engine.binaryMessenger)
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      MainFlutterWindow.registerCredentialVault(controller.engine.binaryMessenger)
    }
    registerSystemFontsChannel(flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }

  private func registerWindowChrome(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.wof.naiStudio/window_chrome", binaryMessenger: messenger)
    let titlebar = MacWindowTitlebar(window: self) {
      channel.invokeMethod("toggleAgent", arguments: nil)
    }
    channel.setMethodCallHandler { call, result in
      guard call.method == "configure" else { result(FlutterMethodNotImplemented); return }
      guard let args = call.arguments as? [String: Any], let surface = args["surface"] as? NSNumber,
            let dark = args["dark"] as? Bool else {
        result(FlutterError(code: "invalid_chrome", message: nil, details: nil)); return
      }
      titlebar.configure(surface: surface.uint32Value, dark: dark,
                         agent: args["agent"] as? String, expanded: args["expanded"] as? Bool ?? false)
      result(nil)
    }
  }

  private static let credentialIO = DispatchQueue(label: "com.wof.naiStudio.credential-io")

  private static func registerCredentialVault(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.wof.naiStudio/local_credentials", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard ["read", "update", "clear", "resetCorrupt"].contains(call.method) else {
        result(FlutterMethodNotImplemented)
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      credentialIO.async {
        let response: Any?
        do {
          let vault = try MacCredentialVault.forCurrentUser()
          switch call.method {
          case "read":
            guard let key = args["key"] as? String, !key.isEmpty else { throw MacCredentialVault.Failure.invalidValue }
            response = try vault.read(key)
          case "update":
            guard let changes = args["changes"] as? [String: Any] else { throw MacCredentialVault.Failure.invalidValue }
            response = try vault.update(changes, ifMatching: args["expected"] as? [String: Any])
          case "resetCorrupt":
            response = try vault.resetIfCorrupt()
          default:
            try vault.clear()
            response = nil
          }
        } catch MacCredentialVault.Failure.corrupt {
          response = FlutterError(code: "local_credential_corrupt", message: nil, details: nil)
        } catch {
          // No path, key name, previous value or credential body crosses the
          // error boundary. Leave unreadable data intact for recovery.
          response = FlutterError(code: "local_credential_storage", message: nil, details: nil)
        }
        DispatchQueue.main.async { result(response) }
      }
    }
  }

  // 系统字体列表，和 Windows runner 同一个通道、同样返回字族名列表
  // （Dart 一侧见 lib/core/services/system_font_service.dart）
  private func registerSystemFontsChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.nailauncher/system_fonts", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "getSystemFonts" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(MainFlutterWindow.systemFontFamilies())
    }
  }

  // 去掉以「.」开头的系统内部字族（例如 .AppleSystemUIFont），按名字选不到，
  // 和 Windows 跳过以「@」开头的竖排字体一样
  static func systemFontFamilies() -> [String] {
    let families = NSFontManager.shared.availableFontFamilies.filter {
      !$0.isEmpty && !$0.hasPrefix(".")
    }
    return Array(Set(families)).sorted()
  }
}
