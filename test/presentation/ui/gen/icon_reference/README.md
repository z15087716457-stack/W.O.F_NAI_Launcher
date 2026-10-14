# Independent SVG contour references

These 128×128 PNGs were rendered by the Codex in-app browser's Chromium SVG
renderer from the original assets at source revision `5aeb618c`, before the
compatibility changes. The SVG viewBox and original geometry are preserved;
the root viewport is square, ink is tinted black, and the background is white,
matching `GenNaiIcon`'s contain layout and `srcIn` tint. They are not Flutter
goldens generated from the repaired implementation.

- `nai-icon-inpaint-browser-128.png`: original rounded rect with `3 3` dashes.
  The identical `nai-icon-inpaint2.svg` uses the same reference.
- `director_remove_bg-browser-128.png`: original rounded rect with `3 3`
  dashes and 0.7 stroke opacity.
- `inpaint_palette-browser-128.png`: original radius 0.5 circles with a
  2-unit stroke; the browser renders solid radius 1.5 disks.

The test tolerates ordinary edge antialiasing differences while catching the
old dash displacement and hollow dots. Do not regenerate these fixtures from
the Flutter assets. The variations icon instead uses an independent geometric
oracle in `official_variations_icon_test.dart`.
