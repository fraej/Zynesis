# ZynAddSubFX VST3

The [ZynAddSubFX](https://github.com/zynaddsubfx/zynaddsubfx) synthesizer as a
self-contained VST3 instrument for Linux and Windows, with the Zyn-Fusion
editor embedded. The plugin bundle carries the editor runtime, its assets, the
factory banks and the license files, so it needs nothing else installed.

![Zyn-Fusion Add Synth editor](docs/zyn-fusion-add.png)

ZynAddSubFX offers additive, subtractive and PAD synthesis engines, a
waveform generator with up to 128 harmonics, analog-modeled, formant and
state-variable filters, envelopes and LFOs, a full effect rack, kits and
layered instruments, microtonal scales, and over 1100 instruments.

## Building

Both builds run on Linux and produce `dist/<platform>/ZynAddSubFX.vst3` and
`dist/ZynAddSubFX-<platform>-x86_64.zip`. CI builds both on every push
(`.github/workflows/ci.yml`) and uploads the bundles as artifacts.

### Linux

Install the dependencies (Ubuntu/Kubuntu 24.04 package names), then build:

```sh
sudo apt install build-essential bison cmake pkg-config ruby rake zip \
    libfftw3-dev libmxml-dev liblo-dev zlib1g-dev libuv1-dev \
    libx11-dev libxcursor-dev libxext-dev libxrandr-dev \
    libgl-dev libglx-dev libopengl-dev libdbus-1-dev
./scripts/build-vst3.sh linux
```

### Windows (cross-build from Linux)

Install the MinGW-w64 toolchain and the build tools, then build:

```sh
sudo apt install gcc-mingw-w64-x86-64-posix g++-mingw-w64-x86-64-posix \
    autoconf automake libtool bison cmake make pkg-config ruby rake zip curl
./scripts/build-vst3.sh windows
```

Use the `posix` threading variant of MinGW-w64. If the `win32` variant is
installed too, select `posix` with
`sudo update-alternatives --config x86_64-w64-mingw32-gcc` (and `-g++`).

On first use, `scripts/build-windows-deps.sh` downloads pinned, SHA-256
verified sources of zlib, FFTW, Mini-XML and liblo and cross-compiles them as
static libraries into `build-win-deps/prefix`. The resulting plugin imports
only Windows system DLLs.

### Options

| Variable          | Default                 | Purpose                               |
| ----------------- | ----------------------- | ------------------------------------- |
| `BUILD_DIR`       | `build-<platform>`      | CMake build directory                 |
| `DIST_DIR`        | `dist`                  | Output directory                      |
| `WIN_DEPS_PREFIX` | `build-win-deps/prefix` | Cross-compiled Windows dependencies   |
| `MINGW_HOST`      | `x86_64-w64-mingw32`    | Cross toolchain prefix                |
| `FFTW_URL`, `FFTW_SHA256`, ... | pinned release | Dependency mirror and checksum (`FFTW`, `MXML`, `ZLIB`, `LIBLO`) |

The Zyn-Fusion runtime (`libzest`) builds inside `zyn-fusion-ui/`; delete
`zyn-fusion-ui/libzest.so` or `libzest.dll` to rebuild it.

## Installing

- Linux: copy `ZynAddSubFX.vst3` to `~/.vst3/`.
- Windows: copy `ZynAddSubFX.vst3` to `C:\Program Files\Common Files\VST3\`.

Then rescan plugins in the DAW.

## Development

Build the synth core, the plugin and the unit tests with CMake directly:

```sh
cmake -S . -B build
cmake --build build --parallel
ctest --test-dir build
```

`-DWerror=ON` (the default) treats warnings in the synth core as errors.

| Path            | Contents                                                  |
| --------------- | --------------------------------------------------------- |
| `src/`          | Synth core, the VST3 plugin (`src/Plugin`) and unit tests |
| `banks/`        | Factory instrument banks                                  |
| `zyn-fusion-ui/`| Zyn-Fusion editor runtime (mruby-zest)                    |
| `DPF/`          | DISTRHO Plugin Framework: VST3 wrapper and editor host    |
| `rtosc/`, `tlsf/` | Realtime OSC and memory allocator libraries             |
| `scripts/`      | Build and packaging scripts                               |
| `cmake/`        | MinGW-w64 toolchain file                                  |

`DPF`, `rtosc` and `zyn-fusion-ui` are vendored from their upstream projects,
without their examples, tests and documentation.

## License

ZynAddSubFX is available under the GPL-2.0-or-later license (`COPYING`); see
`AUTHORS.txt` for its authors. Zyn-Fusion is LGPL-2.1, DPF is ISC. The bundle
ships these licenses and those of the statically linked libraries in
`Contents/Resources/licenses`.
