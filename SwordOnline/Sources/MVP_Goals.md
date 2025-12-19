# NextGenJX - Minimum Viable Product (MVP) Goals

This document outlines the incremental, verifiable goals for the development of the `NextGenJX` engine. Each MVP represents a stable, runnable, and testable state of the project.

---

## MVP 1: "Hello, Window!"

### **Goal**
To create a running `NextGenJX` executable that opens a window, displays a solid color, and can be cleanly closed by the user. This MVP validates that the new project structure, build system (CMake), and the foundational `Platform` module are working correctly.

### **Key Components Involved**
-   New `NextGenJX` CMake project structure.
-   **`Platform` Module:**
    -   `Platform::Window` class (using SDL2 backend).
    -   `Platform::InputManager` class (using SDL2 backend).
    -   `Platform::HiResTimer` class (using `<chrono>`).
-   The main application executable (`NextGenJX_App`).

### **Acceptance Criteria (Verifiable Steps)**
1.  **Build System:** The CMake project for `NextGenJX` can be configured and built without errors, producing a `NextGenJX.exe` executable.
2.  **Window Creation:** Running `NextGenJX.exe` opens a graphical window with the title "NextGenJX".
3.  **Graphics Context:** The window's client area is successfully cleared to a solid, non-black color (e.g., cornflower blue) on every frame. This confirms that a graphics context has been successfully created and attached to the window.
4.  **Main Loop:** The application runs in a continuous loop and does not immediately exit.
5.  **Input & Exit:** The application correctly detects when the user clicks the window's 'X' button (or sends another OS-level close signal). Upon detection, the main loop terminates, and the application exits cleanly with an exit code of 0.
6.  **Timer:** The main loop prints the elapsed time since the last frame (delta time), in milliseconds, to the console for each iteration. This verifies that the `HiResTimer` is functioning correctly.

---
*(Further MVPs will be defined here as development progresses.)*
