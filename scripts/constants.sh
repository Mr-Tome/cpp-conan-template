#!/bin/bash

export PROJECT_NAME="cpp-conan-template"
export destination="$HOME/.configuration-dependencies/$PROJECT_NAME"

# Set up colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}$1${NC}"
}