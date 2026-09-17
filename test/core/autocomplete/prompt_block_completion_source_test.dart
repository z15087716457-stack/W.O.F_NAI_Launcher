import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/prompt_block_completion_source.dart';

void main() {
  test('returns library candidates only for alias queries', () async {
    var calls = 0;
    late int requestedLimit;
    final source = PromptBlockCompletionSource(
      searchEntries: (query, limit) {
        calls++;
        requestedLimit = limit;
        expect(query, '角色');
        return const [
          LibraryCompletionEntry(
            name: '角色立绘',
            contentPreview: '角色提示词内容',
            useCount: 12,
          ),
        ];
      },
    );

    final normal = await source.search(_query());
    final aliases = await source.search(
      _query(token: '角色', kind: CompletionQueryKind.libraryAlias),
    );

    expect(normal, isEmpty);
    expect(calls, 1);
    expect(requestedLimit, PromptBlockCompletionSource.maxResults);
    expect(aliases.single.canonicalTag, '角色立绘');
    expect(aliases.single.translation, '角色提示词内容');
    expect(aliases.single.postCount, 12);
    expect(aliases.single.category, TagCategory.library);
    expect(aliases.single.sources, {CompletionSourceKind.library});
    expect(aliases.single.matchKind, CompletionMatchKind.aliasPrefix);
  });
}

CompletionQuery _query({
  String token = 'tag',
  CompletionQueryKind kind = CompletionQueryKind.tag,
}) => CompletionQuery(
  fullText: token,
  cursorPosition: token.length,
  token: token,
  replacementRange: TextReplacementRange(start: 0, end: token.length),
  existingTags: const {},
  limit: CompletionResultLimits.all,
  locale: 'zh-CN',
  kind: kind,
);
