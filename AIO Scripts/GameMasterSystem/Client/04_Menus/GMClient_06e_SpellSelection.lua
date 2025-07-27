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

-- Spell Selection Modal Module
local SpellSelection = {}
GMMenus.SpellSelection = SpellSelection

-- Local state
local spellSelectionModal = nil
local selectedSpells = {}
local targetPlayerNameForSpell = nil
local currentSpellData = {}

-- Spell Search Module for better organization and reusability
local SpellSearchModule = {}

-- Default configuration constants
SpellSearchModule.DEFAULT_PAGE_SIZE = 50
SpellSearchModule.MIN_PAGE_SIZE = 10
SpellSearchModule.MAX_PAGE_SIZE = 500

-- Create pagination state with safe defaults
function SpellSearchModule.createModalState(castType)
    return {
        castType = castType,
        currentOffset = 0,
        pageSize = 50, -- Use literal value to avoid self-reference
        hasMoreData = false,
        totalSpells = 0
    }
end

-- Safely get pageSize with fallback
function SpellSearchModule.getValidPageSize(modalState)
    if not modalState then return 50 end
    local pageSize = modalState.pageSize or 50
    return math.max(10, math.min(500, pageSize))
end

-- Update modal state from server response
function SpellSearchModule.updateModalState(modalState, offset, pageSize, hasMoreData, totalCount)
    if not modalState then return end
    
    modalState.currentOffset = offset or 0
    modalState.hasMoreData = hasMoreData or false
    modalState.totalSpells = totalCount or 0
    
    -- Preserve pageSize if server doesn't provide it, otherwise use server value
    if pageSize then
        modalState.pageSize = pageSize
    end
    -- Ensure pageSize is never nil (fallback to default)
    modalState.pageSize = SpellSearchModule.getValidPageSize(modalState)
end

-- Handle search request with safe parameters
function SpellSearchModule.handleSearchRequest(modalState, searchText)
    if not modalState then return end
    
    modalState.currentOffset = 0
    local pageSize = SpellSearchModule.getValidPageSize(modalState)
    AIO.Handle("GameMasterSystem", "searchSpells", searchText or "", modalState.currentOffset, pageSize)
end

-- Handle pagination navigation
function SpellSearchModule.handlePreviousPage(modalState, searchText)
    if not modalState or modalState.currentOffset <= 0 then return end
    
    local pageSize = SpellSearchModule.getValidPageSize(modalState)
    modalState.currentOffset = math.max(0, modalState.currentOffset - pageSize)
    AIO.Handle("GameMasterSystem", "searchSpells", searchText or "", modalState.currentOffset, pageSize)
end

function SpellSearchModule.handleNextPage(modalState, searchText)
    if not modalState or not modalState.hasMoreData then return end
    
    local pageSize = SpellSearchModule.getValidPageSize(modalState)
    modalState.currentOffset = modalState.currentOffset + pageSize
    AIO.Handle("GameMasterSystem", "searchSpells", searchText or "", modalState.currentOffset, pageSize)
end

-- Calculate pagination info for display
function SpellSearchModule.getPaginationInfo(modalState)
    if not modalState then
        return { currentPage = 1, startNum = 0, endNum = 0, totalSpells = 0 }
    end
    
    local pageSize = SpellSearchModule.getValidPageSize(modalState)
    local currentPage = math.floor(modalState.currentOffset / pageSize) + 1
    local startNum = modalState.currentOffset + 1
    local endNum = math.min(modalState.currentOffset + pageSize, modalState.totalSpells)
    
    return {
        currentPage = currentPage,
        startNum = startNum,
        endNum = endNum,
        totalSpells = modalState.totalSpells
    }
end

-- Smart spell icon patterns based on common WoW spell ID ranges and patterns
local function getSmartSpellIcon(spellId)
    -- Convert to number for range checks
    local id = tonumber(spellId)
    if not id then return nil end
    
    -- Common spell icon patterns based on WoW 3.3.5 spell ranges
    local iconPatterns = {
        -- Paladin spells (Blessing, Seal, etc.)
        { min = 20100, max = 20500, icon = "Interface\\Icons\\Spell_Holy_SealOfMight" },
        { min = 48930, max = 48950, icon = "Interface\\Icons\\Spell_Holy_FistsOfFury" }, -- Blessings
        
        -- Priest spells (Power Word, Divine, etc.)
        { min = 48160, max = 48170, icon = "Interface\\Icons\\Spell_Holy_WordFortitude" }, -- Power Word
        { min = 48070, max = 48080, icon = "Interface\\Icons\\Spell_Holy_DivineSpirit" }, -- Divine Spirit
        
        -- Druid spells (Mark of the Wild, etc.)
        { min = 48460, max = 48480, icon = "Interface\\Icons\\Spell_Nature_Regeneration" }, -- Mark of the Wild
        
        -- Mage spells (Arcane, Fire, Frost)
        { min = 42890, max = 42920, icon = "Interface\\Icons\\Spell_Arcane_Blast" }, -- Arcane spells
        { min = 47610, max = 47650, icon = "Interface\\Icons\\Spell_Fire_Fireball" }, -- Fire spells
        { min = 42840, max = 42860, icon = "Interface\\Icons\\Spell_Frost_Frostbolt" }, -- Frost spells
        
        -- Warlock spells
        { min = 47860, max = 47890, icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt" }, -- Shadow Bolt
        { min = 47810, max = 47830, icon = "Interface\\Icons\\Spell_Fire_Immolation" }, -- Immolate
        
        -- Warrior spells
        { min = 47440, max = 47470, icon = "Interface\\Icons\\Ability_Warrior_Sunder" }, -- Sunder Armor
        { min = 47500, max = 47520, icon = "Interface\\Icons\\Ability_ThunderBolt" }, -- Thunder Clap
        
        -- Hunter spells
        { min = 49000, max = 49030, icon = "Interface\\Icons\\Ability_Hunter_AimedShot" }, -- Aimed Shot
        { min = 49050, max = 49080, icon = "Interface\\Icons\\Ability_Hunter_MultiShot" }, -- Multi-Shot
        
        -- Rogue spells
        { min = 48650, max = 48680, icon = "Interface\\Icons\\Ability_BackStab" }, -- Backstab
        { min = 48630, max = 48650, icon = "Interface\\Icons\\Ability_Rogue_Eviscerate" }, -- Eviscerate
        
        -- Shaman spells
        { min = 49270, max = 49290, icon = "Interface\\Icons\\Spell_Nature_Lightning" }, -- Lightning Bolt
        { min = 49230, max = 49250, icon = "Interface\\Icons\\Spell_Fire_Elemental_Totem" }, -- Earth Shock
    }
    
    -- Check if spell ID falls within any known pattern range
    for _, pattern in pairs(iconPatterns) do
        if id >= pattern.min and id <= pattern.max then
            return pattern.icon
        end
    end
    
    -- School-based fallbacks for unknown spells
    -- Use modulo to create some variety based on spell ID
    local mod = id % 10
    if mod >= 0 and mod <= 2 then
        return "Interface\\Icons\\Spell_Holy_Heal" -- Holy/Light magic
    elseif mod >= 3 and mod <= 4 then
        return "Interface\\Icons\\Spell_Fire_Fireball" -- Fire magic
    elseif mod >= 5 and mod <= 6 then
        return "Interface\\Icons\\Spell_Frost_Frostbolt" -- Frost/Ice magic
    elseif mod >= 7 and mod <= 8 then
        return "Interface\\Icons\\Spell_Nature_Lightning" -- Nature magic
    else
        return "Interface\\Icons\\Spell_Arcane_Blast" -- Arcane magic
    end
end

-- Real-time search implementation with debouncing (WoW 3.3.5 compatible)
local realtimeSearchFrame = nil
local realtimeSearchText = nil
local SEARCH_DELAY = 0.5 -- 500ms delay after user stops typing

-- Initialize search timer frame (WoW 3.3.5 compatible)
local function initializeSearchTimer()
    if not realtimeSearchFrame then
        realtimeSearchFrame = CreateFrame("Frame")
        realtimeSearchFrame:Hide()
        realtimeSearchFrame:SetScript("OnUpdate", function(self, elapsed)
            self.timeLeft = (self.timeLeft or 0) - elapsed
            if self.timeLeft <= 0 then
                self:Hide()
                -- Execute the search
                if realtimeSearchText and spellSelectionModal and spellSelectionModal:IsVisible() then
                    local currentText = ""
                    if spellSelectionModal.searchBox and spellSelectionModal.searchBox.editBox then
                        currentText = spellSelectionModal.searchBox.editBox:GetText() or ""
                    end
                    
                    -- Verify search text is still the same (user hasn't typed more)
                    if currentText == realtimeSearchText and realtimeSearchText ~= "" then
                        -- Trigger database search via SpellSearchModule
                        if GMConfig and GMConfig.config and GMConfig.config.debug then
                            print("[GMMenus] Real-time search executing for:", realtimeSearchText)
                        end
                        SpellSearchModule.handleSearchRequest(spellSelectionModal, realtimeSearchText)
                    end
                end
            end
        end)
    end
end

function SpellSelection.handleRealtimeSpellSearch(searchText)
    -- Initialize timer frame if needed
    initializeSearchTimer()
    
    -- Cancel previous timer by hiding the frame
    if realtimeSearchFrame then
        realtimeSearchFrame:Hide()
    end
    
    -- Handle empty search - show predefined spells immediately
    if not searchText or searchText == "" or string.len(searchText) == 0 then
        SpellSelection.filterSpells("")
        -- Update UI to show we're in predefined mode
        if spellSelectionModal.spellCountLabel then
            spellSelectionModal.spellCountLabel:SetText("Showing predefined spells")
        end
        return
    end
    
    -- For very short search terms, still show predefined spells filtered
    if string.len(searchText) < 2 then
        SpellSelection.filterSpells(searchText)
        if spellSelectionModal.spellCountLabel then
            spellSelectionModal.spellCountLabel:SetText("Filtering predefined spells...")
        end
        return
    end
    
    -- Show immediate feedback for longer search terms
    if spellSelectionModal.spellCountLabel then
        spellSelectionModal.spellCountLabel:SetText("Searching database...")
        spellSelectionModal.spellCountLabel:SetTextColor(1, 1, 0) -- Yellow while searching
    end
    
    -- Store search text and start timer for database search (debounced)
    realtimeSearchText = searchText
    realtimeSearchFrame.timeLeft = SEARCH_DELAY
    realtimeSearchFrame:Show()
end

-- Create the spell selection modal dialog
function SpellSelection.createDialog(playerName, castType)
    -- Store target player name and cast type
    targetPlayerNameForSpell = playerName
    selectedSpells = {}
    
    -- Initialize modal state using SpellSearchModule
    spellSelectionModal = spellSelectionModal or SpellSearchModule.createModalState(castType)
    
    -- Create modal dialog
    local options = {
        title = "Select Spell for " .. playerName,
        width = 700,
        height = 600, -- Increased height for pagination controls
        closeOnEscape = true,
        buttons = {
            {
                text = "Cancel",
                callback = function()
                    if spellSelectionModal then
                        spellSelectionModal:Hide()
                    end
                end
            },
            {
                text = "Cast Spell",
                callback = function()
                    SpellSelection.confirmCastSpell()
                end
            }
        }
    }
    
    spellSelectionModal = CreateStyledDialog(options)
    
    -- Create custom content area within the dialog
    local content = CreateFrame("Frame", nil, spellSelectionModal)
    content:SetPoint("TOPLEFT", spellSelectionModal, "TOPLEFT", 10, -40)
    content:SetPoint("BOTTOMRIGHT", spellSelectionModal, "BOTTOMRIGHT", -10, 50)
    
    -- Enable mouse and prevent click-through
    content:EnableMouse(true)
    content:SetScript("OnMouseDown", function(self, button)
        -- Stop event propagation
    end)
    
    -- Create search box with real-time search capability
    local searchBox = CreateStyledSearchBox(content, 300, "Search spells...", function(text)
        -- Real-time search with debouncing
        SpellSelection.handleRealtimeSpellSearch(text)
    end)
    searchBox:SetPoint("TOP", content, "TOP", 0, -20)
    spellSelectionModal.searchBox = searchBox
    
    -- Add "Show All Spells" button for database browsing
    local searchAllBtn = CreateStyledButton(content, "Browse All", 100, 24)
    searchAllBtn:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
    searchAllBtn:SetScript("OnClick", function()
        -- Clear search box and show all spells from database
        if searchBox.editBox then
            searchBox.editBox:SetText("")
        end
        -- Cancel any pending search timer
        if realtimeSearchFrame then
            realtimeSearchFrame:Hide()
        end
        -- Use SpellSearchModule to browse all spells
        SpellSearchModule.handleSearchRequest(spellSelectionModal, "")
    end)
    
    -- Spell count label
    local spellCountLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellCountLabel:SetPoint("TOP", searchBox, "BOTTOM", 0, -5)
    spellCountLabel:SetText("Showing 0 spells")
    spellCountLabel:SetTextColor(0.7, 0.7, 0.7)
    spellSelectionModal.spellCountLabel = spellCountLabel
    
    -- Create scrollable spell list
    local listContainer = CreateStyledFrame(content, UISTYLE_COLORS.OptionBg)
    listContainer:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -80)
    listContainer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 50) -- Leave room for pagination
    
    -- Enable mouse to prevent click-through
    listContainer:EnableMouse(true)
    listContainer:SetScript("OnMouseDown", function(self, button)
        -- Stop event propagation
    end)
    
    local scrollContainer, scrollContent, scrollBar, updateScroll = CreateScrollableFrame(
        listContainer,
        listContainer:GetWidth() - 4,
        listContainer:GetHeight() - 4
    )
    scrollContainer:SetPoint("TOPLEFT", 2, -2)
    
    spellSelectionModal.scrollContent = scrollContent
    spellSelectionModal.updateScroll = updateScroll
    spellSelectionModal.spellRows = {}
    
    -- Enable mouse on scroll content to prevent click-through
    scrollContent:EnableMouse(true)
    scrollContent:SetScript("OnMouseDown", function(self, button)
        -- Stop event propagation
    end)
    
    -- Add toggle buttons for spell source
    local predefinedBtn = CreateStyledButton(content, "Show Predefined", 100, 20)
    predefinedBtn:SetPoint("BOTTOMLEFT", listContainer, "TOPLEFT", 0, 5)
    predefinedBtn:SetScript("OnClick", function()
        spellSelectionModal.currentOffset = 0
        SpellSelection.loadPredefinedSpells(castType)
    end)
    
    local allSpellsBtn = CreateStyledButton(content, "Show All Spells", 100, 20)
    allSpellsBtn:SetPoint("LEFT", predefinedBtn, "RIGHT", 10, 0)
    allSpellsBtn:SetScript("OnClick", function()
        -- Use SpellSearchModule for consistent search handling
        SpellSearchModule.handleSearchRequest(spellSelectionModal, "")
    end)
    
    -- Add pagination controls
    local paginationFrame = CreateFrame("Frame", nil, content)
    paginationFrame:SetHeight(40)
    paginationFrame:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 10, 5)
    paginationFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -10, 5)
    
    -- Previous button
    local prevButton = CreateStyledButton(paginationFrame, "< Previous", 80, 24)
    prevButton:SetPoint("LEFT", paginationFrame, "LEFT", 0, 0)
    prevButton:SetScript("OnClick", function()
        local searchText = ""
        if spellSelectionModal.searchBox and spellSelectionModal.searchBox.editBox then
            searchText = spellSelectionModal.searchBox.editBox:GetText() or ""
        end
        SpellSearchModule.handlePreviousPage(spellSelectionModal, searchText)
    end)
    spellSelectionModal.prevButton = prevButton
    
    -- Page info
    local pageInfo = paginationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pageInfo:SetPoint("CENTER", paginationFrame, "CENTER", 0, 0)
    pageInfo:SetText("Page 1")
    spellSelectionModal.pageInfo = pageInfo
    
    -- Next button
    local nextButton = CreateStyledButton(paginationFrame, "Next >", 80, 24)
    nextButton:SetPoint("RIGHT", paginationFrame, "RIGHT", 0, 0)
    nextButton:SetScript("OnClick", function()
        local searchText = ""
        if spellSelectionModal.searchBox and spellSelectionModal.searchBox.editBox then
            searchText = spellSelectionModal.searchBox.editBox:GetText() or ""
        end
        SpellSearchModule.handleNextPage(spellSelectionModal, searchText)
    end)
    spellSelectionModal.nextButton = nextButton
    
    -- Load predefined spells based on type
    SpellSelection.loadPredefinedSpells(castType)
    
    -- Show the modal
    spellSelectionModal:Show()
    
    return spellSelectionModal
end

-- Load predefined spells
function SpellSelection.loadPredefinedSpells(castType)
    local spells = {}
    
    -- Add all spell categories
    for _, category in ipairs(GMConfig.SPELL_CATEGORIES) do
        for _, spell in ipairs(category.spells) do
            table.insert(spells, {
                spellId = spell.spellId,
                name = spell.name,
                icon = spell.icon,
                category = category.name
            })
        end
    end
    
    -- Reset pagination for predefined spells
    spellSelectionModal.currentOffset = 0
    spellSelectionModal.hasMoreData = false
    spellSelectionModal.totalSpells = #spells
    
    -- Hide pagination controls for predefined spells
    if spellSelectionModal.prevButton then
        spellSelectionModal.prevButton:Hide()
    end
    if spellSelectionModal.nextButton then
        spellSelectionModal.nextButton:Hide()
    end
    if spellSelectionModal.pageInfo then
        spellSelectionModal.pageInfo:Hide()
    end
    
    -- Update display
    SpellSelection.updateSpellList(spells)
end

-- Update spell list display
function SpellSelection.updateSpellList(spells)
    -- Clear existing rows
    for _, row in ipairs(spellSelectionModal.spellRows) do
        row:Hide()
        row:SetParent(nil)
    end
    wipe(spellSelectionModal.spellRows)
    
    -- Update count
    if spellSelectionModal.spellCountLabel then
        spellSelectionModal.spellCountLabel:SetText("Showing " .. #spells .. " spells")
    end
    
    -- Create spell rows
    currentSpellData = spells
    for i, spellData in ipairs(spells) do
        local row = SpellSelection.createSpellRow(spellSelectionModal.scrollContent, spellData, i)
        table.insert(spellSelectionModal.spellRows, row)
    end
    
    -- Update scroll content height
    spellSelectionModal.scrollContent:SetHeight(math.max(400, #spells * 35 + 10))
    spellSelectionModal.updateScroll()
end

-- Create a spell row
function SpellSelection.createSpellRow(parent, spellData, index)
    local row = CreateStyledFrame(parent, UISTYLE_COLORS.SectionBg)
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -5 - ((index - 1) * 35))
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -25, -5 - ((index - 1) * 35))
    
    -- Enable mouse for selection
    row:EnableMouse(true)
    
    -- Icon with enhanced resolution
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    
    -- Enhanced icon resolution with multiple fallback strategies
    local function resolveSpellIcon(spellId, fallbackIcon)
        -- Debug mode toggle (can be enabled/disabled as needed)
        local debugIcons = GMConfig and GMConfig.config and GMConfig.config.debug or false
        
        -- Strategy 1: Try GetSpellInfo API (more reliable than GetSpellTexture)
        -- GetSpellInfo returns: name, rank, icon, castTime, minRange, maxRange
        local name, rank, spellIcon = GetSpellInfo(spellId)
        if spellIcon and spellIcon ~= "" then
            if debugIcons then
                print("[GMMenus] GetSpellInfo success for spell", spellId, ":", name, "icon:", spellIcon)
            end
            return spellIcon
        else
            if debugIcons then
                print("[GMMenus] GetSpellInfo failed for spell", spellId, "- name:", name or "nil", "icon:", spellIcon or "nil")
            end
        end
        
        -- Strategy 1b: Fallback to GetSpellTexture API
        local spellTexture = GetSpellTexture(spellId)
        if spellTexture and spellTexture ~= "" then
            if debugIcons then
                print("[GMMenus] GetSpellTexture success for spell", spellId, ":", spellTexture)
            end
            return spellTexture
        else
            if debugIcons then
                print("[GMMenus] GetSpellTexture also failed for spell", spellId, "- returned:", spellTexture or "nil")
            end
        end
        
        -- Strategy 2: Use provided fallback icon (for predefined spells)
        if fallbackIcon and fallbackIcon ~= "" then
            if debugIcons then
                print("[GMMenus] Using fallback icon for spell", spellId, ":", fallbackIcon)
            end
            return fallbackIcon
        end
        
        -- Strategy 3: Smart icon patterns based on spell ID ranges
        local smartIcon = getSmartSpellIcon(spellId)
        if smartIcon then
            if debugIcons then
                print("[GMMenus] Using smart icon for spell", spellId, ":", smartIcon)
            end
            return smartIcon
        end
        
        -- Strategy 4: Final fallback
        if debugIcons then
            print("[GMMenus] Using question mark icon for spell", spellId)
        end
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    
    local resolvedIcon = resolveSpellIcon(spellData.spellId, spellData.icon)
    icon:SetTexture(resolvedIcon)
    
    -- Spell name
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    nameText:SetText(spellData.name)
    nameText:SetTextColor(1, 1, 1)
    
    -- Spell ID
    local idText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    idText:SetPoint("LEFT", nameText, "RIGHT", 10, 0)
    idText:SetText("(ID: " .. spellData.spellId .. ")")
    idText:SetTextColor(0.7, 0.7, 0.7)
    
    -- Category
    if spellData.category then
        local categoryText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        categoryText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        categoryText:SetText(spellData.category)
        categoryText:SetTextColor(0.6, 0.8, 1)
    end
    
    -- Selection highlight
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.3)
    
    -- Click handler
    row:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            -- Deselect all other rows
            for _, otherRow in ipairs(spellSelectionModal.spellRows) do
                if otherRow.selected then
                    otherRow.selected = false
                    otherRow:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                end
            end
            
            -- Select this row
            self.selected = true
            self:SetBackdropBorderColor(1, 0.8, 0, 1)
            
            -- Store selected spell
            selectedSpells = {spellData}
        end
    end)
    
    row.spellData = spellData
    
    return row
end

-- Filter spells by search text
function SpellSelection.filterSpells(searchText)
    if not searchText or searchText == "" then
        SpellSelection.loadPredefinedSpells(spellSelectionModal.castType)
        return
    end
    
    searchText = searchText:lower()
    local filteredSpells = {}
    
    -- Search through all spell categories
    for _, category in ipairs(GMConfig.SPELL_CATEGORIES) do
        for _, spell in ipairs(category.spells) do
            if spell.name:lower():find(searchText, 1, true) or tostring(spell.spellId):find(searchText, 1, true) then
                table.insert(filteredSpells, {
                    spellId = spell.spellId,
                    name = spell.name,
                    icon = spell.icon,
                    category = category.name
                })
            end
        end
    end
    
    -- Hide pagination for filtered predefined spells
    if spellSelectionModal.prevButton then
        spellSelectionModal.prevButton:Hide()
    end
    if spellSelectionModal.nextButton then
        spellSelectionModal.nextButton:Hide()
    end
    if spellSelectionModal.pageInfo then
        spellSelectionModal.pageInfo:Hide()
    end
    
    SpellSelection.updateSpellList(filteredSpells)
end

-- Confirm spell cast
function SpellSelection.confirmCastSpell()
    if #selectedSpells == 0 then
        print("No spell selected")
        return
    end
    
    local spell = selectedSpells[1]
    local castType = spellSelectionModal.castType
    
    if castType == "buff" then
        AIO.Handle("GameMasterSystem", "applyBuffToPlayer", targetPlayerNameForSpell, spell.spellId)
    elseif castType == "self" then
        AIO.Handle("GameMasterSystem", "makePlayerCastOnSelf", targetPlayerNameForSpell, spell.spellId)
    elseif castType == "target" then
        AIO.Handle("GameMasterSystem", "makePlayerCastOnTarget", targetPlayerNameForSpell, spell.spellId)
    elseif castType == "onplayer" then
        AIO.Handle("GameMasterSystem", "castSpellOnPlayer", targetPlayerNameForSpell, spell.spellId)
    end
    
    -- Close modal
    if spellSelectionModal then
        spellSelectionModal:Hide()
    end
end

-- Handle spell search results from server
function SpellSelection.updateSpellSearchResults(spells, offset, pageSize, hasMoreData, totalCount)
    if not spellSelectionModal or not spellSelectionModal:IsVisible() then
        return
    end
    
    print("[GMMenus] Received", #spells, "spells from server, offset:", offset, "hasMore:", hasMoreData, "total:", totalCount)
    
    -- Update modal state using SpellSearchModule
    SpellSearchModule.updateModalState(spellSelectionModal, offset, pageSize, hasMoreData, totalCount)
    
    -- Reset search feedback text color and show results count
    if spellSelectionModal.spellCountLabel then
        spellSelectionModal.spellCountLabel:SetTextColor(0.7, 0.7, 0.7) -- Reset to normal gray
        local searchText = ""
        if spellSelectionModal.searchBox and spellSelectionModal.searchBox.editBox then
            searchText = spellSelectionModal.searchBox.editBox:GetText() or ""
        end
        if searchText ~= "" then
            spellSelectionModal.spellCountLabel:SetText("Database search: " .. #spells .. " results")
        else
            spellSelectionModal.spellCountLabel:SetText("Browsing all spells: " .. #spells .. " results")
        end
    end
    
    -- Show pagination controls for database results
    if spellSelectionModal.prevButton then
        spellSelectionModal.prevButton:Show()
    end
    if spellSelectionModal.nextButton then
        spellSelectionModal.nextButton:Show()
    end
    if spellSelectionModal.pageInfo then
        spellSelectionModal.pageInfo:Show()
    end
    
    -- Update pagination controls
    SpellSelection.updatePaginationControls()
    
    -- Update the spell list with server results
    SpellSelection.updateSpellList(spells)
end

-- Update pagination controls visibility and text
function SpellSelection.updatePaginationControls()
    if not spellSelectionModal then return end
    
    -- Update previous button (WoW 3.3.5 uses Enable/Disable)
    if spellSelectionModal.prevButton then
        if spellSelectionModal.currentOffset > 0 then
            spellSelectionModal.prevButton:Enable()
        else
            spellSelectionModal.prevButton:Disable()
        end
    end
    
    -- Update next button (WoW 3.3.5 uses Enable/Disable)
    if spellSelectionModal.nextButton then
        if spellSelectionModal.hasMoreData then
            spellSelectionModal.nextButton:Enable()
        else
            spellSelectionModal.nextButton:Disable()
        end
    end
    
    -- Update page info using SpellSearchModule
    if spellSelectionModal.pageInfo then
        local paginationInfo = SpellSearchModule.getPaginationInfo(spellSelectionModal)
        
        if paginationInfo.totalSpells > 0 then
            spellSelectionModal.pageInfo:SetText(string.format("Showing %d-%d of %d", 
                paginationInfo.startNum, paginationInfo.endNum, paginationInfo.totalSpells))
        else
            spellSelectionModal.pageInfo:SetText("Page " .. paginationInfo.currentPage)
        end
    end
end

-- Export the creation function
GMMenus.createSpellSelectionDialog = function(playerName, castType)
    return SpellSelection.createDialog(playerName, castType)
end

-- Export update function for server responses
GMMenus.updateSpellSearchResults = function(spells, offset, pageSize, hasMoreData, totalCount)
    if SpellSelection.updateSpellSearchResults then
        SpellSelection.updateSpellSearchResults(spells, offset, pageSize, hasMoreData, totalCount)
    end
end

-- Spell selection module loaded