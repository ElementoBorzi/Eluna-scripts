-- GameMaster UI System - Utility Functions
-- This file contains all utility and helper functions
-- Load order: 02 (Third)

local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    return
end

-- Verify namespace exists
local GameMasterSystem = _G.GameMasterSystem
if not GameMasterSystem then
    print("[ERROR] GameMasterSystem namespace not found! Check load order.")
    return
end

local GMUtils = _G.GMUtils
local GMConfig = _G.GMConfig
local GMData = _G.GMData

-- Debug utility function
function GMUtils.debug(...)
    if GMConfig.config.debug or _G.GM_DEBUG then
        -- [GM Debug]
    end
end

-- String utilities
function GMUtils.trimSpaces(value)
    return tostring(value):match("^%s*(.-)%s*$")
end

-- Tooltip utilities
function GMUtils.ShowTooltip(owner, anchorPoint, ...)
    -- Store original strata
    local originalStrata = GameTooltip:GetFrameStrata()
    
    -- Check if owner is in a high-level frame (modal/tooltip strata)
    local ownerStrata = owner:GetFrameStrata()
    if ownerStrata == "TOOLTIP" or ownerStrata == "FULLSCREEN_DIALOG" then
        GameTooltip:SetFrameStrata("TOOLTIP")
        GameTooltip:SetFrameLevel(owner:GetFrameLevel() + 10)
    end
    
    -- Set owner and show tooltip
    GameTooltip:SetOwner(owner, anchorPoint or "ANCHOR_RIGHT")
    
    -- Handle different tooltip content types
    local args = {...}
    if #args == 1 and type(args[1]) == "string" then
        -- Simple text tooltip
        GameTooltip:SetText(args[1])
    elseif #args == 2 and type(args[1]) == "string" and type(args[2]) == "string" then
        -- Title and description
        GameTooltip:SetText(args[1])
        GameTooltip:AddLine(args[2], nil, nil, nil, true)
    else
        -- Multiple lines
        for i, line in ipairs(args) do
            if i == 1 then
                GameTooltip:SetText(line)
            else
                GameTooltip:AddLine(line, nil, nil, nil, true)
            end
        end
    end
    
    GameTooltip:Show()
    
    -- Store original strata to restore later
    GameTooltip.originalStrata = originalStrata
end

function GMUtils.HideTooltip()
    GameTooltip:Hide()
    
    -- Restore original strata if stored
    if GameTooltip.originalStrata then
        GameTooltip:SetFrameStrata(GameTooltip.originalStrata)
        GameTooltip.originalStrata = nil
    end
end

-- Throttle function to limit execution frequency
function GMUtils.throttle(func, delay)
    local lastCall = 0
    return function(...)
        local now = GetTime()
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        end
    end
end

-- Custom timer implementation for WoW 3.3.5
function GMUtils.customTimer(delay, func)
    local frame = CreateFrame("Frame")
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= delay then
            func()
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- Delayed execution utility
function GMUtils.delayedExecution(delay, func)
    local elapsed = 0
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= delay then
            func()
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end)
    frame:Show()
end

-- Get item icon texture with fallback
function GMUtils.GetItemIcon(itemID)
    if not itemID or itemID == 0 then
        return nil
    end
    
    -- Use GetItemInfo to get the texture
    local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
    
    -- Return the texture path or nil if not found
    return itemTexture
end

-- Get item quality color
function GMUtils.getQualityColor(quality)
    if GMConfig.QUALITY_COLORS[quality] then
        return unpack(GMConfig.QUALITY_COLORS[quality])
    end
    return 1, 1, 1 -- Default to white
end

-- Calculate card dimensions based on parent size
function GMUtils.calculateCardDimensions(parent)
    local parentWidth = parent:GetWidth()
    local parentHeight = parent:GetHeight()
    
    local cardWidth = (parentWidth - 60) / GMConfig.config.NUM_COLUMNS
    local cardHeight = (parentHeight - 120) / GMConfig.config.NUM_ROWS
    
    return cardWidth, cardHeight
end

-- Format numbers with commas
function GMUtils.formatNumber(num)
    if type(num) ~= "number" then
        return tostring(num)
    end
    
    local formatted = tostring(num)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end

-- Check if table is empty
function GMUtils.isTableEmpty(t)
    if type(t) ~= "table" then
        return true
    end
    
    for _ in pairs(t) do
        return false
    end
    return true
end

-- Deep copy a table
function GMUtils.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[GMUtils.deepCopy(orig_key)] = GMUtils.deepCopy(orig_value)
        end
        setmetatable(copy, GMUtils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Get current tab type
function GMUtils.getCurrentTabType()
    local activeTab = GMData.activeTab
    
    -- Check if it's a main tab
    for cardType, data in pairs(GMConfig.CardTypes) do
        if data.tabIndex == activeTab then
            return cardType
        end
    end
    
    -- Check if it's an item subcategory
    for categoryName, category in pairs(GMConfig.CardTypes.Item.categories) do
        for _, subCategory in ipairs(category.subCategories) do
            if subCategory.index == activeTab then
                return "Item", subCategory.value
            end
        end
    end
    
    return nil
end

-- Update data for current tab
function GMUtils.updateCurrentTabData(data, offset, pageSize, hasMore)
    local tabType = GMUtils.getCurrentTabType()
    if not tabType then
        GMUtils.debug("No valid tab type found for activeTab:", GMData.activeTab)
        return
    end
    
    local dataKey = GMConfig.CardTypes[tabType] and GMConfig.CardTypes[tabType].dataKey
    if dataKey then
        GMData.DataStore[dataKey] = data
        GMData.currentOffset = offset
        GMData.hasMoreData = hasMore
    end
end

-- Get display ID for different entity types
function GMUtils.getDisplayId(data, entityType)
    if entityType == "NPC" then
        return data.modelId or data.displayId
    elseif entityType == "GameObject" then
        return data.displayId or data.modelId
    elseif entityType == "SpellVisual" then
        return data.id or data.visualId
    elseif entityType == "Item" then
        return data.displayId or data.modelId
    end
    return nil
end

-- Show tooltip
function GMUtils.showTooltip(frame, title, text)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    if text then
        GameTooltip:AddLine(text, nil, nil, nil, true)
    end
    GameTooltip:Show()
end

-- Hide tooltip
function GMUtils.hideTooltip()
    GameTooltip:Hide()
end

-- Create a simple animation effect (fade in)
function GMUtils.fadeIn(frame, duration)
    duration = duration or 0.3
    frame:SetAlpha(0)
    frame:Show()
    
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        local alpha = elapsed / duration
        if alpha >= 1 then
            alpha = 1
            self:SetScript("OnUpdate", nil)
        end
        self:SetAlpha(alpha)
    end)
end

-- Create a simple animation effect (fade out)
function GMUtils.fadeOut(frame, duration, hideOnComplete)
    duration = duration or 0.3
    
    local startAlpha = frame:GetAlpha()
    local elapsed = 0
    
    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        local alpha = startAlpha * (1 - (elapsed / duration))
        if alpha <= 0 then
            alpha = 0
            self:SetScript("OnUpdate", nil)
            if hideOnComplete then
                self:Hide()
            end
        end
        self:SetAlpha(alpha)
    end)
end

-- Utilities loaded