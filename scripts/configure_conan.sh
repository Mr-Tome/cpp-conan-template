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

# Initialize Conan default profile
echo "Setting up Conan default profile..."
conan profile detect

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