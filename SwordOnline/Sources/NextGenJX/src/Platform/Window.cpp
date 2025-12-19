#include <Platform/Window.h>
#include <SDL.h>
#include <stdexcept>

// Include for GetNativeHandle
#ifdef _WIN32
#include <SDL_syswm.h>
#endif

namespace Platform
{

Window::Window(const std::string& title, int width, int height)
    : m_pSdlWindow(nullptr), m_Width(width), m_Height(height)
{
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        throw std::runtime_error("Failed to initialize SDL Video.");
    }

    m_pSdlWindow = SDL_CreateWindow(
        title.c_str(),
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        width,
        height,
        SDL_WINDOW_SHOWN // Use SDL_WINDOW_VULKAN or SDL_WINDOW_OPENGL for hardware rendering
    );

    if (!m_pSdlWindow)
    {
        throw std::runtime_error("Failed to create SDL window.");
    }
}

Window::~Window()
{
    if (m_pSdlWindow)
    {
        SDL_DestroyWindow(m_pSdlWindow);
    }
    SDL_Quit();
}

int Window::GetWidth() const
{
    return m_Width;
}

int Window::GetHeight() const
{
    return m_Height;
}

void* Window::GetNativeHandle() const
{
#ifdef _WIN32
    SDL_SysWMinfo wmInfo;
    SDL_VERSION(&wmInfo.version);
    SDL_GetWindowWMInfo(m_pSdlWindow, &wmInfo);
    return wmInfo.info.win.window;
#else
    return nullptr; // Implement for other platforms if needed
#endif
}

} // namespace Platform
