#pragma once

/**
 * @brief Main application class for the C++ Conan Template
 * 
 * This class encapsulates the main application logic and provides
 * a clean interface for running the template demonstration.
 */
class App {
public:
    /**
     * @brief Default constructor
     */
    App() = default;
    
    /**
     * @brief Default destructor
     */
    ~App() = default;
    
    // Disable copy and move operations for this example
    App(const App&) = delete;
    App& operator=(const App&) = delete;
    App(App&&) = delete;
    App& operator=(App&&) = delete;
    
    /**
     * @brief Run the main application logic
     * 
     * @return int Exit code (0 for success, non-zero for error)
     */
    int run();
};