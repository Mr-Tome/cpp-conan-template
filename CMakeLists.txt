cmake_minimum_required(VERSION 3.21)

# Project definition with artifact versions
project(cpp-conan-template 
    VERSION 1.0.0
    DESCRIPTION "C++ project template with Conan 2.0"
    LANGUAGES CXX
)
# TODO: Test with 23 (and 26?)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Find dependencies
find_package(fmt REQUIRED)

# Add executable
add_executable(${PROJECT_NAME} source/main.cpp)

# Link libraries
target_link_libraries(${PROJECT_NAME} PRIVATE fmt::fmt)