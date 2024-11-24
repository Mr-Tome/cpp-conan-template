#!/bin/bash

source scripts/constants.sh

cmake_ver=3.29.3
op_sys=windows-x86_64

#let's check the final destination before we actually do anything
destination_dep="$destination/cmake-$cmake_ver-$op_sys"
mingw_path="$destination/mingw64"

if [ -d "$destination_dep" ]; then
    # Convert paths to Windows format with proper escaping
    CMAKE=$(cygpath -w "${destination_dep}/bin/cmake.exe" | sed 's/\\/\\\\/g')
    GCC=$(cygpath -w "${mingw_path}/bin/gcc.exe" | sed 's/\\/\\\\/g')
    GXX=$(cygpath -w "${mingw_path}/bin/g++.exe" | sed 's/\\/\\\\/g')
    NINJA=$(cygpath -w "${mingw_path}/bin/ninja.exe" | sed 's/\\/\\\\/g')

    # Convert paths for PATH variable
    MINGW_BIN=$(cygpath -w "${mingw_path}/bin" | sed 's/\\/\\\\/g')
    CMAKE_BIN=$(cygpath -w "${destination_dep}/bin" | sed 's/\\/\\\\/g')

    print_status "Using paths:"
    print_status "CMAKE: ${CMAKE}"
    print_status "GCC: ${GCC}"
    print_status "GXX: ${GXX}"
    print_status "NINJA: ${NINJA}"

    # Set up environment
    export PATH="${MINGW_BIN};${CMAKE_BIN};${PATH}"
    print_status "PATH: ${PATH}"

    # Create build directory if it doesn't exist
    mkdir -p build/Release
    cd build
    
    print_status "Installing dependencies with Conan..."
    # Create a temporary conan profile for this build
    cat > conan_profile.tmp << EOL
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.version=14.1
compiler.libcxx=libstdc++11
os=Windows

[conf]
tools.cmake.cmaketoolchain:generator=Ninja
tools.cmake:cmake_program=${CMAKE}
tools.build:jobs=8
tools.gnu:make_program=${NINJA}
tools.build:compiler_executables={"c":"${GCC}", "cpp":"${GXX}"}

[buildenv]
CC=${GCC}
CXX=${GXX}
CMAKE=${CMAKE}
CONAN_CMAKE_PROGRAM=${CMAKE}
CMAKE_MAKE_PROGRAM=${NINJA}
PATH=["${MINGW_BIN}", "${CMAKE_BIN}"]
EOL
    
    # Call conan install with the temporary profile
    conan install .. --profile:build=conan_profile.tmp --profile:host=conan_profile.tmp --build=missing -v
    
    if [ $? -eq 0 ]; then
        print_status "Building the project using Ninja..."
        BUILD_DIR=$(pwd)
        cd ..
        
        # Get absolute path to the toolchain file
        TOOLCHAIN_PATH=$(cygpath -w "${BUILD_DIR}/Release/generators/conan_toolchain.cmake")
        
        "${destination_dep}/bin/cmake.exe" . \
            -B build \
            -G "Ninja" \
            -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_PATH}" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_MAKE_PROGRAM="${mingw_path}/bin/ninja.exe" \
            -DCMAKE_C_COMPILER="${mingw_path}/bin/gcc.exe" \
            -DCMAKE_CXX_COMPILER="${mingw_path}/bin/g++.exe"
            
        if [ $? -eq 0 ]; then
            print_status "Running Ninja build..."
            cd build
            "${mingw_path}/bin/ninja.exe"
            if [ $? -eq 0 ]; then
                print_status "Build completed successfully!"
            else
                print_error "Ninja build failed"
                exit 1
            fi
        else
            print_error "CMake configuration failed"
            exit 1
        fi
    else
        print_error "Conan install failed"
        exit 1
    fi
    
    # Clean up temporary profile
    rm conan_profile.tmp
    
else
    print_error "CMake v${cmake_ver} does not exist, please run ./configure"
    exit 1
fi