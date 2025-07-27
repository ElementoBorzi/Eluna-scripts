local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    return -- Exit if on server
end

-- Get the shared namespace
local GameMasterSystem = _G.GameMasterSystem
if not GameMasterSystem then
    print("[ERROR] GameMasterSystem namespace not found! Check load order.")
    return
end

-- Get module references
local GMMenus = _G.GMMenus
if not GMMenus then
    print("[ERROR] GMMenus not found! Check load order.")
    return
end

local GMConfig = _G.GMConfig
local GMUtils = _G.GMUtils

-- Item Selection Modal Module
local ItemSelection = {}
GMMenus.ItemSelection = ItemSelection

-- Local state
local itemSelectionModal = nil
local selectedItems = {}
local targetPlayerName = nil
local currentItemData = {}

-- Helper function to get safe item icon
local function GetItemIconSafe(itemId)
    local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemId)
    return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Create the item selection modal dialog
function ItemSelection.createDialog(playerName)
    -- Store target player name
    targetPlayerName = playerName
    selectedItems = {}
    
    -- Initialize filters
    itemSelectionModal = itemSelectionModal or {}
    itemSelectionModal.currentCategory = "all"
    itemSelectionModal.qualityFilters = {0, 1, 2, 3, 4, 5}
    
    -- Create modal dialog
    local options = {
        title = "Select Items for " .. playerName,
        width = 860,  -- Increased to accommodate 10 columns
        height = 600,
        closeOnEscape = true,
        buttons = {
            {
                text = "Cancel",
                callback = function()
                    if itemSelectionModal then
                        itemSelectionModal:Hide()
                    end
                end
            },
            {
                text = "Give Items",
                callback = function()
                    ItemSelection.confirmGiveItems()
                end
            }
        }
    }
    
    itemSelectionModal = CreateStyledDialog(options)
    
    -- Create custom content area within the dialog
    local content = CreateFrame("Frame", nil, itemSelectionModal)
    content:SetPoint("TOPLEFT", itemSelectionModal, "TOPLEFT", 10, -40)
    content:SetPoint("BOTTOMRIGHT", itemSelectionModal, "BOTTOMRIGHT", -10, 50)
    
    -- Enable mouse and prevent click-through to stop modal from closing
    content:EnableMouse(true)
    content:SetScript("OnMouseDown", function(self, button)
        -- Stop event propagation - prevents closing when clicking inside
    end)
    
    -- Create search box at top
    local searchBox = CreateStyledSearchBox(content, 300, "Search items...", function(text)
        ItemSelection.filterItems(text)
    end)
    searchBox:SetPoint("TOP", content, "TOP", 0, -40)
    itemSelectionModal.searchBox = searchBox
    
    -- Item count label
    local itemCountLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemCountLabel:SetPoint("TOP", searchBox, "BOTTOM", 0, -5)
    itemCountLabel:SetText("Showing 0 items")
    itemCountLabel:SetTextColor(0.7, 0.7, 0.7)
    itemSelectionModal.itemCountLabel = itemCountLabel
    
    -- Create category dropdown
    local categoryLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -95)
    categoryLabel:SetText("Category:")
    categoryLabel:SetTextColor(0.8, 0.8, 0.8)
    
    local categoryItems = {
        { text = "All Items", value = "all" },
        { text = "Weapons", value = "weapon" },
        { text = "Armor", value = "armor" },
        { text = "Consumables", value = "consumable" },
        { text = "Trade Goods", value = "trade" },
        { text = "Quest Items", value = "quest" },
        { text = "Gems", value = "gem" },
        { text = "Miscellaneous", value = "misc" }
    }
    
    local categoryDropdown = CreateFullyStyledDropdown(
        content,
        150,
        categoryItems,
        "All Items",
        function(value)
            ItemSelection.filterByCategory(value)
        end
    )
    categoryDropdown:SetPoint("LEFT", categoryLabel, "RIGHT", 10, 0)
    itemSelectionModal.categoryDropdown = categoryDropdown
    
    -- Create quality filter toggles
    local qualityLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    qualityLabel:SetPoint("LEFT", categoryDropdown, "RIGHT", 30, 0)
    qualityLabel:SetText("Quality:")
    qualityLabel:SetTextColor(0.8, 0.8, 0.8)
    
    local qualityToggles = {}
    local qualityTypes = {
        { name = "Poor", color = UISTYLE_COLORS.Poor },
        { name = "Common", color = UISTYLE_COLORS.Common },
        { name = "Uncommon", color = UISTYLE_COLORS.Uncommon },
        { name = "Rare", color = UISTYLE_COLORS.Rare },
        { name = "Epic", color = UISTYLE_COLORS.Epic },
        { name = "Legendary", color = UISTYLE_COLORS.Legendary }
    }
    
    local xOffset = 0
    for i, quality in ipairs(qualityTypes) do
        local toggle = CreateQualityToggle(content, quality.color, 16)
        toggle:SetPoint("LEFT", qualityLabel, "RIGHT", 10 + xOffset, 0)
        toggle:SetChecked(true)
        toggle:SetScript("OnClick", function(self)
            -- Toggle the state first
            self:SetChecked(not self:GetChecked())
            -- Then update the filter
            ItemSelection.updateQualityFilter()
        end)
        toggle.qualityIndex = i - 1  -- WoW quality indices start at 0
        -- Add tooltip
        toggle:SetTooltip(quality.name, "Click to toggle " .. quality.name .. " quality items")
        qualityToggles[i] = toggle
        xOffset = xOffset + 20
    end
    itemSelectionModal.qualityToggles = qualityToggles
    
    -- Create scrollable item grid
    local gridContainer = CreateStyledFrame(content, UISTYLE_COLORS.OptionBg)
    gridContainer:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -135)
    gridContainer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 100)
    
    -- Enable mouse to prevent click-through
    gridContainer:EnableMouse(true)
    gridContainer:SetScript("OnMouseDown", function(self, button)
        -- Stop event propagation
    end)
    
    local scrollContainer, scrollContent, scrollBar, updateScroll = CreateScrollableFrame(
        gridContainer,
        gridContainer:GetWidth() - 4,
        gridContainer:GetHeight() - 4
    )
    scrollContainer:SetPoint("TOPLEFT", 2, -2)
    
    itemSelectionModal.scrollContent = scrollContent
    itemSelectionModal.updateScroll = updateScroll
    itemSelectionModal.itemCards = {}
    
    -- Enable mouse on scroll content to prevent click-through
    scrollContent:EnableMouse(true)
    scrollContent:SetScript("OnMouseDown", function(self, button)
        -- Stop event propagation
    end)
    
    -- Create quantity controls at bottom
    local quantityFrame = CreateStyledFrame(content, UISTYLE_COLORS.SectionBg)
    quantityFrame:SetHeight(80)
    quantityFrame:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 10, 10)
    quantityFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 10)
    
    -- Enable mouse to prevent click-through
    quantityFrame:EnableMouse(true)
    quantityFrame:SetScript("OnMouseDown", function(self, button)
        -- Stop event propagation
    end)
    
    -- Selected items display
    local selectedLabel = quantityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedLabel:SetPoint("TOPLEFT", quantityFrame, "TOPLEFT", 10, -10)
    selectedLabel:SetText("Selected: 0 items")
    itemSelectionModal.selectedLabel = selectedLabel
    
    -- Unselect All button
    local unselectAllBtn = CreateStyledButton(quantityFrame, "Unselect All", 80, 20)
    unselectAllBtn:SetPoint("LEFT", selectedLabel, "RIGHT", 20, 0)
    unselectAllBtn:SetScript("OnClick", function()
        ItemSelection.unselectAllItems()
    end)
    itemSelectionModal.unselectAllBtn = unselectAllBtn
    
    -- Select All button
    local selectAllBtn = CreateStyledButton(quantityFrame, "Select All", 70, 20)
    selectAllBtn:SetPoint("LEFT", unselectAllBtn, "RIGHT", 10, 0)
    selectAllBtn:SetScript("OnClick", function()
        ItemSelection.selectAllItems()
    end)
    itemSelectionModal.selectAllBtn = selectAllBtn
    
    -- Quantity controls
    local qtyLabel = quantityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    qtyLabel:SetPoint("TOPLEFT", quantityFrame, "TOPLEFT", 10, -35)
    qtyLabel:SetText("Quantity:")
    
    -- Quick quantity buttons
    local qtyButtons = { 1, 5, 10, 20, 50 }  -- Added 50
    local btnXOffset = 0
    for _, qty in ipairs(qtyButtons) do
        local btn = CreateStyledButton(quantityFrame, tostring(qty), 40, 24)
        btn:SetPoint("LEFT", qtyLabel, "RIGHT", 10 + btnXOffset, 0)
        btn:SetScript("OnClick", function()
            if itemSelectionModal.quantitySlider and itemSelectionModal.quantitySlider.slider then
                itemSelectionModal.quantitySlider.slider:SetValue(qty)
            end
            itemSelectionModal.currentQuantity = qty
        end)
        btnXOffset = btnXOffset + 45
    end
    
    -- Max stack button
    local maxBtn = CreateStyledButton(quantityFrame, "Max", 50, 24)
    maxBtn:SetPoint("LEFT", qtyLabel, "RIGHT", 10 + btnXOffset, 0)
    maxBtn:SetScript("OnClick", function()
        -- Set to max stack of selected item
        if itemSelectionModal.selectedItem then
            local maxStack = math.min(itemSelectionModal.selectedItem.maxStack or 100, 100)  -- Cap at 100
            if itemSelectionModal.quantitySlider and itemSelectionModal.quantitySlider.slider then
                itemSelectionModal.quantitySlider.slider:SetValue(maxStack)
            end
            itemSelectionModal.currentQuantity = maxStack
        else
            -- Default to max slider value if no item selected
            if itemSelectionModal.quantitySlider and itemSelectionModal.quantitySlider.slider then
                itemSelectionModal.quantitySlider.slider:SetValue(100)
            end
            itemSelectionModal.currentQuantity = 100
        end
    end)
    
    -- Quantity slider
    local quantitySlider = CreateStyledSliderWithRange(
        quantityFrame,
        200,
        20,
        1,
        100,  -- Increased max value from 20 to 100
        1,
        1,
        ""
    )
    quantitySlider:SetPoint("LEFT", maxBtn, "RIGHT", 20, 0)
    itemSelectionModal.quantitySlider = quantitySlider
    itemSelectionModal.currentQuantity = 1  -- Store quantity separately as fallback
    
    -- Ensure slider is enabled
    if quantitySlider.slider then
        quantitySlider.slider:EnableMouse(true)
        
        -- Debug: verify slider is created properly
        print("[GMMenus] Quantity slider created. Min:", 1, "Max:", 100, "Current:", quantitySlider.slider:GetValue())
    end
    
    -- Add onChange handler
    quantitySlider:SetOnValueChanged(function(value)
        itemSelectionModal.currentQuantity = value
        print("[GMMenus] Quantity changed to:", value)
    end)
    
    -- Request initial item data
    ItemSelection.requestItemsForModal()
    
    -- Show the modal
    itemSelectionModal:Show()
    
    return itemSelectionModal
end

-- Helper function to create item cards in the modal
function ItemSelection.createModalItemCard(parent, itemData, index)
    -- Convert numeric quality to string
    local qualityNames = {
        [0] = "Poor",
        [1] = "Common", 
        [2] = "Uncommon",
        [3] = "Rare",
        [4] = "Epic",
        [5] = "Legendary",
        [6] = "Artifact",
        [7] = "Heirloom"
    }
    
    local qualityName = qualityNames[itemData.quality] or "Common"
    
    local card = CreateStyledCard(parent, 64, {
        texture = GetItemIconSafe(itemData.entry),
        count = 1,
        quality = qualityName,
        link = itemData.link,
        onClick = function(self)
            -- Check if we're in mail selection mode
            if itemSelectionModal and itemSelectionModal.callback and not itemSelectionModal.isMultiSelect then
                ItemSelection.selectItemCardForMail(self, itemData)
            else
                ItemSelection.selectItemCard(self, itemData)
            end
        end
    })
    
    -- Position in grid (10 columns)
    local col = (index - 1) % 10
    local row = math.floor((index - 1) / 10)
    -- Calculate centered position
    -- Total grid width = 10 cards * 70 pixels = 700 pixels
    -- Parent width is approximately 840 pixels (860 modal - 20 padding)
    -- Center offset = (840 - 700) / 2 = 70 pixels
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 70 + (col * 70), -10 - (row * 70))
    
    -- Add selection overlay
    card.selectionOverlay = card:CreateTexture(nil, "OVERLAY")
    card.selectionOverlay:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    card.selectionOverlay:SetBlendMode("ADD")
    card.selectionOverlay:SetAlpha(0.3)
    card.selectionOverlay:SetAllPoints()
    card.selectionOverlay:Hide()
    
    card.itemData = itemData
    card.isSelected = false
    
    return card
end

-- Select/deselect item card
function ItemSelection.selectItemCard(card, itemData)
    if card.isSelected then
        -- Deselect
        card.isSelected = false
        card.selectionOverlay:Hide()
        selectedItems[itemData.entry] = nil
    else
        -- Select
        card.isSelected = true
        card.selectionOverlay:Show()
        selectedItems[itemData.entry] = {
            entry = itemData.entry,
            name = itemData.name,
            icon = GetItemIconSafe(itemData.entry),
            quality = itemData.quality,
            maxStack = itemData.maxStack or 20
        }
        
        -- Update selected item for quantity controls
        itemSelectionModal.selectedItem = selectedItems[itemData.entry]
        
        -- Update max stack for slider
        local maxStack = math.min(itemData.maxStack or 100, 100)  -- Cap at 100
        if itemSelectionModal.quantitySlider and itemSelectionModal.quantitySlider.slider then
            itemSelectionModal.quantitySlider.slider:SetMinMaxValues(1, maxStack)
        end
    end
    
    -- Update selected count
    local count = 0
    for _ in pairs(selectedItems) do
        count = count + 1
    end
    itemSelectionModal.selectedLabel:SetText("Selected: " .. count .. " items")
end

-- Filter items by search text
function ItemSelection.filterItems(searchText)
    -- Request filtered data from server (just use the main request function)
    ItemSelection.requestItemsForModal()
end

-- Filter by category
function ItemSelection.filterByCategory(category)
    itemSelectionModal.currentCategory = category
    ItemSelection.requestItemsForModal()
end

-- Update quality filter
function ItemSelection.updateQualityFilter()
    local qualityFilters = {}
    for i, toggle in ipairs(itemSelectionModal.qualityToggles) do
        if toggle:GetChecked() then
            table.insert(qualityFilters, toggle.qualityIndex)
        end
    end
    itemSelectionModal.qualityFilters = qualityFilters
    
    -- Debug output
    print("[GMMenus] Quality filters updated. Active qualities:", table.concat(qualityFilters, ", "))
    
    ItemSelection.requestItemsForModal()
end

-- Request items from server
function ItemSelection.requestItemsForModal()
    local searchText = ""
    if itemSelectionModal.searchBox and itemSelectionModal.searchBox.editBox then
        searchText = itemSelectionModal.searchBox.editBox:GetText() or ""
    end
    local category = itemSelectionModal.currentCategory or "all"
    local qualities = itemSelectionModal.qualityFilters or {0, 1, 2, 3, 4, 5}
    
    -- Debug output
    print("[GMMenus] Requesting items - Search:", searchText, "Category:", category, "Qualities:", #qualities)
    
    -- Convert qualities array to comma-separated string for AIO
    local qualitiesStr = table.concat(qualities, ",")
    
    AIO.Handle("GameMasterSystem", "requestModalItems", searchText, category, qualitiesStr)
end

-- Update modal with item data
function ItemSelection.updateModalItems(items)
    print("[GMMenus] Updating modal with", #items, "items")
    
    -- Clear existing cards
    for _, card in ipairs(itemSelectionModal.itemCards) do
        card:Hide()
        card:SetParent(nil)
    end
    wipe(itemSelectionModal.itemCards)
    
    -- Update item count display
    if itemSelectionModal.itemCountLabel then
        itemSelectionModal.itemCountLabel:SetText("Showing " .. #items .. " items")
    end
    
    -- Create new cards
    currentItemData = items
    for i, itemData in ipairs(items) do
        local card = ItemSelection.createModalItemCard(itemSelectionModal.scrollContent, itemData, i)
        table.insert(itemSelectionModal.itemCards, card)
    end
    
    -- Update scroll content height
    local rows = math.ceil(#items / 10)
    itemSelectionModal.scrollContent:SetHeight(math.max(400, rows * 70 + 20))
    itemSelectionModal.updateScroll()
end

-- Unselect all items
function ItemSelection.unselectAllItems()
    -- Clear selected items
    wipe(selectedItems)
    
    -- Update all card visual states
    if itemSelectionModal.itemCards then
        for _, card in ipairs(itemSelectionModal.itemCards) do
            if card.isSelected then
                card.isSelected = false
                card.selectionOverlay:Hide()
            end
        end
    end
    
    -- Update selected count
    itemSelectionModal.selectedLabel:SetText("Selected: 0 items")
    
    -- Clear selected item for quantity controls
    itemSelectionModal.selectedItem = nil
end

-- Select all visible items
function ItemSelection.selectAllItems()
    -- Clear first to start fresh
    wipe(selectedItems)
    
    -- Select all visible cards
    if itemSelectionModal.itemCards and currentItemData then
        for i, card in ipairs(itemSelectionModal.itemCards) do
            if card:IsVisible() and currentItemData[i] then
                local itemData = currentItemData[i]
                card.isSelected = true
                card.selectionOverlay:Show()
                selectedItems[itemData.entry] = {
                    entry = itemData.entry,
                    name = itemData.name,
                    icon = GetItemIconSafe(itemData.entry),
                    quality = itemData.quality,
                    maxStack = itemData.maxStack or 20
                }
            end
        end
    end
    
    -- Update selected count
    local count = 0
    for _ in pairs(selectedItems) do
        count = count + 1
    end
    itemSelectionModal.selectedLabel:SetText("Selected: " .. count .. " items")
    
    -- Set first item as selected for quantity controls
    for _, itemData in pairs(selectedItems) do
        itemSelectionModal.selectedItem = itemData
        break
    end
end

-- Confirm giving items
function ItemSelection.confirmGiveItems()
    local quantity = itemSelectionModal.currentQuantity or 1
    
    for itemId, itemData in pairs(selectedItems) do
        AIO.Handle("GameMasterSystem", "givePlayerItem", targetPlayerName, itemId, quantity)
    end
    
    -- Show success message
    print(string.format("Gave %d items to %s", quantity, targetPlayerName))
    
    -- Close modal
    if itemSelectionModal then
        itemSelectionModal:Hide()
    end
end

-- Export update function for server responses
GMMenus.updateModalItems = function(items)
    if ItemSelection.updateModalItems then
        ItemSelection.updateModalItems(items)
    end
end

-- New function to show item selection for mail attachments
function ItemSelection.ShowItemSelectionDialog(callback)
    -- Clear previous state
    selectedItems = {}
    targetPlayerName = nil
    
    -- Store the callback function
    itemSelectionModal = itemSelectionModal or {}
    itemSelectionModal.callback = callback
    
    -- Initialize filters
    itemSelectionModal.currentCategory = "all"
    itemSelectionModal.qualityFilters = {0, 1, 2, 3, 4, 5}
    
    -- Create modal dialog with modified options
    local options = {
        title = "Select Item to Attach",
        width = 860,
        height = 600,
        closeOnEscape = true,
        buttons = {
            {
                text = "Cancel",
                callback = function()
                    if itemSelectionModal then
                        itemSelectionModal:Hide()
                    end
                end
            },
            {
                text = "Select Item",
                callback = function()
                    ItemSelection.confirmSelectItem()
                end
            }
        }
    }
    
    itemSelectionModal = CreateStyledDialog(options)
    
    -- Create custom content area within the dialog
    local content = CreateFrame("Frame", nil, itemSelectionModal)
    content:SetPoint("TOPLEFT", itemSelectionModal, "TOPLEFT", 10, -40)
    content:SetPoint("BOTTOMRIGHT", itemSelectionModal, "BOTTOMRIGHT", -10, 50)
    
    -- Enable mouse and prevent click-through to stop modal from closing
    content:EnableMouse(true)
    content:SetScript("OnMouseDown", function(self, button)
        -- Stop event propagation - prevents closing when clicking inside
    end)
    
    -- Create search box at top
    local searchBox = CreateStyledSearchBox(content, 300, "Search items...", function(text)
        ItemSelection.filterItems(text)
    end)
    searchBox:SetPoint("TOP", content, "TOP", 0, -40)
    itemSelectionModal.searchBox = searchBox
    
    -- Item count label
    local itemCountLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemCountLabel:SetPoint("TOP", searchBox, "BOTTOM", 0, -5)
    itemCountLabel:SetText("Showing 0 items")
    itemCountLabel:SetTextColor(0.7, 0.7, 0.7)
    itemSelectionModal.itemCountLabel = itemCountLabel
    
    -- Create category dropdown
    local categoryLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -95)
    categoryLabel:SetText("Category:")
    categoryLabel:SetTextColor(0.8, 0.8, 0.8)
    
    local categoryItems = {
        { text = "All Items", value = "all" },
        { text = "Weapons", value = "weapon" },
        { text = "Armor", value = "armor" },
        { text = "Consumables", value = "consumable" },
        { text = "Trade Goods", value = "trade" },
        { text = "Quest Items", value = "quest" },
        { text = "Gems", value = "gem" },
        { text = "Miscellaneous", value = "misc" }
    }
    
    local categoryDropdown = CreateFullyStyledDropdown(
        content,
        150,
        categoryItems,
        "All Items",
        function(value)
            ItemSelection.filterByCategory(value)
        end
    )
    categoryDropdown:SetPoint("LEFT", categoryLabel, "RIGHT", 10, 0)
    itemSelectionModal.categoryDropdown = categoryDropdown
    
    -- Create quality filter toggles
    local qualityLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    qualityLabel:SetPoint("LEFT", categoryDropdown, "RIGHT", 30, 0)
    qualityLabel:SetText("Quality:")
    qualityLabel:SetTextColor(0.8, 0.8, 0.8)
    
    local qualityToggles = {}
    local qualityTypes = {
        { name = "Poor", color = UISTYLE_COLORS.Poor },
        { name = "Common", color = UISTYLE_COLORS.Common },
        { name = "Uncommon", color = UISTYLE_COLORS.Uncommon },
        { name = "Rare", color = UISTYLE_COLORS.Rare },
        { name = "Epic", color = UISTYLE_COLORS.Epic },
        { name = "Legendary", color = UISTYLE_COLORS.Legendary }
    }
    
    local xOffset = 0
    for i, quality in ipairs(qualityTypes) do
        local toggle = CreateQualityToggle(content, quality.color, 16)
        toggle:SetPoint("LEFT", qualityLabel, "RIGHT", 10 + xOffset, 0)
        toggle:SetChecked(true)
        toggle:SetScript("OnClick", function(self)
            -- Toggle the state first
            self:SetChecked(not self:GetChecked())
            -- Then update the filter
            ItemSelection.updateQualityFilter()
        end)
        toggle.qualityIndex = i - 1  -- WoW quality indices start at 0
        -- Add tooltip
        toggle:SetTooltip(quality.name, "Click to toggle " .. quality.name .. " quality items")
        qualityToggles[i] = toggle
        xOffset = xOffset + 20
    end
    itemSelectionModal.qualityToggles = qualityToggles
    
    -- Create scrollable item grid
    local gridContainer = CreateStyledFrame(content, UISTYLE_COLORS.OptionBg)
    gridContainer:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -135)
    gridContainer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 30)
    
    -- Enable mouse to prevent click-through
    gridContainer:EnableMouse(true)
    gridContainer:SetScript("OnMouseDown", function(self, button)
        -- Stop event propagation
    end)
    
    local scrollContainer, scrollContent, scrollBar, updateScroll = CreateScrollableFrame(
        gridContainer,
        gridContainer:GetWidth() - 4,
        gridContainer:GetHeight() - 4
    )
    scrollContainer:SetPoint("TOPLEFT", 2, -2)
    
    itemSelectionModal.scrollContent = scrollContent
    itemSelectionModal.updateScroll = updateScroll
    itemSelectionModal.itemCards = {}
    
    -- Enable mouse on scroll content to prevent click-through
    scrollContent:EnableMouse(true)
    scrollContent:SetScript("OnMouseDown", function(self, button)
        -- Stop event propagation
    end)
    
    -- Selected item info at bottom
    local selectedInfo = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedInfo:SetPoint("BOTTOM", content, "BOTTOM", 0, 10)
    selectedInfo:SetText("Click an item to select it")
    selectedInfo:SetTextColor(0.7, 0.7, 0.7)
    itemSelectionModal.selectedInfo = selectedInfo
    
    -- Also create selectedLabel for compatibility
    itemSelectionModal.selectedLabel = selectedInfo
    
    -- Initialize other required fields to prevent nil errors
    itemSelectionModal.unselectAllBtn = nil  -- Not needed for single selection
    itemSelectionModal.selectAllBtn = nil    -- Not needed for single selection
    itemSelectionModal.quantitySlider = nil  -- Not needed for mail attachments
    itemSelectionModal.currentQuantity = 1   -- Default quantity
    
    -- Request initial item data
    ItemSelection.requestItemsForModal()
    
    -- Show the modal
    itemSelectionModal:Show()
    
    return itemSelectionModal
end

-- Confirm selected item for mail attachment
function ItemSelection.confirmSelectItem()
    -- Get the first (and only) selected item
    local selectedItem = nil
    for _, itemData in pairs(selectedItems) do
        selectedItem = itemData
        break
    end
    
    if selectedItem and itemSelectionModal.callback then
        -- Call the callback with the selected item
        itemSelectionModal.callback(selectedItem)
    end
    
    -- Close modal
    if itemSelectionModal then
        itemSelectionModal:Hide()
    end
end

-- Modified select function for single selection mode
function ItemSelection.selectItemCardForMail(card, itemData)
    -- Clear all previous selections
    for _, c in ipairs(itemSelectionModal.itemCards) do
        if c.isSelected then
            c.isSelected = false
            c.selectionOverlay:Hide()
        end
    end
    wipe(selectedItems)
    
    -- Select this item
    card.isSelected = true
    card.selectionOverlay:Show()
    selectedItems[itemData.entry] = {
        entry = itemData.entry,
        name = itemData.name,
        icon = GetItemIconSafe(itemData.entry),
        quality = itemData.quality,
        maxStack = itemData.maxStack or 20
    }
    
    -- Update selected info and selectedLabel
    if itemSelectionModal.selectedInfo then
        itemSelectionModal.selectedInfo:SetText("Selected: " .. itemData.name)
        itemSelectionModal.selectedInfo:SetTextColor(1, 1, 1)
    end
    
    -- Also update selectedLabel if it exists (for compatibility)
    if itemSelectionModal.selectedLabel then
        itemSelectionModal.selectedLabel:SetText("Selected: " .. itemData.name)
    end
end

-- New function to show multi-select dialog for mail
function ItemSelection.ShowMultiSelectDialog(callback, maxItems)
    print("[ItemSelection] ShowMultiSelectDialog called with maxItems:", maxItems)
    
    -- Create the dialog first
    itemSelectionModal = ItemSelection.createDialog("Mail Attachments")
    
    -- THEN set up multi-select specific properties
    targetPlayerName = nil  -- No target player for mail
    selectedItems = {}  -- Clear selected items
    
    -- Store callback and max items AFTER dialog creation
    itemSelectionModal.callback = callback
    itemSelectionModal.maxItems = maxItems or 12
    itemSelectionModal.isMultiSelect = true
    print("[ItemSelection] isMultiSelect set to:", itemSelectionModal.isMultiSelect)
    print("[ItemSelection] Callback set:", callback ~= nil)
    
    -- Override the buttons
    if itemSelectionModal.buttons then
        -- Hide give items button
        if itemSelectionModal.buttons[2] then
            itemSelectionModal.buttons[2]:Hide()
        end
        
        -- Create new attach button
        local attachBtn = CreateStyledButton(itemSelectionModal, "Attach Selected", 120, 30)
        attachBtn:SetPoint("BOTTOMRIGHT", itemSelectionModal, "BOTTOMRIGHT", -20, 20)
        attachBtn:SetScript("OnClick", function()
            ItemSelection.confirmAttachItems()
        end)
    end
    
    -- Update title
    if itemSelectionModal.title then
        itemSelectionModal.title:SetText("Select Items to Attach (Max: " .. itemSelectionModal.maxItems .. ")")
    end
    
    return itemSelectionModal
end

-- Confirm attach items for mail
function ItemSelection.confirmAttachItems()
    -- Get selected items
    local itemList = {}
    local count = 0
    
    local selectedCount = 0
    for _ in pairs(selectedItems) do
        selectedCount = selectedCount + 1
    end
    print("[ItemSelection] confirmAttachItems called. selectedItems count:", selectedCount)
    
    -- Get quantity from slider
    local quantity = itemSelectionModal.currentQuantity or 1
    if itemSelectionModal.quantitySlider and itemSelectionModal.quantitySlider.slider then
        quantity = itemSelectionModal.quantitySlider.slider:GetValue() or 1
    end
    print("[ItemSelection] Using quantity:", quantity)
    
    for _, itemData in pairs(selectedItems) do
        if count < (itemSelectionModal.maxItems or 12) then
            print("[ItemSelection] Adding item to list:", itemData.entry, itemData.name, "x", quantity)
            -- Add the quantity to each item
            local itemWithQty = {}
            for k, v in pairs(itemData) do
                itemWithQty[k] = v
            end
            itemWithQty.count = quantity
            table.insert(itemList, itemWithQty)
            count = count + 1
        end
    end
    
    print("[ItemSelection] Total items to attach:", count)
    
    if itemSelectionModal.callback and count > 0 then
        print("[ItemSelection] Calling callback with items")
        itemSelectionModal.callback(itemList)
    elseif not itemSelectionModal.callback then
        print("[ItemSelection] ERROR: No callback found!")
    elseif count == 0 then
        print("[ItemSelection] ERROR: No items selected!")
    end
    
    -- Close modal
    if itemSelectionModal then
        itemSelectionModal:Hide()
    end
end

-- Override selectItemCard for multi-select mode
local originalSelectItemCard = ItemSelection.selectItemCard
ItemSelection.selectItemCard = function(card, itemData)
    print("[ItemSelection] selectItemCard called. isMultiSelect:", itemSelectionModal and itemSelectionModal.isMultiSelect or false)
    if itemSelectionModal and itemSelectionModal.isMultiSelect then
        -- Multi-select mode - don't clear previous selections
        if card.isSelected then
            -- Deselect
            print("[ItemSelection] Deselecting item:", itemData.entry)
            card.isSelected = false
            card.selectionOverlay:Hide()
            selectedItems[itemData.entry] = nil
        else
            -- Check max items
            local count = 0
            for _ in pairs(selectedItems) do
                count = count + 1
            end
            
            if count < (itemSelectionModal.maxItems or 12) then
                -- Select
                print("[ItemSelection] Selecting item:", itemData.entry, itemData.name)
                card.isSelected = true
                card.selectionOverlay:Show()
                selectedItems[itemData.entry] = {
                    entry = itemData.entry,
                    name = itemData.name,
                    icon = GetItemIconSafe(itemData.entry),
                    quality = itemData.quality,
                    maxStack = itemData.maxStack or 20
                }
            else
                CreateStyledToast("Maximum items selected!", 2, 0.5)
            end
        end
        
        -- Update selected count
        local count = 0
        for _ in pairs(selectedItems) do
            count = count + 1
        end
        
        if itemSelectionModal.selectedLabel then
            itemSelectionModal.selectedLabel:SetText("Selected: " .. count .. " / " .. (itemSelectionModal.maxItems or 12))
        end
    else
        -- Use original single-select behavior
        originalSelectItemCard(card, itemData)
    end
end

-- Export update function for server responses
GMMenus.updateModalItems = function(items)
    if ItemSelection.updateModalItems then
        ItemSelection.updateModalItems(items)
    end
end

-- Item selection module loaded