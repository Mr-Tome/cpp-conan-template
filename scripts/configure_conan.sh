#!/bin/bash

# Check if Python and pip are installed
if ! command -v python &> /dev/null || ! command -v pip &> /dev/null; then
    echo "Python and pip are required for Conan. Please install them first."
    exit 1
fi

# Check if Conan is already installed
if ! command -v conan &> /dev/null; then
    echo "Installing Conan package manager..."
    pip install conan
else
    echo "Conan is already installed. Checking version..."
    conan --version
fi

# Initialize Conan MinGW profile
echo "Setting up a Conan MinGW profile..."
cat > mingw_profile << EOL
[settings]
arch=x86_64
build_type=Release
compiler=gcc
compiler.version=14.1
compiler.libcxx=libstdc++11
os=Windows

[conf]
tools.cmake.cmaketoolchain:generator=Ninja
EOL


echo "Setting mingw_profile as default..."
conan profile detect --force
cp mingw_profile ~/.conan2/profiles/default

# Create conanfile.txt if it doesn't exist
if [[ ! -f "conanfile.txt" ]]; then
    echo "Creating default conanfile.txt..."
    cat > conanfile.txt << EOL
[requires]
# Add your dependencies here
# Example:
# boost/1.83.0
# fmt/10.1.1

[generators]
CMakeDeps
CMakeToolchain

[options]
# Add package-specific options here
# Example:
# boost:shared=True

[layout]
cmake_layout
EOL
    echo "Created default conanfile.txt"
fi

echo "Conan configuration complete!"