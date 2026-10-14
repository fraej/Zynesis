set(CMAKE_CXX_STANDARD 20)

option(CompileTests "Build the unit tests" ON)
option(CompileExtensiveTests "Also run tests that take a long time" OFF)
option(Werror "Treat warnings in the synth core as errors" ON)
option(BuildForDebug "Build without optimization and with debug info" OFF)
set(ZynFusionDir "" CACHE STRING
    "Developers only: directory with a locally built libzest.so for the Linux editor")
mark_as_advanced(FORCE ZynFusionDir)

########### Dependencies ###########
include(CheckCXXCompilerFlag)
include(CheckCXXSourceCompiles)
include(CheckFunctionExists)
include(CheckIncludeFileCXX)

# On Windows, pkg-config only sees the cross-compiled dependency prefix; see
# cmake/mingw-w64-x86_64.cmake.
find_package(PkgConfig REQUIRED)
find_package(ZLIB REQUIRED)
pkg_check_modules(FFTW3F REQUIRED fftw3f)
pkg_check_modules(MXML mxml4)
if(NOT MXML_FOUND)
    pkg_check_modules(MXML REQUIRED mxml)
endif()
pkg_check_modules(LIBLO REQUIRED liblo>=0.26)
if(WIN32)
    # The static liblo archive uses Winsock and the IP helper API.
    list(APPEND LIBLO_LIBRARIES ws2_32 iphlpapi)
    set(PTHREAD_LIBRARY winpthread)
else()
    set(PTHREAD_LIBRARY pthread)
endif()

CHECK_FUNCTION_EXISTS(sched_setscheduler HAVE_SCHEDULER)
check_include_file_cxx(complex HAVE_CPP_STD_COMPLEX)
CHECK_CXX_SOURCE_COMPILES(
    "int main(){
    __asm__ __volatile__ (\"fistpl 0\");
    return 0;}" HAVE_X86_FISTPL)

########### Compiler settings ###########
if(HAVE_SCHEDULER AND NOT APPLE)
    add_definitions(-DHAVE_SCHEDULER=${HAVE_SCHEDULER})
endif()
if(HAVE_CPP_STD_COMPLEX)
    add_definitions(-DHAVE_CPP_STD_COMPLEX=1)
endif()
if(HAVE_X86_FISTPL)
    add_definitions(-DASM_F2I_YES)
endif()
if(WIN32)
    add_definitions(-DWIN32)
endif()
# The synth core talks to its editor over OSC only.
add_definitions(-DNO_UI=1)

add_compile_options(-Wall -Wextra)
# Check for -W... and if available, add compile option -Wno-...
function (zyn_disable_warning W_FLAG)
    string(TOUPPER "${W_FLAG}" CACHE_VAR)
    string(REPLACE "-" "_" CACHE_VAR "${CACHE_VAR}")
    set(_CACHE_VAR "HAVE_WARNING_${CACHE_VAR}")
    check_cxx_compiler_flag("-W${W_FLAG}" "${CACHE_VAR}")
    if (${${CACHE_VAR}})
        add_compile_options("-Wno-${W_FLAG}")
    endif()
endfunction ()

zyn_disable_warning("stringop-truncation")
zyn_disable_warning("vla-cxx-extension")
zyn_disable_warning("nan-infinity-disabled")
zyn_disable_warning("inconsistent-missing-override")

if(BuildForDebug)
    set(CMAKE_BUILD_TYPE "Debug")
    add_compile_options("$<$<CONFIG:Debug>:-O0;-g3;-ggdb;-Wpointer-arith>")
else()
    set(CMAKE_BUILD_TYPE "Release")
    add_compile_options("$<$<CONFIG:Release>:-O3;-ffast-math;-fomit-frame-pointer>")
    set(ZynSSEOptions -msse;-msse2;-mfpmath=sse)
    check_cxx_compiler_flag("${ZynSSEOptions} -Werror" SUPPORT_SSE)
    if(SUPPORT_SSE)
        add_compile_options("$<$<CONFIG:Release>:${ZynSSEOptions}>")
    endif()
endif()

if(NOT WIN32)
    add_definitions(-fPIC)
endif()

########### Synth core ###########
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/zyn-version.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/zyn-version.h)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/zyn-config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/zyn-config.h)

include_directories(
    ${ZLIB_INCLUDE_DIRS} ${FFTW3F_INCLUDE_DIRS} ${MXML_INCLUDE_DIRS}
    ${LIBLO_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR})
link_directories(${FFTW3F_LIBRARY_DIRS} ${MXML_LIBRARY_DIRS} ${LIBLO_LIBRARY_DIRS})

add_library(zynth_core STATIC
    version.cpp
    globals.cpp
    ../tlsf/tlsf.c
    Containers/MultiPseudoStack.cpp
    Containers/NotePool.cpp
    Containers/ScratchString.cpp
    DSP/AnalogFilter.cpp
    DSP/CombFilter.cpp
    DSP/FFTwrapper.cpp
    DSP/Filter.cpp
    DSP/FormantFilter.cpp
    DSP/MoogFilter.cpp
    DSP/Reverter.cpp
    DSP/SVFilter.cpp
    DSP/Unison.cpp
    DSP/Value_Smoothing_Filter.cpp
    Effects/Alienwah.cpp
    Effects/Chorus.cpp
    Effects/CombFilterBank.cpp
    Effects/Distortion.cpp
    Effects/DynamicFilter.cpp
    Effects/EQ.cpp
    Effects/Echo.cpp
    Effects/Effect.cpp
    Effects/EffectLFO.cpp
    Effects/EffectMgr.cpp
    Effects/Phaser.cpp
    Effects/Reverb.cpp
    Effects/Reverse.cpp
    Effects/Sympathetic.cpp
    Misc/Allocator.cpp
    Misc/Bank.cpp
    Misc/BankDb.cpp
    Misc/CallbackRepeater.cpp
    Misc/Config.cpp
    Misc/Master.cpp
    Misc/MemLocker.cpp
    Misc/Microtonal.cpp
    Misc/MiddleWare.cpp
    Misc/MsgParsing.cpp
    Misc/Part.cpp
    Misc/PresetExtractor.cpp
    Misc/Recorder.cpp
    Misc/ResourceDirs.cpp
    Misc/Schema.cpp
    Misc/Util.cpp
    Misc/WavFile.cpp
    Misc/WaveShapeSmps.cpp
    Misc/XMLwrapper.cpp
    Nio/Nio.cpp
    Params/ADnoteParameters.cpp
    Params/Controller.cpp
    Params/EnvelopeParams.cpp
    Params/FilterParams.cpp
    Params/LFOParams.cpp
    Params/PADnoteParameters.cpp
    Params/Presets.cpp
    Params/PresetsArray.cpp
    Params/PresetsStore.cpp
    Params/SUBnoteParameters.cpp
    Synth/ADnote.cpp
    Synth/Envelope.cpp
    Synth/LFO.cpp
    Synth/ModFilter.cpp
    Synth/OscilGen.cpp
    Synth/PADnote.cpp
    Synth/Portamento.cpp
    Synth/Resonance.cpp
    Synth/SUBnote.cpp
    Synth/SynthNote.cpp
    Synth/WatchPoint.cpp
    UI/ConnectionDummy.cpp)

target_link_libraries(zynth_core PUBLIC
    ${ZLIB_LIBRARIES}
    ${FFTW3F_LIBRARIES}
    ${MXML_LIBRARIES}
    ${LIBLO_LIBRARIES}
    ${PTHREAD_LIBRARY}
    ${CMAKE_DL_LIBS}
    rtosc
    rtosc-cpp)

if(Werror)
    target_compile_options(zynth_core PRIVATE -Werror)
endif()

add_subdirectory(Plugin)

if(CompileTests)
    add_subdirectory(Tests)
endif()
