# GameServer Blueprint

## 1. Module Goal

To design the `GameServer` application, the authoritative heart of the game world simulation. A `GameServer` process is responsible for simulating a specific subset of the game's maps. It manages all NPC AI, player actions, combat, and game rule enforcement within its designated maps. It receives authenticated player connections, loads their data from the `Bishop` server, and streams world state updates back to the clients.

This server application will be a modern C++, 64-bit Linux executable. It replaces the legacy `GameServer` project.

## 2. Core Technology

*   **Language:** C++17
*   **Networking:** **Asio**. Used for both accepting client connections and making requests to other backend servers.
*   **ECS:** **EnTT**. The `entt::registry` will be the central data store for all game entities.
*   **Dependencies:** `Shared` module, `Server_Platform` module, `Database` module.

## 3. Class/System Definitions

### Class `GameServer::Server`
**Purpose:** The main application class. It owns the `entt::registry`, the main simulation loop timer, and a list of all `Systems`.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Run` | `void Run()` | Contains the main server loop. It calculates delta time and calls the `Update()` method on all registered systems in a specific order. |

---

### Class `GameServer::NetworkManager`
**Purpose:** Manages all network communication. It listens for connections from clients handed off by `S3Relay`, and it establishes client connections to the `Bishop` and `S3Relay` services for internal requests.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Update` | `void Update()` | Polls all sockets for new messages. When a message is received, it deserializes it and creates a corresponding "event entity" in the ECS registry. |
| `SendToClient` | `void SendToClient(ClientID, const Message&)` | Sends a network message to a specific game client. |
| `RequestCharacterLoad` | `void RequestCharacterLoad(CharID)` | Sends a `Msg_LoadChar` request to the `Bishop` server. |

---

### Server-Side Systems
**Purpose:** These systems contain all the game logic. They are executed every frame by the main server loop and operate on entities in the `entt::registry`.
**Replaces:** The monolithic `Breathe()`/`Active()` methods in `KPlayer` and `KNpc`, and the server-side logic in `CoreServer.lib`.

| New System | Operates On (Components) | Responsibility |
| :--- | :--- | :--- |
| `System::PlayerConnection` | Processes `PlayerConnectEvent` entities. | When a player connects, this system sends a request to the `NetworkManager` to load the character data from `Bishop`. When the data returns, it creates the player entity and all its necessary components in the ECS. |
| `System::PlayerInput` | Processes `InputRequestEvent` entities from clients. | Translates client requests (e.g., "move to X,Y") into changes on player components (e.g., updating the `Target` or `Velocity` component). |
| `System::AI` | `Npc`, `Transform`, `Stats`, `Velocity` | Manages NPC behavior. Updates NPC state machines or behavior trees. Sets `Velocity` and `Target` components to make NPCs move and act. |
| `System::Movement` | `Transform`, `Velocity` | The authoritative movement system. Updates all entity positions based on their velocity, performing server-side collision checks against the map's geometry. |
| `System::Skill` | Processes `CastSkillEvent` entities. | When a `CastSkillEvent` occurs, this system validates the cast, consumes resources, and creates the `Missile` entities with the correct payloads and physics properties. |
| `System::Collision` | `Transform`, `CollisionVolume`, `EffectPayload` | Detects collisions between entities (e.g., missile-vs-player). On collision, it applies the `EffectPayload` from the missile to the target. |
| `System::StateSync` | `Transform`, `Health`, `RenderInfo` (and any other component with a "dirty" flag) | The "networking" system. It finds all components that have changed this frame, collects the data, and sends `UpdateTransform`, `UpdateHealth`, etc. messages to all relevant clients. |

## 4. High-Level Logic Flow (Client Action)

1.  A client sends a `C2S_MoveRequest` message to the `GameServer`.
2.  `NetworkManager::Update()` receives the message and creates an entity with an `InputRequestEvent` component containing the player's entity ID and the target coordinates.
3.  The main loop executes `System::PlayerInput::Update()`.
4.  The `PlayerInputSystem` finds the event entity, gets the corresponding player entity, and updates that player's `Velocity` and `Target` components. The event entity is then destroyed.
5.  The main loop executes `System::Movement::Update()`.
6.  The `MovementSystem` finds all entities with `Transform` and `Velocity` (including the player), and updates their `Transform::position` based on the velocity. It marks the player's `Transform` component as "dirty".
7.  The main loop executes `System::StateSync::Update()`.
8.  The `StateSyncSystem` finds all entities with "dirty" components. It finds the player's dirty `Transform`, creates an `S2C_UpdateTransform` message, and sends it via the `NetworkManager` to all clients in visual range of the player.
