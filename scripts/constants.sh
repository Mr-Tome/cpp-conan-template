#!/bin/bash

export PROJECT_NAME="cpp-conan-template"
export PROJECT_VERSION="1.0.0"
export destination="$HOME/.configuration-dependencies/$PROJECT_NAME"

# Set up colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}
# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}
# Function to print debug messages
print_debug() {
    if [[ "${DEBUG}" == "1" || "${VERBOSE}" == "1" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1" >&2
    fi
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to print step indicators
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}
