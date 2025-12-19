# Database Module Blueprint

## 1. Module Goal

To abstract all database interactions for the `NextGenJX` server applications. This module will provide a clean, modern C++ interface for connecting to, querying, and receiving results from the two required databases: the MySQL Game Database and the MSSQL Account Database. All database-specific code will be isolated within this module.

This module replaces the legacy database code found in the `Bishop` and `Sword3PaySys` server projects.

## 2. Core Technology

*   **For MySQL:** The official **Oracle `mysql-connector-c++`**. This provides a modern, C++-native API.
*   **For MSSQL (on Linux):** The official **Microsoft ODBC Driver for SQL Server**. We will wrap the low-level, C-style ODBC API calls in a clean C++ interface.

## 3. New Class Definitions

### Class `Database::QueryResult`
**Purpose:** A generic class to hold the results of a database query in a tabular format, abstracting away the underlying database-specific result set object.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `GetRowCount` | `size_t GetRowCount() const` | Returns the number of rows in the result set. |
| `GetInt` | `int GetInt(size_t row, const std::string& colName) const` | Gets an integer value from a specific row and column. |
| `GetString` | `std::string GetString(size_t row, const std::string& colName) const` | Gets a string value from a specific row and column. |

---

### Interface `Database::iConnection`
**Purpose:** An abstract interface that defines the contract for a connection to a database.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Connect` | `bool Connect(const ConnectionInfo& info)` | Establishes a connection to the database. |
| `Disconnect`| `void Disconnect()` | Closes the connection. |
| `Execute` | `bool Execute(const std::string& sql)` | Executes a non-query SQL statement (e.g., `INSERT`, `UPDATE`, `DELETE`). |
| `Query` | `std::unique_ptr<QueryResult> Query(const std::string& sql)` | Executes a SQL query that returns a result set (e.g., `SELECT`). |

---

### Class `Database::MySQLConnection`
**Purpose:** The concrete implementation of `iConnection` for the MySQL Game Database.
**Replaces:** Database code in `Bishop`.

| Method | Notes on Implementation |
| :--- | :--- |
| `Connect` | Will use the `mysql-connector-c++` driver to establish the connection. |
| `Execute` / `Query` | Will use the `sql::Statement` or `sql::PreparedStatement` classes from the connector to execute queries. |

---

### Class `Database::MSSQLConnection`
**Purpose:** The concrete implementation of `iConnection` for the MSSQL Account Database.
**Replaces:** Database code in `Sword3PaySys`.

| Method | Notes on Implementation |
| :--- | :--- |
| `Connect` | Will use the Linux ODBC API (`SQLConnect`, `SQLDriverConnect`) to establish the connection. |
| `Execute` / `Query` | Will use the ODBC API (`SQLExecDirect`, `SQLFetch`, `SQLGetData`) to execute queries and retrieve results, wrapping them in the `QueryResult` class. |

---

### Class `Database::ConnectionPool`
**Purpose:** Manages a pool of `iConnection` objects for a specific database to reduce the overhead of repeatedly creating and destroying connections.
**Replaces:** `S3PDBConnectionPool`.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Constructor`| `ConnectionPool(DBType type, const ConnectionInfo& info, int poolSize)` | Creates a pool of a specified size, with all connections pre-established. |
| `GetConnection`| `std::shared_ptr<iConnection> GetConnection()` | Retrieves an available connection from the pool. Blocks if none are available. |
| `ReturnConnection` | `void ReturnConnection(std::shared_ptr<iConnection> conn)` | Returns a connection to the pool, making it available for other threads. |
