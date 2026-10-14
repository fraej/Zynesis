#!/usr/bin/env bash
# Cross-compile the static Windows libraries needed by the VST3 build
# (FFTW single precision, Mini-XML, zlib and liblo) with MinGW-w64.
#
# The result is a prefix with include/ and lib/ that
# scripts/build-vst3-windows.sh consumes through WIN_DEPS_PREFIX.
set -euo pipefail

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
host=${MINGW_HOST:-x86_64-w64-mingw32}
work_dir=${WIN_DEPS_WORK_DIR:-"$root_dir/build-win-deps"}
prefix=${WIN_DEPS_PREFIX:-"$work_dir/prefix"}
jobs=${JOBS:-$(nproc)}

# Pinned sources.  Override the URL (and hash) to use a mirror.
fftw_url=${FFTW_URL:-https://www.fftw.org/fftw-3.3.10.tar.gz}
fftw_sha256=${FFTW_SHA256:-56c932549852cddcfafdab3820b0200c7742675be92179e59e6215b340e26467}
mxml_url=${MXML_URL:-https://github.com/michaelrsweet/mxml/releases/download/v3.3.1/mxml-3.3.1.tar.gz}
mxml_sha256=${MXML_SHA256:-0c663ed1fe393b5619f80101798202eea43534abd7c8aff389022fd8c1dacc32}
zlib_url=${ZLIB_URL:-https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz}
zlib_sha256=${ZLIB_SHA256:-9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23}
liblo_url=${LIBLO_URL:-https://github.com/radarsat1/liblo/releases/download/0.32/liblo-0.32.tar.gz}
liblo_sha256=${LIBLO_SHA256:-5df05f2a0395fc5ac90f6b538b8c82bb21941406fd1a70a765c7336a47d70208}

for tool in "$host-gcc" "$host-g++" "$host-ar" curl make sha256sum tar; do
    if ! command -v "$tool" >/dev/null; then
        echo "missing required tool: $tool" >&2
        exit 1
    fi
done

download_dir="$work_dir/downloads"
src_dir="$work_dir/src"
mkdir -p "$download_dir" "$src_dir" "$prefix"

# fetch NAME URL SHA256: download (cached), verify and unpack into
# $src_dir/NAME.  Mirrors use different top-level directory names, so the
# first path component is always stripped.
fetch() {
    local name=$1 url=$2 sha256=$3
    local archive="$download_dir/$name.tar.gz"
    if [[ ! -f "$archive" ]]; then
        curl -fL --retry 3 -o "$archive.part" "$url"
        mv "$archive.part" "$archive"
    fi
    if ! echo "$sha256  $archive" | sha256sum -c --quiet -; then
        echo "checksum mismatch for $archive" >&2
        exit 1
    fi
    rm -rf "${src_dir:?}/$name"
    mkdir -p "$src_dir/$name"
    tar -xzf "$archive" -C "$src_dir/$name" --strip-components=1
}

# install_licenses NAME FILE...: copy license files of a statically linked
# library so the plugin package can ship them.
install_licenses() {
    local name=$1 file
    shift
    for file in "$@"; do
        install -D -m 644 "$src_dir/$name/$file" "$prefix/share/licenses/$name/$file"
    done
}

configure_args=(--host="$host" --prefix="$prefix" --disable-shared --enable-static)

if [[ ! -f "$prefix/lib/libz.a" ]]; then
    fetch zlib "$zlib_url" "$zlib_sha256"
    make -C "$src_dir/zlib" -f win32/Makefile.gcc PREFIX="$host-" \
        -j"$jobs" libz.a
    make -C "$src_dir/zlib" -f win32/Makefile.gcc PREFIX="$host-" \
        BINARY_PATH="$prefix/bin" INCLUDE_PATH="$prefix/include" \
        LIBRARY_PATH="$prefix/lib" install
    install_licenses zlib LICENSE
fi

if [[ ! -f "$prefix/lib/libfftw3f.a" ]]; then
    fetch fftw "$fftw_url" "$fftw_sha256"
    (
        cd "$src_dir/fftw"
        ./configure "${configure_args[@]}" --enable-float --enable-sse2 \
            --enable-avx --with-our-malloc --disable-fortran
        make -j"$jobs"
        make install
    )
    install_licenses fftw COPYING
fi

if [[ ! -f "$prefix/lib/pkgconfig/mxml.pc" ]]; then
    fetch mxml "$mxml_url" "$mxml_sha256"
    (
        cd "$src_dir/mxml"
        # mxml-file.c uses read()/write() without including <io.h> on
        # Windows, which newer GCC versions reject.
        CPPFLAGS="-include io.h" ./configure "${configure_args[@]}"
        # Only the library is needed; the test program and docs do not
        # cross-build cleanly.
        make -j"$jobs" libmxml.a
        install -D -m 644 libmxml.a "$prefix/lib/libmxml.a"
        install -D -m 644 mxml.h "$prefix/include/mxml.h"
        install -D -m 644 mxml.pc "$prefix/lib/pkgconfig/mxml.pc"
    )
    install_licenses mxml LICENSE NOTICE
fi

if [[ ! -f "$prefix/lib/liblo.a" ]]; then
    fetch liblo "$liblo_url" "$liblo_sha256"
    (
        cd "$src_dir/liblo"
        ./configure "${configure_args[@]}" --disable-tests \
            --disable-network-tests --disable-tools --disable-examples
        make -j"$jobs"
        make install
    )
    install_licenses liblo COPYING
fi

echo "Windows dependencies: $prefix"
