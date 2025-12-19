# Platform Module Blueprint

## 1. Module Goal

To completely abstract all operating system-level interactions into a clean, modern, and cross-platform C++ interface. This module is the foundational layer that the rest of the application will be built upon. It directly replaces the legacy `KWin32App`, `KWin32Wnd`, `KDInput`, `KMouse`, and `KKeyboard` classes and their associated global functions.

**Core Technology:** SDL2 will be used as the backend library to provide the platform abstraction.

## 2. New Class Definitions

### Class `Platform::Window`
**Purpose:** Encapsulates a single OS window and its associated graphics context. Manages window creation, destruction, and events.
**Replaces:** `KWin32App` (window creation parts), `KWin32Wnd` (global HWND access).

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Constructor` | `Window(const std::string& title, int width, int height)` | Creates and displays a new window. Initializes SDL video subsystem. | `KWin32App::InitClass`, `KWin32App::InitWindow` |
| `Destructor` | `~Window()` | Destroys the window and cleans up resources. | `DestroyWindow` calls in `KWin32App::MsgProc` |
| `GetWidth()` | `int GetWidth() const` | Returns the current width of the window's client area. | Part of `g_GetClientRect` |
| `GetHeight()` | `int GetHeight() const` | Returns the current height of the window's client area. | Part of `g_GetClientRect` |
| `GetNativeHandle()` | `void* GetNativeHandle() const` | Returns the underlying native window handle (e.g., HWND on Windows) for interop. | `g_GetMainHWnd` |
| `SwapBuffers()` | `void SwapBuffers()` | Presents the back buffer to the screen (swaps the graphics context). | `KDirectDraw::UpdateScreen` (conceptually) |

---

### Class `Platform::InputManager`
**Purpose:** Manages the state of all input devices and handles the OS event loop. Provides a clean, stateful query interface for keyboard and mouse.
**Replaces:** `KDInput`, `KMouse`, `KKeyboard`, and the message processing part of `KWin32App::Run()` / `MsgProc()`.

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Constructor` | `InputManager()` | Initializes the SDL event system. | `KDirectInput::Init` |
| `ProcessEvents()` | `void ProcessEvents()` | Pumps the SDL event queue. Must be called once per frame. This is the heart of the new event loop. | `PeekMessage`/`DispatchMessage` loop in `KWin32App::Run()` |
| `IsKeyDown()` | `bool IsKeyDown(KeyCode key) const` | Checks if a key is currently held down. | `KKeyboard::IsDown` |
| `WasKeyPressed()` | `bool WasKeyPressed(KeyCode key) const` | Checks if a key was pressed *this frame*. | N/A (new feature) |
| `WasKeyReleased()` | `bool WasKeyReleased(KeyCode key) const` | Checks if a key was released *this frame*. | N/A (new feature) |
| `GetMousePosition()` | `Point GetMousePosition() const` | Gets the current absolute position of the mouse cursor. | `KMouse::GetPos` |
| `GetMouseDelta()` | `Point GetMouseDelta() const` | Gets the relative motion of the mouse since the last frame. | `KDirectInput::GetMouseState` (dx/dy part) |
| `IsMouseButtonDown()` | `bool IsMouseButtonDown(MouseButton button) const` | Checks if a mouse button is currently held down. | `KMouse` state variables (`m_LButton`, etc.) |
| `WasMouseButtonPressed()` | `bool WasMouseButtonPressed(MouseButton button) const` | Checks if a mouse button was pressed *this frame*. | N/A (new feature) |
| `QuitRequested()` | `bool QuitRequested() const` | Returns true if the user has requested to close the window. | `WM_QUIT` / `WM_CLOSE` handling in `MsgProc` |

---

### Class `Platform::HiResTimer`
**Purpose:** A high-resolution timer for measuring frame time and other durations.
**Replaces:** `KTimer`.

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Constructor` | `HiResTimer()` | Initializes the timer and marks the application start time. Based on `<chrono>`. | `KTimer::KTimer` |
| `Tick()` | `void Tick()` | Marks the beginning of a new frame. | `KTimer::Start` |
| `GetDeltaTime()` | `float GetDeltaTime() const` | Returns the time elapsed since the last `Tick()` call, in seconds. | `KTimer::GetElapse` |
| `GetTotalTime()` | `float GetTotalTime() const` | Returns the total time elapsed since the timer was created. | N/A (new feature) |
