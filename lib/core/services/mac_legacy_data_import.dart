import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'adjacent_app_data_migration.dart';
import 'mac_legacy_data_sync.dart';
import 'mac_sync_libraries.dart';
import 'verified_directory_copy.dart';

export 'mac_legacy_data_sync.dart'
    show MacLegacyDataBackup, MacLegacyDataRequest, MacLegacyDataTask;

class MacProfileInUse implements Exception {
  @override
  String toString() => 'Another app is using this profile.';
}

/// The process owns the active data directory until exit, even when a sync
/// renames that directory. Older builds only hold individual Hive locks.
class MacProfileLock {
  RandomAccessFile? _owned;

  Future<void> acquire(Directory profile) async {
    if (_owned != null) return;
    // Different sandbox paths may point at the same physical profile.
    if (await FileSystemEntity.isLink(profile.path)) {
      profile = Directory(await profile.resolveSymbolicLinks());
    }
    final parent = await profile.parent.create(recursive: true);
    final file = File(
      p.join(parent.path, '.${p.basename(profile.path)}.running.lock'),
    );
    final handle = await file.open(mode: FileMode.append);
    try {
      try {
        await handle.lock(FileLock.exclusive);
      } on FileSystemException catch (error) {
        // Darwin fcntl returns EAGAIN or EACCES for a conflicting lock.
        if (error.osError?.errorCode == 35 || error.osError?.errorCode == 13) {
          throw MacProfileInUse();
        }
        rethrow;
      }
      if (await MacLegacyDataImport.hiveBoxesOpenElsewhere(profile)) {
        throw MacProfileInUse();
      }
      _owned = handle;
    } catch (_) {
      await handle.close();
      rethrow;
    }
  }

  Future<void> close() async {
    await _owned?.close();
    _owned = null;
  }
}

/// What one launch's previous-version data step found or did.
enum MacLegacyDataState {
  /// An earlier launch already decided; nothing was checked again.
  prepared,

  /// This version already had data of its own; nothing was copied.
  existingData,

  /// There is no previous version data; this version starts empty.
  fresh,

  /// The previous version's data was copied.
  imported,

  /// A requested sync replaced this version's data; a backup was kept.
  synced,

  /// A requested undo switched back to the data from before the last sync.
  undone,

  /// A requested redo switched back to the data from after the last sync.
  redone,

  /// The user chose to start without copying, syncing or switching back.
  skipped,

  /// The previous version is running; nothing was changed.
  legacyRunning,

  /// The step failed and was rolled back; nothing was changed.
  failed,
}

class MacLegacyDataImportResult {
  const MacLegacyDataImportResult(
    this.state, {
    this.error,
    this.task = MacLegacyDataTask.import,
  });

  final MacLegacyDataState state;
  final Object? error;
  final MacLegacyDataTask task;

  /// The user has to quit the previous version, retry or skip.
  bool get needsDecision =>
      state == MacLegacyDataState.legacyRunning ||
      state == MacLegacyDataState.failed;
}

/// What Settings shows about the previous version's data.
class MacLegacyDataStatus {
  const MacLegacyDataStatus({
    this.copiedAt,
    this.syncedAt,
    this.backups = const [],
    this.legacyRunning = false,
    this.pending,
  });

  /// The data here came from the first-launch copy at this time.
  final DateTime? copiedAt;

  /// The data here came from a sync at this time.
  final DateTime? syncedAt;

  /// Newest first; at most [MacLegacyDataSwitch.keep].
  final List<MacLegacyDataBackup> backups;
  final bool legacyRunning;

  /// A sync, undo or redo waiting for the next launch.
  final MacLegacyDataRequest? pending;
}

/// Copies the previous macOS version's settings, history and libraries on
/// first launch, and later syncs them again, or switches between the data
/// from before and after such a sync, when the user asks in Settings.
///
/// The previous version (W.O.F 1.x and the upstream NAI Launcher, bundle
/// `com.aaalice.naiLauncher`) keeps its data in its own Application Support
/// folder, which this version would otherwise never see. When this version's
/// folder is still empty, the previous folder is snapshotted, copied into a
/// staging folder and verified file by file, and only then renamed into
/// place together with the [AdjacentAppDataMigration.markerName] marker. The
/// previous folder is only read: it stays as it was and keeps working for
/// the previous version itself. Unlike the Windows migration there is no
/// compatibility link and no second backup copy.
///
/// The marker makes the first-launch copy a one-time step. A failed attempt
/// leaves neither a marker nor partial data, so it can simply be repeated.
/// A sync makes the same verified copy and then switches it in through
/// [MacLegacyDataSwitch], which keeps the replaced data as a backup.
class MacLegacyDataImport {
  MacLegacyDataImport({
    required this.legacy,
    required this.destination,
    Future<bool> Function(Directory legacy)? isLegacyRunning,
    this.preferences,
    this.beforeCommit,
    MacLegacyDataSwitch? dataSwitch,
  }) : _isLegacyRunning = isLegacyRunning ?? hiveBoxesOpenElsewhere,
       dataSwitch = dataSwitch ?? MacLegacyDataSwitch(destination);

  static const markerName = AdjacentAppDataMigration.markerName;
  static const layout = 'macos-application-support';

  final Directory legacy;
  final Directory destination;
  final Future<bool> Function(Directory legacy) _isLegacyRunning;
  final MacLegacyDataSwitch dataSwitch;

  /// Copies the previous version's preferences that live outside the data
  /// folder; returns how many were copied. Only values this version lacks are
  /// written. Runs once after a copy or a sync.
  final Future<int> Function()? preferences;

  /// Test hook: runs after copying, before the previous folder is re-checked.
  final Future<void> Function()? beforeCommit;

  String get _name => p.basename(destination.path);
  String get _stagingPrefix => '.$_name.import-';
  File get _lockFile =>
      File(p.join(destination.parent.path, '.$_name.import.lock'));
  File get _markerFile => File(p.join(destination.path, markerName));

  Future<bool> isLegacyRunning() => _isLegacyRunning(legacy);

  /// The marker an earlier launch wrote, or null before the first decision.
  Future<Map<String, Object?>?> readMarker() async {
    if (!await _markerFile.exists()) return null;
    try {
      final value = jsonDecode(await _markerFile.readAsString());
      if (value is Map<String, Object?>) return value;
    } on FormatException {
      // A damaged marker still records that a decision was made.
    }
    return const {};
  }

  Future<MacLegacyDataImportResult> prepare({
    void Function(MacLegacyDataTask task)? onCopyStarted,
  }) async {
    _checkPaths();
    // Every launch after the first one: decided, nothing to lock or check.
    final marker = await readMarker();
    if (marker != null &&
        marker['preferences'] != 'pending' &&
        !await dataSwitch.pending()) {
      return const MacLegacyDataImportResult(MacLegacyDataState.prepared);
    }
    return _locked(() => _prepare(onCopyStarted));
  }

  /// Starts without the step this launch was about to take: a requested
  /// sync, undo or redo is dropped; a first-launch copy is recorded as
  /// skipped and not offered again.
  Future<void> skip() {
    _checkPaths();
    return _locked(() async {
      if (await dataSwitch.readRequest() != null) {
        await dataSwitch.clearRequest();
        return;
      }
      if (await readMarker() != null || !await isEmptyDataFolder(destination)) {
        return;
      }
      await destination.create(recursive: true);
      await _writeMarker(destination, state: MacLegacyDataState.skipped);
    });
  }

  /// Settings: what to show, or null when there is no previous data to sync.
  Future<MacLegacyDataStatus?> status() async {
    if (await isEmptyDataFolder(legacy)) return null;
    final marker = await readMarker() ?? const {};
    final at = DateTime.tryParse('${marker['at']}')?.toLocal();
    return MacLegacyDataStatus(
      copiedAt: marker['state'] == MacLegacyDataState.imported.name ? at : null,
      syncedAt: marker['state'] == MacLegacyDataState.synced.name ? at : null,
      backups: await dataSwitch.backups(),
      legacyRunning: await isLegacyRunning(),
      pending: await dataSwitch.readRequest(),
    );
  }

  /// Settings: carried out on the next launch, before anything opens.
  Future<void> request(MacLegacyDataRequest request) =>
      dataSwitch.writeRequest(request);

  Future<void> cancelRequest() => dataSwitch.clearRequest();

  void _checkPaths() {
    final oldPath = p.normalize(legacy.absolute.path);
    final newPath = p.normalize(destination.absolute.path);
    if (p.equals(oldPath, newPath) ||
        p.isWithin(oldPath, newPath) ||
        p.isWithin(newPath, oldPath)) {
      throw const FileSystemException('Application data paths overlap');
    }
  }

  /// Two launches at the same moment (for example `open -n`) take turns; the
  /// second one finds the first one's marker. The empty lock file stays, like
  /// the Windows migration lock, so no launch can ever lock a different file.
  Future<T> _locked<T>(Future<T> Function() body) async {
    await destination.parent.create(recursive: true);
    final lock = await _lockFile.open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.blockingExclusive);
      return await body();
    } finally {
      await lock.close();
    }
  }

  Future<MacLegacyDataImportResult> _prepare(
    void Function(MacLegacyDataTask task)? onCopyStarted,
  ) async {
    // A switch a crash interrupted is completed or reversed before anything
    // else, and before its staging folder could look like a leftover.
    if (await dataSwitch.recover()) await _finishRequest();
    await _removeStaleStaging();
    if (await FileSystemEntity.type(destination.path, followLinks: false) ==
        FileSystemEntityType.link) {
      // A folder the user moved elsewhere on purpose is left alone.
      await dataSwitch.clearRequest();
      return const MacLegacyDataImportResult(MacLegacyDataState.existingData);
    }
    final request = await dataSwitch.readRequest();
    if (request?.task == MacLegacyDataTask.sync) return _sync(onCopyStarted);
    if (request?.backup case final backup?) {
      return _switchBack(request!.task, backup, onCopyStarted);
    }
    final marker = await readMarker();
    if (marker != null) {
      if (marker['preferences'] == 'pending') await _copyPreferences(marker);
      return const MacLegacyDataImportResult(MacLegacyDataState.prepared);
    }
    if (!await isEmptyDataFolder(destination)) {
      await _writeMarker(destination, state: MacLegacyDataState.existingData);
      return const MacLegacyDataImportResult(MacLegacyDataState.existingData);
    }
    if (await isEmptyDataFolder(legacy)) {
      await destination.create(recursive: true);
      await _writeMarker(destination, state: MacLegacyDataState.fresh);
      return const MacLegacyDataImportResult(MacLegacyDataState.fresh);
    }
    if (await isLegacyRunning()) {
      return const MacLegacyDataImportResult(MacLegacyDataState.legacyRunning);
    }

    onCopyStarted?.call(MacLegacyDataTask.import);
    Directory? staging;
    try {
      staging = await _copyLegacy(MacLegacyDataState.imported);
      await publishDataFolder(staging, destination);
      staging = null;
    } catch (error) {
      if (staging != null) await deleteFolderQuietly(staging);
      return _failure(error, MacLegacyDataTask.import);
    }
    await _copyPendingPreferences();
    return const MacLegacyDataImportResult(MacLegacyDataState.imported);
  }

  /// Replaces this version's data with a fresh verified copy of the previous
  /// version's; the replaced data becomes a backup and the folders only this
  /// version has move over (see [MacLegacyDataSwitch.switchTo]).
  Future<MacLegacyDataImportResult> _sync(
    void Function(MacLegacyDataTask task)? onCopyStarted,
  ) async {
    const task = MacLegacyDataTask.sync;
    if (await isEmptyDataFolder(legacy)) {
      return const MacLegacyDataImportResult(
        MacLegacyDataState.failed,
        error: FileSystemException('The previous version has no data'),
        task: task,
      );
    }
    if (await isLegacyRunning()) {
      return const MacLegacyDataImportResult(
        MacLegacyDataState.legacyRunning,
        task: task,
      );
    }
    onCopyStarted?.call(task);
    Directory? staging;
    try {
      staging = await _copyLegacy(MacLegacyDataState.synced);
      await dataSwitch.switchTo(staging, task: task, incomingIsBackup: false);
      staging = null;
    } catch (error) {
      if (staging != null && !await dataSwitch.hasSwitchJournal()) {
        await deleteFolderQuietly(staging);
      }
      return _failure(error, task);
    }
    await _finishRequest();
    await _copyPendingPreferences();
    return const MacLegacyDataImportResult(
      MacLegacyDataState.synced,
      task: task,
    );
  }

  /// Undo or redo: switches back to a backup, normally the newest one, which
  /// holds the data from before (undo) or after (redo) the last sync. The
  /// data it replaces becomes the newest backup in turn, so the two can be
  /// swapped back and forth.
  Future<MacLegacyDataImportResult> _switchBack(
    MacLegacyDataTask task,
    String backupId,
    void Function(MacLegacyDataTask task)? onCopyStarted,
  ) async {
    final backups = await dataSwitch.backups();
    final backup = backups.where((b) => b.id == backupId).firstOrNull;
    if (backup == null) {
      return MacLegacyDataImportResult(
        MacLegacyDataState.failed,
        error: const FileSystemException(
          'The backup to switch back to is missing',
        ),
        task: task,
      );
    }
    onCopyStarted?.call(task);
    try {
      await dataSwitch.switchTo(
        backup.directory,
        task: task,
        incomingIsBackup: true,
      );
    } catch (error) {
      return MacLegacyDataImportResult(
        MacLegacyDataState.failed,
        error: error,
        task: task,
      );
    }
    await _finishRequest();
    return MacLegacyDataImportResult(
      task == MacLegacyDataTask.redo
          ? MacLegacyDataState.redone
          : MacLegacyDataState.undone,
      task: task,
    );
  }

  Future<void> _finishRequest() async {
    await dataSwitch.clearRequest();
    await dataSwitch.prune();
  }

  Future<MacLegacyDataImportResult> _failure(
    Object error,
    MacLegacyDataTask task,
  ) async {
    if (error is ApplicationDataChangedException && await isLegacyRunning()) {
      return MacLegacyDataImportResult(
        MacLegacyDataState.legacyRunning,
        task: task,
      );
    }
    return MacLegacyDataImportResult(
      MacLegacyDataState.failed,
      error: error,
      task: task,
    );
  }

  /// A verified copy of the previous folder in a new staging folder next to
  /// this version's, with a marker in [state]. The previous folder must not
  /// change while it is copied.
  Future<Directory> _copyLegacy(MacLegacyDataState state) async {
    final snapshot = await snapshotDirectory(legacy, fileLinks: true);
    final staging = await destination.parent.createTemp(_stagingPrefix);
    try {
      await copySnapshot(
        legacy,
        staging,
        snapshot,
        createLink: createRelativeLink,
      );
      Set<String>? oneSidedDirectories;
      Future<void> Function()? verifyRetained;
      if (state == MacLegacyDataState.synced && await destination.exists()) {
        oneSidedDirectories = await MacLegacyDataSwitch.oneSidedDirectories(
          destination,
          staging,
        );
        verifyRetained = await (await MacSyncLibraries.scan(
          destination,
        )).copyMissingTo(staging);
      }
      await beforeCommit?.call();
      await verifySnapshot(legacy, snapshot, fileLinks: true);
      await verifyRetained?.call();
      if (state == MacLegacyDataState.synced &&
          (await isLegacyRunning() ||
              await hiveBoxesOpenElsewhere(destination))) {
        throw const ApplicationDataChangedException();
      }
      final files = snapshot.values.where((entry) => entry.isFile);
      await _writeMarker(
        staging,
        state: state,
        details: {
          if (oneSidedDirectories != null) ...{
            MacLegacyDataSwitch.carryGenerationKey: await dataSwitch
                .nextLibraryGeneration(),
            MacLegacyDataSwitch.carryRootsKey: oneSidedDirectories.toList()
              ..sort(),
          },
          'files': files.length,
          'bytes': files.fold<int>(0, (sum, entry) => sum + entry.bytes),
          'preferences': preferences == null ? 'none' : 'pending',
        },
      );
      return staging;
    } catch (_) {
      await deleteFolderQuietly(staging);
      rethrow;
    }
  }

  Future<void> _copyPendingPreferences() async {
    final marker = await readMarker();
    if (marker != null && marker['preferences'] == 'pending') {
      await _copyPreferences(marker);
    }
  }

  Future<void> _copyPreferences(Map<String, Object?> marker) async {
    final copy = preferences;
    if (copy == null) return;
    Map<String, Object?> result;
    try {
      result = {'preferences': 'imported', 'preferencesCopied': await copy()};
    } catch (error) {
      // Not retried automatically: later launches may already have changed
      // or removed preferences that a second copy would bring back.
      result = {'preferences': 'failed', 'preferencesError': '$error'};
    }
    try {
      await _markerFile.writeAsString(
        jsonEncode({...marker, ...result}),
        flush: true,
      );
    } on FileSystemException {
      // The data is in place; at worst the next launch copies the missing
      // preferences once more.
    }
  }

  Future<void> _writeMarker(
    Directory root, {
    required MacLegacyDataState state,
    Map<String, Object?> details = const {},
  }) async {
    await File(p.join(root.path, markerName)).writeAsString(
      jsonEncode({
        'schema': 1,
        'layout': layout,
        'state': state.name,
        'legacy': legacy.absolute.path,
        'at': DateTime.now().toUtc().toIso8601String(),
        ...details,
      }),
      flush: true,
    );
  }

  /// Leftovers of an attempt that was interrupted (for example the app was
  /// force quit while copying). Only real folders with this import's own
  /// prefix are removed; links are never followed.
  Future<void> _removeStaleStaging() async {
    await for (final entry in destination.parent.list(followLinks: false)) {
      if (!p.basename(entry.path).startsWith(_stagingPrefix)) continue;
      if (await FileSystemEntity.type(entry.path, followLinks: false) ==
          FileSystemEntityType.directory) {
        await deleteFolderQuietly(Directory(entry.path));
      }
    }
  }

  /// True while another process has a Hive box of [legacy] open. Hive holds
  /// an exclusive lock on `hive/<box>.lock` for as long as a box is open, and
  /// the previous version opens its boxes at startup and keeps them open
  /// until it quits. The probe takes a shared lock for an instant and never
  /// writes; lock files left behind by a crash are not locked.
  static Future<bool> hiveBoxesOpenElsewhere(Directory legacy) async {
    final hive = Directory(p.join(legacy.path, 'hive'));
    if (!await hive.exists()) return false;
    await for (final entry in hive.list(followLinks: false)) {
      if (entry is! File || p.extension(entry.path) != '.lock') continue;
      final RandomAccessFile file;
      try {
        file = await entry.open();
      } on FileSystemException catch (error) {
        if (error.osError?.errorCode == 2) continue; // Closed in the meantime.
        rethrow;
      }
      try {
        await file.lock(FileLock.shared);
        await file.unlock();
      } on FileSystemException {
        return true;
      } finally {
        await file.close();
      }
    }
    return false;
  }
}

/// Shows the copy, sync, undo or redo in the window before the app starts.
abstract interface class MacLegacyDataImportPresenter {
  void showCopying(MacLegacyDataTask task);

  /// The previous version is open; the task continues by itself once it
  /// quits.
  void showLegacyRunning(
    MacLegacyDataTask task, {
    required void Function() onSkip,
  });

  void showFailed(
    MacLegacyDataTask task,
    Object error, {
    required void Function() onRetry,
    required void Function() onSkip,
  });

  /// The data is ready; the app is about to replace this screen.
  void showStarting();
}

/// Runs [import] until it is decided. Without a [presenter] a running
/// previous version or a failed step stops startup, like the Windows
/// migration, and the next launch tries again.
Future<MacLegacyDataState> runMacLegacyDataImport(
  MacLegacyDataImport import, {
  MacLegacyDataImportPresenter? presenter,
  Duration pollInterval = const Duration(seconds: 1),
  Duration settleDelay = const Duration(seconds: 2),
}) async {
  var shown = false;
  Future<MacLegacyDataState> skip() async {
    try {
      await import.skip();
    } on FileSystemException {
      // Starting matters more than the marker. Without it the next launch
      // finds this version's own data and leaves it alone as well.
    }
    presenter?.showStarting();
    return MacLegacyDataState.skipped;
  }

  while (true) {
    MacLegacyDataImportResult result;
    try {
      result = await import.prepare(
        onCopyStarted: (task) {
          shown = true;
          presenter?.showCopying(task);
        },
      );
    } catch (error) {
      // Whatever went wrong, nothing was published: let the user decide.
      final request = await import.dataSwitch.readRequest().catchError(
        (Object _) => null,
      );
      result = MacLegacyDataImportResult(
        MacLegacyDataState.failed,
        error: error,
        task: request?.task ?? MacLegacyDataTask.import,
      );
    }
    if (!result.needsDecision) {
      if (shown) presenter?.showStarting();
      return result.state;
    }
    if (presenter == null) {
      throw result.error ??
          const FileSystemException(
            'The previous version is running; quit it and start again',
          );
    }
    shown = true;
    if (result.state == MacLegacyDataState.legacyRunning) {
      final skipped = Completer<void>();
      presenter.showLegacyRunning(
        result.task,
        onSkip: () {
          if (!skipped.isCompleted) skipped.complete();
        },
      );
      // A probe that cannot tell stops the wait; prepare() then reports it.
      Future<bool> stillRunning() =>
          import.isLegacyRunning().catchError((Object _) => false);
      while (!skipped.isCompleted && await stillRunning()) {
        await Future.any([skipped.future, Future<void>.delayed(pollInterval)]);
      }
      if (skipped.isCompleted) return skip();
      // The previous version closes its databases after its Hive boxes.
      await Future.any([skipped.future, Future<void>.delayed(settleDelay)]);
      if (skipped.isCompleted) return skip();
      continue;
    }
    final retry = Completer<bool>();
    presenter.showFailed(
      result.task,
      result.error!,
      onRetry: () {
        if (!retry.isCompleted) retry.complete(true);
      },
      onSkip: () {
        if (!retry.isCompleted) retry.complete(false);
      },
    );
    if (!await retry.future) return skip();
  }
}
