# ZynAddSubFX VST3 build

The build scripts produce a self-contained VST3 instrument bundle with the
embedded Zyn-Fusion editor. Each bundle carries the plugin module, the
Zyn-Fusion runtime and its QML/font/schema assets, the factory banks and the
license files, so it does not depend on the source tree or a system
Zyn-Fusion installation.

The legacy LV2/VST2 targets are disabled by the scripts. Enable them in a
custom CMake build with `-DLegacyPluginFormats=ON`.

Both builds run in CI on every push (`.github/workflows/vst3.yml`), which
uploads the bundles as workflow artifacts.

## Linux

Install the build dependencies (Ubuntu/Kubuntu 24.04 package names):

```sh
sudo apt install build-essential bison cmake pkg-config ruby rake \
    libfftw3-dev libmxml-dev liblo-dev zlib1g-dev libuv1-dev \
    libx11-dev libxcursor-dev libxext-dev libxrandr-dev \
    libgl-dev libglx-dev libopengl-dev libdbus-1-dev
```

Then build:

```sh
./scripts/build-vst3-linux.sh
```

The result is `build-vst3/bin/ZynAddSubFX.vst3`. Copy it to `~/.vst3/` to
install it. The script stages `libzest.so`, the QML/font/schema assets, the
factory banks and the licenses in `Contents/Resources`.

For a development build, set `ZynFusionDir` to a directory containing a
locally built `libzest.so`.

## Windows cross-build from Linux

Install the MinGW-w64 toolchain and build tools:

```sh
sudo apt install gcc-mingw-w64-x86-64-posix g++-mingw-w64-x86-64-posix \
    autoconf automake libtool bison cmake ninja-build make ruby rake zip curl
```

Use the `posix` threading variant of MinGW-w64. If the `win32` variant is
installed as well, select the `posix` one:

```sh
sudo update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix
sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix
```

Then build:

```sh
./scripts/build-vst3-windows.sh
```

The script:

1. Runs `scripts/build-windows-deps.sh` if the dependency prefix is missing.
   It downloads pinned, SHA-256-verified sources of zlib 1.3.1, FFTW 3.3.10,
   Mini-XML 3.3.1 and liblo 0.32, and cross-compiles them as static
   libraries into `build-win-deps/prefix`, together with their licenses.
2. Builds the Zyn-Fusion runtime (`libzest.dll`) with MinGW-w64.
3. Configures the project with `cmake/mingw-w64-x86_64.cmake` and builds the
   `ZynAddSubFX-vst3` target.
4. Packages `dist/ZynAddSubFX.vst3` and
   `dist/ZynAddSubFX-windows-x86_64.zip`.

The bundle layout is:

```text
ZynAddSubFX.vst3/Contents/
  x86_64-win/ZynAddSubFX.vst3   plugin module; imports only Windows system DLLs
  x86_64-win/libzest.dll        Zyn-Fusion runtime
  x86_64-win/qml, font, schema  editor assets, found relative to libzest.dll
  Resources/banks               factory instrument banks
  Resources/licenses            ZynAddSubFX, Zyn-Fusion, DPF and the
                                statically linked libraries
```

To install, extract `ZynAddSubFX.vst3` from the archive into
`C:\Program Files\Common Files\VST3\` and rescan plugins in the DAW.

These environment variables override the defaults:

| Variable                         | Default                 | Purpose                                 |
| -------------------------------- | ----------------------- | --------------------------------------- |
| `WIN_DEPS_PREFIX`                | `build-win-deps/prefix` | Cross-compiled dependency prefix        |
| `WIN_DEPS_WORK_DIR`              | `build-win-deps`        | Dependency downloads and sources        |
| `BUILD_DIR`                      | `build-vst3-win`        | CMake build directory                   |
| `DIST_DIR`                       | `dist`                  | Package output directory                |
| `MINGW_HOST`                     | `x86_64-w64-mingw32`    | Cross toolchain prefix                  |
| `FFTW_URL`, `FFTW_SHA256`, ...   | pinned upstream release | Dependency source mirror and checksum   |

The `*_URL`/`*_SHA256` pairs exist for `FFTW`, `MXML`, `ZLIB` and `LIBLO`.

To configure the cross-build by hand, pass the toolchain file and the
dependency prefix. The toolchain restricts pkg-config to that prefix, so
native development packages installed for the Linux build do not leak into
the Windows build:

```sh
cmake -S . -B build-vst3-win -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake \
    -DZYN_WIN_DEPS_PREFIX="$PWD/build-win-deps/prefix" \
    -DGuiModule=zest -DLegacyPluginFormats=OFF -DCompileTests=OFF
cmake --build build-vst3-win --target ZynAddSubFX-vst3
```

## Zyn-Fusion runtime

Zyn-Fusion builds inside `zyn-fusion-ui/`. The scripts build it only when
`zyn-fusion-ui/package/libzest.so` (Linux) or `zyn-fusion-ui/libzest.dll`
(Windows) is missing; delete that file to rebuild it after changing the
Zyn-Fusion sources. Both platforms share `zyn-fusion-ui/mruby/build`, so the
scripts clear it before each runtime build.

The vendored `DPF`, `rtosc` and `zyn-fusion-ui` trees match their upstream
revisions; keep local changes out of them where possible so they can be
updated. The trailing-whitespace and YAML lint checks skip them.
