function(quick_test test_name)
    add_executable(${test_name} "${test_name}.cpp")
    add_test(NAME ${test_name}
             COMMAND ${test_name})
    target_link_libraries(${test_name} zynaddsubfx_core ${ARGN})
endfunction()

#for tests looking for files stored in the source dir
add_definitions(-DSOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}")

quick_test(AdNoteTest)
quick_test(AllocatorTest)
quick_test(ControllerTest)
quick_test(EchoTest)
quick_test(EffectTest)
quick_test(KitTest)
quick_test(MemoryStressTest)
quick_test(MicrotonalTest)
quick_test(MsgParseTest)
quick_test(OscilGenTest)
quick_test(PadNoteTest)
quick_test(PortamentoTest)
quick_test(RandTest)
quick_test(SubNoteTest)
quick_test(TriggerTest)
quick_test(UnisonTest)
quick_test(WatchTest)
quick_test(XMLwrapperTest)
quick_test(ReverseTest)
quick_test(PluginTest)
quick_test(MiddlewareTest)

if(NOT WIN32)
    #std::thread issues with mingw
    quick_test(MqTest)
    quick_test(MessageTest)

    if(LIBLO_FOUND)
        quick_test(PortChecker lo-server)
        target_include_directories(PortChecker PRIVATE ${RTOSC_TEST_INCLUDE_DIR})
        target_link_directories(PortChecker PRIVATE ${RTOSC_TEST_LIB_DIR})
    endif()

    add_executable(save-osc SaveOSC.cpp)
    target_compile_definitions(save-osc PRIVATE -DZYN_GIT_WORKTREE="${CMAKE_SOURCE_DIR}")
    target_link_libraries(save-osc zynaddsubfx_core)
    # test all presets
    add_test(SaveOscPresets save-osc)
    # test the most insane XIZ file
    add_test(SaveOscBigFile save-osc ${CMAKE_SOURCE_DIR}/banks/olivers-100/0032-Drum\ Kit.xiz)
    # not realized, because it takes 15 minutes each time:
    if (CompileExtensiveTests)
        add_test(SaveOscAllFiles save-osc test-all)
    endif()

    execute_process(
        COMMAND git rev-parse --is-inside-work-tree
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE IS_GIT_REPO
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(IS_GIT_REPO STREQUAL "true")
        add_test(TrailingWhitespace ${CMAKE_SOURCE_DIR}/src/Tests/trailing-whitespace)
    endif()
endif()
