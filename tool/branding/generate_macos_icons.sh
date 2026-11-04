#!/bin/bash
# 用品牌图形（tool/branding/wof_icon.svg 的蓝底白 W）生成 macOS 的图标。
# - Dock 应用图标：照 macOS 规范的圆角方块，1024 画布里内容 824、四周透明边距，写进 AppIcon.appiconset
# - 菜单栏图标：只要 W 的形状（黑色、透明底），当模板图用，系统按菜单栏明暗自动反色
# 依赖 rsvg-convert（Homebrew 的 librsvg）。生成后重新构建 macOS 包。
set -e
cd "$(dirname "$0")/../.."
W='M32 64H68L88 136L112 64H144L168 136L188 64H224L186 192H154L128 120L102 192H70Z'
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/app.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <rect x="100" y="100" width="824" height="824" rx="185" ry="185" fill="#005DFF"/>
  <g transform="translate(100 100) scale(3.21875)"><path fill="#FFFFFF" d="$W"/></g>
</svg>
SVG
set_dir=macos/Runner/Assets.xcassets/AppIcon.appiconset
for size in 16 32 64 128 256 512 1024; do
  rsvg-convert -w $size -h $size "$tmp/app.svg" -o "$set_dir/app_icon_$size.png"
done

cat > "$tmp/tray.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="24 24 208 208">
  <path fill="#000000" d="$W"/>
</svg>
SVG
rsvg-convert -w 36 -h 36 "$tmp/tray.svg" -o assets/icons/tray_icon_macos.png
echo "图标已生成：$set_dir、assets/icons/tray_icon_macos.png"
