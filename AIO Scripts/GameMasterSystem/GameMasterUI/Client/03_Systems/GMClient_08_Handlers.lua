local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    return  -- Exit if on server
end

-- Use existing namespace
local GameMasterSystem = _G.GameMasterSystem
if not GameMasterSystem then
    print("[GameMasterSystem] ERROR: Namespace not found in Handlers! Check load order.")
    return
end

-- Access shared data and UI references
local GMData = _G.GMData
local GMUI = _G.GMUI

if not GMData then
    print("[GameMasterSystem] ERROR: GMData not found! Check load order.")
    return
end

-- Loading client handlers module

-- Test handler to verify AIO is working
function GameMasterSystem.testPing(player, message)
    -- TEST PING received
end

-- AIO Message Handlers
-- IMPORTANT: Client handlers ALWAYS receive player name as first parameter!

function GameMasterSystem.receiveItemData(player, data, offset, pageSize, hasMoreData, inventoryType)
    if not data then
        -- No item data received
        return
    end

    -- Ensure DataStore exists
    if not GMData.DataStore then
        GMData.DataStore = {}
    end

    GMData.DataStore.items = data
    GMData.currentOffset = offset or 0
    GMData.hasMoreData = hasMoreData or false

    -- Update UI if viewing items tab
    if GMUI and GMUI.updateContentForActiveTab then
        GMUI.updateContentForActiveTab()
    end

    -- Update pagination buttons
    if GMUI and GMUI.updatePaginationButtons then
        GMUI.updatePaginationButtons()
    end
end

function GameMasterSystem.receiveNPCData(player, data, offset, pageSize, hasMoreData)
    if not data then
        -- No NPC data received
        return
    end

    -- Ensure DataStore exists
    if not GMData.DataStore then
        GMData.DataStore = {}
    end

    GMData.DataStore.npcs = data
    GMData.currentOffset = offset or 0
    GMData.hasMoreData = hasMoreData or false

    -- Update UI if viewing NPCs tab
    if GMUI and GMUI.updateContentForActiveTab then
        GMUI.updateContentForActiveTab()
    end

    -- Update pagination buttons
    if GMUI and GMUI.updatePaginationButtons then
        GMUI.updatePaginationButtons()
    end
end

function GameMasterSystem.receiveGameObjectData(player, data, offset, pageSize, hasMoreData)
    if not data then
        -- No game object data received
        return
    end

    -- Ensure DataStore exists
    if not GMData.DataStore then
        GMData.DataStore = {}
    end

    GMData.DataStore.gameobjects = data
    GMData.currentOffset = offset or 0
    GMData.hasMoreData = hasMoreData or false
    
    -- Update UI if viewing game objects tab
    if GMUI and GMUI.updateContentForActiveTab then
        GMUI.updateContentForActiveTab()
    end

    -- Update pagination buttons
    if GMUI and GMUI.updatePaginationButtons then
        GMUI.updatePaginationButtons()
    end
end

function GameMasterSystem.receiveSpellData(player, data, offset, pageSize, hasMoreData)
    if not data then
        -- No spell data received
        return
    end

    -- Ensure DataStore exists
    if not GMData.DataStore then
        GMData.DataStore = {}
    end

    GMData.DataStore.spells = data
    GMData.currentOffset = offset or 0
    GMData.hasMoreData = hasMoreData or false

    -- Update UI if viewing spells tab
    if GMUI and GMUI.updateContentForActiveTab then
        GMUI.updateContentForActiveTab()
    end

    -- Update pagination buttons
    if GMUI and GMUI.updatePaginationButtons then
        GMUI.updatePaginationButtons()
    end
end

function GameMasterSystem.receiveSpellVisualData(player, data, offset, pageSize, hasMoreData)
    if not data then
        -- No spell visual data received
        return
    end

    -- Ensure DataStore exists
    if not GMData.DataStore then
        GMData.DataStore = {}
    end

    GMData.DataStore.spellvisuals = data
    GMData.currentOffset = offset or 0
    GMData.hasMoreData = hasMoreData or false

    -- Update UI if viewing spell visuals tab
    if GMUI and GMUI.updateContentForActiveTab then
        GMUI.updateContentForActiveTab()
    end

    -- Update pagination buttons
    if GMUI and GMUI.updatePaginationButtons then
        GMUI.updatePaginationButtons()
    end
end

function GameMasterSystem.receiveGmLevel(player, gmLevel)
    if not gmLevel then
        -- No GM level received
        return
    end

    GMData.PlayerGMLevel = gmLevel
    -- Player GM level received

    -- Update UI if it exists
    if GMUI.mainFrame and GMUI.updateTitleWithGMLevel then
        GMUI.updateTitleWithGMLevel()
    end
end

function GameMasterSystem.receiveCoreName(player, coreName)
    if not coreName then
        -- No core name received
        return
    end

    GMData.CoreName = coreName
    -- Core name received
end

-- Player data handler
function GameMasterSystem.receivePlayerData(player, data, offset, pageSize, hasMoreData)
    -- receivePlayerData called
    
    if not data then
        -- No player data received
        return
    end

    -- Ensure DataStore exists
    if not GMData.DataStore then
        GMData.DataStore = {}
    end

    GMData.DataStore.players = data
    GMData.currentOffset = offset or 0
    GMData.hasMoreData = hasMoreData or false
    
    -- Stored players in DataStore

    -- Update UI if viewing players tab
    if GMUI and GMUI.updateContentForActiveTab then
        -- Calling updateContentForActiveTab
        GMUI.updateContentForActiveTab()
    end

    -- Update pagination buttons
    if GMUI and GMUI.updatePaginationButtons then
        GMUI.updatePaginationButtons()
    end
end

-- Finalize UI pattern for cross-file dependencies
function GameMasterSystem.FinalizeHandlers()
    -- This function can be called after all modules are loaded
    -- to ensure any cross-file dependencies are resolved

    -- Check if main UI is created and needs initial data
    if GMUI.mainFrame and not GMData.initialDataLoaded then
        -- Request initial data from server
        -- Requesting initial data from server
        AIO.Handle("GameMasterSystem", "requestInitialData")
        
        -- Request server capabilities
        AIO.Handle("GameMasterSystem", "getServerCapabilities")
        
        GMData.initialDataLoaded = true
    end
end

-- Handler for receiving modal item data
function GameMasterSystem.receiveModalItemData(player, items)
    if not items then
        -- No modal item data received
        return
    end
    
    -- Update the modal with received items
    if _G.GMMenus and _G.GMMenus.updateModalItems then
        _G.GMMenus.updateModalItems(items)
    end
end

-- Handler for receiving spell search results
function GameMasterSystem.receiveSpellSearchResults(player, spells, offset, pageSize, hasMoreData, totalCount)
    if not spells then
        -- No spell data received
        return
    end
    
    -- Update the spell modal with received data including pagination info
    if _G.GMMenus and _G.GMMenus.updateSpellSearchResults then
        _G.GMMenus.updateSpellSearchResults(spells, offset, pageSize, hasMoreData, totalCount)
    end
end

-- Handler for server capabilities
function GameMasterSystem.receiveServerCapabilities(player, capabilities)
    if not capabilities then
        return
    end
    
    -- Store server capabilities
    GMData.ServerCapabilities = capabilities
    print("[GameMasterSystem] Received server capabilities:")
    print("  - Character ban support: " .. tostring(capabilities.supportsCharacterBan))
    print("  - Server version: " .. (capabilities.serverVersion or "Unknown"))
    
    -- Update any UI elements that depend on capabilities
    if not capabilities.supportsCharacterBan then
        print("[GameMasterSystem] WARNING: Character bans are not supported on this server")
    end
end

-- Register popup dialogs for player management
StaticPopupDialogs["GM_GIVE_PLAYER_GOLD"] = {
    text = "Give gold to %s:",
    button1 = "Give",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    maxLetters = 10,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnAccept = function(self, data)
        local amount = tonumber(self.editBox:GetText())
        if amount and amount > 0 then
            AIO.Handle("GameMasterSystem", "givePlayerGold", data.name, amount)
        else
            -- Invalid gold amount
        end
    end,
    EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent()
        local amount = tonumber(self:GetText())
        if amount and amount > 0 then
            AIO.Handle("GameMasterSystem", "givePlayerGold", data.name, amount)
        end
        parent:Hide()
    end,
}

StaticPopupDialogs["GM_GIVE_PLAYER_ITEM"] = {
    text = "Give item to %s:\nEnter Item ID:",
    button1 = "Give",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    maxLetters = 10,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnAccept = function(self, data)
        local itemId = tonumber(self.editBox:GetText())
        if itemId and itemId > 0 then
            -- Default to 1 item, could be extended with quantity dialog
            AIO.Handle("GameMasterSystem", "givePlayerItem", data.name, itemId, 1)
        else
            -- Invalid item ID
        end
    end,
    EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent()
        local itemId = tonumber(self:GetText())
        if itemId and itemId > 0 then
            AIO.Handle("GameMasterSystem", "givePlayerItem", data.name, itemId, 1)
        end
        parent:Hide()
    end,
}

StaticPopupDialogs["GM_KICK_PLAYER"] = {
    text = "Kick player %s?\nEnter reason:",
    button1 = "Kick",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 300,
    maxLetters = 100,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnAccept = function(self, data)
        local reason = self.editBox:GetText()
        if reason and reason ~= "" then
            AIO.Handle("GameMasterSystem", "kickPlayer", data.name, reason)
        else
            AIO.Handle("GameMasterSystem", "kickPlayer", data.name, "Kicked by GM")
        end
    end,
}

-- Buff/Spell related dialogs
StaticPopupDialogs["GM_APPLY_CUSTOM_BUFF"] = {
    text = "Apply buff to %s:\nEnter Spell ID:",
    button1 = "Apply",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    maxLetters = 10,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnAccept = function(self, data)
        local spellId = tonumber(self.editBox:GetText())
        if spellId and spellId > 0 then
            AIO.Handle("GameMasterSystem", "applyBuffToPlayer", data.name, spellId)
        else
            -- Invalid spell ID
        end
    end,
    EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent()
        local spellId = tonumber(self:GetText())
        if spellId and spellId > 0 then
            AIO.Handle("GameMasterSystem", "applyBuffToPlayer", data.name, spellId)
        end
        parent:Hide()
    end,
}

StaticPopupDialogs["GM_PLAYER_CAST_SELF"] = {
    text = "Make %s cast on self:\nEnter Spell ID:",
    button1 = "Cast",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    maxLetters = 10,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnAccept = function(self, data)
        local spellId = tonumber(self.editBox:GetText())
        if spellId and spellId > 0 then
            AIO.Handle("GameMasterSystem", "makePlayerCastOnSelf", data.name, spellId)
        else
            -- Invalid spell ID
        end
    end,
    EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent()
        local spellId = tonumber(self:GetText())
        if spellId and spellId > 0 then
            AIO.Handle("GameMasterSystem", "makePlayerCastOnSelf", data.name, spellId)
        end
        parent:Hide()
    end,
}

StaticPopupDialogs["GM_PLAYER_CAST_TARGET"] = {
    text = "Make %s cast on their target:\nEnter Spell ID:",
    button1 = "Cast",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    maxLetters = 10,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnAccept = function(self, data)
        local spellId = tonumber(self.editBox:GetText())
        if spellId and spellId > 0 then
            AIO.Handle("GameMasterSystem", "makePlayerCastOnTarget", data.name, spellId)
        else
            -- Invalid spell ID
        end
    end,
    EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent()
        local spellId = tonumber(self:GetText())
        if spellId and spellId > 0 then
            AIO.Handle("GameMasterSystem", "makePlayerCastOnTarget", data.name, spellId)
        end
        parent:Hide()
    end,
}

StaticPopupDialogs["GM_CAST_ON_PLAYER"] = {
    text = "Cast spell on %s:\nEnter Spell ID:",
    button1 = "Cast",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    maxLetters = 10,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnAccept = function(self, data)
        local spellId = tonumber(self.editBox:GetText())
        if spellId and spellId > 0 then
            AIO.Handle("GameMasterSystem", "castSpellOnPlayer", data.name, spellId)
        else
            -- Invalid spell ID
        end
    end,
    EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent()
        local spellId = tonumber(self:GetText())
        if spellId and spellId > 0 then
            AIO.Handle("GameMasterSystem", "castSpellOnPlayer", data.name, spellId)
        end
        parent:Hide()
    end,
}

-- Custom Ban Dialog
function GameMasterSystem.ShowBanDialog(playerName, banType)
    -- Prevent multiple dialogs
    if GameMasterSystem.banDialog and GameMasterSystem.banDialog:IsShown() then
        GameMasterSystem.banDialog:Hide()
    end
    
    -- Default to character ban if not specified
    banType = banType or 1
    
    -- Ban type labels
    local banTypeLabels = {
        [0] = "Account",
        [1] = "Character",
        [2] = "IP"
    }
    
    -- Ban type descriptions
    local banTypeDescriptions = {
        [0] = "Bans all characters on this player's account",
        [1] = "Bans only this specific character",
        [2] = "Bans this player's IP address"
    }
    
    -- Ban type colors
    local banTypeColors = {
        [0] = {1, 0.5, 0},    -- Orange for account ban
        [1] = {1, 1, 0},      -- Yellow for character ban
        [2] = {1, 0, 0}       -- Red for IP ban
    }
    
    -- Create main dialog frame
    local dialog = CreateStyledFrame(UIParent, UISTYLE_COLORS.DarkGrey)
    dialog:SetSize(450, 420)  -- Increased height for ban type info
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(100)
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    
    -- Store reference
    GameMasterSystem.banDialog = dialog
    
    -- Create title bar
    local titleBar = CreateStyledFrame(dialog, UISTYLE_COLORS.SectionBg)
    titleBar:SetHeight(30)
    titleBar:SetPoint("TOPLEFT", dialog, "TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -1, -1)
    
    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    title:SetText(string.format("Ban %s", playerName))
    title:SetTextColor(1, 1, 1)
    
    -- Close button
    local closeBtn = CreateStyledButton(titleBar, "X", 24, 24)
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -5, 0)
    closeBtn:SetScript("OnClick", function() dialog:Hide() end)
    
    -- Content area
    local content = CreateStyledFrame(dialog, UISTYLE_COLORS.OptionBg)
    content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -10)
    content:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -10, 10)
    
    -- Ban type info section
    local banTypeSection = CreateStyledFrame(content, UISTYLE_COLORS.SectionBg)
    banTypeSection:SetHeight(60)
    banTypeSection:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    banTypeSection:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
    
    -- Ban type icon
    local banTypeIcon = banTypeSection:CreateTexture(nil, "ARTWORK")
    banTypeIcon:SetSize(32, 32)
    banTypeIcon:SetPoint("LEFT", banTypeSection, "LEFT", 10, 0)
    if banType == 0 then
        banTypeIcon:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")  -- Account icon
    elseif banType == 1 then
        banTypeIcon:SetTexture("Interface\\Icons\\Achievement_Character_Human_Male")  -- Character icon
    else
        banTypeIcon:SetTexture("Interface\\Icons\\Spell_Fire_SelfDestruct")  -- IP ban icon
    end
    
    -- Ban type label with color
    local banTypeLabel = banTypeSection:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    banTypeLabel:SetPoint("LEFT", banTypeIcon, "RIGHT", 10, 8)
    banTypeLabel:SetText(banTypeLabels[banType] .. " Ban")
    local r, g, b = unpack(banTypeColors[banType])
    banTypeLabel:SetTextColor(r, g, b)
    
    -- Ban type description
    local banTypeDesc = banTypeSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    banTypeDesc:SetPoint("TOPLEFT", banTypeLabel, "BOTTOMLEFT", 0, -2)
    banTypeDesc:SetText(banTypeDescriptions[banType])
    banTypeDesc:SetTextColor(0.7, 0.7, 0.7)
    
    -- Duration label
    local durationLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    durationLabel:SetPoint("TOPLEFT", banTypeSection, "BOTTOMLEFT", 10, -15)
    durationLabel:SetText("Ban Duration (minutes):")
    durationLabel:SetTextColor(1, 1, 1)
    
    -- Duration edit box
    local durationContainer = CreateStyledEditBox(content, 400, true, 10, false)
    durationContainer:SetPoint("TOPLEFT", durationLabel, "BOTTOMLEFT", 0, -5)
    local durationEdit = durationContainer.editBox  -- Get the actual EditBox
    durationEdit:SetText("0")
    durationEdit:HighlightText()
    durationEdit:SetFocus()
    
    -- Duration help text
    local durationHelp = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    durationHelp:SetPoint("TOPLEFT", durationContainer, "BOTTOMLEFT", 0, -2)
    durationHelp:SetText("Enter 0 for permanent ban")
    durationHelp:SetTextColor(0.7, 0.7, 0.7)
    
    -- Reason label
    local reasonLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reasonLabel:SetPoint("TOPLEFT", durationHelp, "BOTTOMLEFT", 0, -15)
    reasonLabel:SetText("Ban Reason:")
    reasonLabel:SetTextColor(1, 1, 1)
    
    -- Reason edit box (multi-line) - Create manually to avoid UIStyleLibrary bug
    local reasonContainer = CreateStyledFrame(content, UISTYLE_COLORS.OptionBg)
    reasonContainer:SetPoint("TOPLEFT", reasonLabel, "BOTTOMLEFT", 0, -5)
    reasonContainer:SetHeight(100)
    reasonContainer:SetWidth(400)
    
    -- Create simple multi-line EditBox without scroll frame
    local reasonEdit = CreateFrame("EditBox", nil, reasonContainer)
    reasonEdit:SetPoint("TOPLEFT", 4, -4)
    reasonEdit:SetPoint("BOTTOMRIGHT", -4, 4)
    reasonEdit:SetMultiLine(true)
    reasonEdit:SetMaxLetters(200)
    reasonEdit:SetFontObject("GameFontHighlight")
    reasonEdit:SetTextColor(1, 1, 1)
    reasonEdit:SetText("Banned by GM")
    reasonEdit:SetAutoFocus(false)
    
    -- Button container
    local buttonContainer = CreateStyledFrame(content, UISTYLE_COLORS.OptionBg)
    buttonContainer:SetHeight(40)
    buttonContainer:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
    buttonContainer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    
    -- Cancel button
    local cancelBtn = CreateStyledButton(buttonContainer, "Cancel", 100, 26)
    cancelBtn:SetPoint("LEFT", buttonContainer, "LEFT", 10, 0)
    cancelBtn:SetScript("OnClick", function() dialog:Hide() end)
    
    -- Ban button
    local banBtn = CreateStyledButton(buttonContainer, "Ban", 100, 26)
    banBtn:SetPoint("RIGHT", buttonContainer, "RIGHT", -10, 0)
    banBtn:SetScript("OnClick", function()
        local duration = tonumber(durationEdit:GetText()) or 0
        local reason = reasonEdit:GetText()
        
        -- Validate input
        if reason == "" then
            reason = "Banned by GM"
        end
        
        -- Show confirmation dialog
        local confirmMsg = string.format(
            "Are you sure you want to %s %s?\n\nBan Type: %s\nDuration: %s\nReason: %s",
            duration == 0 and "permanently ban" or "ban",
            playerName,
            banTypeLabels[banType] .. " Ban",
            duration == 0 and "Permanent" or duration .. " minutes",
            reason
        )
        
        -- Create custom confirmation dialog
        StaticPopupDialogs["GM_CONFIRM_BAN"] = {
            text = confirmMsg,
            button1 = "Confirm Ban",
            button2 = "Cancel",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnAccept = function()
                -- Send ban command with ban type
                AIO.Handle("GameMasterSystem", "banPlayer", playerName, duration, reason, banType)
                
                -- Close ban dialog
                dialog:Hide()
                
                -- Show feedback
                CreateStyledToast("Ban command sent", 2, 0.5)
            end,
            OnCancel = function()
                -- Do nothing, keep ban dialog open
            end,
        }
        
        StaticPopup_Show("GM_CONFIRM_BAN")
    end)
    
    -- Handle escape key
    durationEdit:SetScript("OnEscapePressed", function() dialog:Hide() end)
    reasonEdit:SetScript("OnEscapePressed", function() dialog:Hide() end)
    
    -- Handle enter key on duration to move to reason
    durationEdit:SetScript("OnEnterPressed", function()
        reasonEdit:SetFocus()
    end)
    
    -- Add to UISpecialFrames for ESC key closing
    local dialogName = "GameMasterBanDialog"
    _G[dialogName] = dialog  -- Store in global namespace
    tinsert(UISpecialFrames, dialogName)
    
    -- Show the dialog
    dialog:Show()
    
    return dialog
end

-- Helper function to get safe item icon
local function GetItemIconSafe(itemId)
    local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemId)
    return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Mail composition dialog
function GameMasterSystem.OpenMailDialog(playerName)
    if not playerName then return end
    
    -- Create main frame with improved size
    local mailFrame = CreateStyledFrame(UIParent, UISTYLE_COLORS.DarkGrey)
    mailFrame:SetSize(500, 580)  -- Increased height for better layout
    mailFrame:SetPoint("CENTER")
    mailFrame:SetFrameStrata("DIALOG")
    mailFrame:EnableMouse(true)
    mailFrame:SetMovable(true)
    mailFrame:RegisterForDrag("LeftButton")
    mailFrame:SetScript("OnDragStart", mailFrame.StartMoving)
    mailFrame:SetScript("OnDragStop", mailFrame.StopMovingOrSizing)
    
    -- Create title bar
    local titleBar = CreateStyledFrame(mailFrame, UISTYLE_COLORS.SectionBg)
    titleBar:SetHeight(35)
    titleBar:SetPoint("TOPLEFT", mailFrame, "TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", mailFrame, "TOPRIGHT", -1, -1)
    
    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleBar, "LEFT", 15, 0)
    title:SetText("Send Mail to " .. playerName)
    title:SetTextColor(1, 1, 1)
    
    -- Close button
    local closeButton = CreateStyledButton(titleBar, "X", 24, 24)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", -5, 0)
    closeButton:SetScript("OnClick", function()
        mailFrame:Hide()
    end)
    
    -- Subject section
    local subjectLabel = mailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subjectLabel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 15, -15)
    subjectLabel:SetText("Subject:")
    subjectLabel:SetTextColor(0.8, 0.8, 0.8)
    
    local subjectContainer = CreateStyledEditBox(mailFrame, 450, false, 50)
    subjectContainer:SetPoint("TOPLEFT", subjectLabel, "BOTTOMLEFT", 0, -5)
    
    -- Get the actual EditBox from inside the container
    local subjectBox = subjectContainer:GetChildren()
    
    -- Character count for subject
    local subjectCharCount = mailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subjectCharCount:SetPoint("RIGHT", subjectContainer, "RIGHT", -5, 0)
    subjectCharCount:SetTextColor(0.5, 0.5, 0.5)
    subjectCharCount:SetText("0/50")
    
    subjectBox:SetScript("OnTextChanged", function(self)
        local len = strlen(self:GetText())
        subjectCharCount:SetText(len .. "/50")
        if len > 45 then
            subjectCharCount:SetTextColor(1, 0.5, 0)
        else
            subjectCharCount:SetTextColor(0.5, 0.5, 0.5)
        end
    end)
    
    -- Message section with scrollable area
    local messageLabel = mailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    messageLabel:SetPoint("TOPLEFT", subjectContainer, "BOTTOMLEFT", 0, -15)
    messageLabel:SetText("Message:")
    messageLabel:SetTextColor(0.8, 0.8, 0.8)
    
    -- Create scrollable message area
    local messageContainer, messageContent, messageScrollBar, updateMessageScroll = CreateScrollableFrame(mailFrame, 450, 120)
    messageContainer:SetPoint("TOPLEFT", messageLabel, "BOTTOMLEFT", 0, -5)
    
    -- Create a simple multi-line edit box directly (avoiding the problematic multiline styled editbox)
    local messageBox = CreateFrame("EditBox", nil, messageContent)
    messageBox:SetPoint("TOPLEFT", messageContent, "TOPLEFT", 5, -5)
    messageBox:SetPoint("TOPRIGHT", messageContent, "TOPRIGHT", -5, -5)
    messageBox:SetMultiLine(true)
    messageBox:SetFontObject("GameFontHighlight")
    messageBox:SetTextColor(1, 1, 1, 1)
    messageBox:SetAutoFocus(false)
    messageBox:SetMaxLetters(500)
    messageBox:SetHeight(300)
    
    -- Style it like a styled edit box
    local messageBg = messageBox:CreateTexture(nil, "BACKGROUND")
    messageBg:SetAllPoints()
    messageBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    messageBg:SetVertexColor(0, 0, 0, 0.3)
    
    -- Update scroll when text changes
    messageBox:SetScript("OnTextChanged", function(self)
        local height = self:GetHeight()
        messageContent:SetHeight(math.max(120, height + 20))
        updateMessageScroll()
    end)
    
    -- Clear focus on escape
    messageBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    
    -- Attachments section
    local attachmentLabel = mailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    attachmentLabel:SetPoint("TOPLEFT", messageContainer, "BOTTOMLEFT", 0, -15)
    attachmentLabel:SetText("Attachments:")
    attachmentLabel:SetTextColor(0.8, 0.8, 0.8)
    
    -- Attachment counter
    local attachmentCounter = mailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    attachmentCounter:SetPoint("LEFT", attachmentLabel, "RIGHT", 5, 0)
    attachmentCounter:SetText("(0/12)")
    attachmentCounter:SetTextColor(0.6, 0.6, 0.6)
    
    -- Button row container (positioned to the right of attachments label)
    local buttonRow = CreateFrame("Frame", nil, mailFrame)
    buttonRow:SetHeight(24)
    buttonRow:SetPoint("TOPLEFT", attachmentCounter, "RIGHT", 20, 0)
    buttonRow:SetPoint("TOPRIGHT", mailFrame, "TOPRIGHT", -15, 0)
    
    -- Remove selected button (leftmost)
    local removeSelectedButton = CreateStyledButton(buttonRow, "Remove", 70, 24)
    removeSelectedButton:SetPoint("LEFT", buttonRow, "LEFT", 0, 0)
    removeSelectedButton:SetTooltip("Remove selected items", "Click items to select, then click this to remove")
    removeSelectedButton:Disable() -- Initially disabled
    
    -- Clear all button (middle)
    local clearAllButton = CreateStyledButton(buttonRow, "Clear All", 70, 24)
    clearAllButton:SetPoint("LEFT", removeSelectedButton, "RIGHT", 5, 0)
    clearAllButton:SetTooltip("Remove all attachments", "Click to remove all attached items")
    clearAllButton:Disable() -- Initially disabled
    
    -- Add items button (rightmost)
    local addItemsButton = CreateStyledButton(buttonRow, "Add Items", 80, 24)
    addItemsButton:SetPoint("LEFT", clearAllButton, "RIGHT", 5, 0)
    addItemsButton:SetTooltip("Add items to mail", "Click to search and select items to attach")
    
    -- Create invisible container for attachment slots (no background)
    local attachmentContainer = CreateFrame("Frame", nil, mailFrame)
    attachmentContainer:SetPoint("TOPLEFT", attachmentLabel, "BOTTOMLEFT", 0, -30)  -- More space for button row
    attachmentContainer:SetWidth(450)
    attachmentContainer:SetHeight(90)  -- Space for 2 rows
    
    -- Create grid for attachment slots (also invisible)
    local attachmentGrid = CreateFrame("Frame", nil, attachmentContainer)
    attachmentGrid:SetAllPoints()
    
    -- Initialize attachment system
    local attachedItems = {}  -- Array of attached items
    local attachmentSlots = {}  -- Visual slots (both filled and empty)
    local selectedForRemoval = {}  -- Items selected for removal
    local MAX_ATTACHMENTS = 12
    local SLOT_SIZE = 40  -- Larger slots for better visibility
    local SLOT_SPACING = 5
    
    -- Forward declare AddItems function
    local AddItems
    
    -- Create a styled quantity dialog
    local quantityDialog
    local function ShowQuantityDialog(itemName, itemId, itemLink, itemIcon, onAccept, stackSize, availableQty)
        -- Create dialog if it doesn't exist
        if not quantityDialog then
            -- Create main dialog first
            quantityDialog = CreateStyledFrame(UIParent, UISTYLE_COLORS.DarkGrey)
            quantityDialog:SetSize(320, 230)
            quantityDialog:SetPoint("CENTER")
            quantityDialog:SetFrameStrata("TOOLTIP")
            quantityDialog:EnableMouse(true)
            quantityDialog:SetMovable(true)
            quantityDialog:RegisterForDrag("LeftButton")
            quantityDialog:SetScript("OnDragStart", quantityDialog.StartMoving)
            quantityDialog:SetScript("OnDragStop", quantityDialog.StopMovingOrSizing)
            
            -- Title bar
            local titleBar = CreateStyledFrame(quantityDialog, UISTYLE_COLORS.SectionBg)
            titleBar:SetHeight(30)
            titleBar:SetPoint("TOPLEFT", 1, -1)
            titleBar:SetPoint("TOPRIGHT", -1, -1)
            
            local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetPoint("CENTER")
            title:SetText("Enter Quantity")
            quantityDialog.title = title
            
            -- Close button
            local closeBtn = CreateStyledButton(titleBar, "X", 20, 20)
            closeBtn:SetPoint("RIGHT", -5, 0)
            closeBtn:SetScript("OnClick", function()
                quantityDialog:Hide()
                ClearCursor()
            end)
            
            -- Item icon and name
            local icon = quantityDialog:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32, 32)
            icon:SetPoint("TOPLEFT", 20, -45)
            quantityDialog.icon = icon
            
            local itemLabel = quantityDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            itemLabel:SetPoint("LEFT", icon, "RIGHT", 10, 0)
            itemLabel:SetPoint("RIGHT", -20, 0)
            itemLabel:SetJustifyH("LEFT")
            quantityDialog.itemLabel = itemLabel
            
            -- Quantity input
            local qtyLabel = quantityDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            qtyLabel:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -15)
            qtyLabel:SetText("Quantity:")
            
            local qtyEditContainer = CreateStyledEditBox(quantityDialog, 100, true, 10)  -- Wider and more chars
            qtyEditContainer:SetPoint("LEFT", qtyLabel, "RIGHT", 70, 0)  -- Moved further right
            local qtyEdit = qtyEditContainer:GetChildren()
            quantityDialog.qtyEdit = qtyEdit
            
            -- Quick quantity buttons in a grid
            local quickBtnContainer = CreateFrame("Frame", nil, quantityDialog)
            quickBtnContainer:SetPoint("TOPLEFT", qtyLabel, "BOTTOMLEFT", 0, -10)
            quickBtnContainer:SetSize(255, 70)
            
            -- Common quantities
            local quantities = {
                {1, "1"}, {5, "5"}, {10, "10"}, {20, "20"}, {50, "50"}, {0, "Stack"}
            }
            
            local btnWidth, btnHeight = 75, 26
            local spacing = 10
            local cols = 3
            
            for i, qtData in ipairs(quantities) do
                local qty, label = qtData[1], qtData[2]
                local row = math.floor((i-1) / cols)
                local col = (i-1) % cols
                
                local btn = CreateStyledButton(quickBtnContainer, label, btnWidth, btnHeight)
                btn:SetPoint("TOPLEFT", col * (btnWidth + spacing), -row * (btnHeight + spacing))
                
                -- Store references to special buttons
                if label == "Stack" then
                    quantityDialog.stackBtn = btn
                end
                
                btn:SetScript("OnClick", function()
                    if label == "Stack" then
                        -- Use actual stack size from dialog
                        local stack = quantityDialog.stackSize or 20
                        qtyEdit:SetText(tostring(stack))
                    else
                        qtyEdit:SetText(tostring(qty))
                    end
                    qtyEdit:HighlightText()
                end)
                
                if label == "Stack" then
                    btn:SetTooltip("Stack Size", "Set quantity to one full stack of this item")
                end
            end
            
            
            -- Plus/Minus buttons for fine adjustment
            local minusBtn = CreateStyledButton(quantityDialog, "-", 25, 20)
            minusBtn:SetPoint("RIGHT", qtyEditContainer, "LEFT", -5, 0)
            minusBtn:SetScript("OnClick", function()
                local current = tonumber(qtyEdit:GetText()) or 1
                if current > 1 then
                    qtyEdit:SetText(tostring(current - 1))
                end
            end)
            
            local plusBtn = CreateStyledButton(quantityDialog, "+", 25, 20)
            plusBtn:SetPoint("LEFT", qtyEditContainer, "RIGHT", 5, 0)
            plusBtn:SetScript("OnClick", function()
                local current = tonumber(qtyEdit:GetText()) or 1
                local maxStack = quantityDialog.stackSize or 200
                if current < maxStack then
                    qtyEdit:SetText(tostring(current + 1))
                end
            end)
            
            -- Buttons
            local okBtn = CreateStyledButton(quantityDialog, "OK", 80, 25)
            okBtn:SetPoint("BOTTOMRIGHT", -20, 15)
            quantityDialog.okBtn = okBtn
            
            local cancelBtn = CreateStyledButton(quantityDialog, "Cancel", 80, 25)
            cancelBtn:SetPoint("RIGHT", okBtn, "LEFT", -10, 0)
            cancelBtn:SetScript("OnClick", function()
                quantityDialog:Hide()
                ClearCursor()
            end)
            
            -- Handle escape and enter
            qtyEdit:SetScript("OnEscapePressed", function()
                quantityDialog:Hide()
                ClearCursor()
            end)
            
            qtyEdit:SetScript("OnEnterPressed", function()
                okBtn:Click()
            end)
            
            -- Make dialog hide on escape
            quantityDialog:SetScript("OnKeyDown", function(self, key)
                if key == "ESCAPE" then
                    self:Hide()
                    ClearCursor()
                end
            end)
            quantityDialog:EnableKeyboard(true)
        end
        
        -- Update dialog with item info
        quantityDialog.icon:SetTexture(itemIcon)
        quantityDialog.itemLabel:SetText(itemName)
        quantityDialog.qtyEdit:SetText("1")
        quantityDialog.qtyEdit:HighlightText()
        quantityDialog.qtyEdit:SetFocus()
        
        -- Store stack size and available quantity for special buttons
        quantityDialog.stackSize = stackSize or 20
        quantityDialog.availableQty = availableQty or 1
        
        -- Update button labels to show actual values
        if quantityDialog.stackBtn then
            quantityDialog.stackBtn:SetText("Stack\n(" .. quantityDialog.stackSize .. ")")
        end
        
        -- Set up OK button handler
        quantityDialog.okBtn:SetScript("OnClick", function()
            local count = tonumber(quantityDialog.qtyEdit:GetText()) or 1
            local maxStack = quantityDialog.stackSize or 200
            if count > 0 and count <= maxStack then
                quantityDialog:Hide()
                if onAccept then
                    onAccept(count)
                end
            else
                CreateStyledToast("Invalid quantity (1-" .. maxStack .. ")", 3, 0.5)
            end
        end)
        
        quantityDialog:Show()
    end
    
    -- Create an empty slot frame
    local function CreateEmptySlot(index)
        local slot = CreateFrame("Button", nil, attachmentGrid)
        slot:SetSize(SLOT_SIZE, SLOT_SIZE)
        
        -- Create a styled frame look
        local bg = slot:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
        
        -- Border
        local border = CreateFrame("Frame", nil, slot)
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        -- Plus icon for empty slots
        local plus = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        plus:SetPoint("CENTER")
        plus:SetText("+")
        plus:SetTextColor(0.5, 0.5, 0.5)
        
        -- Highlight on mouse over
        slot:SetScript("OnEnter", function(self)
            bg:SetVertexColor(0.15, 0.15, 0.15, 0.9)
            border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
            plus:SetTextColor(0.7, 0.7, 0.7)
        end)
        slot:SetScript("OnLeave", function(self)
            bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
            border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            plus:SetTextColor(0.5, 0.5, 0.5)
        end)
        
        -- Make it a drop target
        slot:SetScript("OnReceiveDrag", function()
            if CursorHasItem() and #attachedItems < MAX_ATTACHMENTS then
                local type, id, link = GetCursorInfo()
                if type == "item" then
                    local name, _, _, _, _, _, _, maxStack, _, texture = GetItemInfo(link)
                    
                    -- Check if Shift is held for quantity input
                    if IsShiftKeyDown() then
                        -- Get how many the player has (would need to be passed from server or inventory check)
                        local available = 200  -- Default, would need actual count
                        
                        ShowQuantityDialog(name, id, link, texture, function(count)
                            AddItems({{
                                id = id,
                                link = link,
                                icon = texture,
                                name = name,
                                count = count
                            }})
                            ClearCursor()
                        end, maxStack, available)
                    else
                        -- Default behavior - add 1
                        AddItems({{
                            id = id,
                            link = link,
                            icon = texture,
                            name = name,
                            count = 1
                        }})
                        ClearCursor()
                    end
                end
            end
        end)
        
        slot.bg = bg
        slot.border = border
        slot.plus = plus
        slot.isEmpty = true
        slot.index = index
        
        return slot
    end
    
    -- Function to update attachment display
    local function UpdateAttachmentDisplay()
        -- Hide all existing slots
        for _, slot in ipairs(attachmentSlots) do
            slot:Hide()
            slot:SetParent(nil)
        end
        wipe(attachmentSlots)
        wipe(selectedForRemoval)
        
        -- Calculate how many slots to show (items + 1 empty, max 12)
        local slotsToShow = math.min(#attachedItems + 1, MAX_ATTACHMENTS)
        
        -- Create slots
        for i = 1, slotsToShow do
            local col = ((i - 1) % 6)
            local row = math.floor((i - 1) / 6)
            local x = col * (SLOT_SIZE + SLOT_SPACING)
            local y = -row * (SLOT_SIZE + SLOT_SPACING)
            
            if i <= #attachedItems then
                -- Create item card
                local item = attachedItems[i]
                local card = CreateStyledCard(attachmentGrid, SLOT_SIZE, {
                    texture = item.icon or GetItemIconSafe(item.id),
                    count = item.count or 1,
                    quality = item.quality or "Common",
                    link = item.link,
                    onClick = function(self)
                        -- Toggle selection for removal
                        if selectedForRemoval[i] then
                            selectedForRemoval[i] = nil
                            self.selectionBorder:Hide()
                        else
                            selectedForRemoval[i] = true
                            -- Create selection border if it doesn't exist
                            if not self.selectionBorder then
                                self.selectionBorder = self:CreateTexture(nil, "OVERLAY")
                                self.selectionBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                                self.selectionBorder:SetBlendMode("ADD")
                                self.selectionBorder:SetAlpha(0.7)
                                self.selectionBorder:SetPoint("TOPLEFT", -2, 2)
                                self.selectionBorder:SetPoint("BOTTOMRIGHT", 2, -2)
                            end
                            self.selectionBorder:Show()
                        end
                        
                        -- Enable remove button if any selected
                        local hasSelection = false
                        for _ in pairs(selectedForRemoval) do
                            hasSelection = true
                            break
                        end
                        if hasSelection then
                            removeSelectedButton:Enable()
                        else
                            removeSelectedButton:Disable()
                        end
                    end
                })
                
                card:SetPoint("TOPLEFT", attachmentGrid, "TOPLEFT", x, y)
                card.itemIndex = i
                table.insert(attachmentSlots, card)
            else
                -- Create empty slot
                local emptySlot = CreateEmptySlot(i)
                emptySlot:SetPoint("TOPLEFT", attachmentGrid, "TOPLEFT", x, y)
                
                -- First empty slot shows hint text
                if i == 1 then
                    emptySlot.plus:SetText("Drop\nHere")
                    emptySlot.plus:SetTextColor(0.5, 0.5, 0.5)
                    -- Use smaller font
                    local font, size, flags = emptySlot.plus:GetFont()
                    emptySlot.plus:SetFont(font, 10, flags)
                    
                    -- Add tooltip hint about shift-click
                    emptySlot:SetScript("OnEnter", function(self)
                        self.bg:SetVertexColor(0.15, 0.15, 0.15, 0.9)
                        self.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                        self.plus:SetTextColor(0.7, 0.7, 0.7)
                        
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText("Drop items here")
                        GameTooltip:AddLine("Hold SHIFT while dropping to specify quantity", 0.7, 0.7, 0.7)
                        GameTooltip:Show()
                    end)
                    emptySlot:SetScript("OnLeave", function(self)
                        self.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
                        self.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                        self.plus:SetTextColor(0.5, 0.5, 0.5)
                        GameTooltip:Hide()
                    end)
                end
                
                table.insert(attachmentSlots, emptySlot)
            end
        end
        
        -- Update counter
        local count = #attachedItems
        attachmentCounter:SetText("(" .. count .. "/12)")
        if count >= 10 then
            attachmentCounter:SetTextColor(1, 0.5, 0)  -- Orange when near limit
        elseif count >= 12 then
            attachmentCounter:SetTextColor(1, 0, 0)  -- Red when full
        else
            attachmentCounter:SetTextColor(0.6, 0.6, 0.6)  -- Normal gray
        end
        
        -- Update button states
        if count > 0 then
            clearAllButton:Enable()
        else
            clearAllButton:Disable()
        end
        
        if count < MAX_ATTACHMENTS then
            addItemsButton:Enable()
        else
            addItemsButton:Disable()
        end
        
        removeSelectedButton:Disable()  -- Reset remove button
    end
    
    -- Function to add items
    AddItems = function(items)
        -- AddItems called
        local added = 0
        for _, item in ipairs(items) do
            local itemCount = item.count or 1
            -- Processing item
            if #attachedItems < MAX_ATTACHMENTS then
                table.insert(attachedItems, {
                    id = item.entry or item.id,
                    link = item.link or ("item:" .. (item.entry or item.id)),
                    icon = item.icon,
                    count = itemCount,
                    quality = item.quality,
                    name = item.name
                })
                added = added + 1
            else
                break
            end
        end
        
        -- Items added to attachments
        UpdateAttachmentDisplay()
        
        if added > 0 then
            CreateStyledToast("Added " .. added .. " item(s)", 2, 0.5)
        end
        
        local remaining = MAX_ATTACHMENTS - #attachedItems
        if remaining == 0 then
            CreateStyledToast("Attachment limit reached!", 3, 0.5)
        end
    end
    
    -- Function to remove selected items
    local function RemoveSelectedItems()
        -- Build list of indices to remove (in reverse order)
        local toRemove = {}
        for idx in pairs(selectedForRemoval) do
            table.insert(toRemove, idx)
        end
        table.sort(toRemove, function(a, b) return a > b end)  -- Sort descending
        
        -- Remove items
        for _, idx in ipairs(toRemove) do
            table.remove(attachedItems, idx)
        end
        
        UpdateAttachmentDisplay()
        CreateStyledToast("Removed " .. #toRemove .. " item(s)", 2, 0.5)
    end
    
    -- Add items button handler
    addItemsButton:SetScript("OnClick", function()
        if GMMenus and GMMenus.ItemSelection and GMMenus.ItemSelection.ShowMultiSelectDialog then
            local remaining = MAX_ATTACHMENTS - #attachedItems
            GMMenus.ItemSelection.ShowMultiSelectDialog(function(selectedItems)
                -- ShowMultiSelectDialog callback triggered
                if selectedItems and next(selectedItems) then
                    local itemList = {}
                    for _, item in pairs(selectedItems) do
                        -- Item from callback
                        table.insert(itemList, item)
                    end
                    AddItems(itemList)
                else
                    -- No items selected
                end
            end, remaining)
        else
            CreateStyledToast("Item selection not available", 3, 0.5)
        end
    end)
    
    -- Clear all button handler
    clearAllButton:SetScript("OnClick", function()
        wipe(attachedItems)
        UpdateAttachmentDisplay()
        CreateStyledToast("All attachments removed", 2, 0.5)
    end)
    
    -- Remove selected button handler
    removeSelectedButton:SetScript("OnClick", function()
        RemoveSelectedItems()
    end)
    
    -- Support drag and drop on the container as fallback
    attachmentContainer:SetScript("OnReceiveDrag", function()
        -- OnReceiveDrag triggered
        if CursorHasItem() and #attachedItems < MAX_ATTACHMENTS then
            local type, id, link = GetCursorInfo()
            -- Cursor has item
            if type == "item" then
                local name, _, _, _, _, _, _, maxStack, _, texture = GetItemInfo(link)
                
                -- Check if Shift is held for quantity input
                if IsShiftKeyDown() then
                    -- Get how many the player has (would need to be passed from server or inventory check)
                    local available = 200  -- Default, would need actual count
                    
                    ShowQuantityDialog(name, id, link, texture, function(count)
                        AddItems({{
                            id = id,
                            link = link,
                            icon = texture,
                            name = name,
                            count = count
                        }})
                        ClearCursor()
                    end, maxStack, available)
                else
                    -- Default behavior - add 1
                    AddItems({{
                        id = id,
                        link = link,
                        icon = texture,
                        name = name,
                        count = 1
                    }})
                    ClearCursor()
                end
            end
        elseif #attachedItems >= MAX_ATTACHMENTS then
            CreateStyledToast("Attachment limit reached!", 3, 0.5)
        end
    end)
    
    -- Initial update to show first empty slot
    UpdateAttachmentDisplay()
    
    -- Money section
    local moneyLabel = mailFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    moneyLabel:SetPoint("TOPLEFT", attachmentContainer, "BOTTOMLEFT", 0, -20)
    moneyLabel:SetText("Send Money:")
    moneyLabel:SetTextColor(0.8, 0.8, 0.8)
    
    -- Gold input
    local goldBoxContainer = CreateStyledEditBox(mailFrame, 60, true, 6)
    goldBoxContainer:SetPoint("LEFT", moneyLabel, "RIGHT", 10, 0)
    local goldBox = goldBoxContainer:GetChildren()
    
    local goldIcon = mailFrame:CreateTexture(nil, "ARTWORK")
    goldIcon:SetSize(14, 14)
    goldIcon:SetPoint("LEFT", goldBoxContainer, "RIGHT", 3, 0)
    goldIcon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
    
    -- Silver input
    local silverBoxContainer = CreateStyledEditBox(mailFrame, 40, true, 2)
    silverBoxContainer:SetPoint("LEFT", goldIcon, "RIGHT", 10, 0)
    local silverBox = silverBoxContainer:GetChildren()
    
    local silverIcon = mailFrame:CreateTexture(nil, "ARTWORK")
    silverIcon:SetSize(14, 14)
    silverIcon:SetPoint("LEFT", silverBoxContainer, "RIGHT", 3, 0)
    silverIcon:SetTexture("Interface\\MoneyFrame\\UI-SilverIcon")
    
    -- Copper input
    local copperBoxContainer = CreateStyledEditBox(mailFrame, 40, true, 2)
    copperBoxContainer:SetPoint("LEFT", silverIcon, "RIGHT", 10, 0)
    local copperBox = copperBoxContainer:GetChildren()
    
    local copperIcon = mailFrame:CreateTexture(nil, "ARTWORK")
    copperIcon:SetSize(14, 14)
    copperIcon:SetPoint("LEFT", copperBoxContainer, "RIGHT", 3, 0)
    copperIcon:SetTexture("Interface\\MoneyFrame\\UI-CopperIcon")
    
    -- COD checkbox
    local codCheckbox = CreateStyledCheckbox(mailFrame, "Cash on Delivery (COD)")
    codCheckbox:SetPoint("TOPLEFT", moneyLabel, "BOTTOMLEFT", 0, -15)
    codCheckbox:SetTooltip("Request payment on delivery", "The recipient must pay the specified amount to receive the mail")
    
    -- Loading bar (hidden by default)
    local loadingBar = CreateStyledLoadingBar(mailFrame, 300, 20)
    loadingBar:SetPoint("BOTTOM", mailFrame, "BOTTOM", 0, 60)
    loadingBar:Hide()
    
    -- Buttons
    local sendButton = CreateStyledButton(mailFrame, "Send Mail", 120, 30)
    sendButton:SetPoint("BOTTOMRIGHT", mailFrame, "BOTTOMRIGHT", -20, 20)
    sendButton:SetScript("OnClick", function()
        local subject = subjectBox:GetText()
        local message = messageBox:GetText()
        
        -- Calculate total money in copper
        local gold = tonumber(goldBox:GetText()) or 0
        local silver = tonumber(silverBox:GetText()) or 0
        local copper = tonumber(copperBox:GetText()) or 0
        local totalCopper = (gold * 10000) + (silver * 100) + copper
        
        if subject == "" then
            CreateStyledToast("Please enter a subject", 3, 0.5)
            return
        end
        
        if message == "" then
            CreateStyledToast("Please enter a message", 3, 0.5)
            return
        end
        
        -- Prepare item data
        local itemsToSend = {}
        for _, item in ipairs(attachedItems) do
            table.insert(itemsToSend, item.id)
        end
        
        -- Show loading bar
        loadingBar:Show()
        loadingBar:SetProgress(0)
        sendButton:Disable()
        
        -- Animate loading bar
        local elapsed = 0
        mailFrame:SetScript("OnUpdate", function(self, delta)
            elapsed = elapsed + delta
            loadingBar:SetProgress(elapsed / 1.5) -- 1.5 second send time
            
            if elapsed >= 1.5 then
                self:SetScript("OnUpdate", nil)
                
                -- Send the mail with items
                local isCOD = codCheckbox:GetChecked()
                local codAmount = isCOD and totalCopper or 0
                
                -- Prepare item data in format needed for server
                local itemData = {}
                for i, item in ipairs(attachedItems) do
                    -- Sending item
                    table.insert(itemData, {
                        entry = item.id,
                        amount = item.count or 1
                    })
                end
                
                AIO.Handle("GameMasterSystem", "sendPlayerMailWithItems", {
                    recipient = playerName,
                    subject = subject,
                    message = message,
                    money = isCOD and 0 or totalCopper,  -- If COD, money goes in cod field
                    cod = codAmount,
                    items = itemData,
                    stationery = 61,  -- GM stationery (61)
                    delay = 0
                })
                
                -- Show success message
                local itemCount = #itemsToSend
                if itemCount > 0 then
                    CreateStyledToast("Mail sent with " .. itemCount .. " item(s)!", 3, 0.5)
                else
                    CreateStyledToast("Mail sent successfully!", 3, 0.5)
                end
                
                -- Hide the frame
                mailFrame:Hide()
            end
        end)
    end)
    
    local cancelButton = CreateStyledButton(mailFrame, "Cancel", 100, 30)
    cancelButton:SetPoint("BOTTOMLEFT", mailFrame, "BOTTOMLEFT", 20, 20)
    cancelButton:SetScript("OnClick", function()
        mailFrame:Hide()
    end)
    
    -- Make ESC close the frame
    tinsert(UISpecialFrames, mailFrame:GetName() or "GMMailFrame")
    
    -- Focus subject box
    subjectBox:SetFocus()
    
    return mailFrame
end

-- Client handlers module loaded