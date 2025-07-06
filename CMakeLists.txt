cmake_minimum_required(VERSION 3.21)

# Function to read project configuration from .project file
function(read_project_config)
    set(PROJECT_CONFIG_NAME "mosquito-defense-system")
    set(PROJECT_CONFIG_VERSION "1.0.0") 
    set(PROJECT_CONFIG_DESCRIPTION "Modern C++ project template with Conan 2.0")
    
    # Try to read .project file
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.project")
        file(READ "${CMAKE_CURRENT_SOURCE_DIR}/.project" PROJECT_FILE_CONTENT)
        string(REPLACE "\n" ";" PROJECT_FILE_LINES ${PROJECT_FILE_CONTENT})
        
        foreach(line ${PROJECT_FILE_LINES})
            string(STRIP "${line}" line)
            if(NOT "${line}" STREQUAL "" AND NOT "${line}" MATCHES "^#")
                if("${line}" MATCHES "^([^=]+)=(.*)$")
                    set(key "${CMAKE_MATCH_1}")
                    set(value "${CMAKE_MATCH_2}")
                    # Remove quotes
                    string(REGEX REPLACE "^[\"']|[\"']$" "" value "${value}")
                    
                    if("${key}" STREQUAL "PROJECT_NAME")
                        set(PROJECT_CONFIG_NAME "${value}")
                    elseif("${key}" STREQUAL "PROJECT_VERSION")
                        set(PROJECT_CONFIG_VERSION "${value}")
                    elseif("${key}" STREQUAL "PROJECT_DESCRIPTION")
                        set(PROJECT_CONFIG_DESCRIPTION "${value}")
                    endif()
                endif()
            endif()
        endforeach()
    else()
        message(WARNING ".project file not found, using defaults")
    endif()
    
    # Set variables in parent scope
    set(PROJECT_CONFIG_NAME "${PROJECT_CONFIG_NAME}" PARENT_SCOPE)
    set(PROJECT_CONFIG_VERSION "${PROJECT_CONFIG_VERSION}" PARENT_SCOPE)
    set(PROJECT_CONFIG_DESCRIPTION "${PROJECT_CONFIG_DESCRIPTION}" PARENT_SCOPE)
endfunction()

# Read project configuration
read_project_config()

# Use values from Conan if available, otherwise use .project values
if(DEFINED PROJECT_NAME_FROM_CONAN)
    set(ACTUAL_PROJECT_NAME "${PROJECT_NAME_FROM_CONAN}")
    set(ACTUAL_PROJECT_VERSION "${PROJECT_VERSION_FROM_CONAN}")
    set(ACTUAL_PROJECT_DESCRIPTION "${PROJECT_DESCRIPTION_FROM_CONAN}")
    message(STATUS "Using project configuration from Conan")
else()
    set(ACTUAL_PROJECT_NAME "${PROJECT_CONFIG_NAME}")
    set(ACTUAL_PROJECT_VERSION "${PROJECT_CONFIG_VERSION}")
    set(ACTUAL_PROJECT_DESCRIPTION "${PROJECT_CONFIG_DESCRIPTION}")
    message(STATUS "Using project configuration from .project file")
endif()

# Project definition with values from configuration
project(${ACTUAL_PROJECT_NAME}
    VERSION ${ACTUAL_PROJECT_VERSION}
    DESCRIPTION "${ACTUAL_PROJECT_DESCRIPTION}"
    LANGUAGES CXX
)

# Function to get current C++ standard from .cppstd file
function(get_current_cpp_standard)
    set(std "20")  # Default
    
    # Check .cppstd file (managed by cpp_standard.sh)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.cppstd")
        file(READ "${CMAKE_CURRENT_SOURCE_DIR}/.cppstd" cppstd_content)
        string(STRIP "${cppstd_content}" std)
        
        # Validate the standard
        if(NOT std MATCHES "^(17|20|23|26)$")
            message(WARNING "Invalid C++ standard in .cppstd: ${std}, using C++20")
            set(std "20")
        endif()
    endif()
    
    set(CURRENT_CXX_STD "${std}" PARENT_SCOPE)
endfunction()

# Enhanced C++ standard detection and configuration
function(configure_cpp_standard)
    # Get current C++ standard from .cppstd file
    get_current_cpp_standard()
    
    # Use .cppstd value if available, otherwise use CMAKE_CXX_STANDARD or default
    if(CURRENT_CXX_STD)
        set(CMAKE_CXX_STANDARD ${CURRENT_CXX_STD})
    elseif(NOT DEFINED CMAKE_CXX_STANDARD)
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
    
    message(STATUS "Using C++${CMAKE_CXX_STANDARD} standard (from .cppstd)")
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
message(STATUS "Project Name: ${PROJECT_NAME}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Project Version: ${PROJECT_VERSION}")
message(STATUS "==================================")
