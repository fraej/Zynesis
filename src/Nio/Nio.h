/*
  ZynAddSubFX - a software synthesizer

  Nio.h - IO Interface
  Copyright (C) 2016 Mark McCurry

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
*/
#ifndef NIO_H
#define NIO_H
#include <string>
#include <set>

namespace zyn {

class WavFile;
class Master;

/**Interface to the audio/MIDI I/O subsystem.
 *
 * The plugin host owns audio and MIDI I/O, so Nio.cpp implements these as
 * no-ops; they remain because the synth core reports and controls I/O
 * through them. */
namespace Nio
{
    bool setSource(std::string name);
    bool setSink(std::string name);

    std::set<std::string> getSources(void);
    std::set<std::string> getSinks(void);
    std::string getSource(void);
    std::string getSink(void);

    //Complete Master Swaps to ONLY BE CALLED FROM RT CONTEXT
    void masterSwap(Master *master);

    //Wave writing
    void waveNew(class WavFile *wave);
    void waveStart(void);
    void waveStop(void);

    void setAudioCompressor(bool isEnabled);
    bool getAudioCompressor(void);
};

}

#endif
