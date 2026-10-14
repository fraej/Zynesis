#!/usr/bin/env bash
# Build and package the ZynAddSubFX VST3 bundle.
#
#   scripts/build-vst3.sh linux     native Linux x86_64 build
#   scripts/build-vst3.sh windows   Windows x86_64 cross-build with MinGW-w64
#
# Output: dist/<platform>/ZynAddSubFX.vst3 and
#         dist/ZynAddSubFX-<platform>-x86_64.zip
set -euo pipefail

platform=${1:-linux}
root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fusion_dir="$root_dir/zyn-fusion-ui"
build_dir=${BUILD_DIR:-"$root_dir/build-$platform"}
dist_dir=${DIST_DIR:-"$root_dir/dist"}
host=${MINGW_HOST:-x86_64-w64-mingw32}
deps_prefix=${WIN_DEPS_PREFIX:-"$root_dir/build-win-deps/prefix"}

case "$platform" in
    linux)
        tools=(cmake make ruby rake pkg-config zip)
        runtime=libzest.so
        ;;
    windows)
        tools=("$host-gcc" "$host-g++" "$host-ar" cmake make ruby rake zip)
        runtime=libzest.dll
        ;;
    *)
        echo "usage: $0 linux|windows" >&2
        exit 2
        ;;
esac

for tool in "${tools[@]}"; do
    if ! command -v "$tool" >/dev/null; then
        echo "missing required tool: $tool" >&2
        exit 1
    fi
done

cmake_args=(-DCompileTests=OFF -DWerror=OFF)
if [[ $platform == windows ]]; then
    if [[ ! -f "$deps_prefix/lib/libz.a" || ! -f "$deps_prefix/lib/libfftw3f.a" ||
          ! -f "$deps_prefix/lib/pkgconfig/mxml.pc" || ! -f "$deps_prefix/lib/liblo.a" ]]; then
        WIN_DEPS_PREFIX="$deps_prefix" "$root_dir/scripts/build-windows-deps.sh"
    fi
    cmake_args+=(
        -DCMAKE_TOOLCHAIN_FILE="$root_dir/cmake/mingw-w64-x86_64.cmake"
        -DZYN_WIN_DEPS_PREFIX="$deps_prefix")
fi

# The Zyn-Fusion runtime builds in-tree; delete zyn-fusion-ui/$runtime to
# rebuild it.  Both platforms use mruby/build with different settings, so
# always start that from scratch.
if [[ ! -f "$fusion_dir/$runtime" ]]; then
    rm -rf "$fusion_dir/mruby/build"
    if [[ $platform == windows ]]; then
        CC="$host-gcc" CXX="$host-g++" AR="$host-ar" make -C "$fusion_dir" windows
    else
        make -C "$fusion_dir" linux
    fi
fi

cmake -S "$root_dir" -B "$build_dir" "${cmake_args[@]}"
cmake --build "$build_dir" --target ZynAddSubFX-vst3 --parallel

bundle="$dist_dir/$platform/ZynAddSubFX.vst3"
resources="$bundle/Contents/Resources"
rm -rf "$bundle"
mkdir -p "$dist_dir/$platform"
cp -a "$build_dir/bin/ZynAddSubFX.vst3" "$bundle"

# libzest looks up its QML, schema and fonts next to itself.  The editor
# loads it from Contents/Resources on Linux and from beside the plugin
# module (Contents/x86_64-win) on Windows.
if [[ $platform == windows ]]; then
    runtime_dir="$bundle/Contents/x86_64-win"
else
    runtime_dir="$resources"
fi
mkdir -p "$runtime_dir/qml" "$runtime_dir/schema" "$runtime_dir/font"
cp "$fusion_dir/$runtime" "$runtime_dir/"
cp "$fusion_dir"/src/mruby-zest/qml/* "$fusion_dir"/src/mruby-zest/example/* "$runtime_dir/qml/"
cp "$fusion_dir/src/osc-bridge/schema/test.json" "$runtime_dir/schema/"
cp "$fusion_dir"/deps/nanovg/example/*.ttf "$runtime_dir/font/"

mkdir -p "$resources"
cp -a "$root_dir/banks" "$resources/banks"

licenses="$resources/licenses"
mkdir -p "$licenses"
cp "$root_dir/COPYING" "$licenses/zynaddsubfx-GPL-2.0.txt"
cp "$fusion_dir/LICENSE" "$licenses/zyn-fusion-LGPL-2.1.txt"
cp "$root_dir/DPF/LICENSE" "$licenses/DPF-ISC.txt"
if [[ $platform == windows && -d "$deps_prefix/share/licenses" ]]; then
    # Licenses of the statically linked libraries.
    cp -a "$deps_prefix/share/licenses/." "$licenses/"
fi

archive="$dist_dir/ZynAddSubFX-$platform-x86_64.zip"
rm -f "$archive"
(
    cd "$dist_dir/$platform"
    zip -qr "$archive" ZynAddSubFX.vst3
)

echo "VST3 bundle: $bundle"
echo "Archive: $archive"
