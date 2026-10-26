import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_contract.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_controller.dart';

void main() {
  const initial = ProviderSettings(
    name: 'Initial',
    baseUrl: 'http://fixture.invalid',
    protocolId: 'openaiChatCompletions',
    models: [ProviderModelSettings(id: 'model', contextWindow: 131072)],
  );
  late ProvidersController ctrl;
  late ProviderSettings latest;
  late ProvidersActions actions;
  late List<ProviderSettings> writes;
  late List<String?> keys;
  Completer<void>? gate;
  var result = ProvidersSaveResult.saved;
  ProviderItem item() => ProviderItem(id: 'p', settings: latest);
  void sync() => ctrl.sync(ProvidersViewData(providers: [item()]));
  setUp(() {
    ctrl = ProvidersController();
    latest = initial;
    writes = [];
    keys = [];
    gate = null;
    result = ProvidersSaveResult.saved;
    actions = ProvidersActions(
      onSave:
          ({
            required providerId,
            required base,
            required edited,
            apiKey,
          }) async {
            expect(base, latest);
            writes.add(edited);
            keys.add(apiKey);
            final outcome = result;
            if (outcome == ProvidersSaveResult.saved) latest = edited;
            await gate?.future;
            return outcome;
          },
    );
  });
  tearDown(() => ctrl.dispose());

  final externalChanges = <String, ProviderSettings Function(ProviderSettings)>{
    'provider timeout': (s) => s.copyWith(timeoutSeconds: 200),
    'provider header': (s) =>
        s.copyWith(headers: const [ProviderKeyValue('X-Fixture', 'external')]),
    'model context': (s) =>
        s.withModel(s.model('model')!.copyWith(contextWindow: 196608)),
    'model header': (s) => s.withModel(
      s
          .model('model')!
          .copyWith(headers: const [ProviderKeyValue('X-Fixture', 'external')]),
    ),
  };
  for (final entry in externalChanges.entries) {
    test(
      'saving a merged ${entry.key} leaves no reverse draft or second write',
      () async {
        ctrl.edit(item(), (s) => s.copyWith(name: 'User name'));
        latest = entry.value(latest);
        final expected = latest.copyWith(name: 'User name');
        await ctrl.save(item(), actions);
        sync();
        expect(latest, expected);
        expect(ctrl.display(item()), expected);
        expect(ctrl.changes(item()), 0);
        expect(ctrl.draft('p'), isNull);
        expect(await ctrl.save(item(), actions), isNull);
        expect(writes, [expected]);
      },
    );
  }

  test(
    'new edits during a save stay pending and the next save uses the new base',
    () async {
      ctrl.edit(item(), (s) => s.copyWith(name: 'First name'));
      latest = latest.copyWith(timeoutSeconds: 200);
      gate = Completer<void>();
      final saving = ctrl.save(item(), actions);
      ctrl.edit(item(), (s) => s.copyWith(name: 'Later name'));
      gate!.complete();
      await saving;
      sync();
      expect(ctrl.display(item()).name, 'Later name');
      expect(ctrl.display(item()).timeoutSeconds, 200);
      expect(ctrl.changes(item()), 1);
      gate = null;
      await ctrl.save(item(), actions);
      sync();
      expect(latest.name, 'Later name');
      expect(latest.timeoutSeconds, 200);
      expect(ctrl.draft('p'), isNull);
    },
  );

  test(
    'a deliberate edit back to the original value is kept after saving',
    () async {
      ctrl.edit(item(), (s) => s.copyWith(name: 'Submitted name'));
      gate = Completer<void>();
      final saving = ctrl.save(item(), actions);
      ctrl.edit(item(), (s) => s.copyWith(name: initial.name));
      gate!.complete();
      await saving;
      expect(latest.name, 'Submitted name');
      expect(ctrl.display(item()).name, initial.name);
      expect(ctrl.changes(item()), 1);
    },
  );

  test(
    'external values observed during an edit do not become sticky pending edits',
    () async {
      ctrl.edit(item(), (s) => s.copyWith(name: 'Submitted name'));
      latest = latest.copyWith(timeoutSeconds: 200);
      gate = Completer<void>();
      final saving = ctrl.save(item(), actions);
      latest = latest.copyWith(timeoutSeconds: 300);
      ctrl.edit(item(), (s) => s.copyWith(retryAttempts: 3));
      gate!.complete();
      await saving;
      sync();
      latest = latest.copyWith(timeoutSeconds: 400);
      expect(ctrl.display(item()).timeoutSeconds, 400);
      expect(ctrl.display(item()).retryAttempts, 3);
      expect(ctrl.changes(item()), 1);
    },
  );

  test(
    'a newly added model can be edited while an earlier save is finishing',
    () async {
      ctrl.edit(item(), (s) => s.copyWith(name: 'Submitted name'));
      gate = Completer<void>();
      final saving = ctrl.save(item(), actions);
      latest = latest.copyWith(
        models: [
          ...latest.models,
          const ProviderModelSettings(id: 'new-model', contextWindow: 100000),
        ],
      );
      ctrl.editModel(
        item(),
        'new-model',
        (m) => m.copyWith(alias: 'Pending alias'),
      );
      gate!.complete();
      await saving;
      sync();
      latest = latest.withModel(
        latest.model('new-model')!.copyWith(contextWindow: 200000),
      );
      expect(ctrl.display(item()).model('new-model')!.alias, 'Pending alias');
      expect(ctrl.display(item()).model('new-model')!.contextWindow, 200000);
      gate = null;
      await ctrl.save(item(), actions);
      expect(latest.model('new-model')!.alias, 'Pending alias');
      expect(latest.model('new-model')!.contextWindow, 200000);
    },
  );

  test(
    'a changed API key stays pending after the submitted key is saved',
    () async {
      ctrl.setApiKey(item(), 'fixture-key-one');
      gate = Completer<void>();
      final saving = ctrl.save(item(), actions);
      ctrl.setApiKey(item(), 'fixture-key-two');
      gate!.complete();
      await saving;
      expect(ctrl.draft('p')!.apiKey, 'fixture-key-two');
      gate = null;
      await ctrl.save(item(), actions);
      expect(keys, ['fixture-key-one', 'fixture-key-two']);
      expect(ctrl.draft('p'), isNull);
    },
  );

  test('an unchanged submitted API key is cleared from the draft', () async {
    ctrl.setApiKey(item(), 'fixture-key-one');
    await ctrl.save(item(), actions);
    expect(ctrl.draft('p'), isNull);
  });

  for (final outcome in [
    ProvidersSaveResult.failed,
    ProvidersSaveResult.conflict,
  ]) {
    test('$outcome retains current edits for a later retry', () async {
      ctrl.edit(item(), (s) => s.copyWith(name: 'First name'));
      result = outcome;
      gate = Completer<void>();
      final saving = ctrl.save(item(), actions);
      ctrl.edit(item(), (s) => s.copyWith(name: 'Later name'));
      gate!.complete();
      await saving;
      expect(ctrl.display(item()).name, 'Later name');
      expect(ctrl.draft('p')!.result, outcome);
      result = ProvidersSaveResult.saved;
      gate = null;
      await ctrl.save(item(), actions);
      expect(latest.name, 'Later name');
      expect(ctrl.draft('p'), isNull);
    });
  }

  test('a discarded old save cannot remove a replacement draft', () async {
    ctrl.edit(item(), (s) => s.copyWith(name: 'Submitted name'));
    gate = Completer<void>();
    final saving = ctrl.save(item(), actions);
    ctrl.discard('p');
    ctrl.edit(item(), (s) => s.copyWith(name: 'New draft'));
    gate!.complete();
    await saving;
    expect(ctrl.display(item()).name, 'New draft');
    expect(ctrl.changes(item()), 1);
  });
}
