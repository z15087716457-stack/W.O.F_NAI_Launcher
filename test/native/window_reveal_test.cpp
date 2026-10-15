#include <windows.h>
#include <cassert>
#include <functional>
#include <iostream>
#include <vector>
#include "../../windows/runner/window_reveal.h"

namespace {
WindowReveal* reveal = nullptr;
LRESULT CALLBACK Procedure(HWND window, UINT message, WPARAM wp, LPARAM lp) {
  if (reveal) {
    if (auto result = reveal->HandleMessage(message, wp)) return *result;
  }
  return DefWindowProc(window, message, wp, lp);
}
RECT Bounds(HWND window) { RECT rect{}; assert(GetWindowRect(window, &rect)); return rect; }
void Pump(int milliseconds) {
  const auto end = GetTickCount64() + milliseconds;
  do {
    MSG message{};
    while (PeekMessage(&message, nullptr, 0, 0, PM_REMOVE)) {
      TranslateMessage(&message); DispatchMessage(&message);
    }
    Sleep(2);
  } while (GetTickCount64() < end);
}
}

int main() {
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  WNDCLASS cls{};
  cls.lpfnWndProc = Procedure;
  cls.hInstance = GetModuleHandle(nullptr);
  cls.lpszClassName = L"WOF_Reveal_Unit_Test";
  assert(RegisterClass(&cls));
  HWND window = CreateWindow(cls.lpszClassName, L"Hidden native reveal fixture",
      WS_OVERLAPPEDWINDOW, 40, 40, 600, 500, nullptr, nullptr, cls.hInstance, nullptr);
  assert(window && !IsWindowVisible(window));
  std::vector<int> widths;
  std::function<void()> painted;
  int callbacks = 0;
  bool completed = false;
  {
    WindowReveal fixture(window, [&](int width) { widths.push_back(width); },
                         [&](auto callback) { painted = std::move(callback); });
    reveal = &fixture;
    const auto initial = Bounds(window);
    auto complete = [&](bool value) { callbacks++; completed = value; };
    assert(fixture.Start(initial, 760, 96, complete));
    Pump(30);
    assert(Bounds(window).right == initial.right && callbacks == 0);
    assert(widths.size() == 1 && widths.front() > 600);
    painted();
    std::vector<LONG> frames;
    for (int i = 0; i < 100 && callbacks == 0; ++i) {
      Pump(4); frames.push_back(Bounds(window).right);
    }
    assert(callbacks == 1 && completed);
    assert(Bounds(window).right - Bounds(window).left == 760);
    assert(widths.size() == 2 && widths.back() == 0);
    for (size_t i = 1; i < frames.size(); ++i) assert(frames[i] >= frames[i-1]);
    assert(Bounds(window).left == initial.left && Bounds(window).top == initial.top);
    std::cout << "PASS: paints before exposure; monotonic right edge; one surface allocation\n";

    callbacks = 0; widths.clear();
    auto manual = Bounds(window);
    assert(fixture.Start(manual, 880, 96, complete));
    SendMessage(window, WM_ENTERSIZEMOVE, 0, 0);
    assert(callbacks == 1 && !completed && widths.back() == 0);
    SetWindowPos(window, nullptr, manual.left + 20, manual.top, 0, 0,
                 SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
    const auto after = Bounds(window);
    painted(); Pump(120);
    assert(Bounds(window).left == after.left && Bounds(window).right == after.right);
    assert(callbacks == 1);
    std::cout << "PASS: user takeover cancels; stale frame cannot move the window\n";

    callbacks = 0; widths.clear();
    auto wrong = Bounds(window); wrong.left -= 20;
    assert(!fixture.Start(wrong, 880, 96, complete));
    assert(!fixture.Start(Bounds(window), 100000, 96, complete));
    assert(callbacks == 0 && widths.empty());
    std::cout << "PASS: stale geometry and off-screen targets rejected\n";

    assert(fixture.Start(Bounds(window), 880, 0, complete));
    Pump(20); assert(callbacks == 0);
    painted(); Pump(30);
    assert(callbacks == 1 && completed);
    assert(Bounds(window).right - Bounds(window).left == 880);
    std::cout << "PASS: reduced motion still waits for a painted frame\n";

    callbacks = 0; widths.clear();
    assert(fixture.Start(Bounds(window), 960, 96, complete));
    Pump(1600);
    assert(callbacks == 1 && !completed && widths.back() == 0);
    assert(Bounds(window).right - Bounds(window).left == 880);
    std::cout << "PASS: missing frame times out without exposing blank pixels\n";
    reveal = nullptr;
  }
  painted(); Pump(20);
  DestroyWindow(window);
  UnregisterClass(cls.lpszClassName, cls.hInstance);
  std::cout << "PASS: callback lifetime is safe after disposal\n";
}
