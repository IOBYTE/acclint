cmake_minimum_required(VERSION 3.1)

project (acclint VERSION 0.1 LANGUAGES CXX)

configure_file(config.h.in config.h)

add_executable(acclint acclint.cpp ac3d.cpp ac3d.h)

target_compile_features(acclint PUBLIC cxx_std_17)
target_include_directories(acclint PUBLIC "${PROJECT_BINARY_DIR}")
target_compile_options(acclint PUBLIC $<$<CXX_COMPILER_ID:GNU>:-Wno-psabi -Wall -Wextra -Wpedantic>)
target_link_libraries(acclint PUBLIC $<$<CXX_COMPILER_ID:GNU>:stdc++fs>)
