cmake_minimum_required(VERSION 3.9)

project(acclint VERSION 0.1 LANGUAGES CXX)

configure_file(config.h.in config.h)

find_package(ZLIB REQUIRED)
include_directories(${ZLIB_INCLUDE_DIR})

find_package(PNG REQUIRED)
include_directories(${PNG_INCLUDE_DIR})

find_package(OpenMP REQUIRED)

add_executable(acclint acclint.cpp ac3d.cpp ac3d.h triangleintersects.hpp)

target_compile_features(acclint PUBLIC cxx_std_20)
target_include_directories(acclint PUBLIC "${PROJECT_BINARY_DIR}")
target_compile_options(acclint PUBLIC $<$<CXX_COMPILER_ID:GNU>:-Wno-psabi -Wall -Wextra -Wpedantic>)
target_link_libraries(acclint PUBLIC $<$<CXX_COMPILER_ID:GNU>:stdc++fs> ${ZLIB_LIBRARY} ${PNG_LIBRARY} OpenMP::OpenMP_CXX)

install(TARGETS acclint DESTINATION bin)
