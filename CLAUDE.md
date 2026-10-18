# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

An unofficial fork of Barony v5.0.2 (C++17, SDL2, OpenGL). Source only: no game assets are included, and FMOD/Steamworks SDKs are not bundled. Fork changes versus upstream:

- Level-ups bank 3 attribute points the player spends with a `+` button (host-authoritative, network packets `SPTS`/`SPNT`, lang string 6999).
- Only one selectable class: **Classless** (`CLASS_CLASSLESS`), which applies no attribute bonuses, skills or starting gear (all attributes start at 0).
- Local Windows build support (`build-windows.bat`, `build-msvc-prelude.h`) and a Steamworks 1.65 fix.

## Build

There is no test suite or linter. CMake build; see `INSTALL.md` for dependencies (SDL2, SDL2_image/net/ttf, libpng, PhysFS, RapidJSON, OpenGL; FMOD optional via `-DFMOD_ENABLED`).

- Windows (MSVC + vcpkg at `C:\vcpkg`, FMOD and Steamworks SDKs at paths overridable via env vars): run `build-windows.bat`. It configures into `build/` and builds Release for both the game and the map editor. Paths such as `FMOD_SDK`, `STEAM_SDK`, `NFD_DIR`, `VCPKG` are set at the top of the script.
- Other platforms: standard `cmake -S . -B build && cmake --build build`.
- `src/editor.cpp` compiles the shared sources into a separate editor executable, so game-only code must compile against the stubs there (e.g. the dummy `initClass`).

## Architecture

All game code is in `src/`, with heavy use of globals (the upstream README says so itself). Key files are very large; grep rather than read whole files.

- `game.cpp` / `main.cpp`: main loop and global state (e.g. `client_classes[MAXPLAYERS]`, `stats[]`, `players[]`).
- `ui/MainMenu.cpp` / `.hpp`: the in-game menu system (lobby, character creation cards, class/race selection). `menu.cpp` is the older menu code that still holds shared helpers such as `isCharacterValidFromDLC`.
- `charclass.cpp`: `initClassStats` (attribute/skill bonuses per class) and `initClass` (starting items/spells per class). It is a long `if/else if` chain on `client_classes[player]`, followed by shared race/spell/hotbar code.
- `entity.cpp`, `act*.cpp`, `monster*.cpp`: entities and their per-tick behavior.
- `lang/en.txt`: all UI strings, `NNNN text#` format, ends with `7999 END#`. Fork strings use 6999+ (7000/7001 are the Classless names).
- `data/*.json` files (class/race descriptions, hotbar layouts) are loaded at runtime from the user's game assets, not from this repo.

### Player classes (touches several files)

A class is an index in `enum PlayerClasses` (`src/game.hpp`), with `NUMCLASSES` and `playerClassInternalNames` kept in step. The same index must line up in:

- `classes_in_order[]` and the `classes` icon map in `ui/MainMenu.hpp`
- `playerClassLangEntry` (`entity.cpp`, `editor.cpp`) and `playerClassLangEntryCapitalized` (`ui/MainMenu.cpp`) for the display name
- `ClassDescriptions` in `ui/MainMenu.cpp`, normally filled from `data/class_descriptions.json`; the Classless entry is added in code after the JSON loads
- `isCharacterValidFromDLC` in `menu.cpp` (DLC and race gating)

Class selection UI: `characterCardClassMenu` in `ui/MainMenu.cpp`. `reducedClassList` and the button loop there are what restrict the menu to Classless. Other classes' data still exists so saved games, challenge runs and multiplayer peers do not break.

### Networking

Host-authoritative multiplayer using SDL_net packets with 4-character tags (e.g. `SPTS`, `SPNT`). Character class and appearance are sent in the lobby via `sendPlayerOverNet` in `ui/MainMenu.cpp`.
