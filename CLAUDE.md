# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Barony is a C++17 first-person roguelike (SDL2 + OpenGL) for up to 4 players (8 with `BARONY_SUPER_MULTIPLAYER`). This checkout is the v5.0.2 source; it is not a git repo. Game assets are not in the repo: they come from a purchased install (here `C:\Program Files (x86)\Steam\steamapps\common\Barony`).

## Building (Windows, this machine)

```bat
build-windows.bat
```

This configures `build/` with the VS 2022 generator and builds Release `barony.exe` and `editor.exe` into `build\Release\`. It uses:
- vcpkg at `C:\vcpkg` (x64-windows triplet) for SDL2, SDL2_image/net/ttf, PhysFS, RapidJSON, libpng, zlib, GLEW, and dirent
- nativefiledialog prebuilt at `C:\deps\nfd`, which Steam builds require (`NFD_PickFolder` API)
- the FMOD Core 2.03 SDK and the Steamworks SDK 1.65, with paths hardcoded at the top of the script
- EOS disabled (`EOS_ENABLED=0`), because it needs private `BUILD_ENV_*` credentials

The upstream Windows CMake path is out of date, so the script compensates:
- `CMAKE_POLICY_VERSION_MINIMUM=3.5`
- GLEW, glu32, and comdlg32 linked through `CMAKE_CXX_STANDARD_LIBRARIES`
- `/DF_CALLBACK=F_CALL`, because FMOD 2.03 dropped `F_CALLBACK`
- a force-included `build-msvc-prelude.h`, which pulls in `windows.h` and then `#undef GetObject` so RapidJSON's `Value::GetObject()` compiles; the script copies it to `C:\deps\msvc` because `/FI` can't take a path with spaces

A full rebuild re-runs CMake configure; for incremental builds use `cmake --build build --config Release`. Linux CI builds through `ci/*.sh` (see `.github/workflows`). INSTALL.md lists the dependency and CMake flags (`FMOD_ENABLED`, `STEAMWORKS_ENABLED`, `EOS_ENABLED`, `OPENAL_ENABLED`, and others).

Local Steamworks 1.65 compatibility edits to the source:
- `IsSteamRunningOnSteamDeck()` is replaced with `IsRunningOnSteamHardware() == k_ESteamHardwareTypeSteamDeck`
- `RequestCurrentStats()` is removed, and `steam_shared.cpp` returns `true` instead

## Running

The game reads data relative to the working directory (`BASE_DATA_DIR = "./"`). `dist\` is a self-contained play folder: a copy of the Steam data plus the built exes, their DLLs, `fmod.dll`, `steam_api64.dll`, and the repo's `lang\`. After a rebuild, copy `build\Release\*.exe` (and any changed DLLs) into `dist\`, then run `dist\barony.exe` with `dist` as the working directory and Steam running. Logs go to `dist\log.txt`. Don't write into the Steam install folder.

There are no automated tests. To verify a change, launch the game and check `log.txt`. In-game console commands (`ConsoleCommand` objects, e.g. `static ConsoleCommand ccmd_x("/name", ...)`) are the usual debugging hook.

## Architecture

The code is legacy C converted to C++ and relies heavily on globals declared in `main.hpp`/`game.hpp`, so expect cross-file coupling everywhere.

- **Two executables from shared sources.** `src/CMakeLists.txt` lists `GAME_SOURCES` and `EDITOR_SOURCES`. The editor compiles many of the same files, but `editor.cpp` does `#define EDITOR` and editor-specific variants replace game files (`stat_editor.cpp`, `items_editor.cpp`, `entity_editor.cpp`, `eos_editor.cpp`). Shared code branches with `#ifdef EDITOR`, mostly in `opengl.cpp`, `mod_tools.cpp`, `init.cpp`, and `draw.cpp`. Adding a `.cpp` means adding it to the right list or lists in `src/CMakeLists.txt` or a subdirectory `CMakeLists.txt`.
- **Feature macros** come from the generated `src/Config.hpp`, built from `Config.hpp.in` (`WINDOWS`, `STEAMWORKS`, `USE_EOS`, `USE_FMOD`, `USE_IMGUI`, and others). Platform and online code is guarded by these, so keep new Steam or EOS calls inside `#ifdef STEAMWORKS` / `#ifdef USE_EOS`.
- **Main loop.** `main()` and `gameLogic()` are in `game.cpp`. Initialization is split between `init.cpp` (engine) and `init_game.cpp` (game data and JSON configs).
- **Entities.** `Entity` (`entity.hpp`/`entity.cpp`) is one generic type. Behavior comes from a `void (*behavior)(Entity*)` function pointer (`act*.cpp`, `monster_*.cpp`). Per-type state lives in the generic `skill[]` / `fskill[]` arrays, which are exposed through named reference members (e.g. `Sint32& chestStatus` aliasing a `skill[]` index). Before reusing an index, check for collisions with other aliases on the same entity type; `skill[2]` is reserved for all entities. Monster stats are in `Stat` (`stat.hpp`), and monster-specific logic is in `monster_<name>.cpp`.
- **Networking.** Networking is host-authoritative and runs over SDL_net UDP, Steam, or EOS lobbies (`net.cpp`, `lobbies.cpp`, `steam.cpp`, `eos.cpp`). Packets are tagged with a 4-char ID written at `net_packet->data` (e.g. `'KPAL'`) and dispatched through the `clientPacketHandlers` / `serverPacketHandlers` maps in `net.cpp`. A new message needs a sender plus a handler in the right map.
- **UI.**
  - `src/ui/` is the modern widget framework (`Frame`, `Button`, `Field`, `Slider`, `Text`, `Image`). `MainMenu.cpp` (very large) and `GameUI.cpp` build the menus and HUD in code.
  - `src/interface/` holds older in-game interface logic (inventory, shops, minimap, character sheet).
  - Dear ImGui (`src/imgui/`) is used for debug tooling.
- **Magic** is in `src/magic/` (spell definitions in `setupSpells.cpp`, casting, and the projectile and effect actors). **Audio** is in `src/engine/audio/` (FMOD, with an OpenAL fallback that is deprecated).
- **Data and localization.**
  - User-facing strings are numbered entries in `lang/en.txt`, read with `Language::get(N)`. New strings are appended there, and the repo's `lang/` must be copied into the data folder.
  - Item enums are in `items.hpp` (`ItemType`).
  - Much tunable content is JSON parsed with RapidJSON.
  - Assets are read through PhysFS, so mods can override them.

## Contributing notes (from CONTRIBUTING.md and README)

- Upstream takes PRs against `master` for bugfixes; `develop` is for in-progress features.
- Avoid haphazard gameplay-balance changes.
- Models are voxel files edited with VoxelShop (VoxLap export).
