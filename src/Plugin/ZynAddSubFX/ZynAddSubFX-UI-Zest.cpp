/*
  ZynAddSubFX - a software synthesizer

  ZynAddSubFX-UI.cpp - DPF + ZynAddSubFX External UI
  Copyright (C) 2015-2016 Filipe Coelho
  Author: Filipe Coelho

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
*/

#if !defined(WIN32) && !defined(__APPLE__)
#include <string>
#include <cstdio>
#include <unistd.h>
#include "zyn-config.h"
#endif

// DPF includes
#include "DistrhoUI.hpp"
#include "DistrhoPluginUtils.hpp"
#ifdef WIN32
#include <windows.h>
#else
#ifndef __USE_GNU
#define __USE_GNU
#endif
#include <dlfcn.h>
#endif

 #ifdef WIN32
static HMODULE get_zyn_module()
{
    HMODULE module = nullptr;
    GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                           GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                       reinterpret_cast<LPCSTR>(&get_zyn_module), &module);
    return module;
}
 #endif

typedef void *zest_t;
struct zest_handles {
    zest_t *(*zest_open)(const char *);
    void (*zest_close)(zest_t*);
    void (*zest_setup)(zest_t*);
    void (*zest_draw)(zest_t*);
    void (*zest_motion)(zest_t*, int x, int y, int mod);
    void (*zest_scroll)(zest_t*, int x, int y, int dx, int dy, int mod);
    void (*zest_mouse)(zest_t *z, int button, int action, int x, int y, int mod);
    void (*zest_key)(zest_t *z, char *key, bool press);
    void (*zest_resize)(zest_t *z, int w, int h);
    void (*zest_special)(zest_t *z, int key, int press);
    int (*zest_tick)(zest_t*);
    void (*zest_forget_all_state) (zest_t*);
    zest_t *zest;
};

/* ------------------------------------------------------------------------------------------------------------
 * ZynAddSubFX UI class */

class ZynAddSubFXUI : public UI
{
public:
    ZynAddSubFXUI()
        : UI(1181, 659)
    {
        printf("[INFO] Opened the zynaddsubfx UI...\n");
#ifdef WIN32
        char path[1024];
        GetModuleFileNameA(get_zyn_module(), path, sizeof(path));
        char *last_separator = strrchr(path, '\\');
        if (last_separator)
            last_separator[1] = 0;
        strcat(path, "libzest.dll");
        printf("[DEBUG] Loading zest library from <%s>\n", path);
        handle = LoadLibrary(path);
        if(!handle)
            handle = LoadLibrary("./libzest.dll");
        if(!handle)
            handle = LoadLibrary("libzest.dll");
#elif defined __APPLE__
        handle = dlopen("@loader_path/libzest.dylib", RTLD_NOW | RTLD_LOCAL);
        if(!handle) // VST
            handle = dlopen("@loader_path/../Resources/libzest.dylib", RTLD_LAZY);
#else
        // A VST3 editor is loaded from the component bundle.  Resolve the
        // Zest runtime from Contents/Resources first so hosts do not depend
        // on their current working directory or a system installation.
        if (getBundlePath())
        {
            const char* const resources = getResourcePath(getBundlePath());
            if (resources && *resources)
            {
                std::string bundled = resources;
                bundled += "/libzest.so";
                if (access(bundled.c_str(), R_OK) == 0)
                    handle = dlopen(bundled.c_str(), RTLD_NOW | RTLD_LOCAL);
            }
        }
        if(zyn::fusion_dir && *zyn::fusion_dir)
        {
            std::string fusion = zyn::fusion_dir;
            fusion += "/libzest.so";
            if(access(fusion.c_str(), R_OK))
                fputs("Warning: CMake's ZynFusionDir does not contain a"
                      "\"libzest.so\" library - ignoring.", stderr);
            else
                handle = dlopen(fusion.c_str(), RTLD_LAZY);
        }
        if(!handle)
            handle = dlopen("./libzest.so", RTLD_LAZY);
        if(!handle)
            handle = dlopen("/opt/zyn-fusion/libzest.so", RTLD_LAZY);
        if(!handle)
            handle = dlopen("libzest.so", RTLD_LAZY);
#endif
        if(!handle) {
 #ifdef WIN32
            printf("[ERROR] Cannot Open libzest.dll\n");
 #else
            printf("[ERROR] Cannot Open libzest.so\n");
 #endif
#ifndef WIN32
            printf("[ERROR] '%s'\n", dlerror());
#endif
        }
        memset(&z, 0, sizeof(z));
#ifdef WIN32
#define get_sym(x) z.zest_##x = (decltype(z.zest_##x))GetProcAddress(handle, "zest_"#x)
#else
#define get_sym(x) z.zest_##x = (decltype(z.zest_##x))dlsym(handle, "zest_"#x)
#endif
        if(handle) {
            get_sym(open);
            get_sym(setup);
            get_sym(close);
            get_sym(draw);
            get_sym(tick);
            get_sym(key);
            get_sym(motion);
            get_sym(scroll);
            get_sym(mouse);
            get_sym(special);
            get_sym(resize);
            get_sym(forget_all_state);

            if (!z.zest_open || !z.zest_close || !z.zest_setup ||
                !z.zest_draw || !z.zest_tick || !z.zest_resize)
            {
                fputs("[ERROR] libzest.so is missing required symbols\n", stderr);
#ifdef WIN32
                FreeLibrary(handle);
#else
                dlclose(handle);
#endif
                handle = nullptr;
                memset(&z, 0, sizeof(z));
            }
        }
        oscPort = -1;
        printf("[INFO] Ready to run\n");
    }

    ~ZynAddSubFXUI() override
    {
        printf("[INFO:Zyn] zest_close()\n");
        if(z.zest)
            z.zest_close(z.zest);
#ifdef WIN32
#else
        if(handle)
        dlclose(handle);
#endif
    }

protected:
   /* --------------------------------------------------------------------------------------------------------
    * DSP/Plugin Callbacks */

   /**
      A parameter has changed on the plugin side.
      This is called by the host to inform the UI about parameter changes.
    */
    void parameterChanged(uint32_t index, float value) override
    {
        switch (index)
        {
        case kParamOscPort: {
            const int port = int(value+0.5f);

            if (oscPort != port)
            {
                oscPort = port;
                repaint();
            }
        } break;
        }
    }

   /**
      A program has been loaded on the plugin side.
      This is called by the host to inform the UI about program changes.
    */
    void programLoaded(uint32_t index) override
    {
        // Tell Zest that we need to reload the UI.
        // Currently Zyn-Fusion doesn't use built-in program,
        //   and this event may not be raised.
        if(z.zest && z.zest_forget_all_state)
            z.zest_forget_all_state(z.zest);
    }

   /**
      A state has changed on the plugin side.
      This is called by the host to inform the UI about state changes.
    */
    void stateChanged(const char* key, const char* value) override
    {
        // Tell Zest that we need to reload the UI.
        // This event will be raised when you load a preset from your host,
        //   or during UI loads.
        if(z.zest && z.zest_forget_all_state)
            z.zest_forget_all_state(z.zest);
    }

   /* --------------------------------------------------------------------------------------------------------
    * UI Callbacks */

    bool onScroll(const ScrollEvent &ev) override
    {
        if(z.zest && z.zest_scroll)
            z.zest_scroll(z.zest, ev.pos.getX(), ev.pos.getY(), ev.delta.getX(), ev.delta.getY(), ev.mod);
        return true;
    }

    bool onSpecial(const SpecialEvent &ev) override
    {
        printf("special event = %d, %d\n", ev.key, ev.press);
        if(z.zest && z.zest_special)
            z.zest_special(z.zest, ev.key, ev.press);
        return true;
    }

    bool onMouse(const MouseEvent &m) override
    {
        if(z.zest)
        {
            // Zest's legacy mouse callback stores only the button event and
            // consumes the latest cursor position separately.  Hosts are
            // allowed to send a button event without a preceding motion
            // event, so update the cursor explicitly before forwarding it.
            if (z.zest_motion)
                z.zest_motion(z.zest, m.pos.getX(), m.pos.getY(), m.mod);
            if (z.zest_mouse)
                z.zest_mouse(z.zest, m.button, m.press, m.pos.getX(), m.pos.getY(), m.mod);
        }
        return true;
    }

    bool onMotion(const MotionEvent &m) override
    {
        if(z.zest && z.zest_motion)
            z.zest_motion(z.zest, m.pos.getX(), m.pos.getY(), m.mod);
        return true;
    }

   /**
      A function called to draw the view contents with OpenGL.
    */
    void onDisplay() override
    {
        if(oscPort < 1)
            return;
        if(!z.zest) {
            if(!z.zest_open)
                return;
            if(!oscPort)
                return;
            printf("[INFO:Zyn] zest_open()\n");
            char address[1024];
            snprintf(address, sizeof(address), "osc.udp://127.0.0.1:%d",oscPort);
            printf("[INFO:Zyn] zest_open(%s)\n", address);

            z.zest = z.zest_open(address);
            printf("[INFO:Zyn] zest_setup(%s)\n", address);
            z.zest_setup(z.zest);
            // The host may deliver the initial resize before Zest exists.
            // Apply the current editor dimensions now so the embedded UI
            // does not remain confined to its 1181x659 default area.
            z.zest_resize(z.zest, getWidth(), getHeight());
        }

        z.zest_draw(z.zest);
    }

    bool onKeyboard(const KeyboardEvent &ev)
    {
        char c[2] = {};
        if(ev.key < 128)
            c[0] = ev.key;
        if(z.zest && c[0])
            z.zest_key(z.zest, c, ev.press);
        return true;
    }

    void uiIdle(void) override
    {
        if(z.zest) {
            if (z.zest_tick(z.zest)) {
                repaint();
            }
        }
    }

    void uiReshape(uint width, uint height)
    {
        if(z.zest)
            z.zest_resize(z.zest, width, height);
    }

private:
    int oscPort;
    zest_handles z;
#ifdef WIN32
    HMODULE handle = nullptr;
#else
    void *handle = nullptr;
#endif


    DISTRHO_DECLARE_NON_COPY_CLASS(ZynAddSubFXUI)
};

/* ------------------------------------------------------------------------------------------------------------
 * Create UI, entry point */

START_NAMESPACE_DISTRHO

UI* createUI()
{
    return new ZynAddSubFXUI();
}

END_NAMESPACE_DISTRHO
