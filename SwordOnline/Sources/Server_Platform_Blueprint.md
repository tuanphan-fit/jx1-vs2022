# Server Platform Module Blueprint

## 1. Module Goal

To provide a minimal, modern C++ abstraction layer over the underlying Linux/POSIX operating system services. The server applications will use this module for all OS interactions, ensuring the code is clean, portable (to other UNIX-like systems), and easy to reason about.

This module is a **server-side replacement** for the low-level, Win32-specific parts of the legacy `Engine` module (e.g., `KThread`, `KMutex`, `KEvent`). It does **not** deal with windows or graphics.

**Core Technology:** C++17, and standard POSIX APIs (`pthreads`, etc.).

## 2. New Class Definitions

### Class `Platform::Thread`
**Purpose:** A C++ RAII wrapper for a `pthread`. It simplifies thread creation and ensures that `pthread_join` is called automatically.
**Replaces:** `KThread`

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Constructor` | `Thread(std::function<void()> func)` | Creates and immediately starts a new thread, which executes the provided function. | `KThread::Run` |
| `Destructor` | `~Thread()` | Joins the thread, blocking until it completes. | `KThread::Wait` and manual cleanup |
| `Join` | `void Join()` | Explicitly waits for the thread to finish. | `KThread::Wait` |
| `Detach` | `void Detach()` | Allows the thread to run independently. | N/A |

---

### Class `Platform::Mutex`
**Purpose:** A C++ RAII wrapper for a `pthread_mutex_t`. It provides a simple, exception-safe locking mechanism.
**Replaces:** `KMutex`, `KCriticalSection`

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Constructor` | `Mutex()` | Initializes the underlying `pthread_mutex_t`. | `KMutex::KMutex` |
| `Destructor` | `~Mutex()` | Destroys the mutex. | `KMutex::~KMutex` |
| `Lock` | `void Lock()` | Acquires the lock, blocking if necessary. | `KMutex::Lock` |
| `Unlock` | `void Unlock()` | Releases the lock. | `KMutex::Unlock` |
| `TryLock` | `bool TryLock()` | Attempts to acquire the lock without blocking. | N/A |

*Note: In practice, we will almost always use `std::lock_guard` or `std::unique_lock` with this `Mutex` class to ensure automatic unlocking.*

---

### Class `Platform::HiResTimer`
**Purpose:** A high-resolution timer for measuring performance and game loop duration. The implementation is identical to the client-side version to ensure consistent timing logic across the ecosystem.
**Replaces:** `KTimer`

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Constructor`| `HiResTimer()`| Initializes the timer. Based on `<chrono>`.| `KTimer::KTimer` |
| `Tick()` | `void Tick()` | Marks the beginning of a new frame or time interval. | `KTimer::Start` |
| `GetDeltaTime()` | `float GetDeltaTime() const` | Returns the time elapsed since the last `Tick()`, in seconds. | `KTimer::GetElapse` |

---

### Class `Platform::DynamicLibrary`
**Purpose:** A C++ RAII wrapper for loading shared object (`.so`) files.
**Replaces:** Manual `LoadLibrary`/`GetProcAddress`/`FreeLibrary` calls.

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Constructor` | `DynamicLibrary(const std::string& path)` | Loads a shared library using `dlopen`. | `LoadLibrary` |
| `Destructor` | `~DynamicLibrary()` | Unloads the library using `dlclose`. | `FreeLibrary` |
| `GetSymbol` | `template<typename T> T GetSymbol(const std::string& name)` | Gets a pointer to a function or variable in the library using `dlsym`. | `GetProcAddress` |
