import 'package:flutter/material.dart';
import 'studio_text_coverage.dart';

/// Workspace and startup screens keep the prototype's 100% type size.
/// Settings apply their independent user-selected scaling inside this scope.
class WorkspaceTypographyScope extends StatelessWidget {
  const WorkspaceTypographyScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
    child: StudioTextCoverageRegion(child: child),
  );
}
