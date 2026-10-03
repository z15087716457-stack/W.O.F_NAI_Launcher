/// 数据库服务层导出文件
///
/// 提供基于 DataSource 的高级服务接口，用于共现推荐和标签补全。
///
/// 使用示例：
/// ```dart
/// import 'package:nai_launcher/core/database/services/services.dart';
///
/// // 获取服务实例（通过 Riverpod）
/// final cooccurrenceService = ref.watch(cooccurrenceServiceProvider);
/// final completionService = ref.watch(completionServiceProvider);
///
/// // 使用共现服务
/// final recommendations = await cooccurrenceService.getRecommendations(['1girl']);
///
/// // 使用补全服务
/// final completions = await completionService.complete('long_');
/// ```
library;

export 'completion_service.dart' show CompletionService, CompletionResult;

export 'cooccurrence_service.dart' show CooccurrenceService, Recommendation;

export 'service_providers.dart'
    show
        danbooruTagDataSourceProvider,
        cooccurrenceDataSourceProvider,
        cooccurrenceServiceProvider,
        completionServiceProvider;
