#ifndef RUNNER_RESOURCE_WINDOW_GEOMETRY_H_
#define RUNNER_RESOURCE_WINDOW_GEOMETRY_H_

#include <windows.h>

namespace resource_window_geometry {
struct Exclusion {
  double left, top, width, height;
  constexpr bool Contains(double x, double y) const {
    return x >= left && x < left + width && y >= top && y < top + height;
  }
};

constexpr LRESULT BorderHit(int x, int y, int width, int height, int edge,
                            bool maximized) {
  if (maximized) return HTCLIENT;
  const bool left = x < edge, right = x >= width - edge;
  const bool top = y < edge, bottom = y >= height - edge;
  if (top && left) return HTTOPLEFT;
  if (top && right) return HTTOPRIGHT;
  if (bottom && left) return HTBOTTOMLEFT;
  if (bottom && right) return HTBOTTOMRIGHT;
  if (left) return HTLEFT;
  if (right) return HTRIGHT;
  if (top) return HTTOP;
  if (bottom) return HTBOTTOM;
  return HTCLIENT;
}

constexpr bool InTitle(double x, double y, double width, double height,
                        double reserved_right) {
  return x >= 0 && y >= 0 && y < height && x < width - reserved_right;
}

constexpr RECT ClientBounds(RECT outer, bool maximized, RECT work,
                             bool windows11) {
  return maximized ? work : RECT{outer.left + 8,
      outer.top + (windows11 ? 0 : 1), outer.right - 8, outer.bottom - 8};
}
}  // namespace resource_window_geometry
#endif
