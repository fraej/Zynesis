if(WIN32)
    find_package(OpenGL REQUIRED)
else()
    find_package(OpenGL REQUIRED COMPONENTS OpenGL GLX)
endif()

# DPF supplies the VST3 and CLAP wrappers and the embedded OpenGL editor,
# which hosts the Zyn-Fusion UI.  The synth itself is zynth_core.
set(ZYNTH_FORMATS vst3 clap)
dpf_add_plugin(Zynth
    TARGETS ${ZYNTH_FORMATS}
    UI_TYPE opengl
    FILES_DSP
        Zynth.cpp
    FILES_UI
        ZynthUI.cpp)

target_compile_definitions(Zynth PUBLIC
    DGL_OPENGL
    HAVE_DGL)
target_include_directories(Zynth PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_BINARY_DIR}/src)
target_link_libraries(Zynth-dsp PUBLIC zynth_core)

foreach(format ${ZYNTH_FORMATS})
    if(WIN32)
        target_link_libraries(Zynth-${format} PRIVATE
            ws2_32
            winmm
            wsock32
            iphlpapi
            winpthread)
    else()
        target_link_libraries(Zynth-${format} PRIVATE
            OpenGL::OpenGL
            OpenGL::GLX)
    endif()
    # dpf-opengl is a static archive.  Keep the GL provider libraries on the
    # final link line even though the archive appears later than them.
    target_link_options(Zynth-${format} PRIVATE -Wl,--no-as-needed)
endforeach()
