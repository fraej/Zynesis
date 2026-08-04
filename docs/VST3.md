# ZynAddSubFX VST3 build

The focused Linux build produces an embedded Zyn-Fusion VST3 instrument and
leaves the legacy plugin formats disabled by default.

```sh
./scripts/build-vst3-linux.sh
```

The resulting bundle is `build-vst3/bin/ZynAddSubFX.vst3`.  The script stages
the pinned Zyn-Fusion runtime, QML/font/schema assets, factory banks, and
license files in `Contents/Resources`, so the editor does not depend on the
working directory or a system Zyn-Fusion installation.

For a development build, set `ZynFusionDir` to a directory containing a
locally-built `libzest.so`.  Enable the old formats explicitly with
`-DLegacyPluginFormats=ON`.

## Windows cross-build

On Kubuntu, after installing the MinGW-w64 and Ninja toolchain plus the
cross-compiled dependency prefix, run:

```sh
./scripts/build-vst3-windows.sh
```

This creates `dist/ZynAddSubFX-windows-x86_64.zip`. Extract the included
`ZynAddSubFX.vst3` directory into:

```text
C:\Program Files\Common Files\VST3\
```

Then rescan plugins in the Windows DAW. The package contains the Windows
VST3 module, `libzest.dll`, QML/font/schema resources, and factory banks.
