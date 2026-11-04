/// Whether the actual request price depends on an Opus quota that needs checking.
enum OpusPriceCheck {
  none,
  low,
  exhausted,
  recentlyCheckedExhausted;

  bool needsRefresh({bool balanceWouldBlock = false, bool checkLow = true}) {
    return switch (this) {
      OpusPriceCheck.none => balanceWouldBlock,
      OpusPriceCheck.low => checkLow || balanceWouldBlock,
      OpusPriceCheck.exhausted => true,
      OpusPriceCheck.recentlyCheckedExhausted => false,
    };
  }
}
