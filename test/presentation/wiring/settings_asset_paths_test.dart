import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/utils/vibe_library_path_helper.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_edits.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_inventory.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;
  @override
  Future<String?> getApplicationSupportPath() async =>
      p.join(root, 'user-data');
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      p.join(root, 'documents');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'display, write and reset share the actual image, Vibe and PR paths',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'settings-asset-paths-',
      );
      final original = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _Paths(temp.path);
      Hive.init(p.join(temp.path, 'hive'));
      final box = await Hive.openBox(StorageKeys.settingsBox);
      VibeLibraryPathHelper.instance.clearCache();
      final container = ProviderContainer(
        overrides: [
          naiAgentWorkspaceStoreProvider.overrideWithValue(
            AgentWorkspaceStore(Directory(p.join(temp.path, 'agent-data'))),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        VibeLibraryPathHelper.instance.clearCache();
        await Hive.close();
        PathProviderPlatform.instance = original;
        await temp.delete(recursive: true);
      });
      final first = await container.read(settingsFoldersProvider.future);
      expect(
        first[SettingsFolder.images],
        p.join(temp.path, 'user-data', 'images'),
      );
      expect(
        first[SettingsFolder.vibes],
        p.join(temp.path, 'user-data', 'vibes'),
      );
      expect(
        first[SettingsFolder.preciseRefs],
        p.join(temp.path, 'user-data', 'precise_refs'),
      );
      final locations = await container.read(
        settingsStorageLocationsProvider.future,
      );
      expect(locations.folderPaths, first);
      expect(
        locations.imageSaveDirectory,
        p.join(temp.path, 'user-data', 'images', 'Uncategorized'),
      );
      final store = container.read(settingsValueStoreProvider);
      final custom = p.join(temp.path, 'chosen-pr');
      await store.write(SettingKey.preciseRefPath, custom);
      expect(box.get(StorageKeys.preciseRefLibrarySavePath), custom);
      expect(
        (await container.read(
          settingsFoldersProvider.future,
        ))[SettingsFolder.preciseRefs],
        custom,
      );
      await store.write(SettingKey.preciseRefPath, null);
      expect(box.get(StorageKeys.preciseRefLibrarySavePath), isNull);
      expect(
        (await container.read(
          settingsFoldersProvider.future,
        ))[SettingsFolder.preciseRefs],
        first[SettingsFolder.preciseRefs],
      );
      final vibes = p.join(temp.path, 'chosen-vibes');
      await store.write(SettingKey.vibePath, vibes);
      expect(
        (await container.read(
          settingsFoldersProvider.future,
        ))[SettingsFolder.vibes],
        vibes,
      );
      await store.write(SettingKey.vibePath, null);
      expect(
        (await container.read(
          settingsFoldersProvider.future,
        ))[SettingsFolder.vibes],
        first[SettingsFolder.vibes],
      );
      expect(container.exists(naiAgentControllerProvider), isFalse);
    },
  );
}
