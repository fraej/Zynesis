#!/usr/bin/env bash
# Cross-compile the Windows x86_64 VST3 bundle from Linux with MinGW-w64.
set -euo pipefail

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
host=${MINGW_HOST:-x86_64-w64-mingw32}
build_dir=${BUILD_DIR:-"$root_dir/build-vst3-win"}
deps_prefix=${WIN_DEPS_PREFIX:-"$root_dir/build-win-deps/prefix"}
dist_dir=${DIST_DIR:-"$root_dir/dist"}
package_dir=${PACKAGE_DIR:-"$dist_dir/ZynAddSubFX.vst3"}
archive=${WINDOWS_ARCHIVE:-"$dist_dir/ZynAddSubFX-windows-x86_64.zip"}
fusion_dir="$root_dir/zyn-fusion-ui"

for tool in "$host-gcc" "$host-g++" "$host-ar" cmake ninja ruby rake zip; do
    if ! command -v "$tool" >/dev/null; then
        echo "missing required tool: $tool" >&2
        exit 1
    fi
done

if [[ ! -f "$deps_prefix/lib/libz.a" || ! -f "$deps_prefix/lib/libfftw3f.a" ||
      ! -f "$deps_prefix/lib/pkgconfig/mxml.pc" || ! -f "$deps_prefix/lib/liblo.a" ]]; then
    WIN_DEPS_PREFIX="$deps_prefix" "$root_dir/scripts/build-windows-deps.sh"
fi

# Zyn-Fusion builds in-tree.  Delete zyn-fusion-ui/libzest.dll to force a
# rebuild.  mruby/build is shared with the Linux build, which configures the
# same build names differently, so always start it clean.
if [[ ! -f "$fusion_dir/libzest.dll" ]]; then
    rm -rf "$fusion_dir/mruby/build"
    CC="$host-gcc" CXX="$host-g++" AR="$host-ar" make -C "$fusion_dir" windows
fi

cmake -S "$root_dir" -B "$build_dir" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$root_dir/cmake/mingw-w64-x86_64.cmake" \
    -DZYN_WIN_DEPS_PREFIX="$deps_prefix" \
    -DCompileTests=OFF -DWerror=OFF
cmake --build "$build_dir" --target ZynAddSubFX-vst3 --parallel

source_bundle="$build_dir/bin/ZynAddSubFX.vst3"
arch_dir="$package_dir/Contents/x86_64-win"
resources="$package_dir/Contents/Resources"

rm -rf "$package_dir"
mkdir -p "$dist_dir"
cp -a "$source_bundle" "$package_dir"
mkdir -p "$arch_dir" "$resources/licenses"

# libzest.dll is loaded from beside the VST3 module and looks up its QML,
# schema and fonts relative to its own location, so these assets belong in
# Contents/x86_64-win.  This mirrors zyn-fusion-ui's `make pack`, which only
# supports the Linux runtime.
cp "$fusion_dir/libzest.dll" "$arch_dir/"
mkdir -p "$arch_dir/qml" "$arch_dir/schema" "$arch_dir/font"
cp "$fusion_dir"/src/mruby-zest/qml/* "$fusion_dir"/src/mruby-zest/example/* "$arch_dir/qml/"
cp "$fusion_dir/src/osc-bridge/schema/test.json" "$arch_dir/schema/"
cp "$fusion_dir"/deps/nanovg/example/*.ttf "$arch_dir/font/"

cp -a "$root_dir/banks" "$resources/banks"

cp "$root_dir/COPYING" "$resources/licenses/zynaddsubfx-GPL-2.0.txt"
cp "$fusion_dir/LICENSE" "$resources/licenses/zyn-fusion-LGPL-2.1.txt"
cp "$root_dir/DPF/LICENSE" "$resources/licenses/DPF-ISC.txt"
if [[ -d "$deps_prefix/share/licenses" ]]; then
    cp -a "$deps_prefix/share/licenses/." "$resources/licenses/"
fi

rm -f "$archive"
(
    cd "$dist_dir"
    zip -qr "$archive" "$(basename "$package_dir")"
)

echo "VST3 bundle: $package_dir"
echo "Windows archive: $archive"
