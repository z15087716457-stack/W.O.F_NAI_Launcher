import Cocoa
import XCTest

final class MacWindowTitlebarTests: XCTestCase {
  @MainActor func testNativeSurfaceAndAgentShareTheOriginalTitlebar() throws {
    _ = NSApplication.shared
    let style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                          styleMask: style, backing: .buffered, defer: true)
    window.title = "W.O.F NAI Studio"
    let originalContent = window.contentLayoutRect
    let stoplight = window.standardWindowButton(.closeButton)
    var taps = 0
    let chrome = MacWindowTitlebar(window: window) { taps += 1 }

    chrome.configure(surface: 0xff111111, dark: true, agent: nil, expanded: false)
    XCTAssertTrue(window.titlebarAppearsTransparent)
    XCTAssertEqual(window.appearance?.name, .darkAqua)
    XCTAssertEqual(window.title, "W.O.F NAI Studio")
    XCTAssertEqual(window.titleVisibility, .visible)
    XCTAssertTrue(window.titlebarAccessoryViewControllers.isEmpty)
    XCTAssertEqual(try XCTUnwrap(window.backgroundColor.usingColorSpace(.sRGB)).redComponent, 17 / 255.0, accuracy: 0.0001)

    chrome.configure(surface: 0xfffaf4e0, dark: false, agent: "NAI Agent", expanded: false)
    let accessory = try XCTUnwrap(window.titlebarAccessoryViewControllers.first)
    let button = try XCTUnwrap(accessory.view.subviews.compactMap { $0 as? NSButton }.first)
    XCTAssertEqual(accessory.layoutAttribute, .trailing)
    XCTAssertEqual(button.title, "NAI Agent")
    XCTAssertEqual(button.accessibilityLabel(), "NAI Agent")
    XCTAssertEqual(button.state, .off)
    button.performClick(nil)
    XCTAssertEqual(taps, 1)
    XCTAssertEqual(window.appearance?.name, .aqua)
    let light = try XCTUnwrap(window.backgroundColor.usingColorSpace(.sRGB))
    XCTAssertEqual(light.redComponent, 250 / 255.0, accuracy: 0.0001)
    XCTAssertEqual(light.greenComponent, 244 / 255.0, accuracy: 0.0001)
    XCTAssertEqual(light.blueComponent, 224 / 255.0, accuracy: 0.0001)
    chrome.configure(surface: 0xfffaf4e0, dark: false, agent: "NAI Agent", expanded: true)
    XCTAssertEqual(window.titlebarAccessoryViewControllers.count, 1)
    XCTAssertEqual(button.state, .on)
    chrome.configure(surface: 0xfffaf4e0, dark: false, agent: nil, expanded: false)
    XCTAssertTrue(window.titlebarAccessoryViewControllers.isEmpty)
    XCTAssertTrue(window.standardWindowButton(.closeButton) === stoplight)
    XCTAssertEqual(window.styleMask, style)
    XCTAssertEqual(window.contentLayoutRect, originalContent)
    XCTAssertFalse(window.isVisible)
  }
}
