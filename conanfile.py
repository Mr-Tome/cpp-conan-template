from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMakeDeps, cmake_layout
from conan.tools.files import copy
from conan.errors import ConanInvalidConfiguration
from packaging import version
import os
import re

def read_project_config():
    """Read project configuration from .project file"""
    config = {}
    try:
        with open('.project', 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    if '=' in line:
                        key, value = line.split('=', 1)
                        # Remove quotes from value
                        value = value.strip('"\'')
                        config[key.strip()] = value
    except FileNotFoundError:
        print("WARNING: .project file not found, using defaults")
        config = {
            'PROJECT_NAME': 'cpp-conan-template',
            'PROJECT_VERSION': '1.0.0',
            'PROJECT_DESCRIPTION': 'Modern C++ project template with Conan 2.0',
            'PROJECT_URL': 'https://github.com/yourusername/cpp-conan-template',
            'PROJECT_LICENSE': 'MIT'
        }
    return config

# Read project configuration
PROJECT_CONFIG = read_project_config()

class CppConanTemplateConan(ConanFile):
    name = PROJECT_CONFIG.get('PROJECT_NAME', 'cpp-conan-template')
    version = PROJECT_CONFIG.get('PROJECT_VERSION', '1.0.0')
    package_type = "application"
    
    # Binary configuration
    settings = "os", "compiler", "build_type", "arch"
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
        "cxx_standard": ["17", "20", "23", "26"]  # Support future standards
    }
    default_options = {
        "shared": False,
        "fPIC": True,
        "cxx_standard": "20"  # Default to C++20
    }
    
    # Package metadata from .project file
    description = PROJECT_CONFIG.get('PROJECT_DESCRIPTION', 'Modern C++ project template with Conan 2.0')
    topics = ("cpp", "template", "conan")
    url = PROJECT_CONFIG.get('PROJECT_URL', 'https://github.com/yourusername/cpp-conan-template')
    license = PROJECT_CONFIG.get('PROJECT_LICENSE', 'MIT')
    
    def _get_min_compiler_version(self, cxx_std):
        """Get minimum compiler versions required for each C++ standard"""
        requirements = {
            "17": {
                "gcc": "7",
                "clang": "5", 
                "msvc": "191",  # VS 2017
                "apple-clang": "9.1"
            },
            "20": {
                "gcc": "10",      # GCC 10 has good C++20 support
                "clang": "12",    # Clang 12 has good C++20 support  
                "msvc": "192",    # VS 2019 16.0
                "apple-clang": "12"
            },
            "23": {
                "gcc": "11",      # GCC 11+ for C++23 features
                "clang": "14",    # Clang 14+ for C++23
                "msvc": "193",    # VS 2022
                "apple-clang": "14"
            },
            "26": {
                "gcc": "13",      # Future-proofing for C++26
                "clang": "16",    # Future estimates
                "msvc": "194",    # Future VS version
                "apple-clang": "15"
            }
        }
        return requirements.get(str(cxx_std), requirements["20"])
    
    def _check_compiler_support(self, compiler_name, compiler_version, cxx_std):
        """Check if compiler version supports the requested C++ standard"""
        min_versions = self._get_min_compiler_version(cxx_std)
        min_version = min_versions.get(compiler_name)
        
        if not min_version:
            self.output.warn(f"Unknown compiler {compiler_name}, skipping version check")
            return True
            
        try:
            return version.parse(str(compiler_version)) >= version.parse(min_version)
        except Exception as e:
            self.output.warn(f"Could not parse version {compiler_version}: {e}")
            return True  # Be permissive if we can't parse
    
    def _determine_cxx_standard(self):
        """Determine the C++ standard to use based on options and compiler settings"""
        # First check if .cppstd file exists (managed by cpp_standard.sh)
        try:
            with open('.cppstd', 'r') as f:
                std = f.read().strip()
                if std in ["17", "20", "23", "26"]:
                    return std
        except FileNotFoundError:
            pass
        
        # Priority: explicit option > compiler.cppstd setting > default
        if hasattr(self.options, 'cxx_standard') and self.options.cxx_standard:
            return str(self.options.cxx_standard)
        
        if hasattr(self.settings.compiler, "cppstd") and self.settings.compiler.cppstd:
            return str(self.settings.compiler.cppstd)
            
        return "20"  # Default fallback
    
    def configure(self):
        if self.settings.os == "Windows":
            self.options.rm_safe("fPIC")
        
        # Determine target C++ standard
        target_cxx_std = self._determine_cxx_standard()
        self.output.info(f"Target C++ standard: C++{target_cxx_std}")
        
        # Set compiler.cppstd if not already set
        if hasattr(self.settings.compiler, "cppstd"):
            if not self.settings.compiler.cppstd:
                self.settings.compiler.cppstd = target_cxx_std
                self.output.info(f"Set compiler.cppstd to {target_cxx_std}")
        
        # Check compiler support for the requested standard
        compiler_name = str(self.settings.compiler)
        compiler_version = str(self.settings.compiler.version)
        
        if not self._check_compiler_support(compiler_name, compiler_version, target_cxx_std):
            min_versions = self._get_min_compiler_version(target_cxx_std)
            min_version = min_versions.get(compiler_name, "unknown")
            
            raise ConanInvalidConfiguration(
                f"{compiler_name} {min_version}+ required for C++{target_cxx_std} support. "
                f"Current version: {compiler_version}. "
                f"Consider using a lower C++ standard or updating your compiler."
            )
        
        self.output.info(f"✓ {compiler_name} {compiler_version} supports C++{target_cxx_std}")
    
    def requirements(self):
        # Core dependencies - these work with C++17+
        self.requires("fmt/10.2.1")
        self.requires("spdlog/1.12.0")
        
        # Optional dependencies based on build type
        if self.settings.build_type == "Debug":
            self.requires("catch2/3.4.0")
    
    def configure_dependencies(self):
        # Configure fmt
        self.options["fmt"].shared = self.options.shared
        
        # Configure spdlog
        self.options["spdlog"].shared = self.options.shared
        if self.settings.build_type == "Debug":
            self.options["spdlog"].no_exceptions = False
    
    def layout(self):
        cmake_layout(self)
    
    def generate(self):
        # Generate CMake files
        deps = CMakeDeps(self)
        deps.generate()
        
        tc = CMakeToolchain(self)
        tc.variables["CMAKE_EXPORT_COMPILE_COMMANDS"] = True
        
        # Set C++ standard in CMake
        target_cxx_std = self._determine_cxx_standard()
        tc.variables["CMAKE_CXX_STANDARD"] = target_cxx_std
        tc.variables["CMAKE_CXX_STANDARD_REQUIRED"] = True
        tc.variables["CMAKE_CXX_EXTENSIONS"] = False
        
        # Pass project configuration to CMake
        tc.variables["PROJECT_NAME_FROM_CONAN"] = self.name
        tc.variables["PROJECT_VERSION_FROM_CONAN"] = self.version
        tc.variables["PROJECT_DESCRIPTION_FROM_CONAN"] = self.description
        
        # Add build type specific configurations
        if self.settings.build_type == "Debug":
            tc.variables["CMAKE_BUILD_TYPE"] = "Debug"
            tc.variables["ENABLE_TESTING"] = True
        else:
            tc.variables["CMAKE_BUILD_TYPE"] = "Release"
            tc.variables["ENABLE_TESTING"] = False
                
        tc.generate()
