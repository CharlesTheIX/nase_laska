# Nase Laska

A simple game built with Zig and Raylib, featuring persistent timer tracking and save/load functionality.

## Description

Nase Laska is a basic game application demonstrating:

- Real-time timer with nanosecond precision
- Persistent save/load system using JSON files
- Modular architecture with UI abstraction
- Input handling with dev keys for saving game state
- Cross-platform graphics with Raylib

The game displays a running timer that tracks elapsed game time, shows input information, and allows saving the current game state using developer keys (F1/F2). Saved data persists between sessions and is stored in the user's home directory.

## Features

- **Nanosecond-Precision Timer**: Tracks game time with high accuracy using Zig's time functions
- **Persistent Storage**: Saves and loads game time to/from JSON files in `~/.nase_laska/`
- **Modular Design**: Separated concerns with game logic, UI rendering, input handling, and storage
- **Developer Tools**: F1/F2 keys save current game state for testing and development
- **Cross-Platform**: Built with Raylib for Windows, macOS, and Linux support

## Prerequisites

- Zig 0.15.1 or later
- Internet connection for fetching dependencies (raylib-zig)

## Building

To build the project:

```bash
zig build
```

This fetches the raylib-zig dependency and compiles the executable in debug mode.

### Building for Release

For optimized builds:

```bash
zig build -Doptimize=ReleaseFast
```

Other optimization levels:

- `ReleaseFast`: Maximum performance
- `ReleaseSafe`: Performance with safety checks
- `ReleaseSmall`: Minimize binary size

### Cross-Compilation

Build for different platforms, e.g., Windows on macOS:

```bash
zig build -Dtarget=x86_64-windows
```

## Running

To run the application:

```bash
zig build run
```

The game window will open showing:

- Player name (from saved data)
- Input key counts
- Save instructions
- Current game time in seconds

Press F1 or F2 to save the current game time. The timer continues running across sessions.

## Project Structure

```
src/
├── main.zig              # Application entry point
├── root.zig              # Module root, exports Game struct
└── lib/
    ├── game.zig          # Game logic and state management
    └── ui.zig            # UI rendering functions
└── modules/
    ├── storage.zig       # JSON save/load system
    ├── input.zig         # Input handling
    └── timer.zig         # Timer implementation
templates/
├── user.json             # Default user save template
└── world.json            # Default world save template
build.zig                 # Build configuration
build.zig.zon             # Dependencies
```

## Dependencies

- [raylib-zig](https://github.com/raylib-zig/raylib-zig): Zig bindings for raylib graphics library

## Save Files

Game data is saved to `~/.nase_laska/`:

- `user.json`: Contains player name and game time in nanoseconds
- `world.json`: Reserved for future world/level data

Default templates are provided in the `templates/` directory.

## Usage

The game starts with a timer that begins counting from the last saved time (or 0 if no save exists). Use F1/F2 to save progress. The timer displays elapsed time in seconds with millisecond precision.

## Development

The codebase is organized into modules:

- **Game**: Core game state and lifecycle
- **UI**: Rendering and display logic
- **Storage**: JSON serialization/deserialization
- **Input**: Keyboard/mouse event handling
- **Timer**: High-precision time tracking

Add new features by extending the Game struct and corresponding UI functions.
