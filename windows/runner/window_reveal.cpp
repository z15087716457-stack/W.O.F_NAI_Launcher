#include "window_reveal.h"

#include <algorithm>
#include <cmath>
#include <utility>

namespace {
constexpr UINT kPainted = WM_APP + 0x431;
constexpr UINT_PTR kTimer = 0x574f46;
bool Near(const RECT& a, const RECT& b) {
  return std::abs(a.left - b.left) <= 2 &&
         std::abs(a.top - b.top) <= 2 &&
         std::abs(a.right - b.right) <= 2 &&
         std::abs(a.bottom - b.bottom) <= 2;
}
}

WindowReveal::WindowReveal(HWND window, std::function<void(int)> surface_width,
                           AfterFrame after_frame)
    : window_(window), surface_width_(std::move(surface_width)),
      after_frame_(std::move(after_frame)),
      lifetime_(std::make_shared<WindowReveal*>(this)) {}

WindowReveal::~WindowReveal() {
  *lifetime_ = nullptr;
  Cancel();
}

bool WindowReveal::Start(const RECT& expected, int target_width,
                         int duration_ms, std::function<void(bool)> complete) {
  if (complete_ || !IsWindow(window_) || IsZoomed(window_) ||
      IsIconic(window_) || !GetWindowRect(window_, &original_) ||
      !Near(original_, expected) || target_width <= original_.right - original_.left ||
      duration_ms < 0 || duration_ms > 1000) return false;
  MONITORINFO monitor{sizeof(MONITORINFO)};
  if (!GetMonitorInfo(MonitorFromWindow(window_, MONITOR_DEFAULTTONEAREST), &monitor) ||
      original_.left + target_width > monitor.rcWork.right - 8) return false;
  RECT client{};
  if (!GetClientRect(window_, &client)) return false;
  const int target_client = client.right + target_width -
                            (original_.right - original_.left);
  if (target_client <= 0) return false;
  target_width_ = target_width;
  duration_ms_ = duration_ms;
  last_ = original_;
  complete_ = std::move(complete);
  waiting_ = true;
  prepared_ = GetTickCount64();
  const auto revision = ++revision_;
  if (!SetTimer(window_, kTimer, 16, nullptr)) {
    Finish(false);
    return true;
  }
  // Metrics change exactly once, while the newly allocated region is hidden.
  surface_width_(target_client);
  const auto lifetime = lifetime_;
  after_frame_([lifetime, revision]() {
    if (auto* owner = *lifetime) {
      PostMessage(owner->window_, kPainted, revision, 0);
    }
  });
  return true;
}

void WindowReveal::Cancel() { Finish(false); }

void WindowReveal::Finish(bool completed) {
  if (!complete_) return;
  KillTimer(window_, kTimer);
  waiting_ = false;
  ++revision_;
  surface_width_(0);
  auto complete = std::move(complete_);
  complete(completed);
}

void WindowReveal::Tick() {
  if (!complete_) return;
  RECT current{};
  if (!GetWindowRect(window_, &current) || !Near(current, last_) ||
      IsZoomed(window_) || IsIconic(window_)) {
    Finish(false);
    return;
  }
  if (waiting_) {
    if (GetTickCount64() - prepared_ > 1500) Finish(false);
    return;
  }
  const double t = duration_ms_ == 0 ? 1.0 : std::min(
      1.0, static_cast<double>(GetTickCount64() - started_) / duration_ms_);
  const double eased = 1.0 - std::pow(1.0 - t, 3);
  const int start_width = original_.right - original_.left;
  const int width = start_width + static_cast<int>(std::lround(
      (target_width_ - start_width) * eased));
  if (width != last_.right - last_.left) {
    if (!SetWindowPos(window_, nullptr, 0, 0, width,
                      original_.bottom - original_.top,
                      SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE) ||
        !GetWindowRect(window_, &last_)) {
      Finish(false);
      return;
    }
  }
  if (t >= 1.0) Finish(true);
}

std::optional<LRESULT> WindowReveal::HandleMessage(UINT message, WPARAM wparam) {
  if (message == kPainted) {
    if (complete_ && waiting_ && wparam == revision_) {
      waiting_ = false;
      started_ = GetTickCount64();
      Tick();
    }
    return 0;
  }
  if (message == WM_TIMER && wparam == kTimer) {
    Tick();
    return 0;
  }
  // Hand the window back immediately when the person takes over its geometry.
  if (message == WM_ENTERSIZEMOVE || message == WM_DPICHANGED ||
      message == WM_DESTROY) Cancel();
  return std::nullopt;
}
