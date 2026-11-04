#!/bin/bash
# 把 scripts/build_macos.sh --release 构建的应用包打成发布用的 zip（对应 Windows 的便携版 zip）。
#
# 用法：
#   scripts/package_macos_release.sh [--version <版本>] [--dist-dir <目录>] [--app <应用包>]
#
# - 版本默认取 pubspec.yaml（如 2.1.0+43），文件名用去掉构建号的版本：
#   <dist>/WOF_NAI_Studio_macOS_<版本>_Portable.zip 和同名的 .sha256
# - 不改 Flutter 的构建产物：复制到 build/release-stage/ 后再写 package-info.json 和许可文件，重签再打包
# - 打包前检查（scripts/macos_release_payload.py）：是 Release 构建、版本号对得上、没有开发机上的用户数据、
#   数据库不是 Git LFS 指针、Pi 和 Node 版本对、所有可执行文件和库都同时有 arm64 和 x86_64。
#   没装 Rosetta 时 build_macos.sh 只能编出本机架构的 studio-bridge，这样的包默认不收；
#   只给自己用时设 ALLOW_HOST_ONLY_BRIDGE=1
# - 签名：默认 ad-hoc（-）；有证书时用 CODESIGN_IDENTITY 指定（和 build_macos.sh 用同一个）。
#   ad-hoc 包没有经过 Apple 公证，用户第一次打开的方法见 README
# - zip 用 ditto -c -k --keepParent，保留应用包里的符号链接和权限；加 --norsrc 不带扩展属性：本机给每个
#   文件打的 com.apple.provenance 会变成 zip 里上万个 ._ 文件，用 unzip 等工具解压时它们落进应用包，
#   签名就坏了（系统提示“已损坏”）。打完解压一遍核对签名和符号链接
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -n "${FLUTTER_ROOT:-}" ]; then export PATH="$FLUTTER_ROOT/bin:$PATH"; fi
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
APP_NAME=$(sed -n 's/^PRODUCT_NAME = //p' macos/Runner/Configs/AppInfo.xcconfig)
PRODUCTS="build/macos/Build/Products"
STAGE_ROOT="build/release-stage"

usage() {
  echo "用法：$0 [--version <版本>] [--dist-dir <目录>] [--app <应用包>]" >&2
  exit 2
}

version=""
dist="dist"
app="$PRODUCTS/Release/$APP_NAME.app"
while [ $# -gt 0 ]; do
  case "$1" in
    --version | --dist-dir | --app)
      [ $# -ge 2 ] || usage
      case "$1" in
        --version) version="$2" ;;
        --dist-dir) dist="$2" ;;
        --app) app="$2" ;;
      esac
      shift 2
      ;;
    *) usage ;;
  esac
done

version="${version:-$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | tr -d '[:space:]')}"
display="${version%%+*}"
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9]+)?$ ]]; then
  echo "版本号不是安全的语义化版本：$version" >&2
  exit 2
fi
if [ ! -d "$app/Contents" ]; then
  echo "找不到应用包：${app}（先跑 scripts/build_macos.sh --release）" >&2
  exit 1
fi

# 输出目录不能落在构建产物或暂存目录里
mkdir -p "$dist" "$STAGE_ROOT" "$PRODUCTS"
dist_abs=$(cd "$dist" && pwd -P)
for inner in "$STAGE_ROOT" "$PRODUCTS"; do
  inner_abs=$(cd "$inner" && pwd -P)
  case "$dist_abs/" in
    "$inner_abs"/*)
      echo "--dist-dir 不能放在 $inner 里" >&2
      exit 2
      ;;
  esac
done

folder="WOF_NAI_Studio_macOS_$display"
stage_dir="$STAGE_ROOT/$folder"
stage="$stage_dir/$APP_NAME.app"
payload=(python3 scripts/macos_release_payload.py)
verify_options=()
if [ "${ALLOW_HOST_ONLY_BRIDGE:-}" = 1 ]; then verify_options+=(--allow-host-only-bridge); fi
rm -rf "$stage_dir"
mkdir -p "$stage_dir"
ditto "$app" "$stage"
find "$stage" -name .DS_Store -type f -delete

"${payload[@]}" verify --root . --app "$stage" --version "$version" --display "$display" \
  ${verify_options[@]+"${verify_options[@]}"}

cp LICENSE "$stage/Contents/Resources/LICENSE.txt"
cp THIRD_PARTY_NOTICES.md "$stage/Contents/Resources/THIRD_PARTY_NOTICES.md"
flutter --version --machine > "$stage_dir/flutter-version.json"
"${payload[@]}" finish --root . --app "$stage" --version "$version" --display "$display" \
  --flutter-json "$stage_dir/flutter-version.json" --signature "$CODESIGN_IDENTITY"

# 加了文件要重签整个应用包；里面的 node、studio-bridge 在 build_macos.sh 里已经签过
codesign --force --sign "$CODESIGN_IDENTITY" \
  --preserve-metadata=identifier,entitlements,requirements,flags,runtime "$stage"
codesign --verify --deep --strict "$stage"

zip="$dist/${folder}_Portable.zip"
rm -f "$zip" "$zip.sha256"
ditto -c -k --norsrc --keepParent "$stage" "$zip"

# 解压一遍核对：没有 ._ / __MACOSX，签名完好，符号链接（框架的 Versions/Current 等）没被展开成文件
apple_double=$(zipinfo -1 "$zip" | grep -c -e '/\._' -e '^\._' -e '^__MACOSX/' || true)
if [ "$apple_double" != 0 ]; then
  echo "zip 里带了 $apple_double 个 AppleDouble（._）文件：$zip" >&2
  exit 1
fi
check="$stage_dir/unzipped"
ditto -x -k "$zip" "$check"
codesign --verify --deep --strict "$check/$APP_NAME.app"
links=$(find "$stage" -type l | wc -l | tr -d ' ')
unzipped_links=$(find "$check/$APP_NAME.app" -type l | wc -l | tr -d ' ')
if [ "$links" != "$unzipped_links" ]; then
  echo "zip 里的符号链接数对不上：$links → $unzipped_links" >&2
  exit 1
fi
rm -rf "$check"

"${payload[@]}" checksum --output "$zip"
echo "已生成 macOS 包：${zip}（$(du -h "$zip" | cut -f1)，签名 ${CODESIGN_IDENTITY}）"
