// Compile-only assertions: no HWND, process launch, or user data access.
#include "../../../windows/runner/resource_window_geometry.h"

namespace geometry = resource_window_geometry;
static_assert(geometry::BorderHit(1, 1, 1040, 680, 6, false) == HTTOPLEFT);
static_assert(geometry::BorderHit(1039, 1, 1040, 680, 6, false) == HTTOPRIGHT);
static_assert(geometry::BorderHit(1, 679, 1040, 680, 6, false) == HTBOTTOMLEFT);
static_assert(geometry::BorderHit(1039, 679, 1040, 680, 6, false) == HTBOTTOMRIGHT);
static_assert(geometry::BorderHit(1, 300, 1040, 680, 6, false) == HTLEFT);
static_assert(geometry::BorderHit(1039, 300, 1040, 680, 6, false) == HTRIGHT);
static_assert(geometry::BorderHit(300, 1, 1040, 680, 6, false) == HTTOP);
static_assert(geometry::BorderHit(300, 679, 1040, 680, 6, false) == HTBOTTOM);
static_assert(geometry::BorderHit(300, 300, 1040, 680, 6, false) == HTCLIENT);
static_assert(geometry::BorderHit(1, 1, 1040, 680, 6, true) == HTCLIENT);
// 150% DPI resize zone is 9 physical pixels.
static_assert(geometry::BorderHit(8, 300, 1560, 1020, 9, false) == HTLEFT);
static_assert(geometry::BorderHit(9, 300, 1560, 1020, 9, false) == HTCLIENT);
static_assert(geometry::InTitle(400, 20, 1040, 42, 100));
static_assert(!geometry::InTitle(950, 20, 1040, 42, 100));
static_assert(!geometry::InTitle(400, 42, 1040, 42, 100));
static_assert(!geometry::InTitle(-1, 20, 1040, 42, 0));
constexpr geometry::Exclusion buttons{0, 0, 200, 42};
static_assert(buttons.Contains(199, 20));
static_assert(!buttons.Contains(200, 20));
constexpr RECT outer{0, 0, 1040, 680}, work{0, 0, 1040, 640};
static_assert(geometry::ClientBounds(outer, false, work, true).left == 8);
static_assert(geometry::ClientBounds(outer, false, work, true).right == 1032);
static_assert(geometry::ClientBounds(outer, false, work, true).bottom == 672);
static_assert(geometry::ClientBounds(outer, false, work, true).top == 0);
static_assert(geometry::ClientBounds(outer, false, work, false).top == 1);
static_assert(geometry::ClientBounds(outer, true, work, true).bottom == 640);
