#!/bin/bash
# 构建 macOS 版，并把 NAI Agent 运行时（Node + Pi）、桥接客户端和本地放大引擎放进应用包。
#
# 用法：
#   scripts/build_macos.sh [--release]       构建（默认 debug），产物在 build/macos/Build/Products/<Debug|Release>/
#   scripts/build_macos.sh tools <应用包>     只往已有的应用包里放运行时、桥接客户端和放大引擎（例如 flutter run 之后）
#
# - Flutter：用 tool/flutter-sdk.json 登记的版本；FLUTTER_ROOT 指向那份 SDK 时用它，否则用 PATH 上的 flutter
# - Xcode：DEVELOPER_DIR 默认 /Applications/Xcode.app，不改系统的 xcode-select
# - Node：和 Windows 包同一个版本（scripts/prepare_windows_node_runtime.ps1），用官方 darwin-arm64 和
#   darwin-x64 两个包按 SHASUMS256.txt 校验后合成通用二进制，Apple 芯片和 Intel 的 Mac 都能跑
# - studio-bridge：--release 时也合成通用二进制。dart compile exe 只编本机架构，Intel 那一份用官方的
#   macOS x64 Dart SDK（和 Flutter 自带的 Dart 同一版本，按 .sha256sum 校验）在 Rosetta 下编，所以要在
#   装了 Rosetta 的 Apple 芯片 Mac 上构建；做不到时只编本机架构并提示，这样的包 package_macos_release.sh
#   默认不收。debug 和 tools 只编本机架构
# - 本地放大：Real-ESRGAN NCNN/Vulkan 和 Windows 包同一版（assets/local_upscale/manifest.json 的 engine_version），
#   用官方 Release 里的 macOS 包，本身就是通用二进制（静态链接 MoltenVK，走 Metal），按固定的 sha256 校验后放进
#   Contents/Resources/tools/local-upscale。Windows 的程序（assets/local_upscale/windows/）从 flutter_assets 里剔掉
# - 发布包：构建完用 scripts/package_macos_release.sh 打成 zip
# - 额外的 --dart-define 可放在 EXTRA_DART_DEFINES 里
# - 签名：默认 ad-hoc（-）；有自己的证书时用 CODESIGN_IDENTITY 指定
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -n "${FLUTTER_ROOT:-}" ]; then export PATH="$FLUTTER_ROOT/bin:$PATH"; fi
export DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
# super_native_extensions（拖放、剪贴板）要用 Rust 编译；Homebrew 的 rustup 不把 cargo、rustc 放进 PATH
if [ -d /opt/homebrew/opt/rustup/bin ]; then export PATH="/opt/homebrew/opt/rustup/bin:$PATH"; fi

NODE_VERSION="${NODE_VERSION:-v24.18.0}"
REALESRGAN_VERSION=v0.2.0
REALESRGAN_ZIP_SHA256=f1cc31f13398126ddec25a186b9e50c7ab3e4f2bc011d0222331b43ce2037d3b
REALESRGAN_SHA256=c1c35d92079085de96b9d547fd7e4464bc8a2e9ccf28d7b8c712d72ade91b7cc
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
CACHE="build/macos-runtime-cache"
APP_NAME=$(sed -n 's/^PRODUCT_NAME = //p' macos/Runner/Configs/AppInfo.xcconfig)

# 下载卡住（一分钟不到 1 KB/s）就断开重试，不让构建一直挂着
download() {
  curl -fsSL --retry 3 --retry-all-errors --connect-timeout 30 \
    --speed-limit 1024 --speed-time 60 "$1" -o "$2"
}

# 下载一个官方 Dart SDK（macOS x64，版本和频道同 PATH 上的 dart）并校验，解到缓存目录；输出 SDK 目录
fetch_dart_x64() {
  local version channel base name dir expected actual
  read -r version channel < <(dart --version 2>&1 | sed -n 's/^Dart SDK version: \([^ ]*\) (\([a-z]*\)).*/\1 \2/p') || true
  if [ -z "$version" ]; then
    echo "读不出 Dart 版本" >&2
    exit 1
  fi
  base="https://storage.googleapis.com/dart-archive/channels/$channel/release/$version/sdk"
  name="dartsdk-macos-x64-release.zip"
  dir="$CACHE/dart-sdk-$version-macos-x64"
  mkdir -p "$CACHE"
  if [ ! -x "$dir/dart-sdk/bin/dart" ]; then
    download "$base/$name.sha256sum" "$CACHE/$name-$version.sha256sum"
    download "$base/$name" "$CACHE/$name"
    expected=$(cut -d' ' -f1 < "$CACHE/$name-$version.sha256sum")
    actual=$(shasum -a 256 "$CACHE/$name" | cut -d' ' -f1)
    if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
      echo "Dart SDK 包校验不对：$name" >&2
      exit 1
    fi
    rm -rf "$dir"
    mkdir -p "$dir"
    ditto -x -k "$CACHE/$name" "$dir"
    rm -f "$CACHE/$name"
    if [ ! -x "$dir/dart-sdk/bin/dart" ]; then
      echo "Dart SDK 包解压失败：$name" >&2
      exit 1
    fi
  fi
  echo "$dir/dart-sdk"
}

# 编桥接客户端。第二个参数是 universal 时再编一份 x86_64 合成通用二进制；第三个参数是一个
# x86_64 的可执行文件，用来试 Rosetta 能不能用
build_studio_bridge() {
  local out="$1" archs="$2" probe="$3" x64
  dart compile exe tool/studio_bridge.dart -o "$out"
  if [ "$archs" != universal ]; then
    return
  fi
  if [ "$(uname -m)" != arm64 ] || ! arch -x86_64 "$probe" --version >/dev/null 2>&1; then
    echo "Universal release requires an Apple silicon Mac with Rosetta." >&2
    return 1
  fi
  x64=$(fetch_dart_x64)
  arch -x86_64 "$x64/bin/dart" compile exe tool/studio_bridge.dart -o "$out-x86_64"
  lipo -create "$out" "$out-x86_64" -output "$out-universal"
  mv "$out-universal" "$out"
  rm -f "$out-x86_64"
}

# 下载官方的 Real-ESRGAN macOS 包并校验，解到缓存目录；输出程序所在的目录
fetch_realesrgan() {
  local name dir engine windows
  name="realesrgan-ncnn-vulkan-$REALESRGAN_VERSION-macos"
  dir="$CACHE/$name"
  engine="$dir/realesrgan-ncnn-vulkan"
  windows=$(sed -n 's/.*"engine_version": *"\([^"]*\)".*/\1/p' assets/local_upscale/manifest.json)
  if [ "v$windows" != "$REALESRGAN_VERSION" ]; then
    echo "Windows 包的 Real-ESRGAN 是 ${windows}，这里固定的是 ${REALESRGAN_VERSION}，两边要一起换" >&2
    exit 1
  fi
  mkdir -p "$CACHE"
  if [ ! -f "$engine" ] || [ "$(shasum -a 256 "$engine" | cut -d' ' -f1)" != "$REALESRGAN_SHA256" ]; then
    download "https://github.com/xinntao/Real-ESRGAN-ncnn-vulkan/releases/download/$REALESRGAN_VERSION/$name.zip" \
      "$CACHE/$name.zip"
    if [ "$(shasum -a 256 "$CACHE/$name.zip" | cut -d' ' -f1)" != "$REALESRGAN_ZIP_SHA256" ]; then
      echo "Real-ESRGAN 包校验不对：$name.zip" >&2
      exit 1
    fi
    rm -rf "$dir"
    ditto -x -k "$CACHE/$name.zip" "$CACHE"
    rm -f "$CACHE/$name.zip"
    if [ ! -f "$engine" ] || [ "$(shasum -a 256 "$engine" | cut -d' ' -f1)" != "$REALESRGAN_SHA256" ]; then
      echo "Real-ESRGAN 程序校验不对：$engine" >&2
      exit 1
    fi
  fi
  echo "$dir"
}

# 放本地放大引擎和它的许可，剔掉 flutter_assets 里的 Windows 程序。签名只签到 App.framework 这一层，
# 整个应用包由 bundle_tools 最后重签
bundle_local_upscale() {
  local app="$1" engine_dir target windows arch
  engine_dir=$(fetch_realesrgan)
  target="$app/Contents/Resources/tools/local-upscale"
  rm -rf "$target"
  mkdir -p "$target"
  cp -p "$engine_dir/realesrgan-ncnn-vulkan" "$target/realesrgan-ncnn-vulkan"
  chmod 755 "$target/realesrgan-ncnn-vulkan"
  for arch in arm64 x86_64; do
    if ! lipo "$target/realesrgan-ncnn-vulkan" -verify_arch "$arch"; then
      echo "Real-ESRGAN 缺 ${arch}，要 arm64 + x86_64 的通用二进制" >&2
      exit 1
    fi
  done
  cp -p "$engine_dir/LICENSE" "$target/LICENSE"
  # 静态链接进来的 MoltenVK（含 SPIRV-Cross、cereal）和 LLVM OpenMP 的许可
  cp -p tool/local_upscale/macos/*-LICENSE.txt "$target/"
  codesign --force --sign "$CODESIGN_IDENTITY" "$target/realesrgan-ncnn-vulkan"

  # Windows 的程序在 App.framework 里，框架的签名封着这些资源，剔掉以后要重签框架
  windows="$app/Contents/Frameworks/App.framework/Resources/flutter_assets/assets/local_upscale/windows"
  if [ -e "$windows" ]; then
    rm -rf "$windows"
    codesign --force --sign "$CODESIGN_IDENTITY" \
      --preserve-metadata=identifier,entitlements,requirements,flags,runtime \
      "$app/Contents/Frameworks/App.framework"
  fi
}

# 下载一个官方 Node 包并校验，解到缓存目录；输出解出来的目录
fetch_node_arch() {
  local arch="$1" base name dir expected actual
  base="https://nodejs.org/dist/$NODE_VERSION"
  name="node-$NODE_VERSION-darwin-$arch.tar.gz"
  dir="$CACHE/node-$NODE_VERSION-darwin-$arch"
  mkdir -p "$CACHE"
  if [ ! -x "$dir/bin/node" ]; then
    download "$base/SHASUMS256.txt" "$CACHE/SHASUMS256-$NODE_VERSION.txt"
    download "$base/$name" "$CACHE/$name"
    expected=$(grep " $name\$" "$CACHE/SHASUMS256-$NODE_VERSION.txt" | cut -d' ' -f1)
    actual=$(shasum -a 256 "$CACHE/$name" | cut -d' ' -f1)
    if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
      echo "Node 包校验不对：$name" >&2
      exit 1
    fi
    tar -xzf "$CACHE/$name" -C "$CACHE"
  fi
  echo "$dir"
}

# RAG 的进程宿主（Windows 包里是 assets/rag/windows/stdio_host.exe，管 Job Object）：同一份源码的
# macOS 实现，让 uv、Python 和它们起的子进程跟着宿主或应用一起退出（见 lib/core/rag/rag_process.dart）。
# clang 直接编两个架构，不用 Rosetta。Mac 上不用 Windows 的宿主：从 flutter_assets 里删掉，再重签
# App.framework（删了资源它的签名就对不上了），外面的应用包由 bundle_tools 最后重签
bundle_rag_host() {
  local app="$1" host="$1/Contents/Resources/tools/rag-stdio-host"
  local framework="$1/Contents/Frameworks/App.framework"
  local windows="$framework/Resources/flutter_assets/assets/rag/windows"
  mkdir -p "$(dirname "$host")"
  xcrun clang++ -std=c++17 -O2 -Wall -Wextra -arch arm64 -arch x86_64 \
    -mmacosx-version-min=13.5 tool/rag/stdio_host.cpp -o "$host"
  codesign --force --sign "$CODESIGN_IDENTITY" "$host"
  if [ -e "$windows" ]; then
    rm -rf "$windows"
    codesign --force --sign "$CODESIGN_IDENTITY" \
      --preserve-metadata=identifier,entitlements,requirements,flags,runtime "$framework"
  fi
  echo "已放进应用包：RAG 进程宿主（$(lipo -archs "$host")），去掉了 Windows 版宿主"
}

bundle_tools() {
  local app="$1" bridge_archs="${2:-host}" arm x64 host_node tools agent rel
  if [ ! -d "$app/Contents" ]; then
    echo "不是应用包：$app" >&2
    exit 2
  fi
  arm=$(fetch_node_arch arm64)
  x64=$(fetch_node_arch x64)
  tools="$app/Contents/Resources/tools"
  agent="$tools/nai-agent"
  rm -rf "$agent" "$tools/studio-bridge"
  mkdir -p "$agent"

  # Pi 的依赖：照 Windows 的准备脚本用 npm ci，用的是同一个版本 Node 带的 npm（纯 JS 依赖，不分架构）
  case "$(uname -m)" in
    arm64) host_node="$arm" ;;
    x86_64) host_node="$x64" ;;
    *) echo "Unsupported macOS build architecture: $(uname -m)" >&2; return 1 ;;
  esac
  (cd tool/nai_agent && PATH="$OLDPWD/$host_node/bin:$PATH" npm ci --no-audit --no-fund)

  # The npm tarball may only carry the build host's pi-tui native slice.
  # Its pinned source ships an official clang cross-build for both Mac targets.
  bash tool/nai_agent/node_modules/@earendil-works/pi-tui/native/darwin/build.sh

  # 照 scripts/windows_release_payload.py：tool/nai_agent 里跟踪的文件（不要 test/、node_modules/）+ node_modules
  while IFS= read -r -d '' file; do
    rel="${file#tool/nai_agent/}"
    case "$rel" in test/* | node_modules/*) continue ;; esac
    mkdir -p "$agent/$(dirname "$rel")"
    cp -p "$file" "$agent/$rel"
  done < <(git ls-files -z -- tool/nai_agent)
  cp -R tool/nai_agent/node_modules "$agent/node_modules"
  lipo -create "$arm/bin/node" "$x64/bin/node" -output "$agent/node"
  chmod 755 "$agent/node"
  # Agent self-management (2.2.4) and local-command MCP servers need npm/npx.
  bash scripts/bundle_macos_node_tools.sh "$arm" "$agent"
  cp -p "$arm/LICENSE" "$agent/NODE-LICENSE"
  if [ -f tool/nai_agent/node_modules/@earendil-works/pi-coding-agent/LICENSE ]; then
    cp -p tool/nai_agent/node_modules/@earendil-works/pi-coding-agent/LICENSE "$agent/PI-LICENSE"
  else
    cp -p tool/nai_agent/PI-LICENSE "$agent/PI-LICENSE"
  fi

  # 本地放大引擎（Windows 包里从资源包释放 realesrgan-ncnn-vulkan.exe）
  bundle_local_upscale "$app"

  # 桥接客户端（Windows 包里是 studio-bridge.exe）
  build_studio_bridge "$tools/studio-bridge" "$bridge_archs" "$x64/bin/node"
  bundle_rag_host "$app"

  # 先签里面的可执行文件和原生模块，再按原来的 entitlements 重签整个应用包（加了文件不重签，签名就对不上了）
  codesign --force --sign "$CODESIGN_IDENTITY" "$agent/node" "$tools/studio-bridge"
  find "$agent/node_modules" -name '*.node' -type f -exec codesign --force --sign "$CODESIGN_IDENTITY" {} \;
  codesign --force --sign "$CODESIGN_IDENTITY" \
    --preserve-metadata=identifier,entitlements,requirements,flags,runtime "$app"
  codesign --verify --deep --strict "$app"
  echo "已放进应用包：Node $("$agent/node" --version)（$(lipo -archs "$agent/node")）+ Pi，studio-bridge（$(lipo -archs "$tools/studio-bridge")）"
  echo "已放进应用包：Real-ESRGAN ${REALESRGAN_VERSION}（$(lipo -archs "$tools/local-upscale/realesrgan-ncnn-vulkan")）"
}

cmd="${1:-}"
case "$cmd" in
  tools)
    bundle_tools "$2"
    ;;
  "" | --release)
    mode=--debug
    out=Debug
    bridge_archs=host
    if [ "$cmd" = "--release" ]; then
      mode=--release
      out=Release
      bridge_archs=universal
    fi
    # shellcheck disable=SC2086
    flutter build macos "$mode" ${EXTRA_DART_DEFINES:-}
    bundle_tools "build/macos/Build/Products/$out/$APP_NAME.app" "$bridge_archs"
    ;;
  *)
    echo "用法：$0 [--release] | tools <应用包>" >&2
    exit 2
    ;;
esac
