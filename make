#!/bin/bash

# Robust make script - uses predetermined profile, no fallback
# Profile selection should be done by ./configure

set -e  # Exit on any error

# Source constants and utility functions
chmod +x scripts/constants.sh
source scripts/constants.sh

# Configuration
BUILD_TYPE=${BUILD_TYPE:-Release}
JOBS=${JOBS:-$(get_cpu_cores)}

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
    
    # Improved packaging detection
    print_status "Testing Python packaging library..."
    if $python_cmd -c "import packaging; print('✓')" 2>/dev/null | grep -q "✓"; then
        print_status "Python packaging library available ✓"
    else
        print_status "Python packaging library needs installation/upgrade..."
        
        if $pip_cmd install --upgrade packaging >/dev/null 2>&1; then
            # Test again after installation
            if $python_cmd -c "import packaging; print('✓')" 2>/dev/null | grep -q "✓"; then
                print_success "Python packaging library installed ✓"
            else
                print_warning "Packaging installed but not accessible - this may be normal"
                print_status "Continuing with build..."
            fi
        else
            print_error "Failed to install packaging library"
            print_status "This is required for conanfile.py version comparison"
            print_status "Please run: ./configure"
            exit 1
        fi
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
            print_status "Please run: ./configure to update template files"
            exit 1
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
            print_status "Please run: ./configure to update template files"
            exit 1
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

# Determine which profile to use (no fallback logic)
get_build_profile() {
    local profile="default"
    
    # Check if there's a saved profile preference
    if [ -f ".conan_profile" ]; then
        profile=$(cat .conan_profile)
        print_status "Using saved profile: $profile" >&2
    else
        # Use environment-based logic (simplified)
        local platform=$(detect_platform)
        
        if [ "$platform" = "windows" ] && [[ "$MSYSTEM" == "MINGW64" || "$MSYSTEM" == "MINGW32" ]]; then
            if [ -f ~/.conan2/profiles/mingw ]; then
                profile="mingw"
                print_status "Auto-selected MinGW profile for MINGW environment" >&2
            fi
        fi
        
        print_status "Using profile: $profile" >&2
    fi
    
    # Verify the profile exists
    if [ ! -f ~/.conan2/profiles/"$profile" ]; then
        print_error "Conan profile '$profile' not found!" >&2
        print_status "Available profiles:" >&2
        conan profile list 2>/dev/null || print_status "  (run 'conan profile list' to see available profiles)" >&2
        print_status "" >&2
        print_status "Please run: ./configure" >&2
        exit 1
    fi
    
    echo "$profile"
}

# Build with the determined profile (no fallback)
build_with_profile() {
    local profile="$1"
    
    print_header "Building with profile: $profile"
    
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
    
    # Install dependencies
    if ! conan install "${conan_args[@]}"; then
        print_error "Conan install failed with profile: $profile"
        print_status ""
        print_status "💡 Troubleshooting:"
        print_status "1. Check profile: conan profile show $profile"
        print_status "2. Try: ./configure clean && ./configure"
        print_status "3. Check compiler installation"
        cd ..
        exit 1
    fi
    
    # Find the generated toolchain file
    local toolchain_file
    if [ -f "generators/conan_toolchain.cmake" ]; then
        toolchain_file="generators/conan_toolchain.cmake"
    elif [ -f "$BUILD_TYPE/generators/conan_toolchain.cmake" ]; then
        toolchain_file="$BUILD_TYPE/generators/conan_toolchain.cmake"
    else
        print_error "Could not find conan_toolchain.cmake"
        cd ..
        exit 1
    fi
    
    cd ..
    
    print_status "⚙️  Configuring CMake with profile: $profile..."
    
    # Determine build folder
    local build_folder="build"
    if [ "$BUILD_TYPE" != "Release" ]; then
        build_folder="build/$BUILD_TYPE"
    fi
    
    # Configure CMake
    local cmake_args=(
        -B "$build_folder"
        -DCMAKE_TOOLCHAIN_FILE="build/$toolchain_file"
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
        -DCMAKE_CXX_STANDARD="$cpp_std"
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        .
    )
    
    if ! cmake "${cmake_args[@]}"; then
        print_error "CMake configuration failed"
        print_status ""
        print_status "💡 Troubleshooting:"
        print_status "1. Check that your compiler supports C++$cpp_std"
        print_status "2. Try a different C++ standard: ./scripts/cpp_standard.sh set 17"
        print_status "3. Check CMake and compiler installation"
        exit 1
    fi
    
    print_success "CMake configuration successful ✓"
    
    # Build the project
    print_status "🏗️  Building the project with profile: $profile (C++$cpp_std)..."
    if ! cmake --build "$build_folder" --config "$BUILD_TYPE" -j "$JOBS"; then
        print_error "Build failed!"
        print_status ""
        print_status "💡 Common issues:"
        print_status "1. Compilation errors: Check the error output above"
        print_status "2. Missing dependencies: Run ./configure"
        print_status "3. Compiler issues: Try different C++ standard"
        exit 1
    fi
    
    print_success "Build completed successfully ✓"
    
    # Create run script
    create_run_script "$build_folder" "$profile" "$cpp_std"
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
    
    # Show current C++ standard
    show_cpp_standard_info
    
    # Get the profile to use (no fallback logic)
    local profile
    profile=$(get_build_profile)
    
    # Build with the determined profile
    build_with_profile "$profile"
    
    local build_time
    build_time=$(end_timer)
    
    print_header "🎉 Build Process Completed!"
    print_success "Total build time: $build_time"
    print_status ""
    print_status "✅ Successfully built with:"
    print_status "   • C++$(get_current_cpp_standard) standard"
    print_status "   • $BUILD_TYPE configuration"
    print_status "   • Profile: $profile"
    print_status ""
    print_status "Next steps:"
    print_status "1) Run: ./run"
    print_status "2) To clean: ./make clean"
    print_status "3) To rebuild: ./make"
    print_status "4) To change C++ standard: ./scripts/cpp_standard.sh set <17|20|23|26>"
}

# Run main function with all arguments
main "$@"