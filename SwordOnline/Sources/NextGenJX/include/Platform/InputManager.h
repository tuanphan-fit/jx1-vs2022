#pragma once

#include <cstdint>

// Using SDL ScanCodes as our KeyCode definition
#include <SDL_scancode.h>
#include <SDL_mouse.h>

namespace Platform
{

using KeyCode = SDL_Scancode;
using MouseButton = uint8_t;

struct Point {
    int x = 0;
    int y = 0;
};

class InputManager
{
public:
    InputManager();

    void ProcessEvents();

    bool IsKeyDown(KeyCode key) const;
    bool WasKeyPressed(KeyCode key) const;
    bool WasKeyReleased(KeyCode key) const;

    Point GetMousePosition() const;
    Point GetMouseDelta() const;
    bool IsMouseButtonDown(MouseButton button) const;
    bool WasMouseButtonPressed(MouseButton button) const;
    bool WasMouseButtonReleased(MouseButton button) const;

    bool QuitRequested() const;

private:
    const uint8_t* m_pCurrentKeyStates;
    uint8_t m_pPreviousKeyStates[SDL_NUM_SCANCODES];

    Point m_MousePosition;
    Point m_MouseDelta;

    uint32_t m_CurrentMouseButtons;
    uint32_t m_PreviousMouseButtons;

    bool m_QuitRequested;
};

} // namespace Platform
