# Renderer Module Blueprint

## 1. Module Goal

To abstract all graphics API interactions behind a clean, modern rendering interface. This module will be responsible for all communication with the GPU. Its first goal, for MVP 1, is simply to initialize the graphics device and clear the screen to a solid color. In later stages, it will be responsible for all 2D sprite and 3D model rendering.

This module will ultimately replace the entire legacy rendering pipeline, which is currently split between `Engine` (software rasterizer) and `Represent3` (D3D9 compositor and UI renderer).

**Core Technology:** **BGFX**. We will use the BGFX library as a rendering abstraction layer. This allows us to write modern, API-agnostic rendering code while BGFX handles the backend implementation (e.g., DirectX 12, Vulkan). This gives us a powerful, modern feature set without being locked into a single vendor API.

## 2. New Class Definitions

### Interface `Renderer::iRenderer`
**Purpose:** An abstract interface that defines the contract for all rendering operations. The rest of the application will only ever interact with this interface, never with a specific API implementation.
**Replaces:** `iRepresentShell` (conceptually), `KDDraw`, `KCanvas`.

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Init` | `bool Init(Platform::Window* pWindow)` | Initializes the graphics backend, associating it with a specific window. | `KDirectDraw::Init`, `D3D_Device::CreateDevice` |
| `Shutdown` | `void Shutdown()` | Releases all graphics resources and shuts down the backend. | `KDirectDraw::Exit`, `CD3D_Device::FreeAll` |
| `BeginFrame` | `void BeginFrame()` | Prepares the renderer for a new frame. This is where per-frame setup happens. | `KRepresentShell3::RepresentBegin`, `CD3D_Device::Start3D` |
| `EndFrame` | `void EndFrame()` | Submits all rendering commands for the current frame and presents the back buffer. | `KRepresentShell3::RepresentEnd`, `CD3D_Device::End3D` |
| `Clear` | `void Clear(const Color& color)` | Clears the main render target to a specific color. | `KCanvas::FillCanvas`, `KDirectDraw::FillBackBuffer` |

---

### Class `Renderer::BgfxRenderer`
**Purpose:** The concrete implementation of the `iRenderer` interface using the BGFX library. This class will contain all the BGFX-specific API calls.
**Replaces:** `KRepresentShell3`, `CD3D_Device`.

| Method | Notes on Implementation |
| :--- | :--- |
| `Init` | Will call `bgfx::init()`, providing it with the native window handle retrieved from the `Platform::Window` object. |
| `Shutdown` | Will call `bgfx::shutdown()`. |
| `BeginFrame` | In BGFX, this might be as simple as setting a default view and clearing the screen, or it could be a no-op if clearing is handled separately. |
| `EndFrame` | Will call `bgfx::frame()` to advance the frame and submit commands to the rendering thread. |
| `Clear` | Will set the clear color for a specific view (e.g., view 0) using `bgfx::setViewClear()`. The actual clear happens when the view is touched. |

---
*This blueprint will be expanded in later stages to include methods for creating textures, shaders, and vertex buffers, and for submitting draw calls.*
