import Cocoa

/// Styles the existing system row; Flutter's content frame stays below it.
final class MacWindowTitlebar: NSObject {
  private weak var window: NSWindow?
  private let onToggleAgent: () -> Void
  private let accessory = NSTitlebarAccessoryViewController()
  private let button = NSButton()
  private var expanded = false

  init(window: NSWindow, onToggleAgent: @escaping () -> Void) {
    self.window = window
    self.onToggleAgent = onToggleAgent
    super.init()
    accessory.layoutAttribute = .trailing
    accessory.view = NSView()
    button.setButtonType(.pushOnPushOff)
    button.bezelStyle = .rounded
    button.controlSize = .small
    button.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
    button.image = NSImage(systemSymbolName: "sidebar.right", accessibilityDescription: nil)
    button.imagePosition = .imageLeading
    button.target = self
    button.action = #selector(toggleAgent)
    button.setAccessibilityIdentifier("wof-native-agent-toggle")
    button.autoresizingMask = [.minYMargin, .maxYMargin]
    accessory.view.addSubview(button)
  }

  func configure(surface: UInt32, dark: Bool, agent: String?, expanded: Bool) {
    guard let window else { return }
    window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    window.backgroundColor = NSColor(srgbRed: CGFloat((surface >> 16) & 255) / 255,
                                     green: CGFloat((surface >> 8) & 255) / 255,
                                     blue: CGFloat(surface & 255) / 255, alpha: 1)
    window.titlebarAppearsTransparent = true

    let index = window.titlebarAccessoryViewControllers.firstIndex { $0 === accessory }
    guard let agent, !agent.isEmpty else {
      if let index { window.removeTitlebarAccessoryViewController(at: index) }
      return
    }
    self.expanded = expanded
    button.title = agent
    button.setAccessibilityLabel(agent)
    button.toolTip = agent
    button.state = expanded ? .on : .off
    button.sizeToFit()
    let size = button.frame.size
    let height = max(24, size.height)
    accessory.view.setFrameSize(NSSize(width: size.width + 16, height: height))
    button.setFrameOrigin(NSPoint(x: 4, y: (height - size.height) / 2))
    if index == nil { window.addTitlebarAccessoryViewController(accessory) }
  }

  @objc private func toggleAgent() {
    // The same Flutter controller also owns closing the dock from its toolbar.
    // Its response controls the native button's state even if a toggle fails.
    button.state = expanded ? .on : .off
    onToggleAgent()
  }
}
