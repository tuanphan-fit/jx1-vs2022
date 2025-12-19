# Define the library
add_library(Platform STATIC
    Window.cpp
    InputManager.cpp
    HiResTimer.cpp
)

# Public headers (for other modules to include)
target_include_directories(Platform PUBLIC ../../include)

# Find SDL2 - NOTE: This requires SDL2 to be installed and findable by CMake
find_package(SDL2 REQUIRED)

# Link against SDL2
target_link_libraries(Platform PUBLIC SDL2::SDL2)
