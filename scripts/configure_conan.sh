#!/bin/bash

# Check if Python and pip are installed
if ! command -v python &> /dev/null || ! command -v pip &> /dev/null; then
    echo "Python and pip are required for Conan. Please install them first."
    exit 1
fi
