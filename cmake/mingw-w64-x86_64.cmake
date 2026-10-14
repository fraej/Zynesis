set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_VERSION 10.0)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER x86_64-w64-mingw32-windres)

# Prefix holding the cross-compiled static dependencies, as produced by
# scripts/build-windows-deps.sh.  Pass -DZYN_WIN_DEPS_PREFIX=... or set the
# environment variable of the same name.
if(NOT ZYN_WIN_DEPS_PREFIX AND DEFINED ENV{ZYN_WIN_DEPS_PREFIX})
    set(ZYN_WIN_DEPS_PREFIX "$ENV{ZYN_WIN_DEPS_PREFIX}")
endif()
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES ZYN_WIN_DEPS_PREFIX)

# Only let pkg-config see cross-compiled packages.  Host .pc files, such as a
# native liblo installed for the Linux build, would add /usr/include.
set(_zyn_pkg_config_libdir /usr/x86_64-w64-mingw32/lib/pkgconfig)
if(ZYN_WIN_DEPS_PREFIX)
    set(_zyn_pkg_config_libdir
        "${ZYN_WIN_DEPS_PREFIX}/lib/pkgconfig:${_zyn_pkg_config_libdir}")
endif()
set(ENV{PKG_CONFIG_LIBDIR} "${_zyn_pkg_config_libdir}")
set(ENV{PKG_CONFIG_PATH} "")

set(CMAKE_FIND_ROOT_PATH
    ${ZYN_WIN_DEPS_PREFIX}
    /usr/x86_64-w64-mingw32)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
