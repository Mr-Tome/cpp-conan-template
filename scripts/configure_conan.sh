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

