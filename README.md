# 🚀 Modern C++ Conan Template

A **production-ready** C++ project template featuring intelligent **C++ standard management**, **Conan 2.0** dependency management, and **zero-configuration** cross-platform builds.

## ✨ Key Features

- **🎯 Smart C++ Standard Management**: Easily switch between C++17/20/23/26 with compiler compatibility checking
- **📦 Modern Dependency Management**: Conan 2.0 with automatic dependency resolution
- **🔧 Zero-Configuration Builds**: `./configure && ./make && ./run` - it just works
- **🌍 Cross-Platform**: Windows (MinGW/MSVC), Linux, macOS with intelligent profile selection
- **🏗️ Modern CMake**: Best practices with target-based configuration
- **⚡ Enhanced Developer Experience**: Colorful output, intelligent error messages, fast builds

## 🚀 Quick Start

```bash
# 1. Clone and configure (one-time setup)
git clone https://github.com/yourusername/cpp-conan-template.git
cd cpp-conan-template
./configure

# 2. Build and run
./make
./run
```

That's it! The template automatically detects your environment and configures everything.

## 🍴 Setting Up Your Own Project

### Step 1: Fork and Clone
```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOURUSERNAME/my-awesome-app.git
cd my-awesome-app
```

### Step 2: Configure Your Project
Simply edit the `.project` file (single source of truth):

```bash
# Edit the project configuration file
vim .project
```

Update the values in `.project`:
```bash
PROJECT_NAME="my-awesome-app"
PROJECT_VERSION="1.0.0"
PROJECT_DESCRIPTION="My awesome C++ application"
PROJECT_URL="https://github.com/yourusername/my-awesome-app"
PROJECT_LICENSE="MIT"

# Build configuration defaults
DEFAULT_BUILD_TYPE="Release"

# Repository information
GITHUB_USER="yourusername"
GITHUB_REPO="my-awesome-app"
```

**That's it!** All build scripts automatically read from this file.

**C++ Standard**: Use the dedicated utility for C++ standard management:
```bash
# Set your preferred C++ standard (separate from project metadata)
./scripts/cpp_standard.sh set 20
```

### Step 3: Initialize Your Git Repository
```bash
# Remove the template's git history
rm -rf .git

# Initialize your own repository
git init
git add .
git commit -m "Initial commit: Set up project from cpp-conan-template"

# Connect to your GitHub repository
git remote add origin https://github.com/yourusername/my-awesome-app.git
git push -u origin main
```

### Step 4: Configure and Build
```bash
# Set up your development environment
./configure

# Build your project
./make

# Run your application
./run
```

> **💡 Single Source of Truth**: The `.project` file contains ALL project metadata. When you change the project name, version, or description, just edit this one file - all scripts automatically use these values.

## 🎯 C++ Standard Management

This template's standout feature is **intelligent C++ standard management**:

### Check Current Configuration
```bash
./scripts/cpp_standard.sh current
```

### Switch C++ Standards
```bash
# Switch to C++17 (maximum compatibility)
./scripts/cpp_standard.sh set 17

# Switch to C++23 (latest features)
./scripts/cpp_standard.sh set 23

# Check what your compiler supports
./scripts/cpp_standard.sh check 26
```

### Get Information About Standards
```bash
# See C++20 features and compiler requirements
./scripts/cpp_standard.sh info 20

# List all supported standards
./scripts/cpp_standard.sh list
```

### Compiler Compatibility Matrix

| Standard | GCC   | Clang | MSVC        | Key Features |
|----------|-------|-------|-------------|--------------|
| C++17    | 7+    | 5+    | VS 2017+    | structured bindings, if constexpr |
| C++20    | 10+   | 12+   | VS 2019+    | concepts, coroutines, ranges |
| C++23    | 11+   | 14+   | VS 2022+    | deducing this, explicit this |
| C++26    | 13+   | 16+   | VS 2022+    | reflection, networking (future) |

## 📦 Dependency Management

### Adding New Dependencies

Edit `conanfile.py` and add your requirements:

```python
def requirements(self):
    # Core dependencies (already included)
    self.requires("fmt/10.2.1")
    self.requires("spdlog/1.12.0")
    
    # Add your dependencies here
    self.requires("boost/1.83.0")
    self.requires("nlohmann_json/3.11.2")
    self.requires("openssl/3.2.0")
    self.requires("protobuf/3.21.12")
```

Then rebuild:
```bash
./make clean
./make
```

### Finding Packages

Search for packages on [ConanCenter](https://conan.io/center/):

```bash
# Search for packages
conan search fmt*
conan search boost*

# Get package information
conan inspect fmt/10.2.1
```

### Version Constraints

```python
def requirements(self):
    self.requires("boost/[>=1.80.0 <2.0.0]")  # Version range
    self.requires("fmt/[~10.2]")              # Compatible with 10.2.x
    self.requires("openssl/[*]")              # Latest version
```

## 🏗️ Adding New Source Files

### 1. Add Source Files

Create your files in the `src/` directory:

```
src/
├── main.cpp         # Entry point (already exists)
├── app.cpp          # Main application (already exists) 
├── app.hpp          # Application header (already exists)
├── network/         # New module
│   ├── client.cpp
│   ├── client.hpp
│   └── server.cpp
└── utils/
    ├── helpers.cpp
    └── helpers.hpp
```

**For public APIs**, use the `include/` directory:
```
include/
└── your-project/
    ├── network_api.hpp    # Public network interface
    └── utilities.hpp      # Public utility functions
```

### 2. Update CMakeLists.txt

Add your new files to the `target_sources` section:

```cmake
# Add source files
target_sources(${PROJECT_NAME} PRIVATE
    src/main.cpp
    src/app.cpp
    # Add your new files here
    src/network/client.cpp
    src/network/server.cpp
    src/utils/helpers.cpp
)
```

### 3. Rebuild

```bash
./make
```

That's it! CMake will automatically detect changes and rebuild only what's needed.

### Adding Header-Only Libraries

For header-only code that will be used by other projects, create an `include/` directory with your project namespace:

```
include/
└── my-awesome-app/         # Use your actual project name
    ├── algorithms.hpp      # Public algorithms
    ├── data_structures.hpp # Public data structures
    └── detail/             # Implementation details
        └── impl.hpp        # Private implementation headers
```

**Important**: Use a subdirectory with your project name to avoid header name conflicts.

Headers in `include/` are automatically available to your source files and to other projects that depend on yours.

## 🔧 Build Configuration

### Build Types

```bash
# Debug build (with debug symbols)
BUILD_TYPE=Debug ./make

# Release build (optimized, default)
BUILD_TYPE=Release ./make

# Release with debug info
BUILD_TYPE=RelWithDebInfo ./make

# Minimal size release
BUILD_TYPE=MinSizeRel ./make
```

### Parallel Builds

```bash
# Use all CPU cores (default)
./make

# Limit parallel jobs
JOBS=4 ./make

# Single-threaded build
JOBS=1 ./make
```

### Custom Compiler

```bash
# Use specific compiler
CXX=clang++ ./configure
./make

# Use GCC
CXX=g++ ./configure
./make
```

## 🛠️ Development Workflow

### Daily Development

```bash
# 1. Make code changes
vim src/app.cpp

# 2. Quick rebuild (only changed files)
./make

# 3. Test
./run

# 4. Debug build for development
BUILD_TYPE=Debug ./make
```

### Clean Builds

```bash
# Clean build artifacts only
./make clean

# Full clean (dependencies, profiles, cache)
./configure clean
./configure
./make
```

### Changing C++ Standards

```bash
# Switch to C++17 for compatibility
./scripts/cpp_standard.sh set 17
./make clean
./make

# Switch back to C++20
./scripts/cpp_standard.sh set 20
./make clean
./make
```

## 🏗️ Project Structure

```
my-awesome-app/              # Your project root
├── 📄 .project              # Project configuration (single source of truth)
├── 📁 src/                  # Source implementation files
│   ├── main.cpp             # Application entry point
│   ├── app.cpp              # Main application logic
│   └── app.hpp              # Application header
├── 📁 include/              # Public headers (optional)
│   └── my-awesome-app/      # Namespace your headers
│       └── api.hpp          # Public API headers
├── 📁 scripts/              # Build and utility scripts
│   ├── constants.sh         # Shared constants and utilities
│   ├── cpp_standard.sh      # C++ standard management
│   ├── configure_cmake.sh   # Legacy CMake setup (Windows)
│   └── configure_gcc.sh     # Legacy GCC setup (Windows)
├── 📁 build/                # Build artifacts (auto-generated)
├── 📄 conanfile.py          # Dependency configuration
├── 📄 CMakeLists.txt        # Build configuration
├── 🔧 configure             # Environment setup script
├── 🔨 make                 # Build script
├── ▶️ run                  # Auto-generated run script
├── 📖 README.md            # This file
├── .cppstd                # Current C++ standard (auto-generated)
├── .conan_profile         # Selected Conan profile (auto-generated)
└── .gitignore             # Git ignore patterns
```

**Key Files:**
- **`.project`**: **Project metadata** (name, version, description, URLs)
- **`.cppstd`**: **C++ standard** (managed by `cpp_standard.sh` utility)
- **`src/`**: All your `.cpp` implementation files and private `.hpp` headers
- **`include/`**: Public API headers (if building a library)
- **`scripts/`**: Build utilities and configuration scripts
- **`build/`**: Generated build artifacts (add to `.gitignore`)

**Generated Files:** (add these to `.gitignore`)
- `run` - Executable launch script
- `build/` - CMake build directory
- `CMakeUserPresets.json` - CMake configuration
- `.conan_profile` - Selected build profile  

### Recommended `.gitignore`

```gitignore
# Build artifacts
build/
run
CMakeUserPresets.json

# Build configuration (auto-generated/selected)
.conan_profile

# Backup files
*.backup
*.bak

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db
```

**Note**: Both `.project` and `.cppstd` should be **checked into git** as they contain your project's configuration.

## 🔍 Understanding the Scripts

### `./configure` - Environment Setup
- Detects your environment (Windows/Linux/macOS)
- Installs/verifies Python dependencies
- Sets up Conan profiles for your compiler
- Tests and selects the best build configuration
- **Run once** after cloning or when changing environments

### `./make` - Build Process
- Uses the profile selected by `./configure`
- Installs dependencies via Conan
- Configures CMake with the right settings
- Builds your project
- Creates the `./run` script
- **No fallback logic** - fails fast with clear error messages

### `./scripts/cpp_standard.sh` - C++ Management
- Switch between C++ standards (17/20/23/26)
- Check compiler compatibility
- Show standard features and requirements
- Automatically updates conanfile.py and CMakeLists.txt

## 🔧 Troubleshooting

### Build Fails

```bash
# 1. Check C++ standard compatibility
./scripts/cpp_standard.sh check 20

# 2. Try a different standard
./scripts/cpp_standard.sh set 17
./make clean && ./make

# 3. Reconfigure environment
./configure clean
./configure
./make

# 4. Check compiler installation
gcc --version
conan profile show default
```

### Dependency Issues

```bash
# Update Conan cache
conan cache clean "*"

# Rebuild dependencies
./make clean
./make --build=missing

# Check package availability
conan search <package_name>
```

### Environment Issues

```bash
# Check system requirements
./configure

# Update Python dependencies
pip install --upgrade conan packaging

# Check profiles
conan profile list
conan profile show default
```

### Common Errors

| Error | Solution |
|-------|----------|
| `Profile not found` | Run `./configure` to create profiles |
| `Compiler not supported` | Check compiler version or try different C++ standard |
| `Package not found` | Check package name on [ConanCenter](https://conan.io/center/) |
| `Python packaging missing` | Run `pip install packaging` |

## 🎯 Best Practices

### Dependency Management
- Pin dependency versions in production: `self.requires("fmt/10.2.1")`
- Use version ranges for flexibility: `self.requires("boost/[>=1.80 <2.0]")`
- Test with different dependency versions regularly

### C++ Standards
- **C++17**: Maximum compatibility, use for libraries
- **C++20**: Great balance of features and support  
- **C++23**: Latest features, cutting-edge projects
- **C++26**: Future-proofing, experimental

### Project Organization
- Keep headers in `src/` for private use, `include/` for public APIs
- Group related functionality in subdirectories
- Use meaningful names for source files

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and test with different C++ standards
4. Commit your changes: `git commit -m 'Add amazing feature'`
5. Push to the branch: `git push origin feature/amazing-feature`
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Conan.io](https://conan.io/) for excellent C++ package management
- [CMake](https://cmake.org/) for cross-platform build system  
- [fmt](https://fmt.dev/) for modern string formatting
- [spdlog](https://github.com/gabime/spdlog) for fast logging

---

**⭐ If this template helps your C++ development, please star the repository!**

**💡 Questions?** Check the [troubleshooting section](#-troubleshooting) or open an issue.