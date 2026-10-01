import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Open the accounts section even when settings already has another section
/// selected. The settings screen retains its unsaved-model confirmation.
final settingsAccountOpenRequestProvider = StateProvider<int>((ref) => 0);
