# Third-party components

Zynesis is distributed under the GNU General Public License, version 2 or
(at your option) any later version (`COPYING`). It contains or links the
components below. Every license listed is compatible with distributing the
combined plugin under GPL-2.0-or-later. The packaged plugins carry these
license texts in their `licenses` folder.

## Compiled into the plugin binary

| Component | Source | License | License text |
| --- | --- | --- | --- |
| ZynAddSubFX synth core | `src/` | GPL-2.0-or-later | `COPYING`, `AUTHORS.txt` |
| DPF (DISTRHO Plugin Framework) | `DPF/` | ISC | `DPF/LICENSE` |
| CLAP headers (in DPF) | `DPF/distrho/src/clap` | MIT | `DPF/distrho/src/clap/LICENSE` |
| DPF's VST3 interface ("travesty", no Steinberg SDK code) | `DPF/distrho/src/travesty` | ISC | `DPF/LICENSE` |
| pugl (in DPF) | `DPF/dgl/src/pugl-upstream` | ISC | `DPF/dgl/src/pugl-upstream/COPYING` |
| NanoVG (in DPF) | `DPF/dgl/src/nanovg` | zlib | `DPF/dgl/src/nanovg/LICENSE.txt` |
| DejaVu Sans font (embedded by DPF) | `DPF/dgl/src/resources` | Bitstream Vera / DejaVu | `DPF/dgl/src/resources/LICENSE-DejaVuSans.ttf.txt` |
| RtOsc | `rtosc/` | MIT | `rtosc/LICENSE` |
| TLSF allocator, by Matthew Conte | `tlsf/` | BSD (upstream ships no license text) | `tlsf/README.md` |

Linux builds link the system's FFTW (GPL-2.0-or-later), Mini-XML, liblo
(LGPL-2.1-or-later) and zlib dynamically. Windows builds link these statically:

| Component | License | License text in the Windows package |
| --- | --- | --- |
| FFTW 3.3.10 | GPL-2.0-or-later | `fftw/COPYING` |
| Mini-XML 3.3.1 | Apache-2.0 with an explicit GPLv2/LGPLv2 linking exception | `mxml/LICENSE`, `mxml/NOTICE` |
| liblo 0.32 | LGPL-2.1-or-later | `liblo/COPYING` |
| zlib 1.3.1 | zlib | `zlib/LICENSE` |

## Editor runtime (separate library, `libzest`)

The editor is the Zyn-Fusion UI, built from `zyn-fusion-ui/` into a separate
shared library that the plugin loads at runtime.

| Component | License | License text |
| --- | --- | --- |
| Zyn-Fusion (mruby-zest, mruby-widget-lib) | LGPL-2.1 | `zyn-fusion-ui/LICENSE` |
| mruby-qml-parse, mruby-qml-spawn | MIT | `zyn-fusion-ui/src/mruby-qml-*/LICENSE` |
| osc-bridge | MIT | `zyn-fusion-ui/src/osc-bridge/README.adoc` |
| mruby | MIT | `zyn-fusion-ui/mruby/LICENSE` |
| mruby gems: errno, dir, dir-glob, file-stat, process, regexp-pcre, nanovg, set | MIT | each gem's `README.md`, `LICENSE` or `mrbgem.rake` |
| PCRE 8 | BSD-3-Clause | `zyn-fusion-ui/deps/mruby-regexp-pcre/pcre/LICENCE` |
| NanoVG | zlib | `zyn-fusion-ui/deps/nanovg/LICENSE.txt` |
| libuv (Windows; Linux uses the system library) | MIT | `zyn-fusion-ui/deps/libuv/LICENSE` |
| RtOsc header, pugl header | MIT, ISC | `zyn-fusion-ui/deps/rtosc/LICENSE`, `zyn-fusion-ui/deps/pugl/COPYING` |

## Data shipped next to the binaries

| Data | License |
| --- | --- |
| Roboto fonts, © Google 2012 | Apache-2.0 (`docs/licenses/Apache-2.0.txt`) |
| Entypo pictogram font, by Daniel Bruce (www.entypo.com) | CC BY-SA |
| Factory banks (`banks/`) | From the ZynAddSubFX instrument collection. Some banks state their own terms in their folder, for example *The Mysterious Bank* (CC BY) and *Cris Owl Alvarez* (GPL-2.0, patches LGPL); keep those files with the banks. |

## Trademarks

VST is a trademark of Steinberg Media Technologies GmbH. Zynesis uses no
Steinberg SDK code; the VST3 interface comes from DPF. Roboto is a trademark
of Google, and Entypo of Daniel Bruce.
