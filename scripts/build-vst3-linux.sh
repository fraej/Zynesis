#!/usr/bin/env bash
set -euo pipefail

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=${BUILD_DIR:-"$root_dir/build-vst3"}
prefix_dir=${DEPS_PREFIX:-}

if [[ -n "$prefix_dir" ]]; then
    export PATH="$root_dir/scripts:$prefix_dir/usr/bin:$PATH"
    export ZYN_RUBY="$prefix_dir/usr/bin/ruby"
    export ZYN_RAKE_SCRIPT="$prefix_dir/usr/share/rubygems-integration/all/gems/rake-13.3.1/exe/rake"
    export PKG_CONFIG_PATH="$prefix_dir/usr/lib/x86_64-linux-gnu/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export CMAKE_PREFIX_PATH="$prefix_dir${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
    export LD_LIBRARY_PATH="$prefix_dir/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export RUBYLIB="$prefix_dir/usr/lib/x86_64-linux-gnu/ruby/3.3.0:$prefix_dir/usr/lib/x86_64-linux-gnu/ruby/vendor_ruby/3.3.0:$prefix_dir/usr/lib/ruby/3.3.0:$prefix_dir/usr/lib/ruby/vendor_ruby${RUBYLIB:+:$RUBYLIB}"
fi

fusion_dir="$root_dir/zyn-fusion-ui"
if [[ ! -d "$fusion_dir" ]]; then
    echo "bundled zyn-fusion-ui directory is missing" >&2
    exit 1
fi

# Build the pinned Zyn-Fusion runtime only when it is not already packaged.
if [[ ! -f "$fusion_dir/package/libzest.so" ]]; then
    make -C "$fusion_dir" linux pack
fi

cmake_args=(
    -DGuiModule=zest -DPluginEnable=ON -DVst3Enable=ON
    -DLegacyPluginFormats=OFF -DCompileTests=OFF -DWerror=OFF)
if [[ -n "$prefix_dir" ]]; then
    cmake_args+=(
        -DLIBLO_INCLUDE_DIRS="$prefix_dir/usr/include"
        -DLIBLO_LIBRARY_DIRS="$prefix_dir/usr/lib/x86_64-linux-gnu")
fi
cmake -S "$root_dir" -B "$build_dir" -G "${CMAKE_GENERATOR:-Unix Makefiles}" "${cmake_args[@]}"
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
cp "$root_dir/zyn-fusion-ui/COPYING" "$resources/licenses/zyn-fusion-GPL-2.0.txt" 2>/dev/null || true

echo "VST3 bundle: $bundle"
