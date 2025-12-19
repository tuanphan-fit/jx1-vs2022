# Shared Module Blueprint

## 1. Module Goal

To create a statically linked library containing all platform-agnostic code, data structures, and interfaces required by both the `Client` and the various `Server` applications. This module is the cornerstone of the new architecture, ensuring that all parts of the ecosystem have a common understanding of game objects and communication protocols.

This module replaces the need for widespread `#ifdef _SERVER` flags by providing a single, unified codebase for shared logic.

**Core Technology:** C++17, `EnTT` (for component definitions).

## 2. Component Definitions

The `Shared` module will define all the core data components for our Entity-Component-System (ECS) architecture. These are POD (Plain Old Data) structs that contain no logic.

| New Component | Contained Data | Replaces Legacy |
| :--- | :--- | :--- |
| `Component::NetworkID`| `uint64_t id` | `m_dwID` in `KPlayer`/`KNpc` |
| `Component::Transform` | `vec3 position`, `float rotation` | `m_MapX`, `m_MapY`, `m_Dir` in `KNpc` and `KPlayer` |
| `Component::Player` | `string name` | `Name` in `KPlayer` |
| `Component::Npc` | `NpcType type` | `m_Kind` in `KNpc` |
| `Component::Stats` | `int strength`, `int dexterity`, `int vitality`, `int energy` | `m_nStrength`, `m_nDexterity`, etc. in `KPlayer`/`KNpc` |
| `Component::Health` | `int current_hp`, `int max_hp` | `m_CurrentLife`, `m_CurrentLifeMax` in `KPlayer`/`KNpc` |
| `Component::Inventory` | `vector<Entity> items` | `KItemList m_ItemList` in `KPlayer` |
| `Component::RenderInfo`| `string sprite_name`, `Color tint` | `m_DataRes` in `KNpc`, visual properties |

## 3. Network Protocol Definition

The `Shared` module will define the new network protocol. We will move away from the legacy C-style structs to a more robust and extensible message format.

### 3.1. Basic Message Structure

All network messages will follow a simple `Header + Body` format.

```cpp
struct MessageHeader {
    uint16_t message_id; // Unique ID for the message type
    uint16_t message_size; // Size of the body in bytes
};

// Example Message
struct S2C_PlayerSpawn { // Server-to-Client
    MessageHeader header;
    uint64_t network_id;
    float pos_x;
    float pos_y;
    int current_hp;
    int max_hp;
    char sprite_name[32];
};

struct C2S_MoveRequest { // Client-to-Server
    MessageHeader header;
    float target_x;
    float target_y;
};
```

### 3.2. Message IDs (`MessageID.h`)

An enum will define all possible message IDs. This replaces the scattered protocol definitions in the legacy code.

```cpp
enum class MessageID : uint16_t
{
    // Server-to-Client
    PlayerSpawn,
    EntityDestroy,
    UpdateTransform,
    UpdateHealth,

    // Client-to-Server
    MoveRequest,
    CastSkillRequest,
};
```

This modern, explicit approach to the shared components and network protocol will form a solid, type-safe foundation for both the client and server applications.
