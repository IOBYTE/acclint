cmake_minimum_required(VERSION 3.1)

project (acclint VERSION 0.1 LANGUAGES CXX)

configure_file(config.h.in config.h)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

add_executable(acclint acclint.cpp ac3d.cpp ac3d.h)

target_include_directories(acclint PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           )
