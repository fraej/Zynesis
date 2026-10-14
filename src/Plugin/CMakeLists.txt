if(WIN32)
    find_package(OpenGL REQUIRED)
else()
    find_package(OpenGL REQUIRED COMPONENTS OpenGL GLX)
endif()

# DPF supplies the VST3 and CLAP wrappers and the embedded OpenGL editor,
# which hosts the Zyn-Fusion UI.  The synth itself is zynesis_core.
set(ZYNESIS_FORMATS vst3 clap)
dpf_add_plugin(Zynesis
    TARGETS ${ZYNESIS_FORMATS}
    UI_TYPE opengl
    FILES_DSP
        Zynesis.cpp
    FILES_UI
        ZynesisUI.cpp)

target_compile_definitions(Zynesis PUBLIC
    DGL_OPENGL
    HAVE_DGL)
target_include_directories(Zynesis PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_BINARY_DIR}/src)
target_link_libraries(Zynesis-dsp PUBLIC zynesis_core)

foreach(format ${ZYNESIS_FORMATS})
    if(WIN32)
        target_link_libraries(Zynesis-${format} PRIVATE
            ws2_32
            winmm
            wsock32
            iphlpapi
            winpthread)
    else()
        target_link_libraries(Zynesis-${format} PRIVATE
            OpenGL::OpenGL
            OpenGL::GLX)
    endif()
    # dpf-opengl is a static archive.  Keep the GL provider libraries on the
    # final link line even though the archive appears later than them.
    target_link_options(Zynesis-${format} PRIVATE -Wl,--no-as-needed)
endforeach()
