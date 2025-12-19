#include <Platform/InputManager.h>
#include <SDL.h>
#include <cstring> // For memcpy

namespace Platform
{

InputManager::InputManager()
    : m_CurrentKeyStates(nullptr), m_QuitRequested(false)
{
    m_CurrentKeyStates = SDL_GetKeyboardState(nullptr);
    memset(m_pPreviousKeyStates, 0, sizeof(m_pPreviousKeyStates));

    m_MousePosition = {0, 0};
    m_MouseDelta = {0, 0};
    m_CurrentMouseButtons = 0;
    m_PreviousMouseButtons = 0;
}

void InputManager::ProcessEvents()
{
    // Update previous states
    memcpy(m_pPreviousKeyStates, m_CurrentKeyStates, SDL_NUM_SCANCODES);
    m_PreviousMouseButtons = m_CurrentMouseButtons;
    m_MouseDelta = {0, 0};

    SDL_Event event;
    while (SDL_PollEvent(&event))
    {
        if (event.type == SDL_QUIT)
        {
            m_QuitRequested = true;
        }
        if (event.type == SDL_MOUSEMOTION)
        {
            m_MouseDelta.x += event.motion.xrel;
            m_MouseDelta.y += event.motion.yrel;
        }
    }

    // Update current states
    SDL_GetMouseState(&m_MousePosition.x, &m_MousePosition.y);
    m_CurrentMouseButtons = SDL_GetMouseState(NULL, NULL);
}

bool InputManager::IsKeyDown(KeyCode key) const
{
    return m_CurrentKeyStates[key];
}

bool InputManager::WasKeyPressed(KeyCode key) const
{
    return m_CurrentKeyStates[key] && !m_pPreviousKeyStates[key];
}

bool InputManager::WasKeyReleased(KeyCode key) const
{
    return !m_CurrentKeyStates[key] && m_pPreviousKeyStates[key];
}

Point InputManager::GetMousePosition() const
{
    return m_MousePosition;
}

Point InputManager::GetMouseDelta() const
{
    return m_MouseDelta;
}

bool InputManager::IsMouseButtonDown(MouseButton button) const
{
    return (m_CurrentMouseButtons & SDL_BUTTON(button));
}

bool InputManager::WasMouseButtonPressed(MouseButton button) const
{
    return (m_CurrentMouseButtons & SDL_BUTTON(button)) && !(m_PreviousMouseButtons & SDL_BUTTON(button));
}

bool InputManager::WasMouseButtonReleased(MouseButton button) const
{
    return !(m_CurrentMouseButtons & SDL_BUTTON(button)) && (m_PreviousMouseButtons & SDL_BUTTON(button));
}

bool InputManager::QuitRequested() const
{
    return m_QuitRequested;
}

} // namespace Platform
