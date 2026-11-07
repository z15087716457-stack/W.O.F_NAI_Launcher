#include <windows.h>

#include <cassert>
#include <iostream>

#include "../../windows/runner/win32_window.h"

namespace {
int child_layout_requests = 0;

class SurfaceHost : public Win32Window {
 public:
  using Win32Window::SetContentWidthOverride;
};

LRESULT CALLBACK ChildProcedure(HWND window, UINT message, WPARAM wparam,
                                LPARAM lparam) {
  if (message == WM_WINDOWPOSCHANGING) ++child_layout_requests;
  return DefWindowProc(window, message, wparam, lparam);
}

void Resize(HWND window, int width, int height) {
  assert(SetWindowPos(window, nullptr, 0, 0, width, height,
                      SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE));
}

void ExpectSize(HWND child, int width, int height) {
  RECT bounds{};
  assert(GetClientRect(child, &bounds));
  assert(bounds.right == width && bounds.bottom == height);
}
}  // namespace

int main() {
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  SurfaceHost host;
  assert(host.Create(L"Hidden reveal surface fixture", {40, 40}, {600, 500}));
  HWND parent = host.GetHandle();
  assert(!IsWindowVisible(parent));

  WNDCLASS child_class{};
  child_class.lpfnWndProc = ChildProcedure;
  child_class.hInstance = GetModuleHandle(nullptr);
  child_class.lpszClassName = L"WOF_Reveal_Surface_Unit_Test";
  assert(RegisterClass(&child_class));
  HWND child = CreateWindow(child_class.lpszClassName, L"", WS_CHILD, 0, 0, 0,
                            0, parent, nullptr, child_class.hInstance, nullptr);
  assert(child && host.SetChildContent(child));

  RECT original{};
  assert(GetWindowRect(parent, &original));
  const int width = original.right - original.left;
  const int height = original.bottom - original.top;
  const RECT client = host.GetClientArea();
  constexpr int steps = 16;
  constexpr int step_width = 8;
  const int target = client.right + steps * step_width;

  bool passed = true;
  for (int run = 0; run < 2; ++run) {
    child_layout_requests = 0;
    host.SetContentWidthOverride(target);
    ExpectSize(child, target, client.bottom);
    const int prepare = child_layout_requests;
    for (int step = 1; step <= steps; ++step) {
      Resize(parent, width + step * step_width, height);
      ExpectSize(child, target, client.bottom);
    }
    const int reveal = child_layout_requests - prepare;
    host.SetContentWidthOverride(0);
    const int finish = child_layout_requests - prepare - reveal;
    ExpectSize(child, host.GetClientArea().right, client.bottom);
    std::cout << "open " << run + 1 << ": prepare=" << prepare
              << ", during=" << reveal << ", finish=" << finish << '\n';
    passed &= prepare == 1 && reveal == 0 && finish == 0;
    Resize(parent, width, height);
  }

  host.SetContentWidthOverride(target);
  Resize(parent, width + step_width, height + 24);
  ExpectSize(child, target, host.GetClientArea().bottom);
  const int before_cancel = child_layout_requests;
  host.SetContentWidthOverride(0);
  const RECT restored = host.GetClientArea();
  ExpectSize(child, restored.right, restored.bottom);
  assert(child_layout_requests == before_cancel + 1);
  std::cout << "height changes and cancellation resize the child correctly\n";

  host.Destroy();
  UnregisterClass(child_class.lpszClassName, child_class.hInstance);
  return passed ? 0 : 1;
}
