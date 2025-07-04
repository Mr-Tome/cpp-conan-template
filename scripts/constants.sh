#!/bin/bash

# Modern constants and utility functions for cpp-conan-template
# Enhanced with better error handling and cross-platform support

# Project configuration
export PROJECT_NAME="cpp-conan-template"
export PROJECT_VERSION="1.0.0"
export destination="$HOME/.configuration-dependencies/$PROJECT_NAME"

# Build configuration
export DEFAULT_BUILD_TYPE="Release"
export DEFAULT_CXX_STANDARD="20"

# Color definitions for enhanced output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export NC='\033[0m' # No Color

# Unicode symbols for better visual feedback
export CHECKMARK='✓'
export CROSSMARK='✗'
export ARROW='→'
export BULLET='•'
export ROCKET='🚀'
export GEAR='⚙️'
export PACKAGE='📦'
export HAMMER='🔨'
export SPARKLES='✨'

# Enhanced utility functions

# Print status messages with icons
print_status() {
    echo -e "${GREEN}[INFO]${NC} ${BULLET} $1"
}

# Print error messages with enhanced formatting
print_error() {
    echo -e "${RED}[ERROR]${NC} ${CROSSMARK} $1" >&2
}

# Print warning messages
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} ⚠️  $1"
}

# Print debug messages (only if DEBUG is set)
print_debug() {
    if [[ "${DEBUG}" == "1" || "${VERBOSE}" == "1" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1" >&2
    fi
}

# Print success messages
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} ${CHECKMARK} $1"
}

# Print step indicators
print_step() {
    echo -e "${BLUE}[STEP]${NC} ${ARROW} $1"
}

# Print section headers
print_header() {
    echo -e "\n${CYAN}${1}${NC}"
    printf '%*s\n' "${#1}" '' | tr ' ' '='
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get OS type in a standardized way
get_os_type() {
    case "$OSTYPE" in
        linux*)   echo "linux" ;;
        darwin*)  echo "macos" ;;
        msys*)    echo "windows" ;;
        cygwin*)  echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

# Get number of CPU cores
get_cpu_cores() {
    local cores
    case "$(get_os_type)" in
        linux)
            cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 4)
            ;;
        macos)
            cores=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
            ;;
        windows)
            cores=${NUMBER_OF_PROCESSORS:-4}
            ;;
        *)
            cores=4
            ;;
    esac
    echo "$cores"
}

# Validate project structure
validate_project_structure() {
    local errors=0
    
    # Check for essential files
    if [[ ! -f "CMakeLists.txt" ]]; then
        print_error "CMakeLists.txt not found"
        ((errors++))
    fi
    
    if [[ ! -f "conanfile.py" && ! -f "conanfile.txt" ]]; then
        print_error "No conanfile.py or conanfile.txt found"
        ((errors++))
    fi
    
    # Check for source directory
    if [[ ! -d "src" && ! -f "main.cpp" && ! -f "source/main.cpp" ]]; then
        print_warning "No standard source directory found (src/, main.cpp, or source/main.cpp)"
    fi
    
    return $errors
}

# Create directory with error checking
safe_mkdir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        if mkdir -p "$dir" 2>/dev/null; then
            print_debug "Created directory: $dir"
        else
            print_error "Failed to create directory: $dir"
            return 1
        fi
    fi
    return 0
}

# Remove file/directory with error checking
safe_remove() {
    local target="$1"
    if [[ -e "$target" ]]; then
        if rm -rf "$target" 2>/dev/null; then
            print_debug "Removed: $target"
        else
            print_error "Failed to remove: $target"
            return 1
        fi
    fi
    return 0
}

# Check if we're in a git repository
is_git_repo() {
    git rev-parse --git-dir >/dev/null 2>&1
}

# Get git branch name if available
get_git_branch() {
    if is_git_repo; then
        git symbolic-ref --short HEAD 2>/dev/null || echo "detached"
    else
        echo "no-git"
    fi
}

# Print environment information
print_environment_info() {
    print_header "Environment Information"
    print_status "Project: $PROJECT_NAME v$PROJECT_VERSION"
    print_status "OS: $(get_os_type)"
    print_status "CPU cores: $(get_cpu_cores)"
    print_status "Git branch: $(get_git_branch)"
    print_status "Build type: ${BUILD_TYPE:-$DEFAULT_BUILD_TYPE}"
    print_status "C++ standard: ${CXX_STANDARD:-$DEFAULT_CXX_STANDARD}"
    
    if command_exists conan; then
        local conan_version
        conan_version=$(conan --version 2>/dev/null | cut -d' ' -f3 || echo "unknown")
        print_status "Conan version: $conan_version"
    else
        print_status "Conan: not installed"
    fi
    
    if command_exists cmake; then
        local cmake_version
        cmake_version=$(cmake --version 2>/dev/null | head -n1 | cut -d' ' -f3 || echo "unknown")
        print_status "CMake version: $cmake_version"
    else
        print_status "CMake: not installed"
    fi
}

# Timer functions for performance monitoring
start_timer() {
    export TIMER_START=$(date +%s)
}

end_timer() {
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - TIMER_START))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    if [ $minutes -gt 0 ]; then
        echo "${minutes}m ${seconds}s"
    else
        echo "${seconds}s"
    fi
}

# Cleanup function for script exit
cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        print_error "Script exited with error code: $exit_code"
    fi
}

# Set up error handling
set -E
trap cleanup_on_exit EXIT

# Enable debug mode if requested
if [[ "${DEBUG}" == "1" ]]; then
    set -x
    print_debug "Debug mode enabled"
fi