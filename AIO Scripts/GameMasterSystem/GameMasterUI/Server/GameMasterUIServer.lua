--[[
    GameMaster UI Server - Main Entry Point
    
    This is the main server file that loads all modules and initializes the GameMaster UI system.
    
    Module Structure:

    - Server
        - GameMasterUIServer.lua (this file) - Main entry point
    /Core/
        - GameMasterUI_Config.lua - Configuration and constants
        - GameMasterUI_Utils.lua - Utility functions
        - GameMasterUI_Init.lua - Initialization and events
    - Server/Database/
        - GameMasterUI_Database.lua - Database queries
    - Server/Handlers/Entity/
        - GameMasterUI_EntityHandlers.lua - Entity spawn/delete handlers
        - GameMasterUI_ItemHandlers.lua - Item-related handlers
        - GameMasterUI_NPCHandlers.lua - NPC-related handlers
    - Server/Handlers/Player/
        - GameMasterUI_PlayerHandlers.lua - Player management handlers
        - GameMasterUI_SpellHandlers.lua - Spell-related handlers
]]--

-- Add the server directory to the package path
local scriptPath = debug.getinfo(1, "S").source:sub(2)
local scriptDir = scriptPath:match("(.*/)") or ""
package.path = package.path .. ";" .. scriptDir .. "?.lua"

-- Load AIO framework
local AIO = AIO or require("AIO")

-- Load modules in dependency order
local Config = require("GameMasterUI.Server.Core.GameMasterUI_Config")
local Utils = require("GameMasterUI.Server.Core.GameMasterUI_Utils")
local Database = require("GameMasterUI.Server.Database.GameMasterUI_Database")
local EntityHandlers = require("GameMasterUI.Server.Handlers.Entity.GameMasterUI_EntityHandlers")

-- Initialize AIO handlers namespace
local GameMasterSystem = AIO.AddHandlers("GameMasterSystem", {})

-- Load handler modules that will populate GameMasterSystem
local ItemHandlers = require("GameMasterUI.Server.Handlers.Entity.GameMasterUI_ItemHandlers")
local NPCHandlers = require("GameMasterUI.Server.Handlers.Entity.GameMasterUI_NPCHandlers")
local SpellHandlers = require("GameMasterUI.Server.Handlers.Player.GameMasterUI_SpellHandlers")
local PlayerHandlers = require("GameMasterUI.Server.Handlers.Player.GameMasterUI_PlayerHandlers")
local BanHandlers = require("GameMasterUI.Server.Handlers.Player.GameMasterUI_BanHandlers")

-- Set up the handlers
ItemHandlers.RegisterHandlers(GameMasterSystem, Config, Utils, Database)
NPCHandlers.RegisterHandlers(GameMasterSystem, Config, Utils, Database)
SpellHandlers.RegisterHandlers(GameMasterSystem, Config, Utils, Database)
PlayerHandlers.RegisterHandlers(GameMasterSystem, Config, Utils, Database, EntityHandlers)
BanHandlers.RegisterHandlers(GameMasterSystem, Config, Utils, Database)

-- Additional core handlers
function GameMasterSystem.handleGMLevel(player)
    local gmRank = player:GetGMRank()
    AIO.Handle(player, "GameMasterSystem", "receiveGmLevel", gmRank)
end

function GameMasterSystem.getCoreName(player)
    local coreName = GetCoreName()
    AIO.Handle(player, "GameMasterSystem", "receiveCoreName", coreName)
end

function GameMasterSystem.getTarget(player)
    local target = player:GetSelection()
    local isSelf = false

    if not target then
        Utils.sendMessage(player, "info", "No valid target selected. Defaulting to yourself.")
        target = player
        isSelf = true
    else
        Utils.sendMessage(player, "info", "Target selected: " .. target:GetName())
    end

    return target, isSelf
end

-- Entity action handler wrappers
function GameMasterSystem.spawnNpcEntity(player, entry)
    EntityHandlers.spawnNpcEntity(player, entry)
end

function GameMasterSystem.deleteNpcEntity(player, entry)
    EntityHandlers.deleteNpcEntity(player, entry)
end

function GameMasterSystem.morphNpcEntity(player, entry)
    EntityHandlers.morphNpcEntity(player, entry)
end

function GameMasterSystem.demorphNpcEntity(player)
    EntityHandlers.demorphNpcEntity(player)
end

function GameMasterSystem.spawnGameObject(player, entry)
    EntityHandlers.spawnGameObject(player, entry)
end

function GameMasterSystem.deleteGameObjectEntity(player, entry)
    EntityHandlers.deleteGameObjectEntity(player, entry)
end

function GameMasterSystem.spawnAndDeleteNpcEntity(player, entry)
    EntityHandlers.spawnAndDeleteNpcEntity(player, entry)
end

function GameMasterSystem.spawnAndDeleteGameObjectEntity(player, entry)
    EntityHandlers.spawnAndDeleteGameObjectEntity(player, entry)
end

function GameMasterSystem.duplicateNpcEntity(player, entry)
    return EntityHandlers.duplicateNpcEntity(player, entry)
end

function GameMasterSystem.duplicateGameObjectEntity(player, entry)
    return EntityHandlers.duplicateGameObjectEntity(player, entry)
end

function GameMasterSystem.duplicateItemEntity(player, entry)
    return EntityHandlers.duplicateItemEntity(player, entry)
end

-- Load initialization module (registers events)
local Init = require("GameMasterUI.Server.Core.GameMasterUI_Init")

-- Export the GameMasterSystem for potential external use
return GameMasterSystem