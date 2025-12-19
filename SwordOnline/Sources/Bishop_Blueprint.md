# Bishop (Role DB) Server Blueprint

## 1. Module Goal

To design the `Bishop` server application. This service acts as the authoritative manager for all player character ("role") data. It has no direct interaction with game clients. Instead, it listens for internal network requests from other server applications (primarily `GameServer`) to handle the persistence of character information.

Its sole responsibilities are:
1.  Loading character data from the MySQL Game Database.
2.  Saving character data to the MySQL Game Database.
3.  Creating new characters in the database.

This server application will be a modern C++, 64-bit Linux executable. It replaces the legacy `Bishop` project.

## 2. Core Technology

*   **Language:** C++17
*   **Networking:** **Asio**. Used for listening for and communicating with other backend servers.
*   **Dependencies:** `Shared` module, `Server_Platform` module, `Database` module.

## 3. New Class Definitions

### Class `Bishop::TCPServer`
**Purpose:** The main networking class. It listens for incoming TCP connections from other trusted backend servers (like `GameServer`).

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Constructor` | `TCPServer(asio::io_context&, port)` | Initializes the server to listen on a specific port for internal traffic. |
| `StartAccept` | `void StartAccept()` | Begins asynchronously waiting for new server connections. |

---

### Class `Bishop::GameServerSession`
**Purpose:** Manages a persistent connection to a single `GameServer` instance, processing its requests.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Start` | `void Start()` | Begins asynchronously reading requests from the `GameServer`. |
| `ProcessLoadCharRequest` | `void ProcessLoadCharRequest(Msg_LoadChar* msg)` | Handles a request to load a character, calling the `CharacterDB` class. |
| `ProcessSaveCharRequest` | `void ProcessSaveCharRequest(Msg_SaveChar* msg)` | Handles a request to save a character, calling the `CharacterDB` class. |

---

### Class `Bishop::CharacterDB`
**Purpose:** A dedicated data access layer that encapsulates all SQL queries related to character data.
**Replaces:** `PlayerCreator.cpp`, `GamePlayer.cpp` logic.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Constructor`| `CharacterDB(std::shared_ptr<Database::ConnectionPool> pool)` | Takes a dependency on the MySQL database connection pool. |
| `LoadCharacter` | `std::optional<PlayerData> LoadCharacter(uint32_t charId)` | Executes multiple `SELECT` queries to retrieve all data for a character (stats, inventory, skills, etc.) and assembles it into a `PlayerData` struct. |
| `SaveCharacter` | `bool SaveCharacter(const PlayerData& data)` | Executes `UPDATE` or `INSERT` statements to persist all character data back to the database in a transactional manner. |

---

## 4. High-Level Logic Flow (Loading a Character)

1.  A `GameServer` needs to load a player. It sends a `Msg_LoadChar` request containing a `characterId` over its persistent connection to the `Bishop` server.
2.  The `GameServerSession` on the `Bishop` server receives the message and calls `ProcessLoadCharRequest()`.
3.  `ProcessLoadCharRequest()` calls `g_CharacterDB->LoadCharacter(characterId)`.
4.  The `CharacterDB` object gets a `MySQLConnection` from its pool.
5.  It executes all the necessary `SELECT` queries to retrieve the character's full data set.
6.  If successful, it constructs a `PlayerData` object (a struct defined in the `Shared` module).
7.  The `GameServerSession` receives the `PlayerData` object, serializes it into a `Msg_LoadChar_Response` network message, and sends it back to the originating `GameServer`.
8.  The `GameServer` receives the response and can now create the `Player` entity in its world simulation.
