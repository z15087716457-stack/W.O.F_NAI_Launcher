#include "../../../windows/runner/resource_window_group.h"
#include <cassert>
#include <iostream>

int main() {
  // Keep all HWND tests off the user's interactive desktop.
  const auto previous = GetThreadDesktop(GetCurrentThreadId());
  const auto desktop = CreateDesktopW(L"WOFResourceWindowTest", nullptr, nullptr,
      0, GENERIC_ALL, nullptr);
  assert(desktop && SetThreadDesktop(desktop));
  HWND main = CreateWindowExW(0, L"STATIC", L"test-main", WS_OVERLAPPEDWINDOW,
      0, 0, 400, 300, nullptr, nullptr, nullptr, nullptr);
  HWND child = CreateWindowExW(WS_EX_TOOLWINDOW, L"STATIC", L"test-resource",
      WS_OVERLAPPEDWINDOW, 20, 20, 300, 200, nullptr, nullptr, nullptr, nullptr);
  HWND extra = CreateWindowExW(WS_EX_TOOLWINDOW, L"STATIC", L"test-extra",
      WS_OVERLAPPEDWINDOW, 30, 30, 300, 200, nullptr, nullptr, nullptr, nullptr);
  assert(main && child && extra && !GetWindow(child, GW_OWNER));
  ResourceWindowGroup group(main);
  group.windows["quick"] = {child};
  group.windows["extra"] = {extra};
  ShowWindow(main, SW_SHOW);
  ShowWindow(child, SW_SHOW);
  SetWindowPos(child, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
  assert(group.InFront(child));
  // Capture the pointer before clicking the main window activates it.
  group.BeforeMouseActivation();
  SetWindowPos(main, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
  assert(!group.InFront(child));
  group.PointerDown();
  group.Toggle("quick", true);
  assert(!IsWindowVisible(child));
  group.PointerDown();
  group.Toggle("quick", true);
  assert(IsWindowVisible(child) && group.InFront(child));
  assert(!(GetWindowLongPtr(child, GWL_EXSTYLE) & WS_EX_TOPMOST));
  // Main content click puts the unpinned window behind; the next click recalls.
  group.BeforeMouseActivation();
  SetWindowPos(main, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
  group.PointerDown();
  group.PointerDown();
  group.Toggle("quick", true);
  assert(IsWindowVisible(child) && group.InFront(child));
  group.Toggle("quick", false);
  assert(!IsWindowVisible(child));
  group.Toggle("quick", false);
  assert(IsWindowVisible(child));
  // Only the pin adds true topmost status.
  SetWindowPos(child, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
  SetWindowPos(main, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
  assert(group.InFront(child));
  SetWindowPos(child, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
  SetWindowPos(main, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
  assert(!group.InFront(child));
  // Minimize/hide restores only windows that were visible, not hidden ones.
  ShowWindow(main, SW_MINIMIZE);
  group.MainVisibilityChanged();
  assert(!IsWindowVisible(child));
  ShowWindow(main, SW_RESTORE);
  group.MainVisibilityChanged();
  assert(IsWindowVisible(child) && !IsWindowVisible(extra));
  ShowWindow(main, SW_HIDE);
  group.MainVisibilityChanged();
  assert(!IsWindowVisible(child));
  ShowWindow(main, SW_SHOW);
  group.MainVisibilityChanged();
  assert(IsWindowVisible(child));
  group.CloseAll();
  MSG message;
  while (PeekMessage(&message, nullptr, 0, 0, PM_REMOVE)) {
    TranslateMessage(&message);
    DispatchMessage(&message);
  }
  assert(!IsWindow(child) && !IsWindow(extra));
  DestroyWindow(main);
  assert(SetThreadDesktop(previous));
  CloseDesktop(desktop);
  std::cout << "Native resource window lifecycle and pointer/keyboard toggles passed\n";
}
