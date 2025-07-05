#include "app.hpp"

#include <algorithm>
#include <iostream>
#include <string>
#include <string_view>
#include <cctype>

#include <fmt/format.h>
#include <spdlog/spdlog.h>

namespace {
    // Helper function to convert string to lowercase
    std::string to_lower(std::string str) {
        std::transform(str.begin(), str.end(), str.begin(),
                      [](unsigned char c) { return std::tolower(c); });
        return str;
    }
    
    // Helper function to trim whitespace
    std::string trim(const std::string& str) {
        const auto start = str.find_first_not_of(" \t\n\r");
        if (start == std::string::npos) return "";
        
        const auto end = str.find_last_not_of(" \t\n\r");
        return str.substr(start, end - start + 1);
    }
    
    // Check if answer is affirmative
    bool is_affirmative(std::string_view answer) {
        const std::string lower_answer = to_lower(std::string(answer));
        return lower_answer == "yes" || lower_answer == "y" || 
               lower_answer == "si" || lower_answer == "oui" ||
               lower_answer == "da" || lower_answer == "ja";
    }
    
    // Check if answer is negative
    bool is_negative(std::string_view answer) {
        const std::string lower_answer = to_lower(std::string(answer));
        return lower_answer == "no" || lower_answer == "n" ||
               lower_answer == "non" || lower_answer == "nein" ||
               lower_answer == "nyet";
    }
}

int App::run() {
    spdlog::info("Application started successfully");
    
    // Welcome message with simple formatting (compatible with all fmt versions)
    fmt::print("🚀 Welcome to the Modern C++ Conan Template!\n");
    fmt::print("📦 Using fmt v{}\n", FMT_VERSION);
    fmt::print("📝 Using spdlog for logging\n");
    fmt::print("⚡ Built with C++20 and modern practices\n\n");
    
    std::string answer;
    int attempts = 0;
    constexpr int max_attempts = 5;
    
    while (attempts < max_attempts) {
        fmt::print("❓ Is this C++ template awesome? (yes/no): ");
        
        if (!std::getline(std::cin, answer)) {
            spdlog::warn("Failed to read input, exiting");
            return 1;
        }
        
        answer = trim(answer);
        ++attempts;
        
        if (answer.empty()) {
            fmt::print("⚠️  Please provide an answer.\n\n");
        }
        
        if (is_affirmative(answer)) {
            spdlog::info("User confirmed template is awesome! (attempt {})", attempts);
            fmt::print("🎉 Fantastic! Thanks for using this template!\n");
            fmt::print("⭐ Consider starring the repository if you found it useful!\n");
            return 0;
        } 
        
        if (is_negative(answer)) {
            spdlog::info("User provided negative feedback (attempt {})", attempts);
            fmt::print("😔 We appreciate your honesty!\n");
            fmt::print("💡 Please let us know how we can improve this template.\n");
            fmt::print("📧 Feel free to open an issue on our GitHub repository.\n");
            return 0;
        }
        
        // Invalid answer
        spdlog::debug("Invalid answer received: '{}'", answer);
        fmt::print("❌ Please answer with 'yes' or 'no' (or variations like 'y', 'si', 'oui').\n");
        
        if (attempts < max_attempts) {
            fmt::print("🔄 You have {} attempt{} remaining.\n\n", 
                      max_attempts - attempts, 
                      (max_attempts - attempts) == 1 ? "" : "s");
        }
    }
    
    // Too many invalid attempts
    spdlog::warn("Maximum attempts ({}) reached with invalid inputs", max_attempts);
    fmt::print("⏰ Too many invalid attempts. Exiting...\n");
    fmt::print("👋 Thanks for trying the template anyway!\n");
    
    return 0;
}