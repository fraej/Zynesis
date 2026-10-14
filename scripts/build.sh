#!/usr/bin/env bash
# Build and package the Zynth VST3 and CLAP plugins.
#
#   scripts/build.sh linux     native Linux x86_64 build
#   scripts/build.sh windows   Windows x86_64 cross-build with MinGW-w64
#
# Output, in dist/<platform>/:
#   VST3/Zynth.vst3                 VST3 bundle, resources in Contents/Resources
#   CLAP/Zynth.clap, CLAP/Zynth/    CLAP plugin and its resource folder
# and dist/Zynth-<platform>-x86_64.zip with both.
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
cmake --build "$build_dir" --target Zynth-vst3 Zynth-clap --parallel

# stage_resources DIR: the editor runtime and its assets, the factory banks
# and the licenses, laid out as the plugin expects (src/Misc/ResourceDirs.h).
# libzest finds its QML, schema and fonts next to itself.
stage_resources() {
    local dir=$1
    mkdir -p "$dir/qml" "$dir/schema" "$dir/font" "$dir/licenses"
    cp "$fusion_dir/$runtime" "$dir/"
    cp "$fusion_dir"/src/mruby-zest/qml/* "$fusion_dir"/src/mruby-zest/example/* "$dir/qml/"
    cp "$fusion_dir/src/osc-bridge/schema/test.json" "$dir/schema/"
    cp "$fusion_dir"/deps/nanovg/example/*.ttf "$dir/font/"
    cp -a "$root_dir/banks" "$dir/banks"

    # See THIRD_PARTY.md.
    local name src
    while read -r name src; do
        cp "$root_dir/$src" "$dir/licenses/$name"
    done <<'LICENSES'
Zynth-GPL-2.0-or-later.txt COPYING
AUTHORS.txt AUTHORS.txt
THIRD_PARTY.md THIRD_PARTY.md
DPF-ISC.txt DPF/LICENSE
DPF-CLAP-MIT.txt DPF/distrho/src/clap/LICENSE
DPF-pugl-ISC.txt DPF/dgl/src/pugl-upstream/COPYING
DPF-nanovg-zlib.txt DPF/dgl/src/nanovg/LICENSE.txt
DPF-DejaVuSans.txt DPF/dgl/src/resources/LICENSE-DejaVuSans.ttf.txt
rtosc-MIT.txt rtosc/LICENSE
tlsf-README.md tlsf/README.md
zyn-fusion-LGPL-2.1.txt zyn-fusion-ui/LICENSE
mruby-qml-parse-MIT.txt zyn-fusion-ui/src/mruby-qml-parse/LICENSE
mruby-qml-spawn-MIT.txt zyn-fusion-ui/src/mruby-qml-spawn/LICENSE
osc-bridge-README.adoc zyn-fusion-ui/src/osc-bridge/README.adoc
mruby-MIT.txt zyn-fusion-ui/mruby/LICENSE
mruby-errno-README.md zyn-fusion-ui/deps/mruby-errno/README.md
mruby-dir-README.md zyn-fusion-ui/deps/mruby-dir/README.md
mruby-dir-glob-README.md zyn-fusion-ui/deps/mruby-dir-glob/README.md
mruby-file-stat-README.md zyn-fusion-ui/deps/mruby-file-stat/README.md
mruby-process-README.md zyn-fusion-ui/deps/mruby-process/README.md
mruby-regexp-pcre-README.md zyn-fusion-ui/deps/mruby-regexp-pcre/README.md
mruby-set-MIT.txt zyn-fusion-ui/deps/mruby-set/LICENSE
pcre-BSD.txt zyn-fusion-ui/deps/mruby-regexp-pcre/pcre/LICENCE
nanovg-zlib.txt zyn-fusion-ui/deps/nanovg/LICENSE.txt
rtosc-header-MIT.txt zyn-fusion-ui/deps/rtosc/LICENSE
pugl-header-ISC.txt zyn-fusion-ui/deps/pugl/COPYING
Roboto-Apache-2.0.txt docs/licenses/Apache-2.0.txt
LICENSES
    if [[ $platform == windows ]]; then
        cp "$fusion_dir/deps/libuv/LICENSE" "$dir/licenses/libuv-MIT.txt"
        # The statically linked FFTW, Mini-XML, liblo and zlib.
        cp -a "$deps_prefix/share/licenses/." "$dir/licenses/"
    fi
}

out="$dist_dir/$platform"
rm -rf "$out"
mkdir -p "$out/VST3" "$out/CLAP"

cp -a "$build_dir/bin/Zynth.vst3" "$out/VST3/"
stage_resources "$out/VST3/Zynth.vst3/Contents/Resources"

cp "$build_dir/bin/Zynth.clap" "$out/CLAP/"
stage_resources "$out/CLAP/Zynth"

archive="$dist_dir/Zynth-$platform-x86_64.zip"
rm -f "$archive"
(
    cd "$out"
    zip -qr "$archive" VST3 CLAP
)

echo "Plugins: $out"
echo "Archive: $archive"
