import Foundation
import XCTest

final class RunnerTests: XCTestCase {
  private var root: URL!
  private var vault: MacCredentialVault!

  override func setUpWithError() throws {
    root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    vault = MacCredentialVault(directory: root.appendingPathComponent("credentials"))
  }

  override func tearDownWithError() throws { try FileManager.default.removeItem(at: root) }

  func testCredentialsSurviveReopenWithPrivatePermissions() throws {
    XCTAssertNil(try vault.read("token"))
    XCTAssertFalse(FileManager.default.fileExists(atPath: vault.directory.path))
    let secret = "test-only-api-key-秘密"
    _ = try vault.update(["token": secret, "other": "private fixture"])
    let next = MacCredentialVault(directory: vault.directory)
    XCTAssertEqual(try next.read("token"), secret)
    for (file, mode) in [(vault.directory, 0o700), (vault.directory.appendingPathComponent("credentials.v1"), 0o600),
                         (vault.directory.appendingPathComponent("key.v1"), 0o600)] {
      let attrs = try FileManager.default.attributesOfItem(atPath: file.path)
      XCTAssertEqual((attrs[.posixPermissions] as? NSNumber)?.intValue, mode)
    }
    let sealed = try Data(contentsOf: vault.directory.appendingPathComponent("credentials.v1"))
    XCTAssertNil(sealed.range(of: Data(secret.utf8)))
    _ = try next.update(["token": NSNull()])
    XCTAssertNil(try next.read("token"))
    XCTAssertEqual(try next.read("other"), "private fixture")
    try next.clear()
    XCTAssertNil(try next.read("other"))
  }

  func testDamagedVaultDoesNotOverwritePreviousData() throws {
    _ = try vault.update(["token": "fixture"])
    let file = vault.directory.appendingPathComponent("credentials.v1")
    var bytes = try Data(contentsOf: file); bytes[bytes.count-1] ^= 1
    try bytes.write(to: file)
    XCTAssertThrowsError(try vault.update(["token": "replacement"]))
    XCTAssertEqual(try Data(contentsOf: file),bytes)
  }

  func testRefusesSymlinkWithoutChangingItsTarget() throws {
    _ = try vault.update(["token":"fixture"])
    let key = vault.directory.appendingPathComponent("key.v1")
    let untouched = root.appendingPathComponent("other")
    let marker = Data(repeating: 0x31, count: 32)
    try marker.write(to: untouched)
    try FileManager.default.removeItem(at: key)
    try FileManager.default.createSymbolicLink(at: key, withDestinationURL: untouched)
    XCTAssertThrowsError(try vault.update(["token":"replacement"]))
    XCTAssertEqual(try Data(contentsOf: untouched),marker)
  }

  func testResetOnlyRepairsCorruptCredentialsAndAllowsSigningInAgain() throws {
    _ = try vault.update(["token":"original", "other":"other secret"])
    XCTAssertFalse(try vault.resetIfCorrupt())
    XCTAssertEqual(try vault.read("token"), "original")
    let key = vault.directory.appendingPathComponent("key.v1")
    try FileManager.default.removeItem(at: key)
    XCTAssertThrowsError(try vault.read("token")) { error in
      XCTAssertEqual(error as? MacCredentialVault.Failure, .corrupt)
    }
    XCTAssertTrue(try vault.resetIfCorrupt())
    XCTAssertNil(try vault.read("other"))
    _ = try vault.update(["token":"new sign-in"])
    XCTAssertEqual(try vault.read("token"), "new sign-in")
  }

  func testResetCannotEraseUnreadableKeyEvenWhenTheCiphertextIsCorrupt() throws {
    _ = try vault.update(["token":"original"])
    let key = vault.directory.appendingPathComponent("key.v1")
    let data = vault.directory.appendingPathComponent("credentials.v1")
    try Data([0]).write(to: data)
    let elsewhere = root.appendingPathComponent("unrelated")
    try Data([42]).write(to: elsewhere)
    try FileManager.default.removeItem(at: key)
    try FileManager.default.createSymbolicLink(at: key, withDestinationURL: elsewhere)
    XCTAssertThrowsError(try vault.resetIfCorrupt())
    XCTAssertEqual(try Data(contentsOf: data), Data([0]))
    XCTAssertEqual(try Data(contentsOf: elsewhere), Data([42]))
    XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: key.path), elsewhere.path)
  }

  func testLateRollbackDoesNotOverwriteAnotherWriter() throws {
    let previous = try vault.update(["token":"A", "email":"A-local"])
    _ = try vault.update(["token":"B", "email":"B-local"])
    XCTAssertThrowsError(try vault.update(previous, ifMatching:["token":"A", "email":"A-local"]))
    XCTAssertEqual(try vault.read("token"),"B")
  }
}
