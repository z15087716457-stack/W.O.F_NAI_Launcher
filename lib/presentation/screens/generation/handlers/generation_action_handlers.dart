import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/asset_protection_guard.dart';
import '../../../wiring/generation_backend.dart';

/// 带资产保护确认的生成入口（经典布局与官网式布局共用）。
Future<void> generateWithProtection(BuildContext context, WidgetRef ref) => ref
    .read(generationBackendProvider)
    .generate(
      confirm: (cost) => AssetProtectionGuard.confirmHighAnlasCost(
        context: context,
        ref: ref,
        cost: cost,
      ),
      alive: () => context.mounted,
    );
