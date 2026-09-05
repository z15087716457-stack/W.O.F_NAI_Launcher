import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guest_session_provider.g.dart';

/// 当前进程内的游客会话状态。
///
/// 不写入任何持久化存储；应用重启后默认回到未进入游客态。
@Riverpod(keepAlive: true)
class GuestSessionNotifier extends _$GuestSessionNotifier {
  @override
  bool build() => false;

  void enterGuest() {
    state = true;
  }

  void clear() {
    state = false;
  }
}

@riverpod
bool isGuestSession(Ref ref) {
  return ref.watch(guestSessionNotifierProvider);
}
