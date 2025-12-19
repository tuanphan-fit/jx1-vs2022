#include <Platform/Window.h>
#include <Platform/InputManager.h>
#include <Platform/HiResTimer.h>

#include <iostream>
#include <stdexcept>
#include <SDL.h> // For SDL_Delay

// Basic renderer clear for MVP 1
// This will be replaced by the Renderer module later
void ClearScreen(SDL_Window* pSdlWindow)
{
    // This is a placeholder. For a real app, we'd use a graphics API.
    // For now, we get the window surface to clear it.
    SDL_Surface* pSurface = SDL_GetWindowSurface(pSdlWindow);
    if (pSurface)
    {
        // Cornflower blue
        SDL_FillRect(pSurface, NULL, SDL_MapRGB(pSurface->format, 100, 149, 237));
        SDL_UpdateWindowSurface(pSdlWindow);
    }
}


int main(int argc, char* argv[])
{
    try
    {
        Platform::Window window("NextGenJX", 1024, 768);
        Platform::InputManager inputManager;
        Platform::HiResTimer timer;

        bool isRunning = true;
        while(isRunning)
        {
            // --- Update ---
            timer.Tick();
            inputManager.ProcessEvents();

            if (inputManager.QuitRequested())
            {
                isRunning = false;
            }

            // --- Logging ---
            std::cout << "Delta Time: " << timer.GetDeltaTime() * 1000.0f << " ms" << std::endl;

            // --- Drawing ---
            ClearScreen(window.GetSdlWindow());


            // Prevent 100% CPU usage
            SDL_Delay(1);
        }
    }
    catch (const std::exception& e)
    {
        std::cerr << "Fatal Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}