# Goddess (Event Manager) Server Blueprint

## 1. Module Goal

To design the `Goddess` server application. This service acts as the central orchestrator for all periodic in-game events (e.g., "Tống Kim," "Phong Lăng Độ," "Công Thành Chiến"). Its responsibilities include:
1.  **Event Scheduling:** Maintaining a schedule for various events.
2.  **State Management:** Tracking the current state (e.g., upcoming, active, cooldown) of each event.
3.  **Coordination with GameServers:** Communicating with relevant `GameServer` instances to activate/deactivate event-specific maps, teleport players, and manage other event-related mechanics.

This server application will be a modern C++, 64-bit Linux executable. It is a new component in our explicit distributed server architecture.

## 2. Core Technology

*   **Language:** C++17
*   **Networking:** **Asio**. Used for internal communication with `GameServer`s.
*   **Dependencies:** `Shared` module, `Server_Platform` module.

## 3. Class Definitions

### Class `Goddess::Server`
**Purpose:** The main application class for the Goddess server. It owns the `EventManager` and manages network connections to `GameServer`s.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Run` | `void Run()` | Contains the main server loop, processing internal messages and updating the `EventManager`. |
| `SendToGameServer` | `void SendToGameServer(GameServerID, const Message&)` | Routes messages to specific `GameServer` instances. |

---

### Class `Goddess::EventManager`
**Purpose:** Encapsulates the logic for scheduling, managing states, and executing event-specific actions.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Update` | `void Update(float deltaTime)` | Called every tick. Checks the schedule, transitions event states, and sends commands to `GameServer`s via the `Server`'s `GameServerProxy` (or direct messaging). |
| `ScheduleEvent` | `void ScheduleEvent(EventConfig config)` | Adds a new event to the schedule. |
| `StartEvent` | `void StartEvent(EventType eventId)` | Initiates a specific event, sending commands to `GameServer`s to prepare. |
| `EndEvent` | `void EndEvent(EventType eventId)` | Concludes an event, sending cleanup commands. |

---

### Class `Goddess::GameServerProxy`
**Purpose:** Manages persistent network connections to all active `GameServer` instances. It handles sending commands and receiving status updates related to events.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `ConnectToGameServer` | `void ConnectToGameServer(const std::string& address, int port)` | Establishes a connection to a `GameServer`. |
| `SendCommand` | `void SendCommand(GameServerID, const EventCommand&)` | Sends an event-related command (e.g., "ACTIVATE_MAP") to a `GameServer`. |
| `ReceiveUpdate` | `EventStatus Update(GameServerID)` | Receives and processes status updates from a `GameServer`. |

---

## 4. High-Level Logic Flow (Event Activation)

1.  `Goddess::Server` starts and initializes its `EventManager` and `GameServerProxy` connections to all known `GameServer`s.
2.  In `Server::Run()`, `EventManager::Update()` is called periodically.
3.  `EventManager::Update()` determines that a scheduled event (e.g., "Tống Kim") should start.
4.  The `EventManager` then sends commands (e.g., `Msg_ActivateEventMap`) to the relevant `GameServer`s via `GameServerProxy::SendCommand()`.
5.  `GameServer`s receive these commands, activate their event maps, and send back status updates to `Goddess`.
6.  The `EventManager` continues to track the event's progress and sends further commands (e.g., `Msg_TeleportPlayersToEvent`) as needed.
