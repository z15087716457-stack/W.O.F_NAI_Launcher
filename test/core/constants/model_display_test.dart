import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/model_display.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';

void main() {
  group('ModelDisplay', () {
    test('short names mirror the official capsule labels', () {
      expect(
        ModelDisplay.shortNameOf(ImageModels.animeDiffusionV5Curated),
        'V5 Curated',
      );
      expect(
        ModelDisplay.shortNameOf(ImageModels.animeDiffusionV5Full),
        'V5 Full',
      );
      expect(
        ModelDisplay.shortNameOf(ImageModels.animeDiffusionV45Full),
        'V4.5 Full',
      );
      expect(
        ModelDisplay.shortNameOf(ImageModels.animeDiffusionV4Curated),
        'V4 Curated',
      );
    });

    test('unregistered models fall back to display name then raw id', () {
      expect(
        ModelDisplay.shortNameOf(ImageModels.animeDiffusionV5FullInpainting),
        isNotEmpty,
      );
      expect(ModelDisplay.shortNameOf('unknown-model'), 'unknown-model');
    });

    test('groups split V5 models into NEW and the rest into LEGACY', () {
      for (final m in const [
        ImageModels.animeDiffusionV5Curated,
        ImageModels.animeDiffusionV5Full,
      ]) {
        expect(ModelDisplay.groupOf(m), ModelListGroup.newer);
      }
      for (final m in const [
        ImageModels.animeDiffusionV45Full,
        ImageModels.animeDiffusionV45Curated,
        ImageModels.animeDiffusionV4Full,
        ImageModels.animeDiffusionV4Curated,
        ImageModels.animeDiffusionV3,
        ImageModels.furryDiffusionV3,
        ImageModels.furryDiffusion,
      ]) {
        expect(ModelDisplay.groupOf(m), ModelListGroup.legacy);
      }
    });

    test('only the newest curated model carries the NEW badge', () {
      expect(
        ModelDisplay.isNewModel(ImageModels.animeDiffusionV5Curated),
        isTrue,
      );
      expect(
        ModelDisplay.isNewModel(ImageModels.animeDiffusionV5Full),
        isFalse,
      );
    });

    test('descriptions come from l10n and only exist for registered entries',
        () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(
        ModelDisplay.descriptionOf(l10n, ImageModels.animeDiffusionV5Curated),
        l10n.generation_modelDesc_v5Curated,
      );
      expect(
        ModelDisplay.descriptionOf(l10n, ImageModels.animeDiffusionV5Full),
        l10n.generation_modelDesc_v5Full,
      );
      // V3 / Furry 系列无简介
      expect(
        ModelDisplay.descriptionOf(l10n, ImageModels.animeDiffusionV3),
        isNull,
      );
    });
  });
}
