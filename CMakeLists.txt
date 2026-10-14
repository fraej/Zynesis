cmake_minimum_required(VERSION 3.13)
project(zynth)
set(VERSION_MAJOR "3")
set(VERSION_MINOR "0")
set(VERSION_REVISION "7")
cmake_policy(SET CMP0072 NEW)

# DPF provides the VST3 and CLAP wrappers and the OpenGL editor host.  Keep its own
# examples and libraries out; the plugin target creates what it needs.
set(DPF_LIBRARIES OFF CACHE BOOL "Build DPF libraries" FORCE)
set(DPF_EXAMPLES OFF CACHE BOOL "Build DPF examples" FORCE)
add_subdirectory(DPF EXCLUDE_FROM_ALL)

set(RTOSC_NO_INSTALL TRUE)
include(rtosc/cmake/ColorMessage.cmake)
add_subdirectory(rtosc)
include_directories(rtosc/include)

enable_testing()
add_subdirectory(src)
