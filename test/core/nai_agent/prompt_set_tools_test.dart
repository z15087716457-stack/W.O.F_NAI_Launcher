import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/prompt_set_tools.dart';
import 'package:nai_launcher/core/utils/prompt_icon_catalog.dart';

Map<String, dynamic> promptSetInput() => {
  'action': 'create',
  'kind': '分镜卡',
  'kind_icon': 'film',
  'title': 'Rain',
  'unit': '幕',
  'ordered': true,
  'shared': {
    'main': 'best quality, 1girl',
    'characters': ['silver hair'],
    'negative': 'lowres',
  },
  'items': [
    {
      'icon': 'rain',
      'title': 'Rain',
      'main': 'street',
      'characters': ['running'],
    },
    {
      'icon': 'coffee',
      'title': 'Cafe',
      'characters': ['holding mug'],
    },
  ],
};
Map<String, dynamic> clone(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
void main() {
  late Directory dir;
  late NaiAgentPromptSets sets;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('prompt-sets-');
    sets = NaiAgentPromptSets(dir, chatId: 'chat');
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });
  test(
    'all additional stable icons validate and persist including hidden NSFW keys',
    () async {
      for (final icon in additionalPromptIconNames) {
        final input = promptSetInput();
        input['kind_icon'] = icon;
        input['items'][0]['icon'] = icon;
        final result =
            (await sets.execute(input, NaiAgentCancellation()))['details']
                as Map;
        final stored = (await sets.read(result['set_id'] as String))!;
        expect(stored['kind_icon'], icon);
        expect(stored['items'][0]['icon'], icon);
      }
    },
  );
  test(
    'storage round trip, read strips paths, update changed indexes and preserved images',
    () async {
      final created =
          (await sets.execute(
                promptSetInput(),
                NaiAgentCancellation(),
              ))['details']
              as Map;
      final id = created['set_id'] as String;
      expect(id, matches(r'^[a-f0-9]{12}$'));
      expect(created['revision'], 1);
      await sets.appendImages(id, 0, [
        {'path': 'outputs/rain.png', 'image_id': 'image', 'created_at': 'now'},
      ]);
      final updated = promptSetInput()
        ..addAll({'action': 'update', 'set_id': id, 'expected_revision': 1});
      (updated['items'] as List)[1]['note'] = 'New note';
      (updated['items'] as List).add({'icon': 'sun', 'title': 'Morning'});
      final result =
          (await sets.execute(updated, NaiAgentCancellation()))['details']
              as Map;
      expect(result['changed_items'], [1, 2]);
      final restarted = NaiAgentPromptSets(dir);
      expect((await restarted.read(id))!['images']['0'], hasLength(1));
      final read =
          (await restarted.execute({
                'action': 'read',
                'set_id': id,
              }, NaiAgentCancellation()))['details']
              as Map;
      expect(read['images'], {'0': 1, '1': 0, '2': 0});
      expect(jsonEncode(read), isNot(contains('outputs/rain.png')));
      expect(File('${dir.path}/prompt-sets/$id.json').existsSync(), isTrue);
      expect(Directory('${dir.path}/prompt-sets').listSync(), hasLength(1));
    },
  );
  test(
    'positions validate, persist/read and mark own/shared effective changes',
    () async {
      final input = promptSetInput();
      input['shared']['characters'] = ['silver hair', 'brown hair'];
      input['shared']['positions'] = [
        null,
        {'x': 1, 'y': 0},
      ];
      input['items'][0]['positions'] = [
        {'x': 0, 'y': 1},
        null,
      ];
      final created =
          (await sets.execute(input, NaiAgentCancellation()))['details'] as Map;
      final id = created['set_id'] as String;
      final restarted = NaiAgentPromptSets(dir);
      final stored = (await restarted.read(id))!;
      expect(stored.containsKey('shared'), isFalse);
      expect(stored['items'][0]['positions'], [
        {'x': 0.0, 'y': 1.0},
        {'x': 1.0, 'y': 0.0},
      ]);
      expect(stored['items'][1]['positions'], [
        null,
        {'x': 1.0, 'y': 0.0},
      ]);
      final read =
          (await restarted.execute({
                'action': 'read',
                'set_id': id,
              }, NaiAgentCancellation()))['details']
              as Map;
      expect(read['shared'], stored['shared']);
      expect(read['items'], stored['items']);
      final update = clone(input)
        ..addAll({'action': 'update', 'set_id': id, 'expected_revision': 1});
      update['items'][0]['positions'][0] = {'x': .2, 'y': .3};
      var result =
          (await sets.execute(update, NaiAgentCancellation()))['details']
              as Map;
      expect(result['changed_items'], [0]);
      update['expected_revision'] = 2;
      update['shared']['positions'][0] = {'x': .8, 'y': .4};
      result =
          (await sets.execute(update, NaiAgentCancellation()))['details']
              as Map;
      expect(result['changed_items'], [
        1,
      ]); // Item 0 overrides this shared entry.
      update['expected_revision'] = 3;
      update['shared']['positions'][1] = {'x': .5, 'y': .5};
      result =
          (await sets.execute(update, NaiAgentCancellation()))['details']
              as Map;
      expect(result['changed_items'], [
        0,
        1,
      ]); // Explicit item null inherits too.
    },
  );
  test(
    'loading a historical file materializes lanes without rewriting it',
    () async {
      const id = 'abcdef123456';
      final stored = {
        ...NaiAgentPromptSets.validate(promptSetInput()),
        'set_id': id,
        'revision': 1,
        'images': {},
        'changed_items': [],
      };
      final folder = Directory('${dir.path}/prompt-sets')..createSync();
      final file = File('${folder.path}/$id.json')
        ..writeAsStringSync(jsonEncode(stored));
      final original = file.readAsStringSync();
      final set = (await sets.read(id))!;
      expect(set.containsKey('shared'), false);
      expect(set['items'][0]['characters'], ['silver hair, running']);
      expect(set['items'][1]['negative'], 'lowres');
      expect(file.readAsStringSync(), original);
      final card = {
        ...Map<String, dynamic>.from(set['items'][1]),
        'characters': <String>[],
      };
      await sets.execute({
        'action': 'update',
        'set_id': id,
        'expected_revision': 1,
        'card': card,
      }, NaiAgentCancellation());
      final migrated = jsonDecode(file.readAsStringSync());
      expect(migrated.containsKey('shared'), false);
      expect(migrated['items'][0], set['items'][0]);
    },
  );
  test(
    'single-card edits and image history follow stable IDs on reorder',
    () async {
      final source = independentPromptSet(
        NaiAgentPromptSets.validate(promptSetInput()),
      );
      final cards = source['items'] as List;
      final first = {
        ...Map<String, dynamic>.from(cards.first as Map),
        'generation': {'seed': 0, 'steps': 28},
      };
      final token = NaiAgentCancellation();
      final created = (await sets.execute({
        ...source,
        'action': 'create',
        'items': [first],
      }, token))['details'];
      final id = created['set_id'] as String;
      await sets.appendImages(id, 0, [
        {'path': 'old.png', 'created_at': 'then'},
      ]);
      await sets.execute({
        ...source,
        'action': 'update',
        'set_id': id,
        'expected_revision': 1,
        'items': [cards.last, first],
      }, token);
      final edit = {...first, 'characters': <String>[], 'main': 'empty street'};
      await sets.execute({
        'action': 'update',
        'set_id': id,
        'expected_revision': 2,
        'card': edit,
      }, token);
      await sets.appendImages(id, 0, [
        {'path': 'late.png', 'created_at': 'now'},
      ], cardId: first['card_id']);
      final value = (await NaiAgentPromptSets(dir).read(id))!;
      expect(value['items'][0], cards.last);
      expect(value['items'][1]['characters'], isEmpty);
      expect(value['changed_items'], [1]);
      expect(value['images']['1'].length, 2);
      expect(value['items'][1]['generation']['seed'], 0);
      expect(value['images']['0'], isNull);
    },
  );
  test(
    'positions reject non-finite/range/shape and index overflow on both scopes',
    () {
      for (final bad in [
        null,
        {},
        'left',
        [0],
        [
          [.2, .3],
        ],
        [
          {'x': .2},
        ],
        [
          {'x': .2, 'y': .3, 'z': 0},
        ],
        [
          {'x': '0', 'y': 0},
        ],
        [
          {'x': -.01, 'y': 0},
        ],
        [
          {'x': 0, 'y': 1.01},
        ],
        [
          {'x': double.nan, 'y': 0},
        ],
        [
          {'x': 0, 'y': double.infinity},
        ],
        [null, null],
      ]) {
        for (final shared in [false, true]) {
          final input = clone(promptSetInput());
          final Map target = shared
              ? input['shared'] as Map
              : input['items'][0] as Map;
          target['positions'] = bad;
          expect(
            () => NaiAgentPromptSets.validate(input),
            throwsA(isA<NaiAgentToolError>()),
            reason: '$shared: $bad',
          );
        }
      }
    },
  );
  test(
    'invalid icons, sizes, every string bound and character alignment rejected',
    () async {
      final invalid = <Map<String, dynamic>>[
        promptSetInput()..['kind_icon'] = 'unknown',
        promptSetInput()
          ..['items'] = [
            {'icon': 'rain', 'title': 'one'},
          ],
        promptSetInput()
          ..['items'] = List.generate(
            25,
            (_) => {'icon': 'rain', 'title': 'x'},
          ),
        promptSetInput()..['shared'] = {'characters': <String>[]},
        for (final (key, max) in [('kind', 24), ('title', 60), ('unit', 8)])
          promptSetInput()..[key] = 'x' * (max + 1),
        for (final (key, max) in [('main', 2000), ('negative', 2000)])
          promptSetInput()..['shared'] = {key: 'x' * (max + 1)},
        promptSetInput()
          ..['shared'] = {
            'characters': ['x' * 1001],
          },
      ];
      for (final (key, max) in [('title', 40), ('note', 240), ('main', 1000)]) {
        final value = promptSetInput();
        (value['items'] as List)[0][key] = 'x' * (max + 1);
        invalid.add(value);
      }
      final badIcon = promptSetInput();
      badIcon['items'][0]['icon'] = 'unknown';
      invalid.add(badIcon);
      final tooMany = promptSetInput();
      tooMany['items'][0]['characters'] = ['a', 'b'];
      invalid.add(tooMany);
      final longChar = promptSetInput();
      longChar['items'][0]['characters'] = ['x' * 601];
      invalid.add(longChar);
      for (final value in invalid) {
        await expectLater(
          sets.execute(value, NaiAgentCancellation()),
          throwsA(isA<NaiAgentToolError>()),
        );
      }
    },
  );
  test(
    'update requires exact integer revision; concurrent updates conflict atomically',
    () async {
      final created =
          (await sets.execute(
                promptSetInput(),
                NaiAgentCancellation(),
              ))['details']
              as Map;
      final update = promptSetInput()
        ..addAll({'action': 'update', 'set_id': created['set_id']});
      for (final revision in [null, 0, 2, 1.0]) {
        update['expected_revision'] = revision;
        await expectLater(
          sets.execute(update, NaiAgentCancellation()),
          throwsA(
            isA<NaiAgentToolError>().having(
              (e) => e.code,
              'code',
              'revision_conflict',
            ),
          ),
        );
      }
      update['expected_revision'] = 1;
      final outcomes = await Future.wait([
        for (var i = 0; i < 2; i++)
          sets
              .execute(update, NaiAgentCancellation())
              .then((_) => true, onError: (Object _) => false),
      ]);
      expect(outcomes, [true, false]);
    },
  );
  test(
    'unknown id and traversal rejected on every read/update/image append',
    () async {
      await expectLater(
        sets.execute({
          'action': 'read',
          'set_id': '012345abcdef',
        }, NaiAgentCancellation()),
        throwsA(isA<NaiAgentToolError>()),
      );
      for (final id in [
        '../outside',
        '012345abcdef/../x',
        'ABCDEF012345',
        '/outside',
      ]) {
        await expectLater(sets.read(id), throwsA(isA<NaiAgentToolError>()));
        await expectLater(
          sets.appendImages(id, 0, []),
          throwsA(isA<NaiAgentToolError>()),
        );
      }
    },
  );
  test('merge trims and skips empty tags without double commas', () {
    expect(mergeAgentPrompt(' a, b, ,', ' , c, '), 'a, b, c');
    expect(mergeAgentPrompt('', ''), '');
  });
}
