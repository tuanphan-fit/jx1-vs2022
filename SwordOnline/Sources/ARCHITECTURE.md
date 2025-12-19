# Architecture Document: JX Online Engine Modernization

## 1. Project Overview
This project aims to re-architect a legacy game engine (similar to Kingsoft JX Online engine, circa 1999-2000) for modern, multi-core hardware by transitioning from a sequential, single-threaded design to a parallel, job-based architecture.

## 2. Core Challenges
*   **Architectural Shift:** From a monolithic, sequential game loop to a decoupled, parallel task-based system.
*   **Concurrency Management:** Introducing thread-safety to all systems and data structures.
*   **Technology Migration:** Replacing legacy graphics APIs (e.g., DirectX 7/8) with modern alternatives (e.g., DirectX 12, Vulkan).
*   **Code Modernization:** Updating an archaic C++ codebase to modern standards (e.g., C++17/20).

## 3. Current Architecture Analysis

### 3.1. Client Entry Point (`S3Client.cpp`)
*   **Main Function:** `WinMain` serves as the application's entry point.
*   **Application Class:** `KMyApp` encapsulates the main application lifecycle, with key methods:
    *   `Init()`: Calls `GameInit()`.
    *   `Run()`: Contains the main game loop, calling `GameLoop()`.
    *   `GameInit()`: Performs comprehensive initialization:
        *   Console setup and locale (`setlocale(LC_ALL, "en_US.UTF-8");`).
        *   Loads `config.ini`.
        *   Initializes `RepresentShell` (graphics) via dynamic DLL loading (`Represent2.dll` or `Represent3.dll`).
        *   Initializes UI components (`UiInit()`).
        *   Initializes sound (`m_Sound.Init()`).
        *   Obtains and sets up `CoreShell` (`CoreGetShell()`) for core game logic.
        *   Initializes `NetConnectAgent` for networking.
    *   `GameLoop()`: The main game loop handles:
        *   Networking updates (`g_NetConnectAgent.Breathe()`).
        *   Core game logic updates (`g_pCoreShell->Breathe()`).
        *   UI updates (`UiHeartBeat()`, `UiPaint()`).
        *   Frame rate management.
    *   `GameExit()`: Handles cleanup and shutdown.
    *   `HandleInput()`: Processes Windows messages, including game exit confirmation.
*   **Key Modules/Dependencies:** `KCore`, `iRepresentShell`, `UiShell`, `NetConnectAgent`, `TextCtrlCmd`, `KPakList`, `FilterText`, error handling.

### 3.2. Core Module (`Core/Src/KCore.h`, `Core/Src/KCore.cpp`)
*   **Purpose:** Central hub for game data, settings, and core game logic components.
*   **Architecture:**
    *   **Highly Centralized:** Relies extensively on global variables and functions.
    *   **Conditional Compilation:** Heavy use of `#ifdef _SERVER`, `#ifndef _SERVER`, `#ifdef TOOLVERSION` to manage client, server, and tool-specific logic within the same files. This leads to tight coupling.
    *   **Data-Driven:** Leverages `KTabFile` and `KIniFile` extensively for configuring game elements (skills, NPCs, items, settings).
    *   **Pointers to Interfaces:** Global pointers like `g_pServer` and `g_pClient` are used to access `IServer` and `IClient` interfaces, suggesting a form of modularity despite global access.
*   **Key Components/Initializations in `g_InitCore()`:**
    *   Random number generators.
    *   `g_SpriteCache` (client-only), `g_SoundCache` (client-only), `g_SubWorldSet.m_cMusic` (client-only).
    *   `g_InitSeries()` and `g_InitMath()`.
    *   Game data managers: `ItemSet`, `ItemGen`, `g_MagicDesc` (client-only), `g_ItemChangeRes`, `NpcSet`, `ObjSet`, `MissleSet`.
    *   Scripting engine (`g_IniScriptEngine()`).
    *   Loads various settings from files (`SKILL_SETTING_FILE`, `MISSLES_SETTING_FILE`, `NPC_SETTING_FILE`, `GAME_SETTING_FILE_INI`, etc.).
    *   Calls `InitGameSetting()`, `InitSkillSetting()`, `InitMissleSetting()`, `InitNpcSetting()`, `InitTaskSetting()`.
    *   `PlayerSet`, `TongData`, `GameData` (server-only), `g_TeamSet` (server-only), `g_ChatRoomSet` (server-only).
    *   World map data loading (`g_SubWorldSet`).
    *   `g_Faction` initialization.
    *   Weapon physics skill ID loading.
    *   `BuySell` (client-only).
*   **Resource Release (`g_ReleaseCore()`):** Handles systematic cleanup of resources initialized in `g_InitCore()`, including saving server data, releasing server interfaces, deallocating price tables, and closing client-specific modules.
*   **Challenges:** The strong reliance on global state and the intertwined client/server/tool logic within single files due to preprocessor directives make this module difficult to refactor and parallelize.

### 3.3. Represent Module (`Represent/iRepresent/iRepresentShell.h`)
*   **Purpose:** Provides a comprehensive, abstract rendering interface for the game.
*   **Architecture:**
    *   **Interface-based:** Defined by the `iRepresentShell` abstract base class, allowing for flexible backend implementations (e.g., `Represent2.dll` or `Represent3.dll`).
    *   **Centralized Rendering Control:** Exposes a wide range of rendering functionalities through a single interface.
*   **Key Functionalities:**
    *   **Device Management:** Initialization (`Create`), reset (`Reset`), and release (`Release`) of graphics devices.
    *   **Font & Text Rendering:** `CreateAFont`, `OutputText`, `OutputRichText` for displaying text with various options.
    *   **Image & Sprite Management:** `CreateImage`, `FreeImage`, `GetImageParam`, `SaveImage`, etc., for handling game assets. Includes mechanisms for bitmap data access (`GetBitmapDataBuffer`).
    *   **Drawing Operations:** `DrawPrimitives` for rendering geometric shapes, `DrawPrimitivesOnImage` for rendering to textures, `RepresentBegin`/`RepresentEnd` for frame delineation.
    *   **Camera/View Control:** `LookAt` for setting the camera's focus.
    *   **Coordinate Transformations:** `ViewPortCoordToSpaceCoord` for converting between screen and game world coordinates.
    *   **Lighting:** `SetLightInfo` suggests a grid-based lighting system.
    *   **Miscellaneous:** Screen capture (`SaveScreenToFile`), gamma correction (`SetGamma`), color adjustment (`SetAdjustColorList`), and inline picture display integration (`AdviseRepresent`).
*   **Dynamic Loading:** The `CreateRepresentShell()` function is designed for dynamic loading of rendering backend DLLs.
*   **Challenges:** While interface-based, the broad scope of `iRepresentShell`'s responsibilities suggests a potentially monolithic underlying implementation. Modernization would involve replacing the legacy DirectX backend and adapting the interface to a more parallel-friendly, component-based rendering pipeline.

### 3.4. UI Module (`S3Client/Ui/UiShell.h`)
*   **Purpose:** Custom-built, event-driven GUI framework for the game client.
*   **Architecture:**
    *   **Global Control Functions:** A set of global `Ui` prefixed functions (`UiInit`, `UiStart`, `UiExit`, `UiPaint`, `UiHeartBeat`, `UiProcessInput`) manage the overall UI lifecycle and interaction.
    *   **Component-Based:** Utilizes a hierarchy of `KWnd` (K-Window) classes, with `KWndImageTextButton` and `KWndButton` as base classes for various interactive UI elements.
    *   **Tight Game State Integration:** UI components often have `UpdateData()` methods, indicating they directly fetch and display game state. Functions like `UiStartGame()` and `UiOnGameServerConnected()` show deep integration with game events.
*   **Key Functionalities:**
    *   **Initialization & Lifecycle:** `UiInit()`, `UiStart()`, `UiExit()`.
    *   **Rendering:** `UiPaint(int nGameLoop)`.
    *   **Input Processing:** `UiProcessInput(unsigned int uMsg, unsigned int uParam, int nParam)`.
    *   **Heartbeat/Updates:** `UiHeartBeat()` for periodic logic updates.
    *   **Specific UI Elements:** Classes for player stats (`Player_Life`, `Player_Mana`, `Player_Exp`), inventory (`Player_Items`), skills (`Player_Skills`), team management (`Player_Team`), actions (`Player_Sit`, `Player_Run`), etc., each handling their own display and interaction.
*   **Challenges:** The custom nature of the UI framework and its tight coupling with game logic present significant modernization hurdles. Decoupling UI from game state, adopting a more standard and flexible UI framework, and designing for thread-safe UI updates in a multithreaded environment will be crucial for the project's objectives.

### 3.5. NetConnect Module (`S3Client/NetConnect/NetConnectAgent.h`)
*   **Purpose:** Manages client-side network connections, message sending, and message dispatching.
*   **Architecture:**
    *   **Centralized Agent:** `KNetConnectAgent` is a central class with a global instance (`g_NetConnectAgent`) that orchestrates networking operations.
    *   **Module-based Design:** Likely built on top of a lower-level network client interface (`IClient`), which might be dynamically loaded (indicated by `HMODULE`, function pointers, and `IClientFactory`).
    *   **Custom Protocol:** Includes `KProtocol.h`, suggesting a custom game-specific communication protocol.
*   **Key Functionalities:**
    *   **Connection Management:** `Initialize()`, `Exit()`, `ClientConnectByNumericIp()`, `DisconnectClient()`, `ConnectToGameSvr()`, `DisconnectGameSvr()`, `IsConnecting()`. Distinguishes between general client and game server connections.
    *   **Message Sending:** `SendMsg(const void *pBuffer, int nSize)`.
    *   **Network Processing Loop:** `Breathe()` for continuous processing of network events, including receiving and dispatching messages.
    *   **Request Timeouts:** `UpdateClientRequestTime()` to handle network request timeouts.
    *   **Message Dispatching:** `RegisterMsgTargetObject()` allows modules to register `iKNetMsgTargetObject` implementations to handle specific `PROTOCOL_MSG_TYPE` messages, using an internal array (`m_MsgTargetObjs`) for mapping.
*   **Challenges:** The tight coupling through a global agent, the custom protocol, and the potentially blocking nature of network operations in a single-threaded main loop are significant challenges for modernization. Future work would involve adopting asynchronous network operations, potentially using a modern networking library, and integrating message processing into a job-based system to avoid blocking the main thread.

## 4. Proposed New Architecture (Placeholder - To be detailed during Phase 1.3 onwards)

### 4.1. Core Principles
*   **Data-Oriented Design:** Emphasize processing data efficiently.
*   **Job/Task System:** A central component for parallel execution of work units.
*   **Decoupled Subsystems:** Independent modules for Physics, AI, etc.

### 4.2. Major Components
*   **Job System:** Manages and schedules tasks across multiple threads.
*   **Physics Subsystem:** Handles game physics, running as jobs.
*   **AI Subsystem:** Manages NPC behavior, running as jobs.
*   **Rendering Subsystem:**
    *   Abstract Rendering Interface.
    *   Modern Graphics API Backend (DirectX 12/Vulkan).
    *   Dedicated Render Thread.
*   **Game Logic:** High-level gameplay systems that interact with subsystems.

### 4.3. Data Flow and Interaction
*   **Inter-Subsystem Communication:** Define how decoupled systems will communicate (e.g., message queues, shared-memory with proper synchronization).
*   **Synchronization Mechanisms:** Detail chosen methods for ensuring thread-safety (e.g., mutexes, atomics, lock-free structures).

## 5. Coding Standards and Conventions (Placeholder)
*   C++ Standard: C++17/20
*   Naming Conventions:
*   Formatting:
*   Error Handling:

## 6. Development Environment & Tooling (Placeholder)
*   Build System: (e.g., CMake)
*   IDE: (e.g., Visual Studio)
*   Version Control: Git
*   Static Analysis Tools:
*   Profiling Tools:
