--[[
    GameMaster UI - Player Management Handlers Module
    
    This module handles all player management functionality:
    - Player data queries and search
    - Gold management
    - Teleportation
    - Mail sending
    - Buff/Aura management
    - Healing and restoration
]]--

local PlayerHandlers = {}

-- Module dependencies (will be injected)
local GameMasterSystem, Config, Utils, Database, EntityHandlers

function PlayerHandlers.RegisterHandlers(gms, config, utils, database, entityHandlers)
    GameMasterSystem = gms
    Config = config
    Utils = utils
    Database = database
    EntityHandlers = entityHandlers
    
    -- Register all player-related handlers
    GameMasterSystem.getPlayerData = PlayerHandlers.getPlayerData
    GameMasterSystem.searchPlayerData = PlayerHandlers.searchPlayerData
    GameMasterSystem.givePlayerGold = PlayerHandlers.givePlayerGold
    GameMasterSystem.teleportToPlayer = PlayerHandlers.teleportToPlayer
    GameMasterSystem.summonPlayer = PlayerHandlers.summonPlayer
    GameMasterSystem.kickPlayer = PlayerHandlers.kickPlayer
    GameMasterSystem.sendPlayerMail = PlayerHandlers.sendPlayerMail
    GameMasterSystem.sendPlayerMailWithItems = PlayerHandlers.sendPlayerMailWithItems
    GameMasterSystem.applyBuffToPlayer = PlayerHandlers.applyBuffToPlayer
    GameMasterSystem.removePlayerAuras = PlayerHandlers.removePlayerAuras
    GameMasterSystem.healAndRestorePlayer = PlayerHandlers.healAndRestorePlayer
    GameMasterSystem.makePlayerCastOnSelf = PlayerHandlers.makePlayerCastOnSelf
    GameMasterSystem.makePlayerCastOnTarget = PlayerHandlers.makePlayerCastOnTarget
    GameMasterSystem.castSpellOnPlayer = PlayerHandlers.castSpellOnPlayer
end

-- Player Management Functions
function PlayerHandlers.getPlayerData(player, offset, pageSize, sortOrder)
    print("[GameMasterSystem] getPlayerData called by", player:GetName())
    
    -- Send test ping to verify AIO is working
    AIO.Handle(player, "GameMasterSystem", "testPing", "Testing AIO connection")
    
    offset = offset or 0
    pageSize = Utils.validatePageSize(pageSize or Config.defaultPageSize)
    sortOrder = Utils.validateSortOrder(sortOrder or "ASC")
    
    local playerData = {}
    local onlinePlayers = GetPlayersInWorld()
    
    print("[GameMasterSystem] Found", #onlinePlayers, "online players")
    
    -- Debug: Check what type onlinePlayers is
    print("[GameMasterSystem] onlinePlayers type:", type(onlinePlayers))
    if #onlinePlayers > 0 then
        print("[GameMasterSystem] First player type:", type(onlinePlayers[1]))
    end
    
    -- Sort players by name
    table.sort(onlinePlayers, function(a, b)
        if sortOrder == "ASC" then
            return a:GetName() < b:GetName()
        else
            return a:GetName() > b:GetName()
        end
    end)
    
    -- Apply pagination
    local startIdx = offset + 1
    local endIdx = math.min(offset + pageSize, #onlinePlayers)
    
    print("[GameMasterSystem] Pagination: startIdx=", startIdx, "endIdx=", endIdx, "pageSize=", pageSize)
    
    for i = startIdx, endIdx do
        local targetPlayer = onlinePlayers[i]
        print("[GameMasterSystem] Processing player", i, ":", targetPlayer and targetPlayer:GetName() or "nil")
        
        if targetPlayer then
            -- Wrap player data collection in pcall for error handling
            local success, err = pcall(function()
                local classInfo = {
                    [1] = {name = "Warrior", color = "C79C6E"},
                    [2] = {name = "Paladin", color = "F58CBA"},
                    [3] = {name = "Hunter", color = "ABD473"},
                    [4] = {name = "Rogue", color = "FFF569"},
                    [5] = {name = "Priest", color = "FFFFFF"},
                    [6] = {name = "Death Knight", color = "C41F3B"},
                    [7] = {name = "Shaman", color = "0070DE"},
                    [8] = {name = "Mage", color = "69CCF0"},
                    [9] = {name = "Warlock", color = "9482C9"},
                    [11] = {name = "Druid", color = "FF7D0A"}
                }
                
                local raceInfo = {
                    [1] = "Human",
                    [2] = "Orc",
                    [3] = "Dwarf",
                    [4] = "Night Elf",
                    [5] = "Undead",
                    [6] = "Tauren",
                    [7] = "Gnome",
                    [8] = "Troll",
                    [10] = "Blood Elf",
                    [11] = "Draenei"
                }
                
                -- Safely get player properties with nil checks
                local name = targetPlayer:GetName() or "Unknown"
                print("[GameMasterSystem] Getting data for player:", name)
                
                local class = targetPlayer:GetClass() or 1
                local race = targetPlayer:GetRace() or 1
                local level = targetPlayer:GetLevel() or 1
                local guild = targetPlayer:GetGuild()
                local totalMoney = targetPlayer:GetCoinage() or 0
                local gold = math.floor(totalMoney / 10000)
                
                -- Try to get display ID, with fallback
                local displayId = 0
                local displaySuccess = pcall(function()
                    displayId = targetPlayer:GetDisplayId() or 0
                end)
                if not displaySuccess then
                    print("[GameMasterSystem] Warning: Could not get display ID for", name)
                    displayId = 0 -- Use 0 as fallback
                end
                
                -- Try to get zone name
                local zoneName = "Unknown"
                local zoneSuccess = pcall(function()
                    zoneName = targetPlayer:GetZoneName() or "Unknown"
                end)
                if not zoneSuccess then
                    print("[GameMasterSystem] Warning: Could not get zone name for", name)
                end
                
                -- Check ban status
                local accountId = targetPlayer:GetAccountId()
                local isBanned = false
                local banType = nil
                
                -- Check account ban
                local accountBan = AuthDBQuery(string.format(
                    "SELECT 1 FROM account_banned WHERE id = %d AND (unbandate > UNIX_TIMESTAMP() OR unbandate = 0)",
                    accountId
                ))
                if accountBan then
                    isBanned = true
                    banType = "Account"
                else
                    -- Check character ban (try both databases)
                    local charBan = CharDBQuery(string.format(
                        "SELECT 1 FROM character_banned WHERE guid = %d AND (unbandate > UNIX_TIMESTAMP() OR unbandate = 0)",
                        targetPlayer:GetGUIDLow()
                    ))
                    if not charBan then
                        charBan = AuthDBQuery(string.format(
                            "SELECT 1 FROM character_banned WHERE guid = %d AND (unbandate > UNIX_TIMESTAMP() OR unbandate = 0)",
                            targetPlayer:GetGUIDLow()
                        ))
                    end
                    if charBan then
                        isBanned = true
                        banType = "Character"
                    end
                end
                
                local playerInfo = {
                    name = name,
                    level = level,
                    class = classInfo[class] and classInfo[class].name or "Unknown",
                    classColor = classInfo[class] and classInfo[class].color or "FFFFFF",
                    race = raceInfo[race] or "Unknown",
                    zone = zoneName,
                    gold = gold,
                    guildName = guild and guild:GetName() or nil,
                    online = true,
                    displayId = displayId,
                    isBanned = isBanned,
                    banType = banType
                }
                
                print("[GameMasterSystem] Created playerInfo for", playerInfo.name)
                print("[GameMasterSystem] Player details: Level", playerInfo.level, playerInfo.race, playerInfo.class)
                table.insert(playerData, playerInfo)
                print("[GameMasterSystem] playerData now has", #playerData, "entries")
            end)
            
            if not success then
                print("[GameMasterSystem] ERROR collecting player data:", err)
            end
        else
            print("[GameMasterSystem] Warning: targetPlayer is nil at index", i)
        end
    end
    
    local hasMoreData = endIdx < #onlinePlayers
    
    print("[GameMasterSystem] Sending", #playerData, "players to client")
    print("[GameMasterSystem] Data sample:", playerData[1] and playerData[1].name or "no data")
    
    -- Wrap AIO.Handle in pcall to catch any sending errors
    local sendSuccess, sendErr = pcall(function()
        AIO.Handle(player, "GameMasterSystem", "receivePlayerData", playerData, offset, pageSize, hasMoreData)
    end)
    
    if sendSuccess then
        print("[GameMasterSystem] Successfully sent player data to client")
    else
        print("[GameMasterSystem] ERROR sending player data:", sendErr)
    end
end

function PlayerHandlers.searchPlayerData(player, query, offset, pageSize, sortOrder)
    if not query or query == "" then
        return PlayerHandlers.getPlayerData(player, offset, pageSize, sortOrder)
    end
    
    offset = offset or 0
    pageSize = Utils.validatePageSize(pageSize or Config.defaultPageSize)
    sortOrder = Utils.validateSortOrder(sortOrder or "ASC")
    
    local playerData = {}
    local onlinePlayers = GetPlayersInWorld()
    local matchingPlayers = {}
    
    -- Filter players by search query
    query = query:lower()
    for _, targetPlayer in ipairs(onlinePlayers) do
        if targetPlayer:GetName():lower():find(query, 1, true) then
            table.insert(matchingPlayers, targetPlayer)
        end
    end
    
    -- Sort matching players
    table.sort(matchingPlayers, function(a, b)
        if sortOrder == "ASC" then
            return a:GetName() < b:GetName()
        else
            return a:GetName() > b:GetName()
        end
    end)
    
    -- Apply pagination to matching players
    local startIdx = offset + 1
    local endIdx = math.min(offset + pageSize, #matchingPlayers)
    
    for i = startIdx, endIdx do
        local targetPlayer = matchingPlayers[i]
        if targetPlayer then
            -- Same player data collection as above
            local classInfo = {
                [1] = {name = "Warrior", color = "C79C6E"},
                [2] = {name = "Paladin", color = "F58CBA"},
                [3] = {name = "Hunter", color = "ABD473"},
                [4] = {name = "Rogue", color = "FFF569"},
                [5] = {name = "Priest", color = "FFFFFF"},
                [6] = {name = "Death Knight", color = "C41F3B"},
                [7] = {name = "Shaman", color = "0070DE"},
                [8] = {name = "Mage", color = "69CCF0"},
                [9] = {name = "Warlock", color = "9482C9"},
                [11] = {name = "Druid", color = "FF7D0A"}
            }
            
            local raceInfo = {
                [1] = "Human",
                [2] = "Orc",
                [3] = "Dwarf",
                [4] = "Night Elf",
                [5] = "Undead",
                [6] = "Tauren",
                [7] = "Gnome",
                [8] = "Troll",
                [10] = "Blood Elf",
                [11] = "Draenei"
            }
            
            local class = targetPlayer:GetClass()
            local race = targetPlayer:GetRace()
            local guild = targetPlayer:GetGuild()
            local totalMoney = targetPlayer:GetCoinage()
            local gold = math.floor(totalMoney / 10000)
            
            -- Check ban status
            local accountId = targetPlayer:GetAccountId()
            local isBanned = false
            local banType = nil
            
            -- Check account ban
            local accountBan = AuthDBQuery(string.format(
                "SELECT 1 FROM account_banned WHERE id = %d AND (unbandate > UNIX_TIMESTAMP() OR unbandate = 0)",
                accountId
            ))
            if accountBan then
                isBanned = true
                banType = "Account"
            else
                -- Check character ban
                local charBan = CharDBQuery(string.format(
                    "SELECT 1 FROM character_banned WHERE guid = %d AND (unbandate > UNIX_TIMESTAMP() OR unbandate = 0)",
                    targetPlayer:GetGUIDLow()
                ))
                if not charBan then
                    charBan = AuthDBQuery(string.format(
                        "SELECT 1 FROM character_banned WHERE guid = %d AND (unbandate > UNIX_TIMESTAMP() OR unbandate = 0)",
                        targetPlayer:GetGUIDLow()
                    ))
                end
                if charBan then
                    isBanned = true
                    banType = "Character"
                end
            end
            
            local playerInfo = {
                name = targetPlayer:GetName(),
                level = targetPlayer:GetLevel(),
                class = classInfo[class] and classInfo[class].name or "Unknown",
                classColor = classInfo[class] and classInfo[class].color or "FFFFFF",
                race = raceInfo[race] or "Unknown",
                zone = targetPlayer:GetZoneName() or "Unknown",
                gold = gold,
                guildName = guild and guild:GetName() or nil,
                online = true,
                displayId = targetPlayer:GetDisplayId(),
                isBanned = isBanned,
                banType = banType
            }
            
            print("[GameMasterSystem] Created playerInfo for", playerInfo.name)
            table.insert(playerData, playerInfo)
            print("[GameMasterSystem] playerData now has", #playerData, "entries")
        end
    end
    
    local hasMoreData = endIdx < #matchingPlayers
    
    AIO.Handle(player, "GameMasterSystem", "receivePlayerData", playerData, offset, pageSize, hasMoreData)
end

-- Player management action handlers
function PlayerHandlers.givePlayerGold(player, targetName, amount)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        Utils.sendMessage(player, "error", "Invalid gold amount.")
        return
    end
    
    -- Convert gold to copper (1 gold = 10000 copper)
    local copper = amount * 10000
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    -- Give gold
    targetPlayer:ModifyMoney(copper)
    
    -- Notify both players
    Utils.sendMessage(player, "success", string.format("Gave %d gold to %s.", amount, targetName))
    targetPlayer:SendBroadcastMessage(string.format("You received %d gold from Staff %s.", amount, player:GetName()))
end

function PlayerHandlers.teleportToPlayer(player, targetName)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    -- Teleport GM to player
    player:Teleport(
        targetPlayer:GetMapId(),
        targetPlayer:GetX(),
        targetPlayer:GetY(),
        targetPlayer:GetZ(),
        targetPlayer:GetO()
    )
    
    Utils.sendMessage(player, "success", "Teleported to " .. targetName .. ".")
end

function PlayerHandlers.summonPlayer(player, targetName)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    -- Summon player to GM
    targetPlayer:Teleport(
        player:GetMapId(),
        player:GetX(),
        player:GetY(),
        player:GetZ(),
        player:GetO()
    )
    
    Utils.sendMessage(player, "success", "Summoned " .. targetName .. " to your location.")
    targetPlayer:SendBroadcastMessage("You have been summoned by Staff " .. player:GetName() .. ".")
end

function PlayerHandlers.kickPlayer(player, targetName, reason)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    reason = reason or "Kicked by GM"
    
    -- Kick the player
    targetPlayer:KickPlayer()
    
    Utils.sendMessage(player, "success", string.format("Kicked %s. Reason: %s", targetName, reason))
end

function PlayerHandlers.sendPlayerMail(player, targetName, subject, body, gold)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    -- Validate inputs
    if not subject or subject == "" then
        Utils.sendMessage(player, "error", "Mail subject cannot be empty.")
        return
    end
    
    if not body or body == "" then
        Utils.sendMessage(player, "error", "Mail body cannot be empty.")
        return
    end
    
    gold = tonumber(gold) or 0
    if gold < 0 then
        gold = 0
    end
    
    -- Convert gold to copper
    local copper = gold * 10000
    
    -- Find target player (can be offline for mail)
    local targetGuid = nil
    local targetPlayer = GetPlayerByName(targetName)
    
    if targetPlayer then
        targetGuid = targetPlayer:GetGUIDLow()
    else
        -- Try to find offline player
        local result = CharDBQuery(string.format("SELECT guid FROM characters WHERE name = '%s'", targetName))
        if result then
            targetGuid = result:GetUInt32(0)
        else
            Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found.")
            return
        end
    end
    
    -- Send mail using Eluna's SendMail function
    -- SendMail(subject, body, receiverGuid, senderGuid, stationary, delay, money, cod, entry, amount)
    -- Using GM stationery (61) instead of default (41)
    SendMail(subject, body, targetGuid, 0, 61, 0, copper, 0, 0, 0)
    
    Utils.sendMessage(player, "success", string.format("Mail sent to %s with subject: %s", targetName, subject))
    
    -- Notify online player
    if targetPlayer then
        targetPlayer:SendBroadcastMessage(string.format("You have received mail from Staff %s.", player:GetName()))
    end
end

function PlayerHandlers.sendPlayerMailWithItems(player, data)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    -- Extract data from table
    local targetName = data.recipient
    local subject = data.subject
    local body = data.message
    local money = data.money or 0
    local cod = data.cod or 0
    local items = data.items or {}
    local stationery = data.stationery or 61  -- GM stationery (61) by default
    local delay = data.delay or 0
    
    -- Validate inputs
    if not targetName or targetName == "" then
        Utils.sendMessage(player, "error", "Recipient name cannot be empty.")
        return
    end
    
    if not subject or subject == "" then
        Utils.sendMessage(player, "error", "Mail subject cannot be empty.")
        return
    end
    
    if not body or body == "" then
        Utils.sendMessage(player, "error", "Mail body cannot be empty.")
        return
    end
    
    -- Validate money and cod
    money = tonumber(money) or 0
    cod = tonumber(cod) or 0
    
    if money < 0 then money = 0 end
    if cod < 0 then cod = 0 end
    
    -- Find target player (can be offline for mail)
    local targetGuid = nil
    local targetPlayer = GetPlayerByName(targetName)
    
    if targetPlayer then
        targetGuid = targetPlayer:GetGUIDLow()
    else
        -- Try to find offline player
        local result = CharDBQuery(string.format("SELECT guid FROM characters WHERE name = '%s'", targetName))
        if result then
            targetGuid = result:GetUInt32(0)
        else
            Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found.")
            return
        end
    end
    
    -- Build SendMail parameters
    -- SendMail(subject, text, receiverGUIDLow, senderGUIDLow, stationary, delay, money, cod, entry1, amount1, entry2, amount2, ...)
    -- Using senderGUIDLow = 0 to make it appear from "Game Master" system
    local params = {
        subject,
        body,
        targetGuid,
        0,  -- Sender GUID 0 = system/GM mail
        stationery,
        delay,
        money,
        cod
    }
    
    -- Add items (up to 12)
    local itemCount = 0
    for i = 1, math.min(#items, 12) do
        local item = items[i]
        if item and item.entry then
            local entry = tonumber(item.entry) or 0
            local amount = tonumber(item.amount) or 1
            
            if entry > 0 and amount > 0 then
                table.insert(params, entry)
                table.insert(params, amount)
                itemCount = itemCount + 1
            end
        end
    end
    
    -- Send the mail using unpacked parameters
    SendMail(unpack(params))
    
    -- Send success message
    if itemCount > 0 then
        Utils.sendMessage(player, "success", string.format("Mail sent to %s with %d item(s). Subject: %s", targetName, itemCount, subject))
    else
        Utils.sendMessage(player, "success", string.format("Mail sent to %s. Subject: %s", targetName, subject))
    end
    
    -- Notify online player
    if targetPlayer then
        if itemCount > 0 then
            targetPlayer:SendBroadcastMessage(string.format("You have received mail with %d item(s) from Staff %s.", itemCount, player:GetName()))
        else
            targetPlayer:SendBroadcastMessage(string.format("You have received mail from Staff %s.", player:GetName()))
        end
    end
end

-- Buff/Aura Management Functions
function PlayerHandlers.applyBuffToPlayer(player, targetName, spellId)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    spellId = tonumber(spellId)
    if not spellId or spellId <= 0 then
        Utils.sendMessage(player, "error", "Invalid spell ID.")
        return
    end
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    -- Apply the buff/aura using the correct Eluna API
    -- The caster (GM) adds the aura to the target
    player:AddAura(spellId, targetPlayer)
    
    Utils.sendMessage(player, "success", string.format("Applied buff (ID: %d) to %s.", spellId, targetName))
    targetPlayer:SendBroadcastMessage(string.format("You received a buff from Staff %s.", player:GetName()))
end

function PlayerHandlers.removePlayerAuras(player, targetName)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    -- Remove all auras
    targetPlayer:RemoveAllAuras()
    
    Utils.sendMessage(player, "success", string.format("Removed all auras from %s.", targetName))
    targetPlayer:SendBroadcastMessage(string.format("All your auras have been removed by Staff %s.", player:GetName()))
end

function PlayerHandlers.healAndRestorePlayer(player, targetName)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    -- Full heal
    targetPlayer:SetHealth(targetPlayer:GetMaxHealth())
    
    -- Restore mana/energy/rage
    local powerType = targetPlayer:GetPowerType()
    targetPlayer:SetPower(targetPlayer:GetMaxPower(powerType), powerType)
    
    -- Remove common debuffs by spell ID
    -- Common debuff IDs in 3.3.5
    local commonDebuffs = {
        15007, -- Resurrection Sickness
        25771, -- Forbearance
        57723, -- Exhaustion (heroism/bloodlust debuff)
        57724, -- Sated (heroism/bloodlust debuff)
        26013, -- Deserter
        -- Add more common debuffs as needed
    }
    
    for _, debuffId in ipairs(commonDebuffs) do
        if targetPlayer:HasAura(debuffId) then
            targetPlayer:RemoveAura(debuffId)
        end
    end
    
    -- Alternative: Remove ALL auras (both positive and negative)
    -- This is more thorough but also removes buffs
    -- targetPlayer:RemoveAllAuras()
    
    Utils.sendMessage(player, "success", string.format("Fully healed and restored %s.", targetName))
    targetPlayer:SendBroadcastMessage(string.format("You have been fully restored by Staff %s.", player:GetName()))
end

function PlayerHandlers.makePlayerCastOnSelf(player, targetName, spellId)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    spellId = tonumber(spellId)
    if not spellId or spellId <= 0 then
        Utils.sendMessage(player, "error", "Invalid spell ID.")
        return
    end
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    -- Make player cast spell on themselves
    targetPlayer:CastSpell(targetPlayer, spellId, true)
    
    Utils.sendMessage(player, "success", string.format("Made %s cast spell (ID: %d) on themselves.", targetName, spellId))
end

function PlayerHandlers.makePlayerCastOnTarget(player, targetName, spellId)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    spellId = tonumber(spellId)
    if not spellId or spellId <= 0 then
        Utils.sendMessage(player, "error", "Invalid spell ID.")
        return
    end
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    -- Get player's target
    local playersTarget = targetPlayer:GetSelection()
    if not playersTarget then
        Utils.sendMessage(player, "error", targetName .. " has no target selected.")
        return
    end
    
    -- Make player cast spell on their target
    targetPlayer:CastSpell(playersTarget, spellId, true)
    
    Utils.sendMessage(player, "success", string.format("Made %s cast spell (ID: %d) on their target.", targetName, spellId))
end

function PlayerHandlers.castSpellOnPlayer(player, targetName, spellId)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    spellId = tonumber(spellId)
    if not spellId or spellId <= 0 then
        Utils.sendMessage(player, "error", "Invalid spell ID.")
        return
    end
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    -- GM casts spell on target player
    player:CastSpell(targetPlayer, spellId, true)
    
    Utils.sendMessage(player, "success", string.format("Cast spell (ID: %d) on %s.", spellId, targetName))
    targetPlayer:SendBroadcastMessage(string.format("Staff %s cast a spell on you.", player:GetName()))
end

return PlayerHandlers