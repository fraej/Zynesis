if(WIN32)
    find_package(OpenGL REQUIRED)
else()
    find_package(OpenGL REQUIRED COMPONENTS OpenGL GLX)
endif()

# DPF supplies the VST3 component/controller pair and the embedded OpenGL
# editor, which hosts the Zyn-Fusion UI.  The synth itself is zynaddsubfx_core.
dpf_add_plugin(ZynAddSubFX
    TARGETS vst3
    UI_TYPE opengl
    FILES_DSP
        ZynAddSubFX.cpp
    FILES_UI
        ZynAddSubFX-UI-Zest.cpp)

target_compile_definitions(ZynAddSubFX PUBLIC
    DGL_OPENGL
    HAVE_DGL)
target_include_directories(ZynAddSubFX PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_BINARY_DIR}/src)
target_link_libraries(ZynAddSubFX-dsp PUBLIC zynaddsubfx_core)
if(WIN32)
    target_link_libraries(ZynAddSubFX-vst3 PRIVATE
        ws2_32
        winmm
        wsock32
        iphlpapi
        winpthread)
else()
    target_link_libraries(ZynAddSubFX-vst3 PRIVATE
        OpenGL::OpenGL
        OpenGL::GLX)
endif()
# dpf-opengl is a static archive.  Keep the GL provider libraries on the
# final link line even though the archive appears later than them.
target_link_options(ZynAddSubFX-vst3 PRIVATE -Wl,--no-as-needed)
