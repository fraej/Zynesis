/*
  ZynAddSubFX - a software synthesizer

  Nio.cpp - IO Interface (no-op, the plugin host owns audio and MIDI I/O)
  Copyright (C) 2016 Mark McCurry

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
*/
#include "Nio.h"

namespace zyn {
namespace Nio {

bool setSource(std::string) { return true; }
bool setSink(std::string) { return true; }

std::set<std::string> getSources(void) { return std::set<std::string>(); }
std::set<std::string> getSinks(void) { return std::set<std::string>(); }
std::string getSource(void) { return ""; }
std::string getSink(void) { return ""; }

void masterSwap(Master *) {}

void waveNew(WavFile *) {}
void waveStart(void) {}
void waveStop(void) {}

void setAudioCompressor(bool) {}
bool getAudioCompressor(void) { return false; }

}
}
