cmake_minimum_required(VERSION 3.16)

project(NextGenJX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- Sub-modules (as static libraries) ---
# For now, we only add Platform as it's the only one we are building for MVP 1
add_subdirectory(src/Platform)
# add_subdirectory(src/Renderer)
# add_subdirectory(src/Audio)
# add_subdirectory(src/Assets)
# add_subdirectory(src/Scripting)
# add_subdirectory(src/Game)

# --- Main Executable ---
add_executable(NextGenJX_App src/main.cpp)

# Link all modules to the main application
target_link_libraries(NextGenJX_App
    PRIVATE
    Platform
    # Renderer
    # Audio
    # Assets
    # Scripting
    # Game
)