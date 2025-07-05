#include <iostream>
#include <string>
#include <string_view>
#include <stdexcept>

#include <fmt/format.h>
#include <spdlog/spdlog.h>

#include "app.hpp"

int main() {
    try {
        // Initialize logging
        spdlog::set_pattern("[%H:%M:%S] [%^%l%$] %v");
        spdlog::info("Starting C++ Conan Template Application v{}", "1.0.0");
        spdlog::info("Using fmt version: {}", FMT_VERSION);
        
        // Create and run the application
        App app;
        const auto result = app.run();
        
        spdlog::info("Application finished with exit code: {}", result);
        return result;
        
    } catch (const std::exception& e) {
        spdlog::error("Application error: {}", e.what());
        return 1;
    } catch (...) {
        spdlog::error("Unknown error occurred");
        return 2;
    }
}