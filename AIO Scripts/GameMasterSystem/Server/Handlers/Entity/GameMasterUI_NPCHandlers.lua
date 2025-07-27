--[[
    GameMaster UI - NPC Handlers Module
    
    This module handles all NPC-related functionality:
    - NPC data queries
    - NPC search
    - GameObject data queries
    - GameObject search
]]--

local NPCHandlers = {}

-- Module dependencies (will be injected)
local GameMasterSystem, Config, Utils, Database

function NPCHandlers.RegisterHandlers(gms, config, utils, database)
    GameMasterSystem = gms
    Config = config
    Utils = utils
    Database = database
    
    -- Register all NPC-related handlers
    GameMasterSystem.getNPCData = NPCHandlers.getNPCData
    GameMasterSystem.searchNPCData = NPCHandlers.searchNPCData
    GameMasterSystem.getGameObjectData = NPCHandlers.getGameObjectData
    GameMasterSystem.searchGameObjectData = NPCHandlers.searchGameObjectData
end

-- Function to query NPC data from the database with pagination
function NPCHandlers.getNPCData(player, offset, pageSize, sortOrder)
    offset = offset or 0
    pageSize = Utils.validatePageSize(pageSize or Config.defaultPageSize)
    sortOrder = Utils.validateSortOrder(sortOrder or "DESC")
    local coreName = GetCoreName()
    local query = Database.getQuery(coreName, "npcData")(sortOrder, pageSize, offset)
    local result = WorldDBQuery(query)
    local npcData = {}

    if result then
        repeat
            local npc = {
                entry = result:GetUInt32(0),
                modelid = {},
                name = result:GetString(coreName == "TrinityCore" and 5 or 2),
                subname = result:GetString(coreName == "TrinityCore" and 6 or 3),
                type = result:GetUInt32(coreName == "TrinityCore" and 7 or 4),
            }

            if coreName == "TrinityCore" then
                for i = 1, 4 do
                    local modelId = result:GetUInt32(i)
                    if modelId ~= 0 then
                        table.insert(npc.modelid, modelId)
                    end
                end
            elseif coreName == "AzerothCore" then
                local modelId = result:GetUInt32(1)
                if modelId ~= 0 then
                    table.insert(npc.modelid, modelId)
                end
            end

            table.insert(npcData, npc)
        until not result:NextRow()
    end

    local hasMoreData = #npcData == pageSize
    if #npcData == 0 then
        player:SendBroadcastMessage("No NPC data available for the given page.")
    else
        AIO.Handle(player, "GameMasterSystem", "receiveNPCData", npcData, offset, pageSize, hasMoreData)
    end
end

-- Server-side handler to search NPC data
function NPCHandlers.searchNPCData(player, query, offset, pageSize, sortOrder)
    query = Utils.escapeString(query) -- Escape special characters
    local typeId = nil
    sortOrder = Utils.validateSortOrder(sortOrder or "DESC")
    local coreName = GetCoreName()

    local typeQuery = query:match("^%((.-)%)$")
    if typeQuery then
        typeId = Config.npcTypes[typeQuery]
        if not typeId then
            player:SendBroadcastMessage("Invalid NPC type: " .. typeQuery)
            return
        end
    end

    local searchQuery = Database.getQuery(coreName, "searchNpcData")(query, typeId, sortOrder, pageSize, offset)
    local result = WorldDBQuery(searchQuery)
    local npcData = {}

    if result then
        repeat
            local npc = {
                entry = result:GetUInt32(0),
                modelid = {},
                name = result:GetString(coreName == "TrinityCore" and 5 or 2),
                subname = result:GetString(coreName == "TrinityCore" and 6 or 3),
                type = result:GetUInt32(coreName == "TrinityCore" and 7 or 4),
            }

            if coreName == "TrinityCore" then
                for i = 1, 4 do
                    local modelId = result:GetUInt32(i)
                    if modelId ~= 0 then
                        table.insert(npc.modelid, modelId)
                    end
                end
            elseif coreName == "AzerothCore" then
                local modelId = result:GetUInt32(1)
                if modelId ~= 0 then
                    table.insert(npc.modelid, modelId)
                end
            end

            table.insert(npcData, npc)
        until not result:NextRow()
    end

    local hasMoreData = #npcData == pageSize
    if #npcData == 0 then
        player:SendBroadcastMessage("No NPC data found for the given query and page.")
    else
        AIO.Handle(player, "GameMasterSystem", "receiveNPCData", npcData, offset, pageSize, hasMoreData)
    end
end

-- Function to query GameObject data from the database with pagination
function NPCHandlers.getGameObjectData(player, offset, pageSize, sortOrder)
    offset = offset or 0
    pageSize = Utils.validatePageSize(pageSize or Config.defaultPageSize)
    sortOrder = Utils.validateSortOrder(sortOrder or "DESC")

    local query = Database.getQuery(GetCoreName(), "gobData")(sortOrder, pageSize, offset)

    local result = WorldDBQuery(query)
    local gobData = {}

    if result then
        repeat
            local gob = {
                entry = result:GetUInt32(0),
                displayid = result:GetUInt32(1),
                name = result:GetString(2),
                modelName = result:GetString(3),
            }
            table.insert(gobData, gob)
        until not result:NextRow()
    end

    local hasMoreData = #gobData == pageSize

    if #gobData == 0 then
        player:SendBroadcastMessage("No gameobject data available for the given page.")
    else
        AIO.Handle(player, "GameMasterSystem", "receiveGameObjectData", gobData, offset, pageSize, hasMoreData)
    end
end

-- Server-side handler to search GameObject data
function NPCHandlers.searchGameObjectData(player, query, offset, pageSize, sortOrder)
    query = Utils.escapeString(query) -- Escape special characters
    local typeId = nil
    sortOrder = Utils.validateSortOrder(sortOrder or "DESC")

    -- Check if the query is enclosed in parentheses
    local typeQuery = query:match("^%((.-)%)$")
    if typeQuery then
        typeQuery = typeQuery:lower() -- Convert the type query to lowercase
        typeId = Config.gameObjectTypes[typeQuery] -- Get the type ID from the extracted type name
        if not typeId then
            player:SendBroadcastMessage("Invalid GameObject type: " .. typeQuery)
            return
        end
    end

    local searchQuery = Database.getQuery(GetCoreName(), "searchGobData")(query, typeId, sortOrder, pageSize, offset)
    local result = WorldDBQuery(searchQuery)
    local gobData = {}

    if result then
        repeat
            local gob = {
                entry = result:GetUInt32(0),
                displayid = result:GetUInt32(1),
                name = result:GetString(2),
                type = result:GetUInt32(3),
                modelName = result:GetString(4),
            }
            table.insert(gobData, gob)
        until not result:NextRow()
    end

    local hasMoreData = #gobData == pageSize

    if #gobData == 0 then
        player:SendBroadcastMessage("No gameobject data found for the given query and page.")
    else
        AIO.Handle(player, "GameMasterSystem", "receiveGameObjectData", gobData, offset, pageSize, hasMoreData)
    end
end

return NPCHandlers