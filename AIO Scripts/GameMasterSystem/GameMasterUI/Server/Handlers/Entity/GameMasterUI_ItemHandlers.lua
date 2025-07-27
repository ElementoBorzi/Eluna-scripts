--[[
    GameMaster UI - Item Handlers Module
    
    This module handles all item-related functionality:
    - Item data queries
    - Item search
    - Adding items to players
]]--

local ItemHandlers = {}

-- Module dependencies (will be injected)
local GameMasterSystem, Config, Utils, Database

function ItemHandlers.RegisterHandlers(gms, config, utils, database)
    GameMasterSystem = gms
    Config = config
    Utils = utils
    Database = database
    
    -- Register all item-related handlers
    GameMasterSystem.getItemData = ItemHandlers.getItemData
    GameMasterSystem.handleItemCategory = ItemHandlers.getItemData -- Alias for backward compatibility
    GameMasterSystem.searchItemData = ItemHandlers.searchItemData
    GameMasterSystem.addItemEntity = ItemHandlers.addItemEntity
    GameMasterSystem.addItemEntityMax = ItemHandlers.addItemEntityMax
    GameMasterSystem.requestModalItems = ItemHandlers.requestModalItems
    GameMasterSystem.searchItemsForModal = ItemHandlers.searchItemsForModal
    GameMasterSystem.givePlayerItem = ItemHandlers.givePlayerItem
end

-- Function to display debug messages
local function debugMessage(...)
    if Config.debug then
        print("DEBUG:", ...)
    end
end

-- Server-side handler for item data requests
function ItemHandlers.getItemData(player, offset, pageSize, sortOrder, inventoryType)
    offset = offset or 0
    pageSize = Utils.validatePageSize(pageSize or Config.defaultPageSize)
    sortOrder = Utils.validateSortOrder(sortOrder or "DESC")

    local coreName = GetCoreName()
    local query = Database.getQuery(coreName, "itemData")(sortOrder, pageSize, offset, inventoryType)
    local result = WorldDBQuery(query)
    local itemData = {}

    if result then
        repeat
            local item = {
                entry = result:GetUInt32(0),
                name = result:GetString(1),
                description = result:GetString(2),
                displayid = result:GetUInt32(3),
                inventoryType = result:GetUInt32(4),
                quality = result:GetUInt32(5),
                itemLevel = result:GetUInt32(6),
                class = result:GetUInt32(7),
                subclass = result:GetUInt32(8),
            }
            table.insert(itemData, item)
        until not result:NextRow()
    end

    local hasMoreData = #itemData == pageSize

    if #itemData == 0 then
        player:SendBroadcastMessage("No item data available.")
    else
        debugMessage("Sending item data to player")
        AIO.Handle(
            player,
            "GameMasterSystem",
            "receiveItemData",
            itemData,
            offset,
            pageSize,
            hasMoreData,
            inventoryType
        )
    end
end

-- Function to search item data
function ItemHandlers.searchItemData(player, query, offset, pageSize, sortOrder, inventoryType)
    if not query or query == "" then
        return ItemHandlers.getItemData(player, offset, pageSize, sortOrder, inventoryType)
    end

    -- Ensure parameters are valid
    query = Utils.escapeString(query)
    offset = tonumber(offset) or 0
    pageSize = Utils.validatePageSize(pageSize or Config.defaultPageSize)
    sortOrder = Utils.validateSortOrder(sortOrder or "DESC")

    local coreName = GetCoreName()
    local searchQuery = Database.getQuery(coreName, "searchItemData")(query, sortOrder, pageSize, offset, inventoryType)

    if Config.debug then
        print("Item search query:", searchQuery)
    end

    local result = WorldDBQuery(searchQuery)
    local itemData = {}

    if result then
        repeat
            local item = {
                entry = result:GetUInt32(0),
                name = result:GetString(1),
                description = result:GetString(2),
                displayid = result:GetUInt32(3),
                quality = result:GetUInt32(4),
                inventoryType = result:GetUInt32(5),
                itemLevel = result:GetUInt32(6),
                class = result:GetUInt32(7),
                subclass = result:GetUInt32(8),
            }
            table.insert(itemData, item)
        until not result:NextRow()
    end

    local hasMoreData = #itemData == pageSize

    if #itemData == 0 then
        player:SendBroadcastMessage("No item data found for the search query: " .. query)
    else
        AIO.Handle(player, "GameMasterSystem", "receiveItemData", itemData, offset, pageSize, hasMoreData, inventoryType)
    end
end

-- Server-side handler to add item to target or player
function ItemHandlers.addItemEntity(player, itemID, amount)
    print("Adding item to target or player" .. itemID .. " amount: " .. amount)
    -- Validate inputs
    itemID = tonumber(itemID)
    amount = tonumber(amount) or 1

    if not itemID or itemID <= 0 then
        Utils.sendMessage(player, "error", "Invalid item ID.")
        return
    end

    if amount <= 0 or amount > 100 then
        amount = 1 -- Sanitize amount
    end

    local target, isSelf = GameMasterSystem.getTarget(player)

    -- Verify item exists
    local itemQuery = WorldDBQuery("SELECT entry FROM item_template WHERE entry = " .. itemID)
    if not itemQuery then
        Utils.sendMessage(player, "error", "Item ID " .. itemID .. " does not exist.")
        return
    end

    local success = target:AddItem(itemID, amount)

    if success then
        if isSelf then
            Utils.sendMessage(player, "success", string.format("Added %d x item %d to your inventory.", amount, itemID))
        else
            Utils.sendMessage(player, "success", string.format("Added %d x item %d to %s's inventory.",
                amount, itemID, target:GetName()))
        end
    else
        Utils.sendMessage(player, "error", "Failed to add item. Inventory might be full.")
    end
end

function ItemHandlers.addItemEntityMax(player, itemID)
    -- Validate inputs
    itemID = tonumber(itemID)

    if not itemID or itemID <= 0 then
        Utils.sendMessage(player, "error", "Invalid item ID.")
        return
    end

    local target, isSelf = GameMasterSystem.getTarget(player)

    -- Query item information from database
    local itemQuery = WorldDBQuery(string.format(
        "SELECT entry, name, stackable FROM item_template WHERE entry = %d",
        itemID
    ))

    if not itemQuery then
        Utils.sendMessage(player, "error", "Item ID " .. itemID .. " does not exist.")
        return
    end

    -- Get stack size
    local itemName = itemQuery:GetString(1)
    local maxStack = itemQuery:GetUInt32(2)

    -- Ensure valid stack size
    if not maxStack or maxStack <= 0 then
        maxStack = 1
    elseif maxStack > 1000 then
        maxStack = 1000  -- Safety cap
    end

    -- Add item to target's inventory
    local success = target:AddItem(itemID, maxStack)

    if success then
        if isSelf then
            Utils.sendMessage(
                player,
                "success",
                string.format("Added maximum stack (%d) of %s to your inventory.",
                    maxStack, itemName or "item #" .. itemID)
            )
        else
            Utils.sendMessage(
                player,
                "success",
                string.format("Added maximum stack (%d) of %s to %s's inventory.",
                    maxStack, itemName or "item #" .. itemID, target:GetName())
            )
        end
    else
        Utils.sendMessage(player, "error", "Failed to add item. Inventory might be full.")
    end
end

-- Handler for requesting items for the modal
function ItemHandlers.requestModalItems(player, searchText, category, qualitiesStr)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    -- Convert qualities string back to table if needed
    local qualities = {}
    if qualitiesStr and qualitiesStr ~= "" then
        if type(qualitiesStr) == "string" then
            -- Split comma-separated string
            for quality in string.gmatch(qualitiesStr, "[^,]+") do
                table.insert(qualities, tonumber(quality))
            end
        elseif type(qualitiesStr) == "table" then
            qualities = qualitiesStr
        end
    end
    
    -- Build the query
    local query = "SELECT entry, name, Quality, ItemLevel, class, subclass, stackable, displayid FROM item_template WHERE 1=1"
    
    -- Add search filter
    if searchText and searchText ~= "" then
        query = query .. " AND (name LIKE '%" .. searchText .. "%' OR entry = '" .. searchText .. "')"
    end
    
    -- Add category filter
    if category and category ~= "all" then
        if category == "weapon" then
            query = query .. " AND class = 2"
        elseif category == "armor" then
            query = query .. " AND class = 4"
        elseif category == "consumable" then
            query = query .. " AND class = 0"
        elseif category == "trade" then
            query = query .. " AND class = 7"
        elseif category == "quest" then
            query = query .. " AND class = 12"
        elseif category == "gem" then
            query = query .. " AND class = 3"
        elseif category == "misc" then
            query = query .. " AND class = 15"
        end
    end
    
    -- Add quality filter
    if qualities and #qualities > 0 then
        local qualityStr = table.concat(qualities, ",")
        query = query .. " AND Quality IN (" .. qualityStr .. ")"
        print("[GameMasterSystem] Quality filter applied: " .. qualityStr)
    end
    
    -- Limit results
    query = query .. " ORDER BY Quality DESC, name ASC LIMIT 100"
    
    -- Execute query
    local results = WorldDBQuery(query)
    local items = {}
    
    if results then
        repeat
            local entry = results:GetUInt32(0)
            local name = results:GetString(1)
            local quality = results:GetUInt32(2)
            local itemLevel = results:GetUInt32(3)
            local class = results:GetUInt32(4)
            local subclass = results:GetUInt32(5)
            local maxStack = results:GetUInt32(6)
            local displayId = results:GetUInt32(7)
            
            table.insert(items, {
                entry = entry,
                name = name,
                quality = quality,
                itemLevel = itemLevel,
                class = class,
                subclass = subclass,
                maxStack = maxStack,
                displayId = displayId,
                link = "item:" .. entry .. ":0:0:0:0:0:0:0"
            })
        until not results:NextRow()
    end
    
    -- Send data to client
    AIO.Handle(player, "GameMasterSystem", "receiveModalItemData", items)
end

-- Handler for searching items in the modal
function ItemHandlers.searchItemsForModal(player, searchText, category, qualities)
    -- Just redirect to requestModalItems with the search parameters
    ItemHandlers.requestModalItems(player, searchText, category, qualities)
end

function ItemHandlers.givePlayerItem(player, targetName, itemId, count)
    -- Validate GM permissions
    if player:GetGMRank() < 2 then
        Utils.sendMessage(player, "error", "You do not have permission to use this command.")
        return
    end
    
    itemId = tonumber(itemId)
    count = tonumber(count) or 1
    
    if not itemId or itemId <= 0 then
        Utils.sendMessage(player, "error", "Invalid item ID.")
        return
    end
    
    if count <= 0 then
        count = 1
    end
    
    -- Find target player
    local targetPlayer = GetPlayerByName(targetName)
    if not targetPlayer then
        Utils.sendMessage(player, "error", "Player '" .. targetName .. "' not found or offline.")
        return
    end
    
    -- Verify item exists
    local itemQuery = WorldDBQuery("SELECT name FROM item_template WHERE entry = " .. itemId)
    if not itemQuery then
        Utils.sendMessage(player, "error", "Item ID " .. itemId .. " does not exist.")
        return
    end
    
    local itemName = itemQuery:GetString(0)
    
    -- Add item to target
    local success = targetPlayer:AddItem(itemId, count)
    
    if success then
        Utils.sendMessage(player, "success", string.format("Gave %dx %s to %s.", count, itemName, targetName))
        targetPlayer:SendBroadcastMessage(string.format("You received %dx %s from GM %s.", count, itemName, player:GetName()))
    else
        Utils.sendMessage(player, "error", "Failed to give item. Target's inventory might be full.")
    end
end

return ItemHandlers