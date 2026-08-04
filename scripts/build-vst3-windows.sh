#!/usr/bin/env bash
set -euo pipefail

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=${BUILD_DIR:-"$root_dir/build-vst3-win"}
deps_prefix=${WIN_DEPS_PREFIX:-/tmp/zyn-win-deps/prefix}
dist_dir=${DIST_DIR:-"$root_dir/dist"}
package_dir=${PACKAGE_DIR:-"$dist_dir/ZynAddSubFX.vst3"}
archive=${WINDOWS_ARCHIVE:-"$dist_dir/ZynAddSubFX-windows-x86_64.zip"}
fusion_dir="$root_dir/zyn-fusion-ui"

if [[ ! -d "$fusion_dir" ]]; then
    echo "zyn-fusion-ui submodule is missing" >&2
    exit 1
fi
if [[ ! -f "$deps_prefix/include/fftw3.h" || ! -f "$deps_prefix/lib/libfftw3f.a" ]]; then
    echo "Windows dependencies are missing under $deps_prefix" >&2
    echo "Set WIN_DEPS_PREFIX to the cross-compiled dependency prefix." >&2
    exit 1
fi

if [[ ! -f "$fusion_dir/libzest.dll" ]]; then
    make -C "$fusion_dir" windows
fi

cmake -S "$root_dir" -B "$build_dir" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$root_dir/cmake/mingw-w64-x86_64.cmake" \
    -DGuiModule=zest -DPluginEnable=ON -DVst3Enable=ON \
    -DLegacyPluginFormats=OFF -DCompileTests=OFF -DWerror=OFF \
    -DAlsaEnable=OFF -DJackEnable=OFF -DOssEnable=OFF -DSndioEnable=OFF \
    -DPaEnable=OFF -DLashEnable=OFF \
    -DFFTW3F_INCLUDE_DIR="$deps_prefix/include" \
    -DFFTW3F_LIBRARY_DIRS="$deps_prefix/lib" \
    -DMXML_INCLUDE_DIR="$deps_prefix/include" \
    -DMXML_LIBRARY_DIRS="$deps_prefix/lib" \
    -DLIBLO_INCLUDE_DIR="$deps_prefix/include" \
    -DLIBLO_LIBRARY_DIRS="$deps_prefix/lib" \
    -DZLIB_ROOT="$deps_prefix"
cmake --build "$build_dir" --target ZynAddSubFX-vst3 --parallel

source_bundle="$build_dir/bin/ZynAddSubFX.vst3"
arch_dir="$package_dir/Contents/x86_64-win"
resources="$package_dir/Contents/Resources"

rm -rf "$package_dir"
mkdir -p "$dist_dir"
cp -a "$source_bundle" "$package_dir"
mkdir -p "$arch_dir" "$resources/licenses"

# The Windows loader resolves libzest.dll and its QML/resources beside the
# VST3 module, so these assets belong in Contents/x86_64-win.
cp "$fusion_dir/libzest.dll" "$arch_dir/libzest.dll"
for dir in font qml schema; do
    rm -rf "$arch_dir/$dir"
    cp -a "$fusion_dir/package/$dir" "$arch_dir/$dir"
done
rm -rf "$arch_dir/banks"
cp -a "$root_dir/instruments/banks" "$arch_dir/banks"

cp "$root_dir/COPYING" "$resources/licenses/zynaddsubfx-GPL-2.0.txt"
cp "$fusion_dir/COPYING" "$resources/licenses/zyn-fusion-GPL-2.0.txt" 2>/dev/null || true

rm -f "$archive"
(
    cd "$dist_dir"
    zip -qr "$archive" "$(basename "$package_dir")"
)

echo "VST3 bundle: $package_dir"
echo "Windows archive: $archive"
