import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

class ExploreCandidateHoverInfo {
  const ExploreCandidateHoverInfo({
    required this.candidateId,
    required this.anchorContext,
    required this.badgeText,
    this.filePath,
    this.imageBuilder,
  });

  final String candidateId;

  /// 锚点 context（取缩略图全局矩形定位浮层）。
  final BuildContext anchorContext;

  /// 角标文案（'#序号 · 第N轮'，调用方按现成 l10n 拼好）。
  final String badgeText;

  /// 预览图文件路径；null = 无图项（不弹浮层）。
  final String? filePath;

  /// 图片构建器（可注入，测试规避 fakeAsync 真文件 I/O）。
  final Widget Function(BuildContext context, String filePath)? imageBuilder;

  bool get hasImage => filePath != null;
}
