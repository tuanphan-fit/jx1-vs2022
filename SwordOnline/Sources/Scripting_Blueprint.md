# Scripting Module Blueprint

## 1. Module Goal

To create a clean, safe, and powerful C++ interface for interacting with the Lua scripting engine. This module will provide all the functionality needed to load scripts, execute them, and facilitate seamless, type-safe communication between C++ and Lua. This module completely replaces the legacy `KLuaScript` class and its C-style interface.

**Core Technology:**
-   **Lua 5.4:** A modern, standard version of the Lua interpreter.
-   **sol2:** A fast, header-only C++ library for binding Lua and C++. It provides a safe, expressive, and C++-idiomatic API.

## 2. New Class Definitions

### Class `Scripting::LuaContext`
**Purpose:** A single, powerful class that encapsulates the Lua state (`sol::state`). It will be responsible for all scripting-related operations, including loading scripts, binding C++ functions and classes, and executing Lua code.
**Replaces:** `KLuaScript`

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Constructor` | `LuaContext()` | Creates the internal `sol::state` and automatically loads standard Lua libraries. | `KLuaScript::Init`, `RegisterStandardFunctions` |
| `Destructor` | `~LuaContext()` | The `sol::state` destructor handles all cleanup automatically. | `KLuaScript::Exit` |
| `RunScriptFile` | `sol::protected_function_result RunScriptFile(const std::string& path)` | Loads and executes a Lua script file from the VFS. Returns a result object that contains either the return value or an error message. | `KLuaScript::Load`, `KLuaScript::Execute` |
| `RunScript` | `sol::protected_function_result RunScript(const std::string& code)` | Executes a string of Lua code. | `KLuaScript::ExecuteCode` |
| `GetGlobal<T>` | `sol::optional<T> GetGlobal<T>(const std::string& name)` | Safely gets a global variable from the Lua state. Returns an empty optional if the variable doesn't exist or has the wrong type. | Direct, unsafe access to the Lua stack. |
| `SetGlobal<T>` | `void SetGlobal<T>(const std::string& name, const T& value)` | Sets a global variable in the Lua state. | Direct, unsafe access to the Lua stack. |
| `RegisterFunction` | `void RegisterFunction(const std::string& name, FunctionType func)` | Binds a C++ free function or lambda to a global Lua function. | `KLuaScript::RegisterFunction` |
| `RegisterUserType<T>` | `void RegisterUserType<T>(/*...binding info...*/)` | Binds a C++ class to a Lua usertype, exposing its methods and variables. | Manual table manipulation (`SetTableMember`) |

**Example of Modern API vs. Legacy API:**

**Legacy (Calling a Lua function):**
```cpp
// Insecure, error-prone, requires manual type checking
lua_getglobal(L, "MyLuaFunc");
lua_pushnumber(L, 10);
lua_pushstring(L, "hello");
if (lua_pcall(L, 2, 1, 0) != 0) {
    // handle error
}
int result = lua_tonumber(L, -1);
lua_pop(L, 1);
```

**New `sol2` API (Calling a Lua function):**
```cpp
// Safe, expressive, C++-idiomatic
sol::state lua;
// ...
sol::protected_function myLuaFunc = lua["MyLuaFunc"];
sol::protected_function_result result = myLuaFunc(10, "hello");
if (result.valid()) {
    int value = result;
} else {
    sol::error err = result;
    std::cout << "Lua error: " << err.what() << std::endl;
}
```
This demonstrates the vast improvement in safety, clarity, and ease of use that the new module will provide.
