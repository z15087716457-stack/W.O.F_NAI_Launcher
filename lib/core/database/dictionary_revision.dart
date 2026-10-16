import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Successful revisions only, never download progress or failure.
final dictionaryRevisionProvider = StateProvider<int>((ref) => 0);
