--[[
    GameMaster UI - Spell Handlers Module
    
    This module handles all spell-related functionality:
    - Spell data queries
    - Spell visual data
    - Spell search
    - Learn/Remove spells
    - Cast spells
]]--

local SpellHandlers = {}

-- Module dependencies (will be injected)
local GameMasterSystem, Config, Utils, Database

function SpellHandlers.RegisterHandlers(gms, config, utils, database)
    GameMasterSystem = gms
    Config = config
    Utils = utils
    Database = database
    
    -- Register all spell-related handlers
    GameMasterSystem.getSpellData = SpellHandlers.getSpellData
    GameMasterSystem.searchSpellData = SpellHandlers.searchSpellData
    GameMasterSystem.getSpellVisualData = SpellHandlers.getSpellVisualData
    GameMasterSystem.searchSpellVisualData = SpellHandlers.searchSpellVisualData
    GameMasterSystem.learnSpellEntity = SpellHandlers.learnSpellEntity
    GameMasterSystem.deleteSpellEntity = SpellHandlers.deleteSpellEntity
    GameMasterSystem.castSelfSpellEntity = SpellHandlers.castSelfSpellEntity
    GameMasterSystem.castTargetSpellEntity = SpellHandlers.castTargetSpellEntity
    GameMasterSystem.searchSpells = SpellHandlers.searchSpells
end

-- Server-side handler to get the spell data for tab3
function SpellHandlers.getSpellData(player, offset, pageSize, sortOrder)
    offset = offset or 0
    pageSize = Utils.validatePageSize(pageSize or Config.defaultPageSize)
    sortOrder = Utils.validateSortOrder(sortOrder or "DESC")

    local query = Database.getQuery(GetCoreName(), "spellData")(sortOrder, pageSize, offset)

    local result = WorldDBQuery(query)
    local spellData = {}

    if result then
        repeat
            local spell = {
                spellID = result:GetUInt32(0),
                spellName = result:GetString(1),
                spellDescription = result:GetString(2),
                spellToolTip = result:GetString(3),
            }
            table.insert(spellData, spell)
        until not result:NextRow()
    end

    local hasMoreData = #spellData == pageSize

    if #spellData == 0 then
        player:SendBroadcastMessage("No spell data available for the given page.")
    else
        AIO.Handle(player, "GameMasterSystem", "receiveSpellData", spellData, offset, pageSize, hasMoreData)
    end
end

-- Server-side handler to search spell data
function SpellHandlers.searchSpellData(player, query, offset, pageSize, sortOrder)
    query = Utils.escapeString(query) -- Escape special characters
    sortOrder = Utils.validateSortOrder(sortOrder or "DESC")

    local searchQuery = Database.getQuery(GetCoreName(), "searchSpellData")(query, sortOrder, pageSize, offset)

    local result = WorldDBQuery(searchQuery)
    local spellData = {}

    if result then
        repeat
            local spell = {
                spellID = result:GetUInt32(0),
                spellName = result:GetString(1),
                spellDescription = result:GetString(2),
                spellToolTip = result:GetString(3),
            }
            table.insert(spellData, spell)
        until not result:NextRow()
    end

    local hasMoreData = #spellData == pageSize

    if #spellData == 0 then
        player:SendBroadcastMessage("No spell data found for the given query and page.")
    else
        AIO.Handle(player, "GameMasterSystem", "receiveSpellData", spellData, offset, pageSize, hasMoreData)
    end
end

-- Function to get the spell visual data
function SpellHandlers.getSpellVisualData(player, offset, pageSize, sortOrder)
    offset = offset or 0
    pageSize = Utils.validatePageSize(pageSize or Config.defaultPageSize)
    sortOrder = Utils.validateSortOrder(sortOrder or "DESC")

    local coreName = GetCoreName()
    local query = Database.getQuery(coreName, "spellVisualData")(sortOrder, pageSize, offset)

    local result = WorldDBQuery(query)

    local spellVisualData = {}

    if result then
        repeat
            local spellVisual = {
                ID = result:GetUInt32(0),
                Name = result:GetString(1),
                FilePath = result:GetString(2),
                AreaEffectSize = result:GetFloat(3),
                Scale = result:GetFloat(4),
                MinAllowedScale = result:GetFloat(5),
                MaxAllowedScale = result:GetFloat(6),
            }

            table.insert(spellVisualData, spellVisual)
        until not result:NextRow()
    end

    local hasMoreData = #spellVisualData == pageSize

    if #spellVisualData == 0 then
        player:SendBroadcastMessage("No spell visual data available for the given page.")
    else
        AIO.Handle(player, "GameMasterSystem", "receiveSpellVisualData", spellVisualData, offset, pageSize, hasMoreData)
    end
end

-- Function to search spell visual data
function SpellHandlers.searchSpellVisualData(player, query, offset, pageSize, sortOrder)
    query = Utils.escapeString(query) -- Escape special characters
    sortOrder = Utils.validateSortOrder(sortOrder or "DESC")
    local coreName = GetCoreName()

    local searchQuery = Database.getQuery(coreName, "searchSpellVisualData")(query, sortOrder, pageSize, offset)
    local result = WorldDBQuery(searchQuery)
    local spellVisualData = {}

    if result then
        repeat
            local spellVisual = {
                ID = result:GetUInt32(0),
                Name = result:GetString(1),
                FilePath = result:GetString(2),
                AreaEffectSize = result:GetFloat(3),
                Scale = result:GetFloat(4),
                MinAllowedScale = result:GetFloat(5),
                MaxAllowedScale = result:GetFloat(6),
            }
            table.insert(spellVisualData, spellVisual)
        until not result:NextRow()
    end

    local hasMoreData = #spellVisualData == pageSize

    if #spellVisualData == 0 then
        player:SendBroadcastMessage("No spell visual data found for the given query and page.")
    else
        AIO.Handle(player, "GameMasterSystem", "receiveSpellVisualData", spellVisualData, offset, pageSize, hasMoreData)
    end
end

-- Server-side handler to add spell learnSpell
function SpellHandlers.learnSpellEntity(player, spellID)
    local target, isSelf = GameMasterSystem.getTarget(player)

    if not target:HasSpell(spellID) then
        target:LearnSpell(spellID)
        if isSelf then
            Utils.sendMessage(player, "success", string.format("You have successfully learned spell (ID: %d).", spellID))
        else
            Utils.sendMessage(player, "success", string.format("Target has successfully learned spell (ID: %d).", spellID))
        end
    else
        if isSelf then
            Utils.sendMessage(player, "warning", string.format("You already know spell (ID: %d).", spellID))
        else
            Utils.sendMessage(player, "warning", string.format("Target already knows spell (ID: %d).", spellID))
        end
    end
end

-- Server-side handler to delete spell deleteEntitySpell
function SpellHandlers.deleteSpellEntity(player, spellID)
    local target, isSelf = GameMasterSystem.getTarget(player)

    if target:HasSpell(spellID) then
        target:RemoveSpell(spellID)
        if isSelf then
            Utils.sendMessage(player, "success", string.format("You have successfully removed spell (ID: %d).", spellID))
        else
            Utils.sendMessage(player, "success", string.format("Target has successfully removed spell (ID: %d).", spellID))
        end
    else
        if isSelf then
            Utils.sendMessage(player, "warning", string.format("You do not know spell (ID: %d).", spellID))
        else
            Utils.sendMessage(player, "warning", string.format("Target does not know spell (ID: %d).", spellID))
        end
    end
end

-- Server-side handler to castSelfSpellEntity
function SpellHandlers.castSelfSpellEntity(player, spellID)
    local target, isSelf = GameMasterSystem.getTarget(player)
    if not target or isSelf then
        Utils.sendMessage(player, "success", "Casting spell on yourself.")
        player:CastSpell(player, spellID, true)
    else
        Utils.sendMessage(player, "success", "Cast spell on target.")
        player:CastSpell(target, spellID, true)
    end
end

-- Server-side handler to castTargetSpellEntity
function SpellHandlers.castTargetSpellEntity(player, spellID)
    local target, isSelf = GameMasterSystem.getTarget(player)
    if not isSelf then
        Utils.sendMessage(player, "success", "Cast spell from target.")
        target:CastSpell(player, spellID, true)
    end
end

-- Handler for searching spells from database
function SpellHandlers.searchSpells(player, searchText, offset, pageSize)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    offset = offset or 0
    pageSize = Utils.validatePageSize(pageSize or 50)
    
    -- First get total count
    local countQuery
    if searchText and searchText ~= "" then
        searchText = Utils.escapeString(searchText)
        countQuery = string.format([[
            SELECT COUNT(*) 
            FROM spell 
            WHERE spellName0 LIKE '%%%s%%' OR id = '%s'
        ]], searchText, searchText)
    else
        countQuery = [[
            SELECT COUNT(*) 
            FROM spell 
            WHERE spellName0 != ''
        ]]
    end
    
    local countResult = WorldDBQuery(countQuery)
    local totalCount = 0
    if countResult then
        totalCount = countResult:GetUInt32(0)
    end
    
    -- Now get the actual spells
    local query
    if searchText and searchText ~= "" then
        -- Search by name or ID
        query = string.format([[
            SELECT id, spellName0 
            FROM spell 
            WHERE spellName0 LIKE '%%%s%%' OR id = '%s'
            ORDER BY id ASC 
            LIMIT %d OFFSET %d
        ]], searchText, searchText, pageSize, offset)
    else
        -- Get all spells
        query = string.format([[
            SELECT id, spellName0 
            FROM spell 
            WHERE spellName0 != '' 
            ORDER BY id ASC 
            LIMIT %d OFFSET %d
        ]], pageSize, offset)
    end
    
    local result = WorldDBQuery(query)
    local spells = {}
    
    if result then
        repeat
            local spellId = result:GetUInt32(0)
            local spellName = result:GetString(1)
            
            -- Don't get icon on server side - client will get it
            table.insert(spells, {
                spellId = spellId,
                name = spellName,
                -- icon will be fetched on client side using GetSpellTexture
            })
        until not result:NextRow()
    end
    
    -- Calculate if there are more results
    local hasMoreData = (offset + #spells) < totalCount
    
    -- Send data to client with pagination info
    AIO.Handle(player, "GameMasterSystem", "receiveSpellSearchResults", spells, offset, pageSize, hasMoreData, totalCount)
end

return SpellHandlers
