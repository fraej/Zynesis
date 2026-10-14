/*
  Zynth - a ZynAddSubFX-based synthesizer plugin

  ResourceDirs.cpp - Locate the resources shipped with the plugin binary

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
*/
#include "ResourceDirs.h"

#include <filesystem>
#include <system_error>

#ifdef WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

namespace zyn {

// Path of the binary (plugin module or executable) containing this code.
static std::filesystem::path modulePath()
{
#ifdef WIN32
    HMODULE module = nullptr;
    char path[1024];
    if(!GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                               GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                           reinterpret_cast<LPCSTR>(&modulePath), &module))
        return {};
    const DWORD length = GetModuleFileNameA(module, path, sizeof(path));
    if(length == 0 || length == sizeof(path))
        return {};
    return std::filesystem::path(path);
#else
    Dl_info info;
    if(!dladdr(reinterpret_cast<void *>(&modulePath), &info) || !info.dli_fname)
        return {};
    std::error_code ec;
    return std::filesystem::absolute(info.dli_fname, ec);
#endif
}

std::vector<std::string> bundledResourceDirs()
{
    const std::filesystem::path module = modulePath();
    if(module.empty())
        return {};

    const std::filesystem::path dir = module.parent_path();
    return {
        (dir / ".." / "Resources").lexically_normal().string(),
        (dir / module.stem()).string(),
    };
}

}
