# Game Module Blueprint

## 1. Module Goal

To implement all game-specific logic using a modern, data-oriented, and highly modular Entity-Component-System (ECS) architecture. This module will replace the monolithic, object-oriented, and tightly coupled logic of the original `Core` module, including the `KPlayer`, `KNpc`, and `KMissle` "god classes".

**Core Technology:** **EnTT**. A header-only, high-performance C++ ECS library that will provide the core `registry` for managing entities and components.

## 2. ECS Core Concepts

*   **Entity:** A unique identifier for any "thing" in the game world (player, NPC, item, missile, etc.). Managed by the `entt::registry`.
*   **Component:** Simple, Plain Old Data (POD) structs that contain the data for an entity. They have no logic. An entity is defined by the collection of components it possesses.
*   **System:** A function or class that contains all the logic. Systems run every frame and operate on entities that have a specific set of components.

## 3. Component Definitions (Initial Set)

This section maps the member variables from the legacy "god classes" to new, focused data components.

| New Component | Contained Data | Replaces Legacy |
| :--- | :--- | :--- |
| `Component::Transform` | `vec2 position`, `vec2 scale`, `float rotation`, `int direction` | `m_MapX`, `m_MapY`, `m_Dir` in `KNpc` and `KPlayer` |
| `Component::Renderable` | `string sprite_name`, `int current_frame`, `Color tint` | `m_DataRes` in `KNpc`, visual properties |
| `Component::Player` | `string name`, `uint32_t account_id` | `Name`, `AccountName` in `KPlayer` |
| `Component::Npc` | `NpcType type`, `AiBehavior behavior` | `m_Kind`, `m_AiMode` in `KNpc` |
| `Component::Stats` | `int strength`, `int dexterity`, `int vitality`, `int energy` | `m_nStrength`, `m_nDexterity`, etc. in `KPlayer`/`KNpc` |
| `Component::Health` | `int current_hp`, `int max_hp` | `m_CurrentLife`, `m_CurrentLifeMax` in `KPlayer`/`KNpc` |
| `Component::Velocity` | `vec2 linear_velocity` | Inferred from movement logic in `Active()` |
| `Component::Inventory` | `vector<Entity> items` | `KItemList m_ItemList` in `KPlayer` |
| `Component::SkillSet` | `vector<SkillID> skills` | `KSkillList m_SkillList` in `KNpc` |
| `Component::Effect` | `EffectType type`, `float duration`, `float tick_rate` | `KState` members (`m_PoisonState`, etc.) in `KNpc` |
| `Component::Target` | `Entity target_entity` | `m_nPeopleIdx`, `m_nObjectIdx` in `KPlayer`/`KNpc` |

---

## 4. System Definitions (Initial Set)

This section maps the logic from the legacy `Active()` and `Breathe()` methods to new, focused systems.

| New System | Signature / Operates On | Responsibility | Replaces Legacy |
| :--- | :--- | :--- |
| `System::PlayerInput` | `(Registry&, InputManager&)`<br>Entities with `Player` and `Velocity` | Reads input from the `Platform::InputManager` and translates it into movement, skill casting, or other actions by modifying components (e.g., setting `Velocity`) or creating new entities (e.g., a "skill cast" event entity). | `KPlayer::ProcessInputMsg` |
| `System::AI` | `(Registry&)`<br>Entities with `Npc` and `Velocity` | Runs the AI logic for NPCs. This system will read the NPC's behavior type and state, and modify its `Velocity` or `Target` components to produce actions. | `KNpc::ProcCommand`, `KNpc::Activate` (AI part) |
| `System::Movement` | `(Registry&, float deltaTime)`<br>Entities with `Transform` and `Velocity` | Updates the `Transform::position` of all entities based on their `Velocity::linear_velocity` and `deltaTime`. | The position update logic inside `KPlayer::Active` and `KNpc::Activate`. |
| `System::Skill` | `(Registry&)`<br>Responds to "skill cast" events | When a skill is cast, this system reads the skill's data (from the `Assets` module) and creates the appropriate `Missle` entities with the correct components (`Transform`, `Velocity`, `EffectPayload`). | `KSkill::Cast`, `KMissle::Init` |
| `System::Collision` | `(Registry&)`<br>Entities with `Transform` and `CollisionComponent` | Checks for collisions between entities. When a collision is detected (e.g., a missile hits a player), it creates a "collision event" entity. | `KMissle::CheckCollision` |
| `System::Effect` | `(Registry&)`<br>Responds to "collision events" | Processes collision events. If a missile hits a player, this system reads the `EffectPayloadComponent` from the missile and applies the effect (e.g., damage) to the `HealthComponent` of the player. | `KMissle::ProcessDamage`, `KNpc::ModifyAttrib` |
| `System::Render` | `(Registry&, Renderer&)`<br>Entities with `Transform` and `Renderable` | Iterates through all renderable entities and submits draw calls (`Renderer::DrawSprite`) to the `Renderer` module based on the entity's sprite and position. | `KPlayer::Paint`, `KNpc::Paint`, `CoreShell::DrawGameSpace` |
| `System::Lifetime` | `(Registry&, float deltaTime)`<br>Entities with `LifetimeComponent` | Decrements the lifetime of entities (like missiles or temporary effects) and destroys them when their lifetime reaches zero. | `m_nCurrentLife` logic in `KMissle::Activate` |
