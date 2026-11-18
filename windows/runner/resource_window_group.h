#ifndef RUNNER_RESOURCE_WINDOW_GROUP_H_
#define RUNNER_RESOURCE_WINDOW_GROUP_H_

#include <windows.h>
#include <map>
#include <set>
#include <string>

// Independent top-level windows: ownership would force them above the main
// window even with TOPMOST disabled. Keep only the application lifecycle link.
class ResourceWindowGroup {
 public:
  explicit ResourceWindowGroup(HWND main) : main_(main) {}
  struct Window { HWND hwnd; bool hidden_with_main = false; };
  std::map<std::string, Window> windows;

  bool InFront(HWND hwnd) const {
    if (!IsWindowVisible(hwnd) || IsIconic(hwnd)) return false;
    for (HWND current = GetTopWindow(nullptr); current;
         current = GetWindow(current, GW_HWNDNEXT)) {
      if (current == hwnd) return true;
      if (current == main_) return false;
    }
    return false;
  }

  void BeforeMouseActivation() {
    activation_front_ = FrontWindows();
    mouse_activation_ = true;
  }

  void PointerDown() {
    click_front_ = mouse_activation_ ? activation_front_ : FrontWindows();
    mouse_activation_ = false;
  }

  void CancelMouseActivation() { mouse_activation_ = false; }

  void Toggle(const std::string& id, bool from_pointer) {
    auto& window = windows.at(id);
    const bool front = from_pointer ? click_front_.count(window.hwnd) != 0
                                    : InFront(window.hwnd);
    if (IsWindowVisible(window.hwnd) && front) {
      window.hidden_with_main = false;
      ShowWindow(window.hwnd, SW_HIDE);
    } else {
      Focus(window.hwnd);
    }
    click_front_.clear();
  }

  static void Focus(HWND hwnd) {
    ShowWindow(hwnd, IsIconic(hwnd) ? SW_RESTORE : SW_SHOW);
    SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0,
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    SetForegroundWindow(hwnd);
  }

  void MainVisibilityChanged() {
    const bool hidden = !IsWindowVisible(main_) || IsIconic(main_);
    for (auto& [id, window] : windows) {
      if (hidden && IsWindowVisible(window.hwnd)) {
        window.hidden_with_main = true;
        ShowWindow(window.hwnd, SW_HIDE);
      } else if (!hidden && window.hidden_with_main) {
        window.hidden_with_main = false;
        ShowWindow(window.hwnd, SW_SHOWNA);
      }
    }
  }

  void CloseAll() {
    for (const auto& [id, window] : windows)
      PostMessage(window.hwnd, WM_CLOSE, 0, 0);
  }

 private:
  std::set<HWND> FrontWindows() const {
    std::set<HWND> result;
    for (const auto& [id, window] : windows)
      if (InFront(window.hwnd)) result.insert(window.hwnd);
    return result;
  }
  HWND main_;
  bool mouse_activation_ = false;
  std::set<HWND> activation_front_, click_front_;
};
#endif
