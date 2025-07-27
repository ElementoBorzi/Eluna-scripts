-- GameMaster UI System - UI Creation
-- This file handles all UI creation using UIStyleLibrary functions
-- Load order: 03 (Fourth)

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

local GMData = _G.GMData
local GMConfig = _G.GMConfig
local GMUI = _G.GMUI

-- Create the main frame using UIStyleLibrary
function GMUI.createMainFrame()
    -- Create styled frame
    local frame = CreateStyledFrame(UIParent, UISTYLE_COLORS.DarkGrey)
    frame:SetSize(GMConfig.config.BG_WIDTH, GMConfig.config.BG_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetFrameStrata("MEDIUM")
    
    -- Make frame draggable
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Add to special frames for ESC key support
    tinsert(UISpecialFrames, frame:GetName() or "GameMasterMainFrame")
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("Staff System")
    title:SetTextColor(1, 1, 1)
    
    -- Close button using UIStyleLibrary
    local closeButton = CreateStyledButton(frame, "X", 24, 24)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Store reference
    GMData.frames.mainFrame = frame
    
    return frame
end

-- Create content container system
function GMUI.createContentContainer(parent)
    -- Create category indicator first (positioned above content area)
    local categoryIndicator = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryIndicator:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -55)
    categoryIndicator:SetTextColor(0.8, 0.8, 0.8)
    categoryIndicator:Hide() -- Hidden by default
    
    -- Create main content area using styled frame
    local contentArea = CreateStyledFrame(parent, UISTYLE_COLORS.OptionBg)
    -- Adjust height: 80px top (dropdowns + category) + 50px bottom for pagination = 130px total
    contentArea:SetSize(parent:GetWidth() - 20, parent:GetHeight() - 125)
    contentArea:SetPoint("TOP", parent, "TOP", 0, -75) -- Position below dropdowns and category
    
    -- Enable mouse wheel for page navigation
    contentArea:EnableMouseWheel(true)
    contentArea:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            -- Scroll up = Previous page
            if GMData.currentOffset > 0 then
                GMData.currentOffset = math.max(0, GMData.currentOffset - GMConfig.config.PAGE_SIZE)
                if GMData.activeTab then
                    GMUI.requestDataForTab(GMData.activeTab)
                end
            end
        else
            -- Scroll down = Next page
            if GMData.hasMoreData then
                GMData.currentOffset = GMData.currentOffset + GMConfig.config.PAGE_SIZE
                if GMData.activeTab then
                    GMUI.requestDataForTab(GMData.activeTab)
                end
            end
        end
    end)
    
    -- Initialize dynamic content frames storage
    GMData.dynamicContentFrames = {}
    
    -- Store references
    GMData.frames.contentArea = contentArea
    GMData.frames.categoryIndicator = categoryIndicator
    
    return contentArea
end

-- Create search functionality
function GMUI.createSearchBox(parent)
    local searchBox = CreateStyledSearchBox(parent, 200, "Search...", function(text)
        -- Handle search
        GMData.currentSearchQuery = text
        GMData.currentOffset = 0 -- Reset offset when searching
        
        -- Request data for current tab with search query
        if GMData.activeTab then
            GMUI.requestDataForTab(GMData.activeTab)
        end
    end)
    
    searchBox:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -40, -15)
    
    GMData.frames.searchBox = searchBox
    return searchBox
end

-- Create sort dropdown
function GMUI.createSortDropdown(parent)
    -- Wait for category dropdown to be created
    if not GMData.frames.categoryDropdown then
        -- Warning: Category dropdown not found, creating sort dropdown anyway
    end
    
    -- Create label for sort dropdown
    local sortLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if GMData.frames.categoryDropdown then
        sortLabel:SetPoint("LEFT", GMData.frames.categoryDropdown, "RIGHT", 20, 0)
    else
        sortLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 170, -15)
    end
    sortLabel:SetText("Sort:")
    sortLabel:SetTextColor(0.8, 0.8, 0.8)
    
    -- Create sort dropdown items
    local sortItems = {
        {
            text = "Ascending",
            value = "ASC",
            func = function()
                GMData.sortOrder = "ASC"
                if GameMasterSystem.refreshData then
                    GameMasterSystem.refreshData()
                end
            end
        },
        {
            text = "Descending", 
            value = "DESC",
            func = function()
                GMData.sortOrder = "DESC"
                if GameMasterSystem.refreshData then
                    GameMasterSystem.refreshData()
                end
            end
        }
    }
    
    -- Create fully styled dropdown
    local sortDropdown, sortMenuFrame = CreateFullyStyledDropdown(
        parent,
        120,
        sortItems,
        "Ascending",
        function(value, item)
            -- Additional handling if needed
            if GMConfig.config.debug then
                -- Debug: Sort order changed
            end
        end
    )
    
    -- Position the dropdown next to the label
    sortDropdown:SetPoint("LEFT", sortLabel, "RIGHT", 10, 0)
    
    GMData.frames.sortDropdown = sortDropdown
    GMData.frames.sortMenuFrame = sortMenuFrame
    GMData.frames.sortLabel = sortLabel
    
    return sortDropdown, sortMenuFrame
end

-- Create pagination controls
function GMUI.createPaginationControls(parent)
    -- Previous button
    local prevButton = CreateStyledButton(parent, "Previous", 100, 30)
    prevButton:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 10)  -- Moved down to 10
    prevButton:SetScript("OnClick", function()
        if GMData.currentOffset > 0 then
            GMData.currentOffset = math.max(0, GMData.currentOffset - GMConfig.config.PAGE_SIZE)
            if GMData.activeTab then
                GMUI.requestDataForTab(GMData.activeTab)
            end
        end
    end)
    
    -- Next button
    local nextButton = CreateStyledButton(parent, "Next", 100, 30)
    nextButton:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)  -- Moved down to 10
    nextButton:SetScript("OnClick", function()
        if GMData.hasMoreData then
            GMData.currentOffset = GMData.currentOffset + GMConfig.config.PAGE_SIZE
            if GMData.activeTab then
                GMUI.requestDataForTab(GMData.activeTab)
            end
        end
    end)
    
    -- Refresh button
    local refreshButton = CreateStyledButton(parent, "Refresh", 100, 30)
    refreshButton:SetPoint("BOTTOM", parent, "BOTTOM", 0, 10)  -- Moved down to 10
    refreshButton:SetScript("OnClick", function()
        if GMData.activeTab then
            GMUI.requestDataForTab(GMData.activeTab)
        end
    end)
    
    GMData.frames.prevButton = prevButton
    GMData.frames.nextButton = nextButton
    GMData.frames.refreshButton = refreshButton
    
    return prevButton, nextButton, refreshButton
end


-- Create category dropdown menu
function GMUI.createCategoryDropdown(parent)
    -- Build nested menu structure for styled dropdown
    local dropdownItems = GMUI.buildDropdownItems()
    
    -- Create fully styled dropdown with nested menu support
    local dropdown, menuFrame = CreateFullyStyledDropdown(
        parent,
        150,
        dropdownItems,
        "Select Category",
        function(value, item)
            -- Handle selection if needed
            if GMConfig.config.debug then
                -- Debug: Dropdown selection
            end
        end
    )
    
    -- Position the dropdown
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -15)
    
    GMData.frames.categoryDropdown = dropdown
    GMData.frames.categoryMenu = menuFrame
    return dropdown, menuFrame
end

-- Initialize dropdown menu content
function GMUI.initializeDropdownMenu(frame, level, menuList)
    if not frame then return end
    
    level = level or 1
    local info = UIDropDownMenu_CreateInfo()
    
    if level == 1 then
        -- Main menu items
        local menuItems = GMUI.getMainMenuItems()
        for _, item in ipairs(menuItems) do
            wipe(info)
            info.text = item.text
            info.func = item.func
            info.notCheckable = true
            
            if item.hasArrow then
                info.hasArrow = true
                info.menuList = item.menuList
            end
            
            UIDropDownMenu_AddButton(info, level)
        end
    elseif level == 2 then
        -- Submenu items
        if menuList == "spell" then
            GMUI.addSpellSubmenu(info, level)
        elseif menuList == "items" then
            GMUI.addItemsSubmenu(info, level)
        elseif menuList == "categories" then
            -- Item categories submenu
            wipe(info)
            info.text = "Equipment"
            info.hasArrow = true
            info.menuList = "equipment"
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
            
            wipe(info)
            info.text = "Weapons"
            info.hasArrow = true
            info.menuList = "weapons"
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
            
            wipe(info)
            info.text = "Misc"
            info.hasArrow = true
            info.menuList = "misc"
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
        end
    elseif level == 3 then
        -- Third level menus
        if menuList == "equipment" then
            GMUI.addEquipmentSubmenu(info, level)
        elseif menuList == "weapons" then
            GMUI.addWeaponsSubmenu(info, level)
        elseif menuList == "misc" then
            GMUI.addMiscSubmenu(info, level)
        end
    end
end

-- Build dropdown items for styled dropdown
function GMUI.buildDropdownItems()
    local items = {}
    
    -- Creatures
    table.insert(items, {
        text = "Creatures",
        value = "creatures",
        func = function()
            GMUI.switchToTab(1)
        end
    })
    
    -- Objects
    table.insert(items, {
        text = "Objects", 
        value = "objects",
        func = function()
            GMUI.switchToTab(2)
        end
    })
    
    -- Spells submenu
    table.insert(items, {
        text = "Spells",
        hasArrow = true,
        menuList = {
            {
                text = "Spells",
                value = "spells",
                func = function()
                    GMUI.switchToTab(3)
                end
            },
            {
                text = "Spell Visuals",
                value = "spellvisuals",
                func = function()
                    GMUI.switchToTab(4)
                end
            }
        }
    })
    
    -- Items submenu
    table.insert(items, {
        text = "Items",
        hasArrow = true,
        menuList = {
            {
                text = "Search All Items",
                value = "allitems",
                func = function()
                    GMUI.switchToTab(5)
                end
            },
            {
                text = "Item Categories",
                hasArrow = true,
                menuList = GMUI.buildItemCategoriesMenu()
            }
        }
    })
    
    -- Player Management
    table.insert(items, {
        text = "Player Management",
        value = "players",
        func = function()
            GMUI.switchToTab(6)
        end
    })
    
    return items
end

-- Build item categories menu
function GMUI.buildItemCategoriesMenu()
    local categories = {}
    
    if GMConfig.CardTypes and GMConfig.CardTypes.Item and GMConfig.CardTypes.Item.categories then
        -- Equipment category
        local equipment = GMConfig.CardTypes.Item.categories.Equipment
        if equipment and equipment.subCategories then
            local equipmentItems = {}
            for _, subCategory in ipairs(equipment.subCategories) do
                table.insert(equipmentItems, {
                    text = subCategory.name,
                    value = subCategory.value,
                    func = function()
                        GMUI.switchToTab(subCategory.index)
                    end
                })
            end
            
            table.insert(categories, {
                text = "Equipment",
                hasArrow = true,
                menuList = equipmentItems
            })
        end
        
        -- Weapons category
        local weapons = GMConfig.CardTypes.Item.categories.Weapons
        if weapons and weapons.subCategories then
            local weaponItems = {}
            for _, subCategory in ipairs(weapons.subCategories) do
                table.insert(weaponItems, {
                    text = subCategory.name,
                    value = subCategory.value,
                    func = function()
                        GMUI.switchToTab(subCategory.index)
                    end
                })
            end
            
            table.insert(categories, {
                text = "Weapons",
                hasArrow = true,
                menuList = weaponItems
            })
        end
        
        -- Misc category
        local misc = GMConfig.CardTypes.Item.categories.Misc
        if misc and misc.subCategories then
            local miscItems = {}
            for _, subCategory in ipairs(misc.subCategories) do
                table.insert(miscItems, {
                    text = subCategory.name,
                    value = subCategory.value,
                    func = function()
                        GMUI.switchToTab(subCategory.index)
                    end
                })
            end
            
            table.insert(categories, {
                text = "Misc",
                hasArrow = true,
                menuList = miscItems
            })
        end
    end
    
    return categories
end

-- Get main menu items (kept for backward compatibility)
function GMUI.getMainMenuItems()
    return {
        {
            text = "Creatures",
            func = function()
                GMUI.switchToTab(1)
                CloseDropDownMenus()
            end,
        },
        {
            text = "Objects",
            func = function()
                GMUI.switchToTab(2)
                CloseDropDownMenus()
            end,
        },
        {
            text = "Spells",
            hasArrow = true,
            menuList = "spell",
        },
        {
            text = "Items",
            hasArrow = true,
            menuList = "items",
        },
        {
            text = "Player Management",
            func = function()
                GMUI.switchToTab(6)
                CloseDropDownMenus()
            end,
        },
    }
end

-- Add spell submenu
function GMUI.addSpellSubmenu(info, level)
    wipe(info)
    info.text = "Spells"
    info.func = function()
        GMUI.switchToTab(3)
        CloseDropDownMenus()
    end
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)
    
    wipe(info)
    info.text = "Spell Visuals"
    info.func = function()
        GMUI.switchToTab(4)
        CloseDropDownMenus()
    end
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)
end

-- Add items submenu
function GMUI.addItemsSubmenu(info, level)
    wipe(info)
    info.text = "Search All Items"
    info.func = function()
        GMUI.switchToTab(5)
        CloseDropDownMenus()
    end
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)
    
    wipe(info)
    info.text = "Item Categories"
    info.hasArrow = true
    info.notCheckable = true
    info.menuList = "categories"
    UIDropDownMenu_AddButton(info, level)
end

-- Add equipment submenu
function GMUI.addEquipmentSubmenu(info, level)
    if GMConfig.CardTypes and GMConfig.CardTypes.Item and GMConfig.CardTypes.Item.categories then
        local equipment = GMConfig.CardTypes.Item.categories.Equipment
        if equipment and equipment.subCategories then
            for _, subCategory in ipairs(equipment.subCategories) do
                wipe(info)
                info.text = subCategory.name
                info.func = function()
                    GMUI.switchToTab(subCategory.index)
                    CloseDropDownMenus()
                end
                info.notCheckable = true
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
end

-- Add weapons submenu
function GMUI.addWeaponsSubmenu(info, level)
    if GMConfig.CardTypes and GMConfig.CardTypes.Item and GMConfig.CardTypes.Item.categories then
        local weapons = GMConfig.CardTypes.Item.categories.Weapons
        if weapons and weapons.subCategories then
            for _, subCategory in ipairs(weapons.subCategories) do
                wipe(info)
                info.text = subCategory.name
                info.func = function()
                    GMUI.switchToTab(subCategory.index)
                    CloseDropDownMenus()
                end
                info.notCheckable = true
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
end

-- Add misc submenu
function GMUI.addMiscSubmenu(info, level)
    if GMConfig.CardTypes and GMConfig.CardTypes.Item and GMConfig.CardTypes.Item.categories then
        local misc = GMConfig.CardTypes.Item.categories.Misc
        if misc and misc.subCategories then
            for _, subCategory in ipairs(misc.subCategories) do
                wipe(info)
                info.text = subCategory.name
                info.func = function()
                    GMUI.switchToTab(subCategory.index)
                    CloseDropDownMenus()
                end
                info.notCheckable = true
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
end



-- Show kofi frame

-- Initialize complete UI
function GMUI.initializeUI()
    -- Create main frame
    local mainFrame = GMUI.createMainFrame()
    
    -- Create content container instead of tab system
    local contentArea = GMUI.createContentContainer(mainFrame)
    
    -- Create category dropdown first
    GMUI.createCategoryDropdown(mainFrame)
    
    -- Create sort dropdown (positioned next to category dropdown)
    GMUI.createSortDropdown(mainFrame)
    
    -- Create search box
    GMUI.createSearchBox(mainFrame)
    
    if GMConfig.config.debug then
        -- Debug: UI initialized with content container
    end
    
    -- Create pagination controls
    GMUI.createPaginationControls(mainFrame)
    
    -- Set initial active tab
    GMData.activeTab = 1 -- Start with Creatures tab
    
    -- Hide main frame initially
    mainFrame:Hide()
    
    return mainFrame
end

-- Show/hide functions
function GMUI.show()
    if GMData.frames.mainFrame then
        GMData.frames.mainFrame:Show()
    end
end

function GMUI.hide()
    if GMData.frames.mainFrame then
        GMData.frames.mainFrame:Hide()
    end
end

-- Update pagination button states
function GMUI.updatePaginationButtons()
    if GMData.frames.prevButton then
        if GMData.currentOffset > 0 then
            GMData.frames.prevButton:Enable()
        else
            GMData.frames.prevButton:Disable()
        end
    end
    
    if GMData.frames.nextButton then
        if GMData.hasMoreData then
            GMData.frames.nextButton:Enable()
        else
            GMData.frames.nextButton:Disable()
        end
    end
end

-- Create styled card for items
function GMUI.createStyledCard(parent, index, size)
    local card = CreateStyledCard(parent, size, {
        texture = nil,
        quality = "common",
        count = nil,
        onClick = nil,
        onRightClick = nil
    })
    
    -- Add custom properties for GM system
    card.nameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.nameText:SetPoint("BOTTOM", card, "BOTTOM", 0, 5)
    card.nameText:SetWidth(size - 10)
    card.nameText:SetJustifyH("CENTER")
    
    return card
end

-- Update content for active tab
function GMUI.updateContentForActiveTab()
    
    if not GMData.activeTab then
        GMUtils.debug("No active tab set")
        return
    end
    
    -- Get the active content frame
    local activeFrame = GMUI.getOrCreateContentFrame(GMData.activeTab)
    
    if not activeFrame then
        GMUtils.debug("Could not get content frame for tab:", GMData.activeTab)
        return
    end
    
    -- Debug: Check frame visibility
    
    -- Clear existing cards
    GMUI.clearContentFrame(activeFrame)
    
    -- Determine data type based on active tab
    local dataType = GMUI.getDataTypeForTab(GMData.activeTab)
    
    if not dataType then
        GMUtils.debug("Unknown data type for tab:", GMData.activeTab)
        return
    end
    
    -- Get data from store
    local data = GMData.DataStore[dataType]
    
    -- Special debug for player data
    if dataType == "players" and data and GMConfig.config.debug then
        -- Debug: Player data available
    end
    
    if not data or #data == 0 then
        GMUtils.debug("No data available for:", dataType)
        -- Show empty state
        GMUI.showEmptyState(activeFrame, "No " .. dataType .. " found")
        return
    end
    
    -- Generate and display cards
    if _G.GMCards and _G.GMCards.generateCards then
        local cardType = GMUI.getCardTypeForDataType(dataType)
        local cards = _G.GMCards.generateCards(activeFrame, data, cardType)
        activeFrame.cards = cards
        
        -- Debug: Check if cards are visible
        if cards and #cards > 0 and GMConfig.config.debug then
            -- Debug: Cards visibility check
        end
    else
        GMUtils.debug("GMCards.generateCards not available")
    end
end

-- Clear content frame
function GMUI.clearContentFrame(frame)
    if not frame then return end
    
    -- Clear existing cards
    if frame.cards then
        for _, card in ipairs(frame.cards) do
            if card and card.Hide then
                card:Hide()
                card:SetParent(nil)
            end
        end
        wipe(frame.cards)
    end
    
    -- Clear any child frames
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        if child and child ~= frame then
            child:Hide()
            child:SetParent(nil)
        end
    end
end

-- Get data type for tab index
function GMUI.getDataTypeForTab(tabIndex)
    local dataTypeMap = {
        [1] = "npcs",           -- Creatures
        [2] = "gameobjects",    -- Objects
        [3] = "spells",         -- Spells
        [4] = "spellvisuals",   -- Spell Visuals
        [5] = "items",          -- Items (All)
        [6] = "players",        -- Player Management
    }
    
    -- Check if it's a subcategory tab
    if tabIndex >= 100 then
        return "items"  -- All subcategory tabs are items
    end
    
    return dataTypeMap[tabIndex]
end

-- Get card type for data type
function GMUI.getCardTypeForDataType(dataType)
    local cardTypeMap = {
        npcs = "NPC",
        gameobjects = "GameObject",
        spells = "Spell",
        spellvisuals = "SpellVisual",
        items = "Item",
        players = "Player"
    }
    
    return cardTypeMap[dataType] or "Item"
end

-- Show empty state
function GMUI.showEmptyState(frame, message)
    local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    emptyText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    emptyText:SetText(message or "No data available")
    emptyText:SetTextColor(0.5, 0.5, 0.5)
end

-- Get or create content frame for a tab
function GMUI.getOrCreateContentFrame(tabIndex)
    -- Ensure content area exists and is visible
    if not GMData.frames.contentArea then
        -- ERROR: Content area does not exist!
        return nil
    end
    
    -- Make sure content area is visible
    GMData.frames.contentArea:Show()
    
    -- Check if frame already exists
    if GMData.dynamicContentFrames[tabIndex] then
        -- Reusing existing content frame
        return GMData.dynamicContentFrames[tabIndex]
    end
    
    -- Create new content frame
    local contentFrame = CreateFrame("Frame", nil, GMData.frames.contentArea)
    contentFrame:SetAllPoints(GMData.frames.contentArea)
    contentFrame:Hide()
    
    -- Add debug background for visibility testing
    if GMConfig.config.debug then
        local bg = contentFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.1, 0.1, 0.1, 0.3) -- Slight tint to see the frame
    end
    
    -- Store in dynamic frames
    GMData.dynamicContentFrames[tabIndex] = contentFrame
    
    -- Created new content frame
    
    return contentFrame
end

-- Get category name for tab index
function GMUI.getCategoryNameForTab(tabIndex)
    -- Main categories
    local mainCategories = {
        [1] = "Creatures",
        [2] = "Objects", 
        [3] = "Spells",
        [4] = "Spell Visuals",
        [5] = "Items",
        [6] = "Player Management"
    }
    
    if mainCategories[tabIndex] then
        return mainCategories[tabIndex]
    end
    
    -- Check subcategories
    if GMConfig.CardTypes and GMConfig.CardTypes.Item and GMConfig.CardTypes.Item.categories then
        for categoryName, category in pairs(GMConfig.CardTypes.Item.categories) do
            if category.subCategories then
                for _, subCategory in ipairs(category.subCategories) do
                    if subCategory.index == tabIndex then
                        return "Items > " .. categoryName .. " > " .. subCategory.name
                    end
                end
            end
        end
    end
    
    return "Unknown Category"
end

-- Handle tab switching
function GMUI.switchToTab(tabIndex)
    
    -- Update active tab
    GMData.activeTab = tabIndex
    
    -- Update category indicator
    if GMData.frames.categoryIndicator then
        local categoryName = GMUI.getCategoryNameForTab(tabIndex)
        GMData.frames.categoryIndicator:SetText(categoryName)
        GMData.frames.categoryIndicator:Show()
    end
    
    -- Hide all existing content frames
    for idx, frame in pairs(GMData.dynamicContentFrames) do
        if frame then
            GMUI.clearContentFrame(frame)
            frame:Hide()
        end
    end
    
    -- Get or create content frame for this tab
    local activeFrame = GMUI.getOrCreateContentFrame(tabIndex)
    if activeFrame then
        activeFrame:Show()
        
        -- Ensure content area is visible
        if GMData.frames.contentArea then
            GMData.frames.contentArea:Show()
        end
        
        -- Ensure main frame is visible
        if GMData.frames.mainFrame then
            -- Main frame visibility check
        end
    else
        -- ERROR: Could not create content frame for tab
    end
    
    -- Request data for this tab
    GMUI.requestDataForTab(tabIndex)
end

-- Request data for specific tab
function GMUI.requestDataForTab(tabIndex)
    local offset = GMData.currentOffset or 0
    local pageSize = GMConfig.config.PAGE_SIZE or 15
    local sortOrder = GMData.sortOrder or "ASC"
    
    -- Determine handler based on tab
    if tabIndex == 1 then
        -- NPCs
        if GMData.currentSearchQuery and GMData.currentSearchQuery ~= "" then
            AIO.Handle("GameMasterSystem", "searchNPCData", GMData.currentSearchQuery, offset, pageSize, sortOrder)
        else
            AIO.Handle("GameMasterSystem", "getNPCData", offset, pageSize, sortOrder)
        end
    elseif tabIndex == 2 then
        -- GameObjects
        if GMData.currentSearchQuery and GMData.currentSearchQuery ~= "" then
            AIO.Handle("GameMasterSystem", "searchGameObjectData", GMData.currentSearchQuery, offset, pageSize, sortOrder)
        else
            AIO.Handle("GameMasterSystem", "getGameObjectData", offset, pageSize, sortOrder)
        end
    elseif tabIndex == 3 then
        -- Spells
        if GMData.currentSearchQuery and GMData.currentSearchQuery ~= "" then
            AIO.Handle("GameMasterSystem", "searchSpellData", GMData.currentSearchQuery, offset, pageSize, sortOrder)
        else
            AIO.Handle("GameMasterSystem", "getSpellData", offset, pageSize, sortOrder)
        end
    elseif tabIndex == 4 then
        -- Spell Visuals
        if GMData.currentSearchQuery and GMData.currentSearchQuery ~= "" then
            AIO.Handle("GameMasterSystem", "searchSpellVisualData", GMData.currentSearchQuery, offset, pageSize, sortOrder)
        else
            AIO.Handle("GameMasterSystem", "getSpellVisualData", offset, pageSize, sortOrder)
        end
    elseif tabIndex == 5 then
        -- Items (All)
        if GMData.currentSearchQuery and GMData.currentSearchQuery ~= "" then
            AIO.Handle("GameMasterSystem", "searchItemData", GMData.currentSearchQuery, offset, pageSize, sortOrder)
        else
            AIO.Handle("GameMasterSystem", "getItemData", offset, pageSize, sortOrder)
        end
    elseif tabIndex == 6 then
        -- Player Management
        if GMData.currentSearchQuery and GMData.currentSearchQuery ~= "" then
            AIO.Handle("GameMasterSystem", "searchPlayerData", GMData.currentSearchQuery, offset, pageSize, sortOrder)
        else
            AIO.Handle("GameMasterSystem", "getPlayerData", offset, pageSize, sortOrder)
        end
    elseif tabIndex >= 100 then
        -- Item subcategory - need to find inventory type
        local inventoryType = GMUI.getInventoryTypeForTab(tabIndex)
        if inventoryType then
            if GMData.currentSearchQuery and GMData.currentSearchQuery ~= "" then
                AIO.Handle("GameMasterSystem", "searchItemData", GMData.currentSearchQuery, offset, pageSize, sortOrder, inventoryType)
            else
                AIO.Handle("GameMasterSystem", "getItemData", offset, pageSize, sortOrder, inventoryType)
            end
        end
    end
end

-- Get inventory type for subcategory tab
function GMUI.getInventoryTypeForTab(tabIndex)
    -- Check all categories for matching tab index
    if GMConfig.CardTypes and GMConfig.CardTypes.Item and GMConfig.CardTypes.Item.categories then
        for categoryName, category in pairs(GMConfig.CardTypes.Item.categories) do
            if category.subCategories then
                for _, subCategory in ipairs(category.subCategories) do
                    if subCategory.index == tabIndex then
                        -- The config uses 'value' for the inventory type/class
                        return subCategory.value
                    end
                end
            end
        end
    end
    return nil
end

-- UI module loaded