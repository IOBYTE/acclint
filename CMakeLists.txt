cmake_minimum_required(VERSION 3.12)

project(acclint VERSION 0.1 LANGUAGES CXX C)

# An optimised build unless asked for another. With no build type, single
# config generators build with no optimisation at all.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release MinSizeRel RelWithDebInfo)
endif()

configure_file(config.h.in config.h)

find_package(ZLIB REQUIRED)
include_directories(${ZLIB_INCLUDE_DIR})

find_package(PNG REQUIRED)
include_directories(${PNG_INCLUDE_DIR})

find_package(OpenMP REQUIRED)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

find_package(Sanitizers)

if(WIN32)
    add_executable(acclint acclint.cpp ac3d.cpp ac3d.h triangleintersects.hpp ya_getopt.c ya_getopt.h)
    set_source_files_properties(acclint.cpp ya_getopt.c PROPERTIES COMPILE_DEFINITIONS "_CRT_SECURE_NO_WARNINGS")
else()
    add_executable(acclint acclint.cpp ac3d.cpp ac3d.h triangleintersects.hpp)
endif()
add_sanitizers(acclint)

target_compile_features(acclint PUBLIC cxx_std_20)
target_include_directories(acclint PUBLIC "${PROJECT_BINARY_DIR}")
target_compile_options(acclint PUBLIC $<$<CXX_COMPILER_ID:GNU>:-Wno-psabi -Wall -Wextra -Wpedantic>)
target_link_libraries(acclint PUBLIC $<$<CXX_COMPILER_ID:GNU>:stdc++fs> ${ZLIB_LIBRARY} ${PNG_LIBRARY} OpenMP::OpenMP_CXX)

install(TARGETS acclint DESTINATION bin)
