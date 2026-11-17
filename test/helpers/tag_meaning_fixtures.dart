import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/tag_expansion/tag_semantics_repository.dart';

TagSemanticProfile meaningFixture(
  String tag, {
  String? summary,
  List<String>? synonyms,
}) => TagSemanticProfile(
  tag: tag,
  coreZh: '内衣',
  summaryZh: summary ?? '穿在衣服下面的衣物，通常直接接触皮肤。',
  synonymsZh: synonyms ?? const ['内衣', '贴身衣物', '内裤'],
  sourceCategory: 0,
  sourcePostCount: 100,
);

final tagMeaningBoundary = GlobalKey();

Future<void> captureTagMeaning(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_TAG_MEANING'] != '1') return;
  await tester.pump();
  await tester.runAsync(() async {
    final render =
        tagMeaningBoundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await render.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('.dart_tool/tag-meaning-20261116/captures')
      ..createSync(recursive: true);
    File(
      '${folder.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
