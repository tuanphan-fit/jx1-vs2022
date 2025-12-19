# Linux Deployment Impact Report

## 1. Objective

This document analyzes the impact of the new dual-target architecture (64-bit Windows Client, 64-bit Linux Server) on our project plan. It reviews the validity of existing blueprints and outlines the analysis required for the new server-side components.

---

## 2. Part 1: Client Blueprint Review

The architectural decision to target a 64-bit Windows client **validates** the blueprints created thus far. These documents describe the architecture for a modern, presentation-focused application and are perfectly suited for the client.

**Conclusion:** The following blueprint documents are confirmed as the architectural plan for the **`Client`** application. They will be considered part of the `Client/` portion of our new architecture.

-   `Platform_Blueprint.md` (based on SDL2)
-   `Renderer_Blueprint.md` (based on BGFX)
-   `Audio_Blueprint.md` (based on miniaudio)
-   `Assets_Blueprint.md`
-   `Scripting_Blueprint.md` (the client-side usage of the scripting engine)
-   `Game_Blueprint.md` (the client-side Components and Systems, e.g., `RenderSystem`, `PlayerInputSystem`)

No re-work is needed for these client-side plans at this stage.

---

## 3. Part 2: Legacy Server & Database Analysis

This section outlines the plan to analyze the legacy server code to inform the design of the new 64-bit Linux `Server` application.

### 3.1. Core Server Project Identification

From the `JXAll.sln` file, the `GameServer` project is identified as the central application for the game world simulation. Our analysis will begin here.

### 3.2. Analysis Plan & Initial Findings

1.  **`GameServer` Dependency Analysis:** `GameServer.vcxproj` links against `CoreServer.lib` and `engine.lib`, but **not** against any direct database libraries (e.g., ODBC).

2.  **`Sword3PaySys` (Account Server) Analysis:** `Sword3PaySys.vcxproj` **does** link against `odbc32.lib` and contains source files clearly related to MSSQL connections (`S3P_MSSQLServer_Connection.cpp`). This is the **Account Database Server**.

3.  **`Bishop` (Role Server) Analysis:** `Bishop.vcxproj` also **does** link against `odbc32.lib` and contains source files related to player/role management (`PlayerCreator.cpp`). This is the **Role/Game Database Server**.

### 3.3. Legacy Server Architecture Conclusion

The legacy server architecture is a **distributed, multi-server system**:

*   A **`GameServer`** instance is responsible for running the actual game simulation (using `CoreServer.lib`) but has no direct database access.
*   When a player's data needs to be saved or loaded, the `GameServer` sends a network message to the **`Bishop`** server.
*   The **`Bishop`** server receives this message, performs the necessary database operations against the **Game Database (MySQL)** using ODBC, and then sends a confirmation message back to the `GameServer`.
*   A separate **`Sword3PaySys`** server handles all account-related database operations against the **Account Database (MSSQL)**, also using ODBC.

This is a classic distributed architecture designed to separate concerns. However, for our initial modernization effort, it introduces unnecessary complexity.

### 4. Impact on `NextGenJX` Server Blueprint

This analysis directly informs the design of our new 64-bit Linux `Server` application.

1.  **Consolidated Architecture:** For `NextGenJX`, we will not replicate the complex multi-server network communication for database access. We will build a single, monolithic **`NextGenJX_Server`** application for our initial milestones.
2.  **Direct Database Connection:** This new server application will be responsible for **both** game simulation and direct database communication.
3.  **Database Connectors:** The `Server` blueprint must include a new **`Database` module**. This module will be responsible for:
    *   Connecting to the **MySQL** game database. A modern C++ library like **`mysql-connector-c++`** or a similar reputable one will be used instead of raw ODBC.
    *   Connecting to the **MSSQL** account database. Since the server is on Linux, we must use Microsoft's official **ODBC Driver for SQL Server on Linux**.
4.  **Revised Server Blueprint:** The blueprint for the `Server` application will now be simpler in terms of network architecture but more complex in terms of direct responsibilities. It will link against the `Shared` library and contain the new `Database` module.

This completes the analysis of the legacy server architecture and its impact on our new design. We have a clear path forward for designing the `NextGenJX_Server`.

