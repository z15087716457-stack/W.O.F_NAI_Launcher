import 'package:flutter/material.dart';

/// Workspace and startup screens retain the original 100% type size.
/// Settings apply their independent comfortable baseline inside this scope.
class WorkspaceTypographyScope extends StatelessWidget {
  const WorkspaceTypographyScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
    child: child,
  );
}
