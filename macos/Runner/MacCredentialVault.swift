import CryptoKit
import Darwin
import Foundation

/// A user-owned credential file outside the movable settings and backup tree.
/// The random key is a separate 0600 file. Both files are private to the OS
/// user; an application with access to both can read the credentials.
struct MacCredentialVault {
  enum Failure: Error { case storage, corrupt, unsafeFile, invalidValue, conflict }
  let directory: URL
  private let keyFile = "key.v1"
  private let dataFile = "credentials.v1"
  private let header = Data("WOF-CREDENTIALS-1\n".utf8)
  private let limit = 16 * 1024 * 1024

  static func forCurrentUser() throws -> Self {
    let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                               appropriateFor: nil, create: false)
    return Self(directory: support.appendingPathComponent("com.wof.naiStudio.credentials", isDirectory: true))
  }

  func read(_ name: String) throws -> String? {
    try locked(create: false, missing: nil) { dir in try entries(dir)[name] }
  }

  /// Update a whole group in one replacement. A rollback may check the values
  /// it wrote first, to avoid overwriting another process's later update.
  func update(_ changes: [String: Any], ifMatching expected: [String: Any]? = nil) throws -> [String: Any] {
    let missing = changes.mapValues { _ in NSNull() as Any }
    let create = changes.values.contains { $0 is String }
    return try locked(create: create, missing: missing) { dir in
      var values = try entries(dir)
      if let expected {
        for (key, value) in expected {
          guard value is String || value is NSNull else { throw Failure.invalidValue }
          guard values[key] == value as? String else { throw Failure.conflict }
        }
      }
      var previous: [String: Any] = [:]
      var changed = false
      for (key, value) in changes {
        guard !key.isEmpty, value is String || value is NSNull else { throw Failure.invalidValue }
        previous[key] = values[key] as Any? ?? NSNull()
        let newValue = value as? String
        if values[key] != newValue {
          values[key] = newValue
          changed = true
        }
      }
      guard changed else { return previous }
      let plain = try JSONEncoder().encode(values)
      guard plain.count + header.count + 28 <= limit else { throw Failure.invalidValue }
      let key = try masterKey(dir, create: true)
      let sealed = try AES.GCM.seal(plain, using: key, authenticating: header)
      guard let combined = sealed.combined else { throw Failure.storage }
      try replace(dir, dataFile, header + combined)
      return previous
    }
  }

  func clear() throws {
    try locked(create: false, missing: ()) { dir in
      _ = try entries(dir)
      for name in [dataFile, keyFile] {
        if unlinkat(dir, name, 0) != 0 && errno != ENOENT { throw Failure.storage }
      }
    }
  }

  /// Called only after confirmation. Recheck under the same lock as all other
  /// writers; a recovered file or an access error must never erase secrets.
  func resetIfCorrupt() throws -> Bool {
    try locked(create: false, missing: false) { dir in
      do {
        _ = try entries(dir)
        return false
      } catch Failure.corrupt {
        // A malformed header can hide an inaccessible key. Validate it
        // separately before making any change, and reuse a sound key.
        let previous: SymmetricKey?
        do { previous = try existingKey(dir) }
        catch Failure.corrupt { previous = nil }
        let key = previous ?? SymmetricKey(size: .bits256)
        let empty = try AES.GCM.seal(Data("{}".utf8), using: key, authenticating: header)
        guard let bytes = empty.combined else { throw Failure.storage }
        if previous == nil {
          try replace(dir, keyFile, key.withUnsafeBytes { Data($0) })
        }
        try replace(dir, dataFile, header + bytes)
        return true
      }
    }
  }

  private func entries(_ dir: Int32) throws -> [String: String] {
    guard let bytes = try load(dir, dataFile, max: limit) else {
      _ = try existingKey(dir)
      return [:]
    }
    guard bytes.starts(with: header) else { throw Failure.corrupt }
    let key = try masterKey(dir, create: false)
    do {
      let box = try AES.GCM.SealedBox(combined: bytes.dropFirst(header.count))
      let plain = try AES.GCM.open(box, using: key, authenticating: header)
      return try JSONDecoder().decode([String: String].self, from: plain)
    } catch { throw Failure.corrupt }
  }

  private func masterKey(_ dir: Int32, create: Bool) throws -> SymmetricKey {
    if let key = try existingKey(dir) { return key }
    guard create else { throw Failure.corrupt }
    let key = SymmetricKey(size: .bits256)
    try replace(dir, keyFile, key.withUnsafeBytes { Data($0) })
    return key
  }

  private func existingKey(_ dir: Int32) throws -> SymmetricKey? {
    guard let raw = try load(dir, keyFile, max: 32) else { return nil }
    guard raw.count == 32 else { throw Failure.corrupt }
    return SymmetricKey(data: raw)
  }

  private func locked<T>(create: Bool, missing: T, _ body: (Int32) throws -> T) throws -> T {
    if create && mkdir(directory.path, 0o700) != 0 && errno != EEXIST { throw Failure.storage }
    let dir = open(directory.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
    if dir < 0 && errno == ENOENT && !create { return missing }
    guard dir >= 0 else { throw Failure.storage }
    defer { close(dir) }
    var info = stat()
    guard fstat(dir, &info) == 0, info.st_uid == geteuid(),
          info.st_mode & 0o777 == 0o700 || fchmod(dir, 0o700) == 0 else {
      throw Failure.unsafeFile
    }
    let lock = openat(dir, ".lock", O_RDWR | O_CREAT | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK, 0o600)
    guard lock >= 0 else { throw Failure.storage }
    defer { close(lock) }
    _ = try privateFile(lock)
    while flock(lock, LOCK_EX) != 0 {
      if errno != EINTR { throw Failure.storage }
    }
    defer { flock(lock, LOCK_UN) }
    return try body(dir)
  }

  private func privateFile(_ fd: Int32) throws -> stat {
    var info = stat()
    guard fstat(fd, &info) == 0, info.st_uid == geteuid(), info.st_nlink == 1,
          info.st_mode & S_IFMT == S_IFREG,
          info.st_mode & 0o777 == 0o600 || fchmod(fd, 0o600) == 0 else { throw Failure.unsafeFile }
    return info
  }

  private func load(_ dir: Int32, _ name: String, max: Int) throws -> Data? {
    let fd = openat(dir, name, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NONBLOCK)
    if fd < 0 && errno == ENOENT { return nil }
    guard fd >= 0 else { throw Failure.storage }
    defer { close(fd) }
    let info = try privateFile(fd)
    guard info.st_size >= 0, info.st_size <= max else { throw Failure.corrupt }
    let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: false)
    let bytes = try handle.readToEnd() ?? Data()
    guard bytes.count == info.st_size else { throw Failure.corrupt }
    return bytes
  }

  private func replace(_ dir: Int32, _ name: String, _ bytes: Data) throws {
    let temp = ".new-" + UUID().uuidString
    let fd = openat(dir, temp, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
    guard fd >= 0 else { throw Failure.storage }
    defer { close(fd); unlinkat(dir, temp, 0) }
    _ = try privateFile(fd)
    let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: false)
    try handle.write(contentsOf: bytes)
    try handle.synchronize()
    guard renameat(dir, temp, dir, name) == 0 else { throw Failure.storage }
    _ = fsync(dir)
  }
}
