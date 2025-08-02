# GameMasterUI for TrinityCore 3.3.5

tldr: place GameMasterUI in `lua_scripts\AIO_Server` like `lua_scripts\AIO_Server\GameMasterUI` you also need the two files 
You can find `AIO_UIStyleLibraryClient.lua` here: [AIO_UIStyleLibraryClient.lua on GitHub](https://github.com/Isidorsson/Eluna-scripts/blob/master/AIO%20Scripts/AIO_UIStyleLibraryClient.lua)
You can find `UIStyleLibraryServer.lua` here: [AIO_UIStyleLibraryClient.lua on GitHub](https://github.com/Isidorsson/Eluna-scripts/blob/master/AIO%20Scripts/AIO_UIStyleLibraryClient.lua)

A comprehensive in-game Game Master management interface for TrinityCore servers using the AIO (AddOn In-game Organizer) framework.

## Features

- **NPC Management**: Search, spawn, and manage NPCs
- **Item Management**: Search, add items, and manage inventories
- **Spell Management**: Search and manage spells
- **Player Management**: Manage player accounts, characters, and permissions
- **Ban System**: Comprehensive ban management interface
- **Model Preview**: 3D model viewer for NPCs and items
- **Context Menus**: Right-click context menus for quick actions

## Prerequisites

- TrinityCore or AzerothCore 3.3.5
- Eluna Lua Engine installed and working
- AIO framework (included in most Eluna packages)
- MySQL/MariaDB database

## Installation

### 1. Copy Files

Copy the entire `GameMasterUI` folder to your server's Lua scripts directory:
```
lua_scripts/AIO_Server/GameMasterUI/
```

### 2. Ensure AIO Framework

Make sure these AIO core files exist in your `AIO_Server` directory:
- `AIO.lua` - Core AIO framework
- `UIStyleLibraryServer.lua` - Server-side UI library
You can find `AIO_UIStyleLibraryClient.lua` here: [AIO_UIStyleLibraryClient.lua on GitHub](https://github.com/Isidorsson/Eluna-scripts/blob/master/AIO%20Scripts/AIO_UIStyleLibraryClient.lua)

### 3. Database Setup

Require a spell dbc file to be present in your database. Required for spell management features.

### 4. Server Configuration

No additional server configuration is required. The addon will automatically load when Eluna initializes.

## Usage

### Opening the Interface

Game Masters can open the interface using:
```
/gm
/gamemaster
```

### Permissions

The addon automatically checks GM levels:
- Only accounts with GM level > 0 can access the interface
- Different features may require different GM levels

### Key Bindings

- **ESC**: Close the current window
- **Right-Click**: Open context menus on items, NPCs, or players
- **Left-Click**: Select items or activate buttons

## File Structure

```
GameMasterUI/
├── GameMasterUIServer.lua      # Main server entry point
├── Client/                     # Client-side UI files
│   ├── 00_Core/               # Core functionality
│   ├── 01_UI/                 # UI framework
│   ├── 02_Cards/              # Card system for displaying entities
│   ├── 03_Systems/            # Model viewer and data systems
│   ├── 04_Menus/              # Context menu system
│   └── GMClient_09_Init.lua   # Client initialization
└── Server/                     # Server-side logic
    ├── Core/                  # Core server functionality
    ├── Database/              # Database queries
    └── Handlers/              # AIO message handlers
```

## Troubleshooting

### Common Issues

1. **"You do not have permission to use this command"**
   - Ensure your account has GM level > 2
   - Check account permissions in the auth database

2. **UI doesn't appear**
   - Verify AIO is working: `.aio` command should show AIO status
   - Check server console for Lua errors
   - Ensure all files are in the correct directories

3. **Missing UI elements**
   - Verify `AIO_UIStyleLibraryClient.lua` is present
   - Clear WoW cache and reload


## Customization

### Adding Custom Context Menu Actions

Edit the appropriate handler file in `Server/Handlers/` to add new actions.

### Modifying UI Layout

UI elements are defined in the `Client/` files. Modify these to change appearance or layout.

### Changing Permissions

Edit `GameMasterUI_Config.lua` to modify required GM levels for different features.

## Support

For issues or questions:
1. Check the server console for error messages
2. Review the [AIO Development Guide](../AIO-DEVELOPMENT-GUIDE.md)
3. Contact the Eluna community on Discord

## Credits

- Built using the AIO framework by Rochet2
- Uses Eluna Lua Engine for TrinityCore
- UI styling based on WoW 3.3.5 interface guidelines
