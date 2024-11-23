cmake_minimum_required(VERSION 3.12)
project(cpp-conan-template CXX)

# Conan setup
list(APPEND CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})
list(APPEND CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})

# Enable C++11
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Find dependencies
find_package(Boost REQUIRED COMPONENTS filesystem system)
find_package(CURL REQUIRED)
find_package(SQLite3 REQUIRED)

# Add executable
add_executable(${PROJECT_NAME} source/main.cpp)

# Link libraries
target_link_libraries(${PROJECT_NAME} 
    PRIVATE 
        Boost::filesystem 
        Boost::system
        CURL::libcurl
        SQLite::SQLite3
)