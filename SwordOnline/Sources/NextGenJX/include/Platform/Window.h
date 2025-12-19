#pragma once

#include <string>

// Forward declare SDL_Window
struct SDL_Window;

namespace Platform
{

class Window
{
public:
    Window(const std::string& title, int width, int height);
    ~Window();

    // Non-copyable, non-movable for simplicity for now
    Window(const Window&) = delete;
    Window& operator=(const Window&) = delete;
    Window(Window&&) = delete;
    Window& operator=(Window&&) = delete;

    int GetWidth() const;
    int GetHeight() const;

    void* GetNativeHandle() const;
    SDL_Window* GetSdlWindow() const { return m_pSdlWindow; }

private:
    SDL_Window* m_pSdlWindow;
    int m_Width;
    int m_Height;
};

} // namespace Platform
