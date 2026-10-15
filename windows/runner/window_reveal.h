#ifndef RUNNER_WINDOW_REVEAL_H_
#define RUNNER_WINDOW_REVEAL_H_

#include <windows.h>
#include <functional>
#include <memory>
#include <optional>

// Paint the complete Flutter surface before exposing its new right edge.
// During the reveal, only the parent HWND changes size; the child surface stays
// at its final size and is clipped by its parent, avoiding per-frame relayout.
class WindowReveal {
 public:
  using AfterFrame = std::function<void(std::function<void()>)>;
  WindowReveal(HWND window, std::function<void(int)> surface_width,
               AfterFrame after_frame);
  ~WindowReveal();
  bool Start(const RECT& expected, int target_width, int duration_ms,
             std::function<void(bool)> complete);
  void Cancel();
  std::optional<LRESULT> HandleMessage(UINT message, WPARAM wparam);

 private:
  void Finish(bool completed);
  void Tick();
  HWND window_;
  std::function<void(int)> surface_width_;
  AfterFrame after_frame_;
  std::shared_ptr<WindowReveal*> lifetime_;
  std::function<void(bool)> complete_;
  RECT original_{}, last_{};
  int target_width_ = 0, duration_ms_ = 0;
  ULONGLONG started_ = 0, prepared_ = 0;
  UINT_PTR revision_ = 0;
  bool waiting_ = false;
};

#endif
