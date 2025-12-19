# Assets Module Blueprint

## 1. Module Goal

To create a centralized, extensible, and modern system for loading and managing all game assets. This module will abstract the source of the assets (physical file vs. archived file) into a unified Virtual File System (VFS). It will also manage the lifetime of loaded resources to avoid redundant loads and memory leaks.

This module will replace the ad-hoc collection of legacy classes: `KPakFile`, `KFile`, `XPackFile`, and all the various cache classes (`KSpriteCache`, `KSoundCache`).

**Core Technology:** This will be a custom C++ system built with modern principles. It will use standard library containers and smart pointers for management.

## 2. New Class Definitions

### Interface `Assets::iAssetProvider`
**Purpose:** An abstract interface representing a source of asset data. This allows the `AssetManager` to treat a directory on disk the same way it treats a `.pak` archive.

| New Method | Signature | Responsibility |
| :--- | :--- | :--- |
| `Exists` | `bool Exists(const std::string& assetPath) const` | Checks if an asset exists at the given path within this provider. |
| `Open` | `std::unique_ptr<std::istream> Open(const std::string& assetPath) const` | Opens an asset and returns a standard C++ stream for reading its data. |

---

### Class `Assets::FileSystemProvider`
**Purpose:** A concrete implementation of `iAssetProvider` that reads assets directly from a directory on the physical file system.

| Method | Notes on Implementation | Replaces Legacy |
| :--- | :--- | :--- |
| `Exists` | Will check `std::filesystem::exists()` on the combined base path and asset path. | `KFile` logic |
| `Open` | Will create and return a `std::ifstream` for the requested file. | `KFile::Open` |

---

### Class `Assets::PakFileProvider`
**Purpose:** A concrete implementation of `iAssetProvider` that reads assets from one of the original game's `.pak` archives.

| Method | Notes on Implementation | Replaces Legacy |
| :--- | :--- | :--- |
| `Constructor` | `PakFileProvider(const std::filesystem::path& pakPath)` | Opens the `.pak` file, reads its internal file index into a hash map for fast lookups. | `XPackFile::Open` |
| `Exists` | Will perform a lookup in its internal file index hash map. | `XPackFile::FindElemFile` |
| `Open` | Will read the compressed/uncompressed data for the requested file from the `.pak` archive into a memory buffer and return a `std::istream` (like `std::istringstream`) that reads from that buffer. | `XPackFile::ElemFileRead` |

---

### Class `Assets::AssetManager`
**Purpose:** The main public-facing class of the module. It orchestrates all asset loading. It maintains a prioritized list of `iAssetProvider`s and a cache of loaded assets.
**Replaces:** `KPakList`, `KSpriteCache`, `KSoundCache`.

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `AddProvider` | `void AddProvider(std::unique_ptr<iAssetProvider> provider)` | Adds a source of assets (e.g., a `.pak` file or a directory) to the manager. Providers are searched in the order they are added. | `KPakList::Open` |
| `Load<T>` | `AssetHandle<T> Load<T>(const std::string& assetPath)` | The primary loading function. It finds the asset path in its providers, checks if the asset is already cached, loads it if not, and returns a handle to it. `T` is the type of asset (e.g., `Texture`, `Sound`). | `g_SpriteCache.GetSprite`, `g_SoundCache.GetSound` |
| `Get<T>` | `std::shared_ptr<T> Get<T>(AssetHandle<T> handle)` | Resolves a handle to get a pointer to the actual asset data. | Direct pointer access in legacy caches. |

---

### Class `Assets::AssetHandle`
**Purpose:** A lightweight, type-safe handle that represents a loaded asset. It allows the system to pass around references to assets without exposing raw pointers, and it can be used to check if an asset is loaded, unloaded, or in an error state.

| Member | Type | Responsibility |
| :--- | :--- | :--- |
| `m_Id` | `UUID` or `uint64_t` | A unique identifier for the loaded asset instance. |
| `m_Type` | `AssetType` | An enum identifying the type of asset this handle points to. |
