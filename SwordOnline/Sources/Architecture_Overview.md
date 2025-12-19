# NextGenJX Architecture Overview

## 1. High-Level Goal

The primary goal of the `NextGenJX` project is to re-architect the legacy JX Online codebase into a modern, performant, and maintainable ecosystem with two distinct deployment targets:

1.  **Game Client:** A 64-bit native Windows application, optimized for modern GPUs to deliver a high-quality visual experience.
2.  **Game Server:** A 64-bit native Linux application, designed for high-performance, scalable, and authoritative game state simulation.

## 2. Core Principle: Separation of Concerns

The fundamental principle of this new architecture is the strict separation of concerns between client, server, and shared logic. This replaces the legacy model of a single codebase with numerous `#ifdef` preprocessor flags.

## 3. The 3-Part Module Structure

The entire `NextGenJX` solution will be organized into three primary component types: a `Shared` library, a single `Client` application, and a collection of distributed `Server` applications.

### 3.1. `Shared` (Static Library)
*   **Purpose:** To contain all code that is platform-agnostic and required by *both* the client and the server services. This is the heart of the game's logic and rules.
*   **Contents:**
    *   The ECS framework (`EnTT`).
    *   Definitions of all `Components`.
    *   Definitions of purely logical `Systems`.
    *   The Network Protocol Definition.
*   **Build Target:** A statically linked library (`.lib`/`.a`).

### 3.2. `Client` (Windows Executable)
*   **Purpose:** The user-facing game application, responsible for presentation and communicating with the server gateway.
*   **Contents:** `Platform`, `Renderer`, `Audio`, and `Assets` modules. Client-side `Systems` and a `NetworkClient`.
*   **Links Against:** `Shared`.

### 3.3. `Server` (Multiple Linux Executables)
The server-side is a distributed architecture composed of several distinct services.

*   #### `GameServer`
    *   **Purpose:** Runs the authoritative simulation for a specific set of maps/regions. There will be multiple `GameServer` instances running.
    *   **Links Against:** `Shared`.
    *   **Communicates With:** `Bishop`, `S3Relay`.

*   #### `Bishop` (Role DB Server)
    *   **Purpose:** Manages player character data (loading, creating, saving).
    *   **Connects To:** **MySQL** Game Database.
    *   **Links Against:** `Shared`.

*   #### `S3Relay` (Account DB & Gateway Server)
    *   **Purpose:** Handles player authentication, account management, and billing/top-up operations. Also acts as the initial gateway for client connections before handing them off to a `GameServer`.
    *   **Connects To:** **MSSQL** Account Database.
    *   **Links Against:** `Shared`.

*   #### `Goddess` (Event Manager Server)
    *   **Purpose:** Manages the scheduling and execution of periodic in-game events (e.g., "Tống Kim", "Phong Lăng Độ", "Công Thành Chiến"). It orchestrates state transitions for these events and communicates with `GameServer` instances to manage event zones and player participation.
    *   **Links Against:** `Shared`.
    *   **Communicates With:** `GameServer` (to trigger/manage events).

## 4. High-Level Dependency Graph

```
                               +----------------+
                               | MSSQL Database |
                               +----------------+
                                       ^
                                       | (ODBC)
+-----------------+            +-------+--------+
|     Client      |----------->|    S3Relay     |
| (Windows .exe)  | (TCP)      | (Login/Account)|
+-----------------+            +-------+--------+
        ^      \                     /
        | (TCP) \                   / (RPC)
        |        \                 /
+-------+--------+ \               / +----------------+
|   GameServer   |  \-------------+  | MySQL Database |
|  (Map Logic)   | (Hand-off)         +----------------+
+----------------+                       ^
        | (RPC)                          | (ODBC/mysql-conn)
        |                          +-------+--------+
        +------------------------->|     Bishop     |
                                   | (Role/Char DB) |
                                   +----------------+
```

