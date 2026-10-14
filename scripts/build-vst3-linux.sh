#!/usr/bin/env bash
# Build the Linux x86_64 VST3 bundle.
set -euo pipefail

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=${BUILD_DIR:-"$root_dir/build-vst3"}
fusion_dir="$root_dir/zyn-fusion-ui"

# Zyn-Fusion builds in-tree.  Delete zyn-fusion-ui/package/libzest.so to
# force a rebuild.  mruby/build is shared with the Windows build, which
# configures the same build names differently, so always start it clean.
if [[ ! -f "$fusion_dir/package/libzest.so" ]]; then
    rm -rf "$fusion_dir/mruby/build"
    make -C "$fusion_dir" linux pack
fi

cmake -S "$root_dir" -B "$build_dir" -G "${CMAKE_GENERATOR:-Unix Makefiles}" \
    -DGuiModule=zest -DPluginEnable=ON -DVst3Enable=ON \
    -DLegacyPluginFormats=OFF -DCompileTests=OFF -DWerror=OFF
cmake --build "$build_dir" --target ZynAddSubFX-vst3 --parallel

bundle="$build_dir/bin/ZynAddSubFX.vst3"
resources="$bundle/Contents/Resources"
mkdir -p "$resources"
cp "$fusion_dir/package/libzest.so" "$resources/"
for dir in font qml schema; do
    rm -rf "$resources/$dir"
    cp -a "$fusion_dir/package/$dir" "$resources/$dir"
done
rm -rf "$resources/banks"
cp -a "$root_dir/instruments/banks" "$resources/banks"
mkdir -p "$resources/licenses"
cp "$root_dir/COPYING" "$resources/licenses/zynaddsubfx-GPL-2.0.txt"
cp "$fusion_dir/LICENSE" "$resources/licenses/zyn-fusion-LGPL-2.1.txt"
cp "$root_dir/DPF/LICENSE" "$resources/licenses/DPF-ISC.txt"

echo "VST3 bundle: $bundle"
