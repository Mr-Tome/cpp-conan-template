#!/bin/bash

# Robust make script with intelligent fallback strategies
# Tries multiple build configurations when one fails

set -e  # Exit on any error

# Source constants and utility functions
chmod +x scripts/constants.sh
source scripts/constants.sh

# Configuration
BUILD_TYPE=${BUILD_TYPE:-Release}
JOBS=${JOBS:-$(get_cpu_cores)}
ATTEMPTED_PROFILES=()

# Enhanced utility functions
detect_platform() {
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos" 
    else
        echo "linux"
    fi
}

check_python_dependencies() {
    print_header "Checking Python Dependencies"
    
    local python_cmd="python3"
    command_exists python3 || python_cmd="python"
    
    local pip_cmd="pip3"  
    command_exists pip3 || pip_cmd="pip"
    
    # Check if packaging is installed
    if ! $python_cmd -c "import packaging" 2>/dev/null; then
        print_warning "Python packaging library not found"
        print_status "Installing packaging library..."
        
        if $pip_cmd install packaging; then
            print_success "Python packaging library installed ✓"
        else
            print_error "Failed to install packaging library"
            print_status "This is required for conanfile.py version comparison"
            print_status "Please run: ./configure"
            exit 1
        fi
    else
        print_status "Python packaging library available ✓"
    fi
}

check_conan() {
    if ! command -v conan &> /dev/null; then
        print_error "Conan is not installed. Please run ./configure first"
        exit 1
    fi
    
    local version
    version=$(conan --version | cut -d' ' -f3)
    local major_version
    major_version=$(echo "$version" | cut -d'.' -f1)
    
    if [ "$major_version" != "2" ]; then
        print_error "Conan 2.x is required. Current version: $version"
        print_status "Please run: ./configure"
        exit 1
    fi
    
    print_status "Conan $version detected ✓"
}

check_cpp_standard_utility() {
    if [ ! -f "scripts/cpp_standard.sh" ]; then
        print_warning "C++ standard utility not found"
        print_status "Creating C++ standard utility script..."
        
        # Call configure to set up the utility
        if [ -f "./configure" ]; then
            print_status "Running ./configure to set up missing components..."
            ./configure
        else
            print_error "Configure script not found. Please ensure you have a complete template."
            exit 1
        fi
    else
        # Ensure it's executable
        chmod +x scripts/cpp_standard.sh
        print_status "C++ standard utility available ✓"
    fi
}

check_template_files() {
    print_header "Checking Template Configuration"
    
    # Check if conanfile.py has enhanced version
    if [ -f "conanfile.py" ]; then
        if grep -q "from packaging import version" conanfile.py; then
            print_status "Enhanced conanfile.py detected ✓"
        else
            print_warning "Legacy conanfile.py detected"
            print_status "Updating to enhanced version..."
            
            # Run configure to update files
            if [ -f "./configure" ]; then
                ./configure
            else
                print_error "Configure script not found"
                exit 1
            fi
        fi
    else
        print_error "No conanfile.py found. Please run ./configure first"
        exit 1
    fi
    
    # Check if CMakeLists.txt has enhanced version
    if [ -f "CMakeLists.txt" ]; then
        if grep -q "configure_cpp_standard" CMakeLists.txt; then
            print_status "Enhanced CMakeLists.txt detected ✓"
        else
            print_warning "Legacy CMakeLists.txt detected"
            print_status "Enhanced version will be used automatically"
        fi
    else
        print_error "No CMakeLists.txt found"
        exit 1
    fi
}

get_current_cpp_standard() {
    local std="20"  # Default
    
    # Check .cppstd file first
    if [ -f ".cppstd" ]; then
        std=$(cat .cppstd)
    fi
    
    # Validate the standard
    case "$std" in
        17|20|23|26)
            echo "$std"
            ;;
        *)
            print_warning "Invalid C++ standard in .cppstd: $std, using C++20"
            echo "20"
            ;;
    esac
}

show_cpp_standard_info() {
    local std=$(get_current_cpp_standard)
    
    print_status "Current C++ Standard: C++$std"
    
    # Show compiler compatibility
    if [ -x "scripts/cpp_standard.sh" ]; then
        scripts/cpp_standard.sh check "$std" 2>/dev/null || {
            print_warning "Compiler compatibility check failed"
            print_status "You can check manually with: ./scripts/cpp_standard.sh check $std"
        }
    fi
}

clean_build() {
    print_status "Cleaning build artifacts..."
    
    # Remove build directory
    if [ -d "build" ]; then
        rm -rf build
        print_status "Removed build directory"
    fi
    
    # Remove run script
    if [ -f "run" ]; then
        rm run
        print_status "Removed run script"
    fi
    
    # Remove CMake presets
    if [ -f "CMakeUserPresets.json" ]; then
        rm CMakeUserPresets.json
        print_status "Removed CMakeUserPresets.json"
    fi
    
    # Remove any temporary Conan files
    find . -name "conan_profile.tmp" -delete 2>/dev/null || true
    
    print_status "✅ Build cleanup completed"
}

# Get available Conan profiles
get_available_profiles() {
    local profiles=()
    
    # Check for default profile
    if [ -f ~/.conan2/profiles/default ]; then
        profiles+=("default")
    fi
    
    # Check for mingw profile
    if [ -f ~/.conan2/profiles/mingw ]; then
        profiles+=("mingw")
    fi
    
    # List all profiles in the profiles directory
    if [ -d ~/.conan2/profiles ]; then
        for profile in ~/.conan2/profiles/*; do
            if [ -f "$profile" ]; then
                local profile_name=$(basename "$profile")
                if [[ "$profile_name" != "default" && "$profile_name" != "mingw" ]]; then
                    profiles+=("$profile_name")
                fi
            fi
        done
    fi
    
    echo "${profiles[@]}"
}

# Try to build with a specific profile
run_cmake_configure() {
    local build_folder="$1"
    local toolchain_file="$2"
    local cpp_std="$3"
    local generator="$4"
    
    print_debug "Trying CMake configuration with generator: ${generator:-default}"
    
    # Prepare CMake arguments
    local cmake_args=(
        -B "$build_folder"
        -DCMAKE_TOOLCHAIN_FILE="build/$toolchain_file"
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
        -DCMAKE_CXX_STANDARD="$cpp_std"
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    )
    
    # Add generator if specified
    if [[ -n "$generator" ]]; then
        cmake_args=(-G "$generator" "${cmake_args[@]}")
    fi
    
    # Add source directory
    cmake_args=("${cmake_args[@]}" .)
    
    # Run CMake and capture both output and exit code
    print_debug "Running: cmake ${cmake_args[*]}"
    
    # Create a temporary file to capture stderr
    local cmake_output=$(mktemp)
    local cmake_stderr=$(mktemp)
    
    # Run cmake and capture exit code
    if cmake "${cmake_args[@]}" > "$cmake_output" 2> "$cmake_stderr"; then
        local exit_code=0
    else
        local exit_code=$?
    fi
    
    # Show output if there's useful information
    if [ -s "$cmake_output" ]; then
        print_debug "CMake output:"
        cat "$cmake_output" | sed 's/^/  /'
    fi
    
    # Show errors if there are any
    if [ -s "$cmake_stderr" ]; then
        print_debug "CMake errors:"
        cat "$cmake_stderr" | sed 's/^/  /'
    fi
    
    # Cleanup temp files
    rm -f "$cmake_output" "$cmake_stderr"
    
    return $exit_code
}

try_build_with_profile() {
    local profile="$1"
    local build_attempt="$2"
    
    print_step "Attempt $build_attempt: Trying profile '$profile'"
    
    # Skip if already attempted
    for attempted in "${ATTEMPTED_PROFILES[@]}"; do
        if [ "$attempted" = "$profile" ]; then
            print_warning "Profile '$profile' already attempted, skipping"
            return 1
        fi
    done
    
    ATTEMPTED_PROFILES+=("$profile")
    
    # Create build directory
    mkdir -p build
    cd build
    
    print_status "📦 Installing dependencies with profile: $profile..."
    
    # Get current C++ standard
    local cpp_std=$(get_current_cpp_standard)
    
    local conan_args=(
        ".."
        "--profile:build=$profile"
        "--profile:host=$profile"
        "-s" "build_type=$BUILD_TYPE"
        "--build=missing"
        "-c" "tools.build:jobs=$JOBS"
    )
    
    # Try Conan install
    if ! conan install "${conan_args[@]}"; then
        print_warning "Conan install failed with profile: $profile"
        cd ..
        return 1
    fi
    
    # Find the generated toolchain file
    local toolchain_file
    if [ -f "generators/conan_toolchain.cmake" ]; then
        toolchain_file="generators/conan_toolchain.cmake"
    elif [ -f "$BUILD_TYPE/generators/conan_toolchain.cmake" ]; then
        toolchain_file="$BUILD_TYPE/generators/conan_toolchain.cmake"
    else
        print_warning "Could not find conan_toolchain.cmake for profile: $profile"
        cd ..
        return 1
    fi
    
    cd ..
    
    print_status "⚙️  Configuring CMake with profile: $profile..."
    
    # Determine build folder
    local build_folder="build"
    if [ "$BUILD_TYPE" != "Release" ]; then
        build_folder="build/$BUILD_TYPE"
    fi
    
    # Try different CMake configurations based on profile
    local cmake_success=false
    
    # Strategy 1: Use detected generator from Conan (usually Ninja)
    if ! $cmake_success; then
        if run_cmake_configure "$build_folder" "$toolchain_file" "$cpp_std" ""; then
            cmake_success=true
            print_debug "CMake configuration successful with default generator"
        fi
    fi
    
    # Strategy 2: Force Ninja generator (for MinGW/GCC)
    if ! $cmake_success && [[ "$profile" == *"mingw"* || "$profile" == *"gcc"* ]]; then
        print_debug "Trying with forced Ninja generator..."
        if run_cmake_configure "$build_folder" "$toolchain_file" "$cpp_std" "Ninja"; then
            cmake_success=true
            print_debug "CMake configuration successful with Ninja generator"
        fi
    fi
    
    # Strategy 3: Force Visual Studio generator (for MSVC)
    if ! $cmake_success && [[ "$profile" == *"msvc"* ]]; then
        print_debug "Trying with Visual Studio generator..."
        if run_cmake_configure "$build_folder" "$toolchain_file" "$cpp_std" "Visual Studio 17 2022"; then
            cmake_success=true
            print_debug "CMake configuration successful with Visual Studio generator"
        fi
    fi
    
    # Strategy 4: Try Unix Makefiles as last resort
    if ! $cmake_success; then
        print_debug "Trying with Unix Makefiles generator..."
        if run_cmake_configure "$build_folder" "$toolchain_file" "$cpp_std" "Unix Makefiles"; then
            cmake_success=true
            print_debug "CMake configuration successful with Unix Makefiles"
        fi
    fi
    
    if ! $cmake_success; then
        print_warning "CMake configuration failed with profile: $profile"
        print_status "Check the debug output above for specific errors"
        return 1
    fi
    
    print_success "CMake configuration successful with profile: $profile"
    
    # Build the project
    print_status "🏗️  Building the project with profile: $profile (C++$cpp_std)..."
    if ! cmake --build "$build_folder" --config "$BUILD_TYPE" -j "$JOBS"; then
        print_warning "Build failed with profile: $profile"
        return 1
    fi
    
    print_success "Build completed successfully with profile: $profile!"
    
    # Create run script
    create_run_script "$build_folder" "$profile" "$cpp_std"
    return 0
}

build_with_fallback() {
    print_header "Building with intelligent fallback strategy"
    
    local platform
    platform=$(detect_platform)
    
    # Define build strategies based on platform and environment
    local strategies=()
    
    if [ "$platform" = "windows" ]; then
        # Windows strategies
        if [[ "$MSYSTEM" == "MINGW64" || "$MSYSTEM" == "MINGW32" ]]; then
            # We're in MINGW environment - prefer MinGW builds
            strategies+=("mingw")
            strategies+=("default")     # Try default as fallback
        else
            # Regular Windows environment - prefer MSVC
            strategies+=("default")
            strategies+=("mingw")
        fi
    else
        # Linux/macOS strategies
        strategies+=("default")
        
        # Add any custom profiles
        local available_profiles
        available_profiles=($(get_available_profiles))
        for prof in "${available_profiles[@]}"; do
            if [[ "$prof" != "default" ]]; then
                strategies+=("$prof")
            fi
        done
    fi
    
    print_status "Platform: $platform"
    print_status "Environment: ${MSYSTEM:-system}"
    print_status "Build strategies: ${strategies[*]}"
    
    # Show current C++ standard
    show_cpp_standard_info
    
    local attempt=1
    local success=false
    
    for strategy in "${strategies[@]}"; do
        print_status ""
        print_status "🎯 Trying build strategy $attempt/${#strategies[@]}: $strategy"
        
        if try_build_with_profile "$strategy" "$attempt"; then
            success=true
            break
        else
            print_warning "Strategy $attempt failed, trying next approach..."
            # Clean partial build artifacts
            [ -d "build" ] && rm -rf build
        fi
        
        ((attempt++))
    done
    
    if ! $success; then
        print_error "All build strategies failed!"
        print_status ""
        print_status "💡 Troubleshooting suggestions:"
        print_status "1. Check C++ standard compatibility:"
        print_status "   ./scripts/cpp_standard.sh check $(get_current_cpp_standard)"
        print_status "2. Try a different C++ standard:"
        print_status "   ./scripts/cpp_standard.sh set 17"
        print_status "3. Check that required compilers are installed:"
        print_status "   - For MinGW: gcc, g++, ninja"
        print_status "   - For MSVC: Visual Studio 2019/2022"
        print_status "4. Try running: ./configure clean && ./configure"
        print_status "5. Check Conan profiles: conan profile list"
        print_status "6. Enable debug output: DEBUG=1 ./make"
        print_status ""
        print_status "Attempted profiles: ${ATTEMPTED_PROFILES[*]}"
        exit 1
    fi
}

create_run_script() {
    local build_folder="$1"
    local profile="$2"
    local cpp_std="$3"
    local executable_name="$PROJECT_NAME"
    
    # Find the executable
    local exe_path
    if [ -f "$build_folder/$executable_name" ]; then
        exe_path="$build_folder/$executable_name"
    elif [ -f "$build_folder/$executable_name.exe" ]; then
        exe_path="$build_folder/$executable_name.exe"
    elif [ -f "$build_folder/bin/$executable_name" ]; then
        exe_path="$build_folder/bin/$executable_name"
    elif [ -f "$build_folder/bin/$executable_name.exe" ]; then
        exe_path="$build_folder/bin/$executable_name.exe"
    elif [ -f "$build_folder/Release/$executable_name.exe" ]; then
        exe_path="$build_folder/Release/$executable_name.exe"
    elif [ -f "$build_folder/Debug/$executable_name.exe" ]; then
        exe_path="$build_folder/Debug/$executable_name.exe"
    else
        print_warning "Could not find executable, creating generic run script"
        exe_path="$build_folder/$executable_name"
    fi
    
    print_status "Creating run script for: $exe_path"
    print_status "Built with: profile=$profile, C++$cpp_std, $BUILD_TYPE"
    
    cat > run << EOL
#!/bin/bash

# Auto-generated run script
# Built with: profile=$profile, C++$cpp_std, $BUILD_TYPE mode
source scripts/constants.sh

EXE_PATH="$exe_path"

print_status "🚀 Running \$EXE_PATH..."
print_status "Built with: Conan profile=$profile, C++$cpp_std, $BUILD_TYPE mode"

if [ -f "\$EXE_PATH" ]; then
    "\$EXE_PATH"
    exit_code=\$?
    print_status "Program finished with exit code: \$exit_code"
    exit \$exit_code
else
    print_error "Executable not found: \$EXE_PATH"
    print_status "Make sure the build completed successfully"
    exit 1
fi
EOL
    
    chmod +x run
    print_success "Run script created successfully!"
}

# Comprehensive dependency check
check_all_dependencies() {
    print_header "Comprehensive Dependency Check"
    
    # Check Python dependencies (packaging)
    check_python_dependencies
    
    # Check Conan
    check_conan
    
    # Check C++ standard utility
    check_cpp_standard_utility
    
    # Check template files
    check_template_files
    
    print_success "All dependencies checked ✓"
}

# Main script logic
main() {
    print_header "🏗️  Enhanced C++ Conan Template Build"
    print_environment_info
    
    # Check for clean argument
    local found_clean=false
    for arg in "$@"; do
        if [[ $arg == *"clean"* ]]; then
            found_clean=true
            break
        fi
    done
    
    if $found_clean; then
        clean_build
        return 0
    fi
    
    # Comprehensive dependency check - this ensures everything is configured
    check_all_dependencies
    
    # Check if we have a conanfile
    if [[ ! -f "conanfile.py" && ! -f "conanfile.txt" ]]; then
        print_error "No conanfile.py or conanfile.txt found"
        print_status "Please run ./configure first or add a conanfile to your project"
        exit 1
    fi
    
    start_timer
    
    # Build with enhanced fallback strategies
    build_with_fallback
    
    local build_time
    build_time=$(end_timer)
    
    print_header "🎉 Build Process Completed!"
    print_success "Total build time: $build_time"
    print_status ""
    print_status "✅ Successfully built with:"
    print_status "   • C++$(get_current_cpp_standard) standard"
    print_status "   • $BUILD_TYPE configuration"
    print_status "   • Profile: ${ATTEMPTED_PROFILES[-1]}"
    print_status ""
    print_status "Next steps:"
    print_status "1) Run: ./run"
    print_status "2) To clean: ./make clean"
    print_status "3) To rebuild: ./make"
    print_status "4) To change C++ standard: ./scripts/cpp_standard.sh set <17|20|23|26>"
}

# Run main function with all arguments
main "$@"