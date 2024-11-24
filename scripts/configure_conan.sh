#!/bin/bash

source scripts/constants.sh

# Check if Python and pip are installed
if ! command -v python &> /dev/null || ! command -v pip &> /dev/null; then
    print_error "Python and pip are required for Conan. Please install them first."
    exit 1
fi

# Check if Conan is already installed
if ! command -v conan &> /dev/null; then
    print_status "Installing Conan package manager..."
    pip install conan
else
    print_status "Conan is already installed. Checking version..."
    conan --version
fi

# Set paths
mingw_path="$destination/mingw64"
cmake_path="$destination/cmake-3.29.3-windows-x86_64"

# Show debug info
print_status "Using paths:"
print_status "MinGW: $mingw_path"
print_status "CMake: $cmake_path"

# Initialize Conan MinGW profile
print_status "Creating a Conan MinGW profile..."

# Create the profiles directory if it doesn't exist
mkdir -p ~/.conan2/profiles

# Convert to Windows paths with double backslashes for the profile
cmake_win_path=$(cygpath -w "$cmake_path/bin/cmake.exe" | sed 's/\\/\\\\/g')
mingw_win_path=$(cygpath -w "$mingw_path/bin" | sed 's/\\/\\\\/g')
gcc_win_path=$(cygpath -w "$mingw_path/bin/gcc.exe" | sed 's/\\/\\\\/g')
gxx_win_path=$(cygpath -w "$mingw_path/bin/g++.exe" | sed 's/\\/\\\\/g')
ninja_win_path=$(cygpath -w "$mingw_path/bin/ninja.exe" | sed 's/\\/\\\\/g')
cmake_bin_win_path=$(cygpath -w "$cmake_path/bin" | sed 's/\\/\\\\/g')

# Create the default profile directly (skip detect)
cat > ~/.conan2/profiles/default << EOL
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.version=14.1
compiler.libcxx=libstdc++11
os=Windows

[conf]
tools.cmake.cmaketoolchain:generator=Ninja
tools.cmake:cmake_program="${cmake_win_path}"
tools.build.ninja:ninja_program="${ninja_win_path}"
tools.build:compiler_executables={"c": "${gcc_win_path}", "cpp": "${gxx_win_path}"}

[buildenv]
CC="${gcc_win_path}"
CXX="${gxx_win_path}"
CMAKE="${cmake_win_path}"
CONAN_CMAKE_PROGRAM="${cmake_win_path}"
CMAKE_MAKE_PROGRAM="${ninja_win_path}"
PATH=["${mingw_win_path}", "${cmake_bin_win_path}"]
EOL

print_status "MinGW profile created as default"
print_status "Profile contents:"
cat ~/.conan2/profiles/default

# Create conanfile.txt if it doesn't exist
if [[ ! -f "conanfile.txt" ]]; then
    print_status "Creating default conanfile.txt..."
    cat > conanfile.txt << EOL
[requires]
fmt/10.1.1

[generators]
CMakeDeps
CMakeToolchain

[options]
*:shared=False

[layout]
cmake_layout
EOL
    print_status "Created default conanfile.txt"
fi

print_status "Conan configuration complete!"