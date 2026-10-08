import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/data/models/precise_ref/precise_ref_library_entry.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/precise_ref_library/widgets/precise_ref_card.dart';

class _FakeStorage extends PreciseRefLibraryStorageService {
  @override
  Future<Uint8List?> getDisplayThumbnail(String id) async => null;
}

void main() {
  final entry = PreciseRefLibraryEntry(
    id: 'entry-1',
    name: '银发少女',
    imagePath: r'C:\refs\entry-1.png',
    typeIndex: PreciseRefType.character.index,
    strength: 1.0,
    fidelity: 0.85,
    isFavorite: true,
    createdAt: DateTime(2026, 8, 1),
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    VoidCallback? onSendToPreciseRef,
    VoidCallback? onToggleFavorite,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preciseRefLibraryStorageServiceProvider.overrideWithValue(
            _FakeStorage(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 250,
                child: PreciseRefCard(
                  entry: entry,
                  onSendToPreciseRef: onSendToPreciseRef,
                  onToggleFavorite: onToggleFavorite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('显示名称、参数与类型徽标', (tester) async {
    await pumpCard(tester);

    expect(find.text('银发少女'), findsOneWidget);
    expect(find.text('强度 1.00  保真 0.85'), findsOneWidget);
    // 角色类型徽标（zh 显示“角色”）
    expect(find.text('角色'), findsOneWidget);
    // 收藏态显示实心星标
    expect(find.byKey(const Key('library-card-favorite')), findsOneWidget);
  });

  testWidgets('单击卡片不发送，星标与明确发送按钮可用', (tester) async {
    var sendCount = 0;
    var favoriteCount = 0;
    await pumpCard(
      tester,
      onSendToPreciseRef: () => sendCount++,
      onToggleFavorite: () => favoriteCount++,
    );

    await tester.tap(find.byKey(const Key('library-card-favorite')));
    expect(favoriteCount, 1);

    await tester.tap(find.text('银发少女'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(sendCount, 0);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(PreciseRefCard)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('发送到精准参考'));
    expect(sendCount, 1);
    await mouse.removePointer();
  });
}
