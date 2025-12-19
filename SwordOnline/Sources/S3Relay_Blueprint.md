# S3Relay (Account & Gateway) Server Blueprint

## 1. Module Goal

To design the `S3Relay` server application, the primary entry point for all game clients. This server has two core responsibilities:
1.  **Gateway:** Accept incoming client connections and manage them during the pre-game phase.
2.  **Authentication:** Process login requests by validating user credentials against the MSSQL Account Database.
3.  **Handoff:** Upon successful authentication, provide the client with the address of a `GameServer` to connect to.

This server application will be a modern C++, 64-bit Linux executable. It replaces the legacy `Sword3PaySys` and `S3Relay` projects.

## 2. Core Technology

*   **Language:** C++17
*   **Networking:** **Asio** (either standalone or the version from the C++20 standard). Asio is a high-performance, asynchronous networking library perfect for a scalable server.
*   **Dependencies:** `Shared` module, `Server_Platform` module, `Database` module.

## 3. Class Definitions

### Class `S3Relay::TCPServer`
**Purpose:** The main networking class. It listens for incoming TCP connections and creates a `ClientSession` to handle each one.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Constructor` | `TCPServer(asio::io_context&, port)` | Initializes the server to listen on a specific port. |
| `StartAccept` | `void StartAccept()` | Begins asynchronously waiting for new client connections. |

---

### Class `S3Relay::ClientSession`
**Purpose:** Manages a single client connection from the moment it's accepted until the client is authenticated and handed off.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Start` | `void Start()` | Begins asynchronously reading data from the client socket. |
| `HandleRead`| `void HandleRead(error_code, bytes_transferred)` | Callback executed when data is received. It will parse messages and dispatch them. |
| `HandleWrite`| `void HandleWrite(error_code, bytes_transferred)` | Callback executed after data has been sent. |
| `ProcessLoginRequest` | `void ProcessLoginRequest(C2S_Login* msg)` | Processes a login message, calling the `AccountAuthenticator`. |

---

### Class `S3Relay::AccountAuthenticator`
**Purpose:** A utility class that encapsulates the logic for authenticating a user.
**Replaces:** `S3PAccount.cpp`

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Constructor`| `AccountAuthenticator(std::shared_ptr<Database::ConnectionPool> pool)` | Takes a dependency on the MSSQL database connection pool. |
| `Authenticate` | `bool Authenticate(const std::string& user, const std::string& pass)` | Executes a `SELECT` query against the account database to verify the user's credentials. Returns true on success. |

---

## 4. High-Level Logic Flow (Authentication)

1.  `S3Relay::TCPServer` is created and `StartAccept()` is called.
2.  A game client connects. The `TCPServer` accepts the connection and creates a `std::shared_ptr<ClientSession>`, then calls `session->Start()`.
3.  The client sends a `C2S_Login` message containing a username and password.
4.  The `ClientSession::HandleRead` callback is fired. It deserializes the message and calls `ProcessLoginRequest()`.
5.  `ProcessLoginRequest` calls `g_AccountAuthenticator->Authenticate(user, pass)`.
6.  The `AccountAuthenticator` gets a connection from its `Database::ConnectionPool`, executes the SQL query, and returns the result.
7.  If authentication is successful, the `ClientSession` will look up an available `GameServer` (logic to be defined) and send an `S2C_LoginSuccess_Redirect` message to the client with the IP and port of the `GameServer`.
8.  The `ClientSession` then closes the connection. The client is now responsible for connecting to the `GameServer`.
