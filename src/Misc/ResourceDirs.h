/*
  Zynth - a ZynAddSubFX-based synthesizer plugin

  ResourceDirs.h - Locate the resources shipped with the plugin binary

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
*/
#ifndef ZYN_RESOURCE_DIRS_H
#define ZYN_RESOURCE_DIRS_H

#include <string>
#include <vector>

namespace zyn {

/**
 * Directories that may hold the resources shipped with the plugin (the
 * editor runtime and its assets, and the factory banks), derived from the
 * location of the binary that contains this code:
 *
 *   Zynth.vst3/Contents/<arch>/<binary>  ->  Zynth.vst3/Contents/Resources
 *   <dir>/Zynth.clap                     ->  <dir>/Zynth
 *
 * The directories are not checked for existence.
 */
std::vector<std::string> bundledResourceDirs();

}

#endif
