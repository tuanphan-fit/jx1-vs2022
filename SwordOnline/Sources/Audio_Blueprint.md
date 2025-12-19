# Audio Module Blueprint

## 1. Module Goal

To abstract all audio playback operations into a clean, modern C++ interface. This includes handling short, one-shot sound effects and long, streaming music tracks. This module is intended to be a complete replacement for the legacy audio system built on DirectSound (`KDSound`, `KMusic`, `KMp3Music`, `KWavSound`, `KSoundCache`).

**Core Technology:** **miniaudio**. This is a single-file, public domain audio library that is extremely easy to integrate and provides a simple, powerful, cross-platform API for audio playback.

## 2. New Class Definitions

### Class `Audio::Sound`
**Purpose:** A handle to a decoded, in-memory sound effect. This is a lightweight object that can be passed to the audio manager for playback. It is non-copyable but movable.
**Replaces:** The concept of a cached sound buffer in `KSoundCache`.

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Constructor` | `Sound(const std::filesystem::path& filePath)` | Loads and decodes an entire sound file into memory. | `KSoundCache::LoadNode` |
| `Destructor` | `~Sound()` | Frees the decoded audio data. | `KSoundCache::FreeNode` |

---

### Class `Audio::Music`
**Purpose:** A handle to a music stream. It does not load the entire file into memory. This is a lightweight, non-copyable, movable object.
**Replaces:** `KMusic` and its derived classes.

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Constructor` | `Music(const std::filesystem::path& filePath)` | Opens a music file for streaming. | `KMusic::Open` |
| `Destructor` | `~Music()` | Closes the music file stream. | `KMusic::Close` |

---

### Interface `Audio::iAudioManager`
**Purpose:** An abstract interface that defines the contract for all audio operations. The rest of the application will use this interface to play sounds and music.
**Replaces:** Global access to `g_pDirectSound`, `g_pMusic`, etc.

| New Method | Signature | Responsibility | Replaces Legacy |
| :--- | :--- | :--- | :--- |
| `Init` | `bool Init()` | Initializes the audio backend device. | `KDirectSound::Init` |
| `Shutdown` | `void Shutdown()` | Releases the audio device. | `KDirectSound::Exit` |
| `Play` | `void Play(const Sound& sound)` | Plays a one-shot sound effect. | `KSoundCache` play logic. |
| `Play` | `void Play(const Music& music, bool loop = true)` | Starts playing a music stream. | `KMusic::Play` |
| `StopMusic` | `void StopMusic()` | Stops the currently playing music stream. | `KMusic::Stop` |
| `SetMasterVolume` | `void SetMasterVolume(float volume)` | Sets the overall master volume (0.0f to 1.0f). | `KMusic::SetVolume` (partially) |
| `SetMusicVolume` | `void SetMusicVolume(float volume)` | Sets the volume for the music channel. | `KMusic::SetVolume` |

---

### Class `Audio::MiniaudioManager`
**Purpose:** The concrete implementation of the `iAudioManager` interface using the `miniaudio` library.

| Method | Notes on Implementation |
| :--- | :--- |
| `Init` | Will initialize the `ma_engine` object, which is the core of the miniaudio playback system. |
| `Shutdown` | Will call `ma_engine_uninit()`. |
| `Play(Sound)` | Will use `ma_engine_play_sound()` to play a sound effect that has been pre-loaded into memory by a `Sound` object. |
| `Play(Music)` | Will initialize a `ma_sound` object from a streaming source (`ma_sound_init_from_file`) and start it. |
| `StopMusic` | Will stop and release the `ma_sound` object associated with the music stream. |
| `Set*Volume` | Will use the volume control functions available on the `ma_engine` or `ma_sound` objects. |
