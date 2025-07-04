cmake_minimum_required(VERSION 3.21)

# Project definition with version
project(cpp-conan-template 
    VERSION 1.0.0
    DESCRIPTION "C++ project template with Conan 2.0"
    LANGUAGES CXX
)

# Enhanced C++ standard detection and configuration
function(configure_cpp_standard)
    # Default to C++20 if not specified
    if(NOT DEFINED CMAKE_CXX_STANDARD)
        set(CMAKE_CXX_STANDARD 20)
    endif()
    
    # Ensure we have a valid C++ standard
    set(SUPPORTED_STANDARDS 17 20 23 26)
    if(NOT CMAKE_CXX_STANDARD IN_LIST SUPPORTED_STANDARDS)
        message(WARNING "Unsupported C++ standard: ${CMAKE_CXX_STANDARD}. Falling back to C++20")
        set(CMAKE_CXX_STANDARD 20)
    endif()
    
    # Apply the standard globally
    set(CMAKE_CXX_STANDARD ${CMAKE_CXX_STANDARD} PARENT_SCOPE)
    set(CMAKE_CXX_STANDARD_REQUIRED ON PARENT_SCOPE)
    set(CMAKE_CXX_EXTENSIONS OFF PARENT_SCOPE)
    
    message(STATUS "Using C++${CMAKE_CXX_STANDARD} standard")
endfunction()

# Configure the C++ standard
configure_cpp_standard()

# Enhanced compiler warnings and options
function(configure_compiler_options target)
    # Base warnings for all compilers
    if(MSVC)
        target_compile_options(${target} PRIVATE 
            /W4 /WX-  # High warning level, but don't treat warnings as errors
            /permissive-  # Disable non-conforming code
            /Zc:__cplusplus  # Enable proper __cplusplus macro
        )
        
        # MSVC-specific options for newer C++ standards
        if(CMAKE_CXX_STANDARD GREATER_EQUAL 20)
            target_compile_options(${target} PRIVATE /std:c++20)
        endif()
        if(CMAKE_CXX_STANDARD GREATER_EQUAL 23)
            target_compile_options(${target} PRIVATE /std:c++latest)
        endif()
        
    else()
        # GCC and Clang
        target_compile_options(${target} PRIVATE
            -Wall -Wextra -Wpedantic
            -Wshadow -Wnon-virtual-dtor -Wcast-align -Wunused
            -Woverloaded-virtual -Wconversion -Wsign-conversion
        )
    endif()
    
    # Add debug/release specific options
    target_compile_options(${target} PRIVATE
        $<$<CONFIG:Debug>:-DDEBUG -g -O0>
        $<$<CONFIG:Release>:-DNDEBUG -O3>
        $<$<CONFIG:RelWithDebInfo>:-DNDEBUG -O2 -g>
        $<$<CONFIG:MinSizeRel>:-DNDEBUG -Os>
    )
endfunction()

# Enhanced feature detection for different C++ standards
function(configure_cpp_features target)
    # C++17 features (baseline)
    target_compile_features(${target} PRIVATE cxx_std_17)
    
    # C++20 features
    if(CMAKE_CXX_STANDARD GREATER_EQUAL 20)
        target_compile_features(${target} PRIVATE cxx_std_20)
        target_compile_definitions(${target} PRIVATE 
            CPP_TEMPLATE_HAS_CPP20=1
        )
    endif()
    
    # C++23 features
    if(CMAKE_CXX_STANDARD GREATER_EQUAL 23)
        target_compile_definitions(${target} PRIVATE 
            CPP_TEMPLATE_HAS_CPP23=1
        )
    endif()
    
    # C++26 features (future-proofing)
    if(CMAKE_CXX_STANDARD GREATER_EQUAL 26)
        target_compile_definitions(${target} PRIVATE 
            CPP_TEMPLATE_HAS_CPP26=1
        )
    endif()
endfunction()

# Find dependencies
find_package(fmt REQUIRED)
find_package(spdlog REQUIRED)

# Create main executable
add_executable(${PROJECT_NAME})

# Add source files
target_sources(${PROJECT_NAME} PRIVATE
    src/main.cpp
    src/app.cpp
)

# Add include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    include
    src  # Allow internal headers
)

# Configure C++ features and compiler options
configure_cpp_features(${PROJECT_NAME})
configure_compiler_options(${PROJECT_NAME})

# Link libraries
target_link_libraries(${PROJECT_NAME} PRIVATE 
    fmt::fmt
    spdlog::spdlog
)

# Create interface libraries for common settings (reusable for other targets)
add_library(project_options INTERFACE)
add_library(project_warnings INTERFACE)

# Configure project options
target_compile_features(project_options INTERFACE cxx_std_${CMAKE_CXX_STANDARD})

# Configure warnings based on compiler
if(MSVC)
    target_compile_options(project_warnings INTERFACE /W4)
else()
    target_compile_options(project_warnings INTERFACE 
        -Wall -Wextra -Wpedantic
        -Wshadow -Wnon-virtual-dtor -Wcast-align -Wunused
        -Woverloaded-virtual -Wconversion -Wsign-conversion
    )
endif()

# Link options to main target
target_link_libraries(${PROJECT_NAME} PRIVATE 
    project_options 
    project_warnings
)

# Installation rules
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
)

# Export compile commands for IDEs
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Print configuration summary
message(STATUS "=== C++ Template Configuration ===")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Project Version: ${PROJECT_VERSION}")
message(STATUS "==================================")
