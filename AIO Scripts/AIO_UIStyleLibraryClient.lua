local AIO = AIO or require("AIO")

if AIO.AddAddon() then
    return
end

-- ===================================
-- UI STYLE LIBRARY FOR WOW 3.3.5 AIO
-- ===================================
-- A reusable AIO client library for creating consistent dark-themed UI components
-- Compatible with WoW 3.3.5 client limitations

-- ===================================
-- HELPER FUNCTIONS FOR 3.3.5 COMPATIBILITY
-- ===================================

-- Helper function for WoW 3.3.5 compatible timers (C_Timer doesn't exist in 3.3.5)
local function CreateTimer(delay, callback)
    if not delay or not callback then
        return nil
    end
    
    local frame = CreateFrame("Frame")
    local elapsed = 0
    
    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= delay then
            self:SetScript("OnUpdate", nil)
            if callback then
                callback()
            end
        end
    end)
    
    -- Return a timer object with Cancel method
    return {
        Cancel = function()
            frame:SetScript("OnUpdate", nil)
        end
    }
end

-- ===================================
-- COLOR SYSTEM
-- ===================================

-- Define global color constants for consistency across addons
UISTYLE_COLORS = {
    -- Base colors
    Black = { 0, 0, 0 },
    DarkGrey = { 0.06, 0.06, 0.06 }, -- Main background
    SectionBg = { 0.12, 0.12, 0.12 }, -- Section header backgrounds
    OptionBg = { 0.08, 0.08, 0.08 }, -- Option area backgrounds
    BorderGrey = { 0.2, 0.2, 0.2 }, -- Borders
    TextGrey = { 0.7, 0.7, 0.7 }, -- Inactive text
    White = { 1, 1, 1 },
    -- Add more colors as needed

    -- Accent colors
    Blue = { 0.31, 0.69, 0.89 },
    Gold = { 1, 0.82, 0 },
    Green = { 0.31, 0.89, 0.31 },
    Red = { 0.89, 0.31, 0.31 },
    Orange = { 1, 0.5, 0 },
    Purple = { 0.64, 0.21, 0.93 },
    Yellow = { 1, 1, 0 },
    -- Add more accent colors as needed

    -- Item quality colors (WoW standard)
    Poor = { 0.62, 0.62, 0.62 }, -- Grey
    Common = { 1, 1, 1 }, -- White
    Uncommon = { 0.12, 1, 0 }, -- Green
    Rare = { 0, 0.44, 0.87 }, -- Blue
    Epic = { 0.64, 0.21, 0.93 }, -- Purple
    Legendary = { 1, 0.5, 0 }, -- Orange
    --    Add more item qualities as needed
}

-- ===================================
-- BACKDROP TEMPLATES
-- ===================================

UISTYLE_BACKDROPS = {
    Frame = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    },
    Solid = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
    },
}

-- ===================================
-- UI CONSTANTS
-- ===================================

UISTYLE_PADDING = 10
UISTYLE_SMALL_PADDING = 5
UISTYLE_SECTION_SPACING = 2

-- ===================================
-- TOOLTIP HELPER
-- ===================================

--[[
Sets up a tooltip for a frame
@param frame - The frame to attach tooltip to
@param text - Main tooltip text
@param subtext - Optional secondary text (appears in different color)
]]
local function SetupTooltip(frame, text, subtext)
    if not text then
        return
    end

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        if subtext then
            GameTooltip:AddLine(subtext, 0.7, 0.7, 0.7, true)
        end
        GameTooltip:Show()

        -- Call original OnEnter if it exists
        if self.originalOnEnter then
            self:originalOnEnter()
        end
    end)

    -- Store original OnLeave handler
    local originalOnLeave = frame:GetScript("OnLeave")
    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()

        -- Call original OnLeave if it exists
        if originalOnLeave then
            originalOnLeave(self)
        end
    end)
end

-- ===================================
-- CORE WIDGET FUNCTIONS
-- ===================================

--[[
Creates a styled frame with dark theme and optional background color
@param parent - Parent frame
@param bgColor - Optional background color (defaults to DarkGrey)
@return Frame with dark styling applied
]]
function CreateStyledFrame(parent, bgColor)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetBackdrop(UISTYLE_BACKDROPS.Frame)

    local bg = bgColor or UISTYLE_COLORS.DarkGrey
    frame:SetBackdropColor(bg[1], bg[2], bg[3], 1)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    return frame
end

--[[
Creates a styled button with dark theme
@param parent - Parent frame
@param text - Button text
@param width - Optional width (defaults to auto-size)
@param height - Optional height (defaults to 22)
@return Styled button
]]
function CreateStyledButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(height or 22)
    if width then
        button:SetWidth(width)
    end

    -- Button backdrop
    button:SetBackdrop(UISTYLE_BACKDROPS.Frame)
    button:SetBackdropColor(UISTYLE_COLORS.SectionBg[1], UISTYLE_COLORS.SectionBg[2], UISTYLE_COLORS.SectionBg[3], 1)
    button:SetBackdropBorderColor(UISTYLE_COLORS.BorderGrey[1], UISTYLE_COLORS.BorderGrey[2], UISTYLE_COLORS.BorderGrey[3], 1)

    -- Button text
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText(text or "Button")
    label:SetTextColor(1, 1, 1, 1)
    button.text = label

    -- Auto-size if no width specified
    if not width then
        button:SetWidth(label:GetStringWidth() + 20)
    end

    -- Hover effects
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(UISTYLE_COLORS.SectionBg[1], UISTYLE_COLORS.SectionBg[2], UISTYLE_COLORS.SectionBg[3], 1)
    end)

    -- Click effect
    button:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.05, 0.05, 0.05, 1)
    end)

    button:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
    end)

    -- Add SetTooltip method
    button.SetTooltip = function(self, text, subtext)
        -- Store original handlers
        self.originalOnEnter = self:GetScript("OnEnter")
        self.originalOnLeave = self:GetScript("OnLeave")

        self:SetScript("OnEnter", function(self)
            -- Show tooltip
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text, 1, 1, 1, 1, true)
            if subtext then
                GameTooltip:AddLine(subtext, 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()

            -- Call original hover effect
            if self.originalOnEnter then
                self:originalOnEnter()
            end
        end)

        self:SetScript("OnLeave", function(self)
            GameTooltip:Hide()

            -- Call original hover effect
            if self.originalOnLeave then
                self:originalOnLeave()
            end
        end)
    end

    return button
end

--[[
Creates a styled checkbox with clickable row
@param parent - Parent frame
@param text - Checkbox label text
@return Checkbox frame with check property
]]
function CreateStyledCheckbox(parent, text)
    -- Make the entire frame clickable
    local frame = CreateFrame("Button", nil, parent)
    frame:SetHeight(24)
    frame:EnableMouse(true)

    -- Add border around the entire clickable area
    frame:SetBackdrop(UISTYLE_BACKDROPS.Frame)
    frame:SetBackdropColor(0, 0, 0, 0) -- Transparent background
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.5) -- Subtle border

    -- Create visual checkbox (not clickable)
    local check = CreateFrame("Frame", nil, frame)
    check:SetSize(14, 14) -- Slightly larger for better visibility
    check:SetPoint("LEFT", 6, 0)

    -- Custom checkbox appearance
    check:SetBackdrop(UISTYLE_BACKDROPS.Frame)
    check:SetBackdropColor(0.1, 0.1, 0.1, 1) -- Dark grey background instead of transparent
    check:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) -- Lighter grey border

    -- Label
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", check, "RIGHT", UISTYLE_SMALL_PADDING, 0)
    label:SetText(text)
    label:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3])
    label:SetJustifyH("LEFT")

    -- Highlight texture for hover
    local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlight:SetVertexColor(1, 1, 1, 0.03)
    highlight:SetPoint("TOPLEFT", 1, -1)
    highlight:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Checked state
    local checked = false

    -- Custom SetChecked function
    local function SetChecked(self, isChecked)
        checked = isChecked
        if checked then
            check:SetBackdropColor(0.9, 0.9, 0.9, 1) -- Bright white/grey fill when checked
            check:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
            label:SetTextColor(1, 1, 1, 1)
        else
            check:SetBackdropColor(0.1, 0.1, 0.1, 1) -- Dark grey when unchecked
            check:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            label:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3])
        end
    end

    local function GetChecked(self)
        return checked
    end

    -- Click handler for entire frame
    frame:SetScript("OnClick", function(self)
        SetChecked(self, not GetChecked(self))
    end)

    -- Hover effect
    frame:SetScript("OnEnter", function(self)
        if checked then
            check:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
        else
            check:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        end
    end)

    frame:SetScript("OnLeave", function(self)
        if checked then
            check:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
        else
            check:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
    end)

    -- Expose functions and elements
    frame.SetChecked = SetChecked
    frame.GetChecked = GetChecked
    frame.check = check
    frame.label = label
    frame.SetTooltip = function(self, text, subtext)
        -- Store original handlers
        self.originalOnEnter = self:GetScript("OnEnter")
        self.originalOnLeave = self:GetScript("OnLeave")

        self:SetScript("OnEnter", function(self)
            -- Show tooltip
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text, 1, 1, 1, 1, true)
            if subtext then
                GameTooltip:AddLine(subtext, 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()

            -- Call original hover effect
            if self.originalOnEnter then
                self:originalOnEnter()
            end
        end)

        self:SetScript("OnLeave", function(self)
            GameTooltip:Hide()

            -- Call original hover effect
            if self.originalOnLeave then
                self:originalOnLeave()
            end
        end)
    end

    return frame
end

--[[
Creates a quality toggle button (colored square with outline/fill states)
@param parent - Parent frame
@param color - Quality color {r, g, b}
@param size - Optional size (defaults to 16)
@return Quality toggle button
]]
function CreateQualityToggle(parent, color, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size or 16, size or 16)

    -- Store the quality color for later use
    button.qualityColor = color
    button.enabled = true -- Track enabled state

    -- Background with border
    button:SetBackdrop(UISTYLE_BACKDROPS.Frame)

    -- Set initial state (unchecked = colored border)
    button.checked = false
    button:SetBackdropColor(0, 0, 0, 0) -- Transparent background
    button:SetBackdropBorderColor(color[1], color[2], color[3], 1) -- Colored border

    -- Update visual state based on enabled and checked
    local function UpdateVisualState(self)
        local dimFactor = self.enabled and 1 or 0.3 -- Dim to 30% when disabled

        if self.checked then
            -- Filled state with quality color
            self:SetBackdropColor(
                    self.qualityColor[1] * dimFactor,
                    self.qualityColor[2] * dimFactor,
                    self.qualityColor[3] * dimFactor,
                    0.8  -- Slightly transparent when checked
            )
            self:SetBackdropBorderColor(
                    self.qualityColor[1] * dimFactor,
                    self.qualityColor[2] * dimFactor,
                    self.qualityColor[3] * dimFactor,
                    1
            )
        else
            -- Outline only with colored border
            self:SetBackdropColor(0, 0, 0, 0)
            self:SetBackdropBorderColor(
                    self.qualityColor[1] * dimFactor,
                    self.qualityColor[2] * dimFactor,
                    self.qualityColor[3] * dimFactor,
                    1
            )
        end
    end

    -- State management
    button.SetChecked = function(self, checked)
        self.checked = checked
        UpdateVisualState(self)
    end

    button.GetChecked = function(self)
        return self.checked
    end

    button.SetEnabled = function(self, enabled)
        self.enabled = enabled
        self:EnableMouse(enabled) -- Disable mouse interaction when disabled
        UpdateVisualState(self)
    end

    button.GetEnabled = function(self)
        return self.enabled
    end

    button.SetTooltip = function(self, text, subtext)
        self.tooltipText = text
        self.tooltipSubtext = subtext
    end

    -- Click handler
    button:SetScript("OnClick", function(self)
        if self.enabled then
            -- Only allow clicks when enabled
            self:SetChecked(not self:GetChecked())
        end
    end)

    -- Hover effect
    button:SetScript("OnEnter", function(self)
        -- Show tooltip if set
        if self.tooltipText then
            -- Check parent strata to determine if we need elevated tooltip
            local parent = self:GetParent()
            while parent and parent ~= UIParent do
                local strata = parent:GetFrameStrata()
                if strata == "TOOLTIP" or strata == "FULLSCREEN_DIALOG" then
                    -- Use elevated tooltip
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetFrameStrata("TOOLTIP")
                    GameTooltip:SetFrameLevel(self:GetFrameLevel() + 10)
                    GameTooltip:SetText(self.tooltipText, 1, 1, 1, 1, true)
                    if self.tooltipSubtext then
                        GameTooltip:AddLine(self.tooltipSubtext, 0.7, 0.7, 0.7, true)
                    end
                    GameTooltip:Show()
                    break
                end
                parent = parent:GetParent()
            end
            
            -- If no high-level parent found, use normal tooltip
            if parent == UIParent then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.tooltipText, 1, 1, 1, 1, true)
                if self.tooltipSubtext then
                    GameTooltip:AddLine(self.tooltipSubtext, 0.7, 0.7, 0.7, true)
                end
                GameTooltip:Show()
            end
        end

        if self.enabled and not self:GetChecked() then
            -- Slightly transparent fill on hover (only when enabled)
            self:SetBackdropColor(self.qualityColor[1], self.qualityColor[2], self.qualityColor[3], 0.3)
        end
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()

        if self.enabled and not self:GetChecked() then
            -- Back to transparent
            self:SetBackdropColor(0, 0, 0, 0)
        elseif not self.enabled then
            -- Ensure disabled state is maintained
            UpdateVisualState(self)
        end
    end)

    return button
end

--[[
Creates a checkbox with quality toggles arranged in two rows
@param parent - Parent frame
@param text - Checkbox label text
@param hasValue - Whether to show an editable value
@param value - Default value (if hasValue is true)
@param hasQualityToggles - Whether to show quality toggle buttons
@return Complex checkbox frame with quality toggles
]]
function CreateCheckboxWithQualityToggles(parent, text, hasValue, value, hasQualityToggles)
    -- Make the entire frame clickable
    local frame = CreateFrame("Button", nil, parent)
    -- Increase height to accommodate two rows when quality toggles are present
    frame:SetHeight(hasQualityToggles and 40 or 24)
    frame:EnableMouse(true)

    -- Add border around the entire clickable area
    frame:SetBackdrop(UISTYLE_BACKDROPS.Frame)
    frame:SetBackdropColor(0, 0, 0, 0) -- Transparent background
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.5) -- Subtle border

    -- Create visual checkbox (not clickable)
    local check = CreateFrame("Frame", nil, frame)
    check:SetSize(14, 14) -- Match simple checkbox size
    -- Position checkbox vertically centered if no quality toggles, otherwise align to top
    local checkYOffset = hasQualityToggles and 8 or 0
    check:SetPoint("LEFT", 6, checkYOffset)

    -- Custom checkbox appearance
    check:SetBackdrop(UISTYLE_BACKDROPS.Frame)
    check:SetBackdropColor(0.1, 0.1, 0.1, 1) -- Dark grey background to match simple checkbox
    check:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) -- Lighter grey border

    -- Label
    local labelText = text
    if hasValue and value then
        labelText = text .. " (" .. value .. ")"
    end

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    -- Adjust label position based on checkbox position
    label:SetPoint("LEFT", check, "RIGHT", UISTYLE_SMALL_PADDING, 0)
    label:SetText(labelText)
    label:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3])
    label:SetJustifyH("LEFT")

    -- Edit box for value (if needed)
    local editBox, valueStart, valueEnd
    if hasValue then
        -- Find the position of the value in the label
        valueStart = string.find(labelText, "%(")
        valueEnd = string.find(labelText, "%)")

        editBox = CreateFrame("EditBox", nil, frame)
        editBox:SetSize(50, 16)
        editBox:SetBackdrop(UISTYLE_BACKDROPS.Frame)
        editBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
        editBox:SetBackdropBorderColor(UISTYLE_COLORS.Blue[1], UISTYLE_COLORS.Blue[2], UISTYLE_COLORS.Blue[3], 1)
        editBox:SetFontObject("GameFontNormalSmall")
        editBox:SetTextColor(1, 1, 1, 1)
        editBox:SetAutoFocus(false)
        editBox:SetNumeric(true)
        editBox:SetMaxLetters(4)
        editBox:Hide()

        -- Position it over the value text
        editBox:SetPoint("LEFT", label, "LEFT", label:GetStringWidth() - 50, 0)
    end

    -- Quality toggles (if needed)
    local qualityToggles = {}
    if hasQualityToggles then
        local qualities = {
            { name = "Poor", color = UISTYLE_COLORS.Poor },
            { name = "Common", color = UISTYLE_COLORS.Common },
            { name = "Uncommon", color = UISTYLE_COLORS.Uncommon },
            { name = "Rare", color = UISTYLE_COLORS.Rare },
            { name = "Epic", color = UISTYLE_COLORS.Epic },
        }

        -- Position quality toggles below the checkbox/text on second row
        local toggleStartX = 25  -- Align with text start position (checkbox width + padding)

        for i, quality in ipairs(qualities) do
            local toggle = CreateQualityToggle(frame, quality.color, 14)

            -- Position from left to right, below the checkbox
            local xOffset = toggleStartX + ((i - 1) * 17)  -- 14px width + 3px spacing
            toggle:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, -20)

            -- Stop propagation of clicks on quality toggles
            toggle:SetScript("OnClick", function(self)
                self:SetChecked(not self:GetChecked())
            end)

            table.insert(qualityToggles, toggle)
        end
    end

    -- Extend clickable area to full width with some padding
    frame:SetPoint("RIGHT", parent, "RIGHT", -2, 0)

    -- Highlight texture for hover
    local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlight:SetVertexColor(1, 1, 1, 0.03)
    highlight:SetPoint("TOPLEFT", 1, -1)
    highlight:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Checked state
    local checked = false

    -- Custom SetChecked function
    local function SetChecked(self, isChecked)
        checked = isChecked
        if checked then
            check:SetBackdropColor(0.9, 0.9, 0.9, 1) -- Bright white/grey fill when checked
            check:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
            label:SetTextColor(1, 1, 1, 1)
        else
            check:SetBackdropColor(0.1, 0.1, 0.1, 1) -- Dark grey when unchecked
            check:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            label:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3])
        end

        -- Update quality toggles enabled state if they exist
        if hasQualityToggles and #qualityToggles > 0 then
            for _, toggle in ipairs(qualityToggles) do
                toggle:SetEnabled(checked)
            end
        end
    end

    local function GetChecked(self)
        return checked
    end

    -- Click handler for main checkbox area (avoid quality toggles)
    frame:SetScript("OnClick", function(self)
        SetChecked(self, not GetChecked(self))
    end)

    -- Right-click handler for value editing
    if hasValue then
        frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        frame:SetScript("OnClick", function(self, button)
            if button == "RightButton" and hasValue then
                -- Show edit box for value editing
                editBox:SetText(tostring(value))
                editBox:Show()
                editBox:SetFocus()
                editBox:HighlightText()

                -- Hide edit box when done
                editBox:SetScript("OnEnterPressed", function(self)
                    local newValue = tonumber(self:GetText()) or value
                    value = newValue
                    labelText = text .. " (" .. value .. ")"
                    label:SetText(labelText)
                    self:Hide()
                end)

                editBox:SetScript("OnEscapePressed", function(self)
                    self:Hide()
                end)
            else
                SetChecked(self, not GetChecked(self))
            end
        end)
    end

    -- Hover effect
    frame:SetScript("OnEnter", function(self)
        if checked then
            check:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
        else
            check:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        end
    end)

    frame:SetScript("OnLeave", function(self)
        if checked then
            check:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
        else
            check:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
    end)

    -- Initialize quality toggles to disabled state if checkbox starts unchecked
    if hasQualityToggles and #qualityToggles > 0 and not checked then
        for _, toggle in ipairs(qualityToggles) do
            toggle:SetEnabled(false)
        end
    end

    -- Expose functions and elements
    frame.SetChecked = SetChecked
    frame.GetChecked = GetChecked
    frame.check = check
    frame.label = label
    frame.qualityToggles = qualityToggles
    frame.editBox = editBox
    frame.SetTooltip = function(self, text, subtext)
        -- Store original handlers
        self.originalOnEnter = self:GetScript("OnEnter")
        self.originalOnLeave = self:GetScript("OnLeave")

        self:SetScript("OnEnter", function(self)
            -- Show tooltip
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(text, 1, 1, 1, 1, true)
            if subtext then
                GameTooltip:AddLine(subtext, 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()

            -- Call original hover effect
            if self.originalOnEnter then
                self:originalOnEnter()
            end
        end)

        self:SetScript("OnLeave", function(self)
            GameTooltip:Hide()

            -- Call original hover effect
            if self.originalOnLeave then
                self:originalOnLeave()
            end
        end)
    end

    return frame
end

--[[
Creates a collapsible section header
@param parent - Parent frame
@param text - Header text
@param expanded - Initial expanded state
@return Section header button
]]
function CreateSectionHeader(parent, text, expanded)
    local header = CreateFrame("Button", nil, parent)
    header:SetHeight(22)
    header:SetBackdrop(UISTYLE_BACKDROPS.Frame)
    header:SetBackdropColor(UISTYLE_COLORS.SectionBg[1], UISTYLE_COLORS.SectionBg[2], UISTYLE_COLORS.SectionBg[3], 1)
    header:SetBackdropBorderColor(UISTYLE_COLORS.BorderGrey[1], UISTYLE_COLORS.BorderGrey[2], UISTYLE_COLORS.BorderGrey[3], 1)

    -- Expand/Collapse indicator
    local indicator = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    indicator:SetPoint("LEFT", 5, 0)
    indicator:SetText(expanded and "˅" or "˃")
    indicator:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3])
    header.indicator = indicator

    -- Section text
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("LEFT", indicator, "RIGHT", 3, 0)
    title:SetText(text)
    title:SetTextColor(1, 1, 1, 1)

    -- Expanded state
    header.expanded = expanded

    -- Toggle function
    header.SetExpanded = function(self, isExpanded)
        self.expanded = isExpanded
        indicator:SetText(isExpanded and "˅" or "˃")
    end

    -- Click handler
    header:SetScript("OnClick", function(self)
        self:SetExpanded(not self.expanded)
    end)

    -- Hover effect
    header:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
    end)

    header:SetScript("OnLeave", function(self)
        self:SetBackdropColor(UISTYLE_COLORS.SectionBg[1], UISTYLE_COLORS.SectionBg[2], UISTYLE_COLORS.SectionBg[3], 1)
    end)

    return header
end

--[[
Creates a styled scrollbar matching Dejunk dark theme
@param parent - Parent frame
@param width - Scrollbar width (defaults to 12)
@param height - Scrollbar height
@param orientation - "VERTICAL" or "HORIZONTAL" (defaults to "VERTICAL")
@return Styled scrollbar slider
]]
function CreateStyledScrollBar(parent, width, height, orientation)
    local scrollBar = CreateFrame("Slider", nil, parent)
    scrollBar:SetWidth(width or 12)
    scrollBar:SetHeight(height)
    scrollBar:SetOrientation(orientation or "VERTICAL")

    -- Track (background)
    local track = scrollBar:CreateTexture(nil, "BACKGROUND")
    track:SetTexture("Interface\\Buttons\\WHITE8X8")
    track:SetVertexColor(UISTYLE_COLORS.DarkGrey[1], UISTYLE_COLORS.DarkGrey[2], UISTYLE_COLORS.DarkGrey[3], 1)
    track:SetAllPoints()

    -- Border
    scrollBar:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    scrollBar:SetBackdropBorderColor(UISTYLE_COLORS.BorderGrey[1], UISTYLE_COLORS.BorderGrey[2], UISTYLE_COLORS.BorderGrey[3], 1)

    -- Thumb (the draggable part)
    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetVertexColor(0.3, 0.3, 0.3, 1) -- Slightly lighter than track

    if orientation == "HORIZONTAL" then
        thumb:SetSize(30, height - 4)
    else
        thumb:SetSize(width - 4, 30)
    end

    scrollBar:SetThumbTexture(thumb)

    -- Interactive states
    scrollBar.isHovered = false
    scrollBar.isDragging = false

    -- Hover effect
    scrollBar:EnableMouse(true)
    scrollBar:SetScript("OnEnter", function(self)
        self.isHovered = true
        thumb:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter on hover
    end)

    scrollBar:SetScript("OnLeave", function(self)
        self.isHovered = false
        if not self.isDragging then
            thumb:SetVertexColor(0.3, 0.3, 0.3, 1)
        end
    end)

    -- Dragging state
    scrollBar:SetScript("OnMouseDown", function(self)
        self.isDragging = true
        thumb:SetVertexColor(0.5, 0.5, 0.5, 1) -- Even lighter when dragging
    end)

    scrollBar:SetScript("OnMouseUp", function(self)
        self.isDragging = false
        if self.isHovered then
            thumb:SetVertexColor(0.4, 0.4, 0.4, 1)
        else
            thumb:SetVertexColor(0.3, 0.3, 0.3, 1)
        end
    end)

    return scrollBar
end

--[[
Creates a scrollable frame with styled scrollbar compatible with WoW 3.3.5

IMPORTANT WoW 3.3.5 NOTES:
1. The content frame MUST NOT be parented to the ScrollFrame
2. SetClipsChildren does not exist in 3.3.5
3. Always call SetScrollChild AFTER creating the content frame
4. Set content height explicitly after adding all elements

Usage Example:
    local container, content, scrollBar, updateScrollBar = CreateScrollableFrame(parent, 400, 300)
    -- Add your elements to 'content'
    -- Set content:SetHeight(totalHeight) based on your content
    -- Call updateScrollBar() to refresh the scrollbar

@param parent - Parent frame
@param width - Container width
@param height - Container height
@return container, content, scrollBar, updateScrollBar function
]]
function CreateScrollableFrame(parent, width, height)
    -- Container frame
    local container = CreateStyledFrame(parent, UISTYLE_COLORS.OptionBg)
    container:SetSize(width, height)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -14, 2) -- Leave room for scrollbar

    -- Content frame (what gets scrolled)
    -- CRITICAL: In WoW 3.3.5, the content frame MUST NOT be parented to scrollFrame!
    -- The ScrollFrame will manage the content's position when SetScrollChild is called
    local content = CreateFrame("Frame", nil, container)
    content:SetWidth(width - 16) -- Account for scrollbar and borders
    content:SetHeight(1) -- Initial height, will be adjusted by user

    -- Set the scroll child - this makes the ScrollFrame manage the content
    scrollFrame:SetScrollChild(content)

    -- Ensure the scroll frame shows content properly
    scrollFrame:Show()
    content:Show()

    -- Styled scrollbar
    local scrollBar = CreateStyledScrollBar(container, 12, height - 4)
    scrollBar:SetPoint("TOPRIGHT", -2, -2)
    scrollBar:SetPoint("BOTTOMRIGHT", -2, 2)
    scrollBar:SetMinMaxValues(0, 100)
    scrollBar:SetValue(0)

    -- Connect scrollbar to scroll frame
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    -- Mouse wheel support
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local step = 20 -- Scroll speed

        if delta > 0 then
            scrollBar:SetValue(math.max(min, current - step))
        else
            scrollBar:SetValue(math.min(max, current + step))
        end
    end)

    -- Update scrollbar when content changes
    local function UpdateScrollBar()
        local contentHeight = content:GetHeight()
        local frameHeight = scrollFrame:GetHeight()

        if contentHeight > frameHeight then
            local maxScroll = contentHeight - frameHeight
            scrollBar:SetMinMaxValues(0, maxScroll)
            scrollBar:Show()
            scrollFrame:SetPoint("BOTTOMRIGHT", -14, 2)
        else
            scrollBar:SetMinMaxValues(0, 0)
            scrollBar:Hide()
            scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
        end
    end

    return container, content, scrollBar, UpdateScrollBar
end

--[[
Creates a styled loading/progress bar with dark theme
@param parent - Parent frame
@param width - Optional width (defaults to 250)
@param height - Optional height (defaults to 24)
@return Styled loading bar frame with progress functionality
]]
function CreateStyledLoadingBar(parent, width, height)
    local loadingBarFrame = CreateStyledFrame(parent, UISTYLE_COLORS.DarkGrey)
    loadingBarFrame:SetSize(width or 250, height or 24)

    -- Progress bar background
    local progressBg = loadingBarFrame:CreateTexture(nil, "BACKGROUND")
    progressBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    progressBg:SetVertexColor(0.05, 0.05, 0.05, 1)
    progressBg:SetPoint("TOPLEFT", 2, -2)
    progressBg:SetPoint("BOTTOMRIGHT", -2, 2)

    -- Progress bar texture
    local loadingBarTexture = loadingBarFrame:CreateTexture(nil, "OVERLAY")
    loadingBarTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
    loadingBarTexture:SetVertexColor(UISTYLE_COLORS.Blue[1], UISTYLE_COLORS.Blue[2], UISTYLE_COLORS.Blue[3], 1)
    loadingBarTexture:SetPoint("LEFT", loadingBarFrame, "LEFT", 2, 0)
    loadingBarTexture:SetHeight((height or 24) - 4)
    loadingBarTexture:SetWidth(0)

    -- Percentage text
    local loadingBarPercentage = loadingBarFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    loadingBarPercentage:SetPoint("CENTER", loadingBarFrame, "CENTER", 0, 0)
    loadingBarPercentage:SetText("0%")

    -- Spark effect
    local loadingBarSpark = loadingBarFrame:CreateTexture(nil, "OVERLAY")
    loadingBarSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    loadingBarSpark:SetBlendMode("ADD")
    loadingBarSpark:SetWidth(20)
    loadingBarSpark:SetHeight(loadingBarFrame:GetHeight() * 1.5)
    loadingBarSpark:SetPoint("LEFT", loadingBarTexture, "RIGHT", -10, 0)
    loadingBarSpark:Hide()

    -- Progress update function
    function loadingBarFrame:SetProgress(progress)
        progress = math.max(0, math.min(1, progress)) -- Clamp between 0 and 1
        local width = (loadingBarFrame:GetWidth() - 4) * progress
        loadingBarTexture:SetWidth(width)
        loadingBarPercentage:SetText(math.floor(progress * 100) .. "%")

        if progress > 0 and progress < 1 then
            loadingBarSpark:SetPoint("LEFT", loadingBarTexture, "RIGHT", -10, 0)
            loadingBarSpark:Show()
        else
            loadingBarSpark:Hide()
        end
    end

    -- Reset function
    function loadingBarFrame:Reset()
        loadingBarTexture:SetWidth(0)
        loadingBarPercentage:SetText("0%")
        loadingBarSpark:Hide()
    end

    -- Set custom color
    function loadingBarFrame:SetBarColor(r, g, b, a)
        loadingBarTexture:SetVertexColor(r, g, b, a or 1)
    end

    -- Show/hide percentage text
    function loadingBarFrame:ShowPercentage(show)
        if show then
            loadingBarPercentage:Show()
        else
            loadingBarPercentage:Hide()
        end
    end

    -- Expose elements for advanced customization
    loadingBarFrame.texture = loadingBarTexture
    loadingBarFrame.percentage = loadingBarPercentage
    loadingBarFrame.spark = loadingBarSpark

    -- Initialize at 0%
    loadingBarFrame:Reset()

    return loadingBarFrame
end

--[[
Creates a styled dropdown menu with dark theme
@param parent - Parent frame
@param width - Width of the dropdown (excluding arrow)
@param items - Table of string options
@param defaultValue - Optional default selected value
@param onSelect - Callback function when selection changes
@return dropdown frame, background frame
]]
function CreateStyledDropdown(parent, width, items, defaultValue, onSelect)
    -- Generate unique global name (required for UIDropDownMenuTemplate in 3.3.5)
    local dropdownName = "UIStyleDropdown" .. math.random(100000, 999999)

    -- Create background frame with enhanced styling
    local dropdownBg = CreateStyledFrame(parent, UISTYLE_COLORS.SectionBg)
    dropdownBg:SetSize(width + 30, 32)

    -- Add inner shadow effect
    local innerShadow = dropdownBg:CreateTexture(nil, "OVERLAY")
    innerShadow:SetTexture("Interface\\Buttons\\WHITE8X8")
    innerShadow:SetVertexColor(0, 0, 0, 0.3)
    innerShadow:SetPoint("TOPLEFT", 1, -1)
    innerShadow:SetPoint("BOTTOMRIGHT", -1, 1)
    innerShadow:SetBlendMode("BLEND")

    -- Create dropdown with global name
    local dropdown = CreateFrame("Frame", dropdownName, dropdownBg, "UIDropDownMenuTemplate")
    dropdown:SetPoint("CENTER", dropdownBg, "CENTER", -16, 0)

    -- Style the dropdown text
    local dropdownText = _G[dropdownName .. "Text"]
    if dropdownText then
        dropdownText:SetTextColor(UISTYLE_COLORS.White[1], UISTYLE_COLORS.White[2], UISTYLE_COLORS.White[3], 1)
        dropdownText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    end

    -- Create a custom highlight overlay for better visual feedback
    local highlightOverlay = dropdownBg:CreateTexture(nil, "HIGHLIGHT")
    highlightOverlay:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlightOverlay:SetVertexColor(1, 1, 1, 0.05)
    highlightOverlay:SetPoint("TOPLEFT", 1, -1)
    highlightOverlay:SetPoint("BOTTOMRIGHT", -1, 1)

    -- Hide the default dropdown button borders (they don't match our theme)
    local leftTexture = _G[dropdownName .. "Left"]
    local middleTexture = _G[dropdownName .. "Middle"]
    local rightTexture = _G[dropdownName .. "Right"]
    if leftTexture then
        leftTexture:SetAlpha(0)
    end
    if middleTexture then
        middleTexture:SetAlpha(0)
    end
    if rightTexture then
        rightTexture:SetAlpha(0)
    end

    -- Helper function to process menu items recursively
    local function processMenuItem(item, level, parentList)
        local info = UIDropDownMenu_CreateInfo()
        
        -- Handle simple string items
        if type(item) == "string" then
            info.text = item
            info.value = item
            info.func = function()
                UIDropDownMenu_SetSelectedName(dropdown, item)
                if onSelect then
                    onSelect(item)
                end
            end
            info.checked = (UIDropDownMenu_GetSelectedName(dropdown) == item)
        -- Handle complex table items
        elseif type(item) == "table" then
            -- Required properties
            info.text = item.text or "Unnamed"
            info.value = item.value or item.text
            
            -- Optional properties
            info.hasArrow = item.hasArrow
            info.menuList = item.menuList
            info.disabled = item.disabled
            info.isTitle = item.isTitle
            info.notCheckable = item.notCheckable or item.isTitle
            
            -- Icon support
            if item.icon then
                info.icon = item.icon
                info.tCoordLeft = item.tCoordLeft or 0.1
                info.tCoordRight = item.tCoordRight or 0.9
                info.tCoordTop = item.tCoordTop or 0.1
                info.tCoordBottom = item.tCoordBottom or 0.9
            end
            
            -- Separator support
            if item.isSeparator then
                info = UIDropDownMenu_CreateInfo()
                info.text = ""
                info.disabled = true
                info.notClickable = true
                info.notCheckable = true
            else
                -- Function handling
                if item.func then
                    info.func = item.func
                elseif not item.hasArrow and not item.isTitle and not item.disabled then
                    -- Default selection behavior for non-submenu items
                    info.func = function()
                        UIDropDownMenu_SetSelectedName(dropdown, info.value)
                        if onSelect then
                            onSelect(info.value, item)
                        end
                    end
                end
                
                -- Checked state
                if item.checked ~= nil then
                    info.checked = item.checked
                elseif not item.notCheckable and not item.hasArrow then
                    info.checked = (UIDropDownMenu_GetSelectedName(dropdown) == info.value)
                end
            end
        end
        
        return info
    end
    
    -- Initialize dropdown with nested menu support
    UIDropDownMenu_SetWidth(dropdown, width)
    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        level = level or 1
        local itemList = menuList or items
        
        if type(itemList) == "table" then
            for _, item in ipairs(itemList) do
                local info = processMenuItem(item, level, itemList)
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)

    -- Set default value if provided
    if defaultValue then
        UIDropDownMenu_SetSelectedName(dropdown, defaultValue)
    end

    -- Store references
    dropdown.bg = dropdownBg

    -- Add method to update items
    dropdown.UpdateItems = function(self, newItems, newDefault)
        items = newItems
        UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
            level = level or 1
            local itemList = menuList or items
            
            if type(itemList) == "table" then
                for _, item in ipairs(itemList) do
                    local info = processMenuItem(item, level, itemList)
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end)
        if newDefault then
            UIDropDownMenu_SetSelectedName(dropdown, newDefault)
        end
    end

    -- Add method to get selected value
    dropdown.GetValue = function(self)
        return UIDropDownMenu_GetSelectedName(dropdown)
    end

    -- Add method to set value
    dropdown.SetValue = function(self, value)
        UIDropDownMenu_SetSelectedName(dropdown, value)
    end

    return dropdown, dropdownBg
end

--[[
Creates a styled nested dropdown menu with support for submenus, icons, and complex items
@param parent - Parent frame
@param width - Width of the dropdown (excluding arrow)
@param items - Table of menu items (can be strings or tables with properties)
@param defaultValue - Optional default selected value
@param onSelect - Callback function when selection changes
@param options - Optional table with additional configuration:
    - multiSelect: boolean - Allow multiple selections
    - closeOnSelect: boolean - Close menu on selection (default true)
    - showValue: boolean - Show value instead of text when selected
@return dropdown frame, background frame

Example usage:
local items = {
    "Simple Option",
    { text = "Disabled Option", disabled = true },
    { isSeparator = true },
    { text = "Title", isTitle = true },
    {
        text = "Submenu",
        hasArrow = true,
        menuList = {
            { text = "Sub Option 1", value = "sub1", icon = "Interface\\Icons\\Spell_Nature_MoonKey" },
            { text = "Sub Option 2", value = "sub2" }
        }
    }
}
]]
function CreateStyledNestedDropdown(parent, width, items, defaultValue, onSelect, options)
    options = options or {}
    
    -- Use the enhanced CreateStyledDropdown which now supports nested menus
    local dropdown, dropdownBg = CreateStyledDropdown(parent, width, items, defaultValue, onSelect)
    
    -- Add additional configuration based on options
    if options.multiSelect then
        -- Store selected values for multi-select
        dropdown.selectedValues = {}
        
        -- Override the default selection behavior for multi-select
        local originalInit = dropdown:GetScript("OnShow")
        UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
            level = level or 1
            local itemList = menuList or items
            
            if type(itemList) == "table" then
                for _, item in ipairs(itemList) do
                    local info = UIDropDownMenu_CreateInfo()
                    
                    if type(item) == "string" then
                        info.text = item
                        info.value = item
                        info.checked = dropdown.selectedValues[item]
                        info.keepShownOnClick = true
                        info.func = function()
                            dropdown.selectedValues[item] = not dropdown.selectedValues[item]
                            if onSelect then
                                onSelect(item, dropdown.selectedValues)
                            end
                        end
                    elseif type(item) == "table" and not item.hasArrow and not item.isTitle and not item.disabled and not item.isSeparator then
                        -- Handle complex items for multi-select
                        info.text = item.text
                        info.value = item.value or item.text
                        info.checked = dropdown.selectedValues[info.value]
                        info.keepShownOnClick = true
                        info.func = function()
                            dropdown.selectedValues[info.value] = not dropdown.selectedValues[info.value]
                            if onSelect then
                                onSelect(info.value, dropdown.selectedValues)
                            end
                        end
                    end
                    
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end)
        
        -- Add method to get all selected values
        dropdown.GetSelectedValues = function(self)
            local selected = {}
            for value, isSelected in pairs(self.selectedValues) do
                if isSelected then
                    table.insert(selected, value)
                end
            end
            return selected
        end
    end
    
    -- Configure close on select behavior
    if options.closeOnSelect == false then
        -- This would require overriding the menu behavior
        -- which is complex with UIDropDownMenuTemplate
    end
    
    return dropdown, dropdownBg
end

--[[
Creates a fully custom styled dropdown using a button instead of UIDropDownMenuTemplate
This gives complete control over appearance but requires more manual handling
@param parent - Parent frame
@param width - Width of the dropdown
@param items - Table of string options
@param defaultValue - Optional default selected value
@param onSelect - Callback function when selection changes
@return dropdown button frame, menu frame
]]
function CreateCustomStyledDropdown(parent, width, items, defaultValue, onSelect)
    -- Create main button
    local dropdownButton = CreateStyledButton(parent, defaultValue or "Select...", width, 26)
    dropdownButton.value = defaultValue

    -- Add dropdown arrow on the right
    local arrow = dropdownButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetText("v")
    arrow:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)

    -- Adjust text to make room for arrow
    dropdownButton.text:ClearAllPoints()
    dropdownButton.text:SetPoint("LEFT", 8, 0)
    dropdownButton.text:SetPoint("RIGHT", arrow, "LEFT", -5, 0)
    dropdownButton.text:SetJustifyH("LEFT")

    -- Create dropdown menu frame
    local menuFrame = CreateStyledFrame(UIParent, UISTYLE_COLORS.DarkGrey)
    menuFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    menuFrame:SetWidth(width)
    menuFrame:Hide()

    -- Position menu below button
    menuFrame:SetPoint("TOPLEFT", dropdownButton, "BOTTOMLEFT", 0, -2)

    -- Create menu items
    local menuItems = {}
    local itemHeight = 22

    for i, itemText in ipairs(items) do
        local menuItem = CreateFrame("Button", nil, menuFrame)
        menuItem:SetHeight(itemHeight)
        menuItem:SetPoint("LEFT", 1, 0)
        menuItem:SetPoint("RIGHT", -1, 0)

        if i == 1 then
            menuItem:SetPoint("TOP", 0, -1)
        else
            menuItem:SetPoint("TOP", menuItems[i - 1], "BOTTOM", 0, 0)
        end

        -- Item text
        local text = menuItem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", 8, 0)
        text:SetText(itemText)
        text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
        menuItem.text = text

        -- Highlight texture
        local highlight = menuItem:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlight:SetVertexColor(1, 1, 1, 0.1)
        highlight:SetAllPoints()

        -- Click handler
        menuItem:SetScript("OnClick", function(self)
            dropdownButton.value = itemText
            dropdownButton.text:SetText(itemText)
            menuFrame:Hide()
            if onSelect then
                onSelect(itemText)
            end
        end)

        -- Hover effect
        menuItem:SetScript("OnEnter", function(self)
            self.text:SetTextColor(1, 1, 1, 1)
        end)

        menuItem:SetScript("OnLeave", function(self)
            self.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
        end)

        table.insert(menuItems, menuItem)
    end

    -- Set menu frame height
    menuFrame:SetHeight((#items * itemHeight) + 2)

    -- Toggle menu on button click
    dropdownButton:SetScript("OnClick", function(self)
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            menuFrame:Show()
            menuFrame:Raise()
        end
    end)

    -- Close menu when clicking elsewhere
    local closeHandler = CreateFrame("Button", nil, UIParent)
    closeHandler:SetAllPoints(UIParent)
    closeHandler:SetFrameStrata("FULLSCREEN")
    closeHandler:Hide()

    closeHandler:SetScript("OnClick", function()
        menuFrame:Hide()
        closeHandler:Hide()
    end)

    menuFrame:SetScript("OnShow", function()
        closeHandler:Show()
        closeHandler:SetFrameLevel(menuFrame:GetFrameLevel() - 1)
    end)

    menuFrame:SetScript("OnHide", function()
        closeHandler:Hide()
    end)

    -- Helper methods
    dropdownButton.GetValue = function(self)
        return self.value
    end

    dropdownButton.SetValue = function(self, value)
        self.value = value
        self.text:SetText(value)
    end

    dropdownButton.UpdateItems = function(self, newItems, newDefault)
        -- Clear existing items
        for _, item in ipairs(menuItems) do
            item:Hide()
            item:SetParent(nil)
        end
        wipe(menuItems)

        -- Create new items
        items = newItems
        for i, itemText in ipairs(items) do
            local menuItem = CreateFrame("Button", nil, menuFrame)
            menuItem:SetHeight(itemHeight)
            menuItem:SetPoint("LEFT", 1, 0)
            menuItem:SetPoint("RIGHT", -1, 0)

            if i == 1 then
                menuItem:SetPoint("TOP", 0, -1)
            else
                menuItem:SetPoint("TOP", menuItems[i - 1], "BOTTOM", 0, 0)
            end

            -- Item text
            local text = menuItem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            text:SetPoint("LEFT", 8, 0)
            text:SetText(itemText)
            text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
            menuItem.text = text

            -- Highlight texture
            local highlight = menuItem:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
            highlight:SetVertexColor(1, 1, 1, 0.1)
            highlight:SetAllPoints()

            -- Click handler
            menuItem:SetScript("OnClick", function(self)
                dropdownButton.value = itemText
                dropdownButton.text:SetText(itemText)
                menuFrame:Hide()
                if onSelect then
                    onSelect(itemText)
                end
            end)

            -- Hover effect
            menuItem:SetScript("OnEnter", function(self)
                self.text:SetTextColor(1, 1, 1, 1)
            end)

            menuItem:SetScript("OnLeave", function(self)
                self.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
            end)

            table.insert(menuItems, menuItem)
        end

        -- Update menu frame height
        menuFrame:SetHeight((#items * itemHeight) + 2)

        -- Set new default if provided
        if newDefault then
            self:SetValue(newDefault)
        end
    end

    return dropdownButton, menuFrame
end

--[[
Creates a fully custom styled dropdown with nested menu support
@param parent - Parent frame
@param width - Dropdown width
@param items - Table of menu items (can be nested)
@param defaultValue - Default selected value
@param onSelect - Callback function(value, item) when item is selected
@return dropdownButton, menuFrame - The dropdown button and menu frame
]]
function CreateFullyStyledDropdown(parent, width, items, defaultValue, onSelect)
    -- Create main button
    local dropdownButton = CreateStyledButton(parent, defaultValue or "Select...", width, 26)
    dropdownButton.value = defaultValue
    
    -- Add dropdown arrow as text
    local arrow = dropdownButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetText("v")
    arrow:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
    dropdownButton.arrow = arrow
    
    -- Adjust text to make room for arrow
    dropdownButton.text:ClearAllPoints()
    dropdownButton.text:SetPoint("LEFT", 8, 0)
    dropdownButton.text:SetPoint("RIGHT", arrow, "LEFT", -5, 0)
    dropdownButton.text:SetJustifyH("LEFT")
    
    -- Menu management variables
    local activeMenus = {}
    local menuLevel = 0
    
    -- Create menu frame function
    local function createMenuFrame(level)
        local menuFrame = CreateStyledFrame(UIParent, UISTYLE_COLORS.DarkGrey)
        
        -- Check parent's frame strata and set accordingly
        local parentStrata = parent:GetFrameStrata()
        if parentStrata == "TOOLTIP" then
            -- If parent is at TOOLTIP level, use TOOLTIP for dropdown too
            menuFrame:SetFrameStrata("TOOLTIP")
            menuFrame:SetFrameLevel(parent:GetFrameLevel() + 10 + level * 10)
        else
            -- Default behavior for normal dropdowns
            menuFrame:SetFrameStrata("FULLSCREEN_DIALOG")
            menuFrame:SetFrameLevel(100 + level * 10)
        end
        
        menuFrame:SetWidth(width)
        menuFrame:Hide()
        
        -- Add shadow
        local shadow = menuFrame:CreateTexture(nil, "BACKGROUND")
        shadow:SetTexture("Interface\\Buttons\\WHITE8X8")
        shadow:SetVertexColor(0, 0, 0, 0.5)
        shadow:SetPoint("TOPLEFT", -3, 3)
        shadow:SetPoint("BOTTOMRIGHT", 3, -3)
        
        menuFrame.level = level
        menuFrame.items = {}
        
        return menuFrame
    end
    
    -- Process menu item (recursive for nested menus)
    local function processMenuItem(itemData, parentMenu, index)
        local itemHeight = 22
        local menuItem = CreateFrame("Button", nil, parentMenu)
        menuItem:SetHeight(itemHeight)
        menuItem:SetPoint("LEFT", 2, 0)
        menuItem:SetPoint("RIGHT", -2, 0)
        
        if index == 1 then
            menuItem:SetPoint("TOP", 0, -2)
        else
            menuItem:SetPoint("TOP", parentMenu.items[index - 1], "BOTTOM", 0, 0)
        end
        
        -- Handle different item types
        if type(itemData) == "table" and itemData.isSeparator then
            -- Separator
            menuItem:SetHeight(7)
            local line = menuItem:CreateTexture(nil, "OVERLAY")
            line:SetTexture("Interface\\Buttons\\WHITE8X8")
            line:SetVertexColor(0.3, 0.3, 0.3, 0.5)
            line:SetHeight(1)
            line:SetPoint("LEFT", 10, 0)
            line:SetPoint("RIGHT", -10, 0)
            menuItem:EnableMouse(false)
            
        elseif type(itemData) == "table" and itemData.isTitle then
            -- Title
            menuItem:SetHeight(24)
            local titleText = menuItem:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            titleText:SetPoint("CENTER")
            titleText:SetText(itemData.text or "")
            titleText:SetTextColor(1, 0.82, 0, 1)
            menuItem:EnableMouse(false)
            
        else
            -- Regular item or submenu
            local itemText = ""
            local itemValue = ""
            local hasArrow = false
            local menuList = nil
            local icon = nil
            local isChecked = false
            local func = nil
            
            if type(itemData) == "string" then
                itemText = itemData
                itemValue = itemData
            elseif type(itemData) == "table" then
                itemText = itemData.text or ""
                itemValue = itemData.value or itemText
                hasArrow = itemData.hasArrow
                menuList = itemData.menuList
                icon = itemData.icon
                isChecked = itemData.checked
                func = itemData.func
            end
            
            -- Checkbox/radio button
            if type(itemData) == "table" and (itemData.isRadio or isChecked ~= nil) then
                local check = menuItem:CreateTexture(nil, "ARTWORK")
                check:SetSize(16, 16)
                check:SetPoint("LEFT", 4, 0)
                if isChecked then
                    if itemData.isRadio then
                        check:SetTexture("Interface\\Buttons\\UI-RadioButton")
                        check:SetTexCoord(0.25, 0.5, 0, 1)
                    else
                        check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                    end
                end
                menuItem.check = check
            end
            
            -- Icon
            if icon then
                local iconTexture = menuItem:CreateTexture(nil, "ARTWORK")
                iconTexture:SetSize(16, 16)
                iconTexture:SetPoint("LEFT", menuItem.check and 24 or 4, 0)
                iconTexture:SetTexture(icon)
                menuItem.icon = iconTexture
            end
            
            -- Text
            local text = menuItem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            local leftOffset = 8
            if menuItem.check then leftOffset = leftOffset + 20 end
            if menuItem.icon then leftOffset = leftOffset + 20 end
            text:SetPoint("LEFT", leftOffset, 0)
            text:SetText(itemText)
            text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
            text:SetJustifyH("LEFT")
            menuItem.text = text
            
            -- Arrow for submenus
            if hasArrow and menuList then
                local arrowText = menuItem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                arrowText:SetPoint("RIGHT", -8, 0)
                arrowText:SetText(">")
                arrowText:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
                menuItem.arrow = arrowText
                
                -- Adjust text width for arrow
                text:SetPoint("RIGHT", arrowText, "LEFT", -5, 0)
            else
                text:SetPoint("RIGHT", -8, 0)
            end
            
            -- Highlight
            local highlight = menuItem:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
            highlight:SetVertexColor(1, 1, 1, 0.1)
            highlight:SetPoint("LEFT", 1, 0)
            highlight:SetPoint("RIGHT", -1, 0)
            highlight:SetHeight(itemHeight - 2)
            
            -- Store data
            menuItem.data = itemData
            menuItem.value = itemValue
            menuItem.hasSubmenu = hasArrow and menuList
            menuItem.menuList = menuList
            menuItem.func = func
            
            -- Click handler
            menuItem:SetScript("OnClick", function(self)
                if not self.hasSubmenu then
                    -- Handle checkbox toggling
                    if type(self.data) == "table" and self.data.checked ~= nil then
                        -- Toggle the checked state
                        self.data.checked = not self.data.checked
                        
                        -- Update checkbox texture
                        if self.check then
                            if self.data.checked then
                                if self.data.isRadio then
                                    self.check:SetTexture("Interface\\Buttons\\UI-RadioButton")
                                    self.check:SetTexCoord(0.25, 0.5, 0, 1)
                                else
                                    self.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                                end
                                self.check:Show()
                            else
                                self.check:Hide()
                            end
                        end
                    end
                    
                    -- Execute item function if exists
                    if self.func then
                        self.func()
                    end
                    
                    -- Update dropdown value and text
                    if not (type(self.data) == "table" and self.data.notCheckable) then
                        dropdownButton.value = self.value
                        dropdownButton.text:SetText(itemText)
                    end
                    
                    -- Close all menus
                    for _, menu in pairs(activeMenus) do
                        menu:Hide()
                    end
                    wipe(activeMenus)
                    
                    -- Call selection callback
                    if onSelect and not (type(self.data) == "table" and self.data.notCheckable) then
                        onSelect(self.value, self.data)
                    end
                end
            end)
            
            -- Submenu handling
            if hasArrow and menuList then
                local submenuTimer
                
                menuItem:SetScript("OnEnter", function(self)
                    self.text:SetTextColor(1, 1, 1, 1)
                    
                    -- Cancel any pending submenu close
                    if submenuTimer and submenuTimer.Cancel then
                        submenuTimer:Cancel()
                        submenuTimer = nil
                    end
                    
                    -- Close other submenus at this level
                    for level = parentMenu.level + 1, #activeMenus do
                        if activeMenus[level] then
                            activeMenus[level]:Hide()
                            activeMenus[level] = nil
                        end
                    end
                    
                    -- Show submenu
                    local submenu = activeMenus[parentMenu.level + 1] or createMenuFrame(parentMenu.level + 1)
                    
                    -- Clear existing items
                    for _, item in ipairs(submenu.items) do
                        item:Hide()
                        item:SetParent(nil)
                    end
                    wipe(submenu.items)
                    
                    -- Create submenu items
                    for i, subItemData in ipairs(self.menuList) do
                        processMenuItem(subItemData, submenu, i)
                    end
                    
                    -- Calculate submenu height
                    local totalHeight = 4
                    for _, item in ipairs(submenu.items) do
                        totalHeight = totalHeight + item:GetHeight()
                    end
                    submenu:SetHeight(totalHeight)
                    
                    -- Position submenu
                    submenu:ClearAllPoints()
                    local screenWidth = UIParent:GetWidth()
                    local menuRight = parentMenu:GetRight() + width
                    
                    if menuRight > screenWidth then
                        -- Open to the left
                        submenu:SetPoint("TOPRIGHT", self, "TOPLEFT", -2, 0)
                    else
                        -- Open to the right
                        submenu:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, 0)
                    end
                    
                    submenu:Show()
                    activeMenus[parentMenu.level + 1] = submenu
                end)
                
                menuItem:SetScript("OnLeave", function(self)
                    self.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
                    
                    -- Delay submenu closing
                    submenuTimer = CreateTimer(0.3, function()
                        -- Check if mouse is over any active menu
                        local mouseOverAnyMenu = false
                        
                        -- Check all active menus
                        for _, menu in pairs(activeMenus) do
                            if menu and menu:IsVisible() and menu:IsMouseOver() then
                                mouseOverAnyMenu = true
                                break
                            end
                        end
                        
                        -- Also check if mouse is over any menu item
                        if not mouseOverAnyMenu then
                            for _, menu in pairs(activeMenus) do
                                if menu and menu.items then
                                    for _, item in ipairs(menu.items) do
                                        if item and item:IsVisible() and item:IsMouseOver() then
                                            mouseOverAnyMenu = true
                                            break
                                        end
                                    end
                                    if mouseOverAnyMenu then break end
                                end
                            end
                        end
                        
                        -- Only close if mouse is not over any menu or menu item
                        if not mouseOverAnyMenu then
                            for level = parentMenu.level + 1, #activeMenus do
                                if activeMenus[level] then
                                    activeMenus[level]:Hide()
                                    activeMenus[level] = nil
                                end
                            end
                        end
                    end)
                end)
            else
                -- Regular item hover
                menuItem:SetScript("OnEnter", function(self)
                    self.text:SetTextColor(1, 1, 1, 1)
                    
                    -- Close submenus if hovering over non-submenu item
                    for level = parentMenu.level + 1, #activeMenus do
                        if activeMenus[level] then
                            activeMenus[level]:Hide()
                            activeMenus[level] = nil
                        end
                    end
                end)
                
                menuItem:SetScript("OnLeave", function(self)
                    self.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
                end)
            end
        end
        
        table.insert(parentMenu.items, menuItem)
        return menuItem
    end
    
    -- Create main menu
    local mainMenu = createMenuFrame(0)
    
    -- Build main menu items
    for i, itemData in ipairs(items) do
        processMenuItem(itemData, mainMenu, i)
    end
    
    -- Calculate menu height
    local totalHeight = 4
    for _, item in ipairs(mainMenu.items) do
        totalHeight = totalHeight + item:GetHeight()
    end
    mainMenu:SetHeight(totalHeight)
    
    -- Position main menu
    mainMenu:SetPoint("TOPLEFT", dropdownButton, "BOTTOMLEFT", 0, -2)
    
    -- Toggle menu on button click
    dropdownButton:SetScript("OnClick", function(self)
        if mainMenu:IsShown() then
            -- Close all menus
            for _, menu in pairs(activeMenus) do
                menu:Hide()
            end
            wipe(activeMenus)
            mainMenu:Hide()
        else
            mainMenu:Show()
            mainMenu:Raise()
            activeMenus[0] = mainMenu
        end
    end)
    
    -- Close handler
    local closeHandler = CreateFrame("Button", nil, UIParent)
    closeHandler:SetAllPoints(UIParent)
    closeHandler:SetFrameStrata("FULLSCREEN")
    closeHandler:Hide()
    
    closeHandler:SetScript("OnClick", function()
        for _, menu in pairs(activeMenus) do
            menu:Hide()
        end
        wipe(activeMenus)
        mainMenu:Hide()
        closeHandler:Hide()
    end)
    
    mainMenu:SetScript("OnShow", function()
        closeHandler:Show()
        closeHandler:SetFrameLevel(mainMenu:GetFrameLevel() - 1)
    end)
    
    mainMenu:SetScript("OnHide", function()
        closeHandler:Hide()
    end)
    
    -- Helper methods
    dropdownButton.GetValue = function(self)
        return self.value
    end
    
    dropdownButton.SetValue = function(self, value, text)
        self.value = value
        self.text:SetText(text or value)
    end
    
    -- Update items method
    dropdownButton.UpdateItems = function(self, newItems)
        items = newItems
        
        -- Clear existing items
        for _, item in ipairs(mainMenu.items) do
            item:Hide()
            item:SetParent(nil)
        end
        wipe(mainMenu.items)
        
        -- Create new items
        for i, itemData in ipairs(items) do
            processMenuItem(itemData, mainMenu, i)
        end
        
        -- Recalculate height
        local totalHeight = 4
        for _, item in ipairs(mainMenu.items) do
            totalHeight = totalHeight + item:GetHeight()
        end
        mainMenu:SetHeight(totalHeight)
    end
    
    return dropdownButton, mainMenu
end

--[[
Creates a styled tab button matching the dark theme
@param parent - Parent frame
@param text - Tab text
@param width - Optional width (defaults to auto-size)
@param height - Optional height (defaults to 26)
@param icon - Optional icon texture path
@return Styled tab button
]]
function CreateStyledTabButton(parent, text, width, height, icon)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(height or 26)
    
    -- Button backdrop
    button:SetBackdrop(UISTYLE_BACKDROPS.Frame)
    
    -- Set initial state (inactive)
    button.isActive = false
    button:SetBackdropColor(0.05, 0.05, 0.05, 1) -- Darker for inactive
    button:SetBackdropBorderColor(UISTYLE_COLORS.BorderGrey[1], UISTYLE_COLORS.BorderGrey[2], UISTYLE_COLORS.BorderGrey[3], 1)
    
    -- Icon (optional)
    local iconTexture
    if icon then
        iconTexture = button:CreateTexture(nil, "ARTWORK")
        iconTexture:SetSize(16, 16)
        iconTexture:SetPoint("LEFT", 6, 0)
        iconTexture:SetTexture(icon)
        button.icon = iconTexture
    end
    
    -- Button text
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if icon then
        label:SetPoint("LEFT", iconTexture, "RIGHT", 4, 0)
        label:SetPoint("RIGHT", -10, 0)
    else
        label:SetPoint("CENTER")
    end
    label:SetText(text or "Tab")
    label:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
    button.text = label
    
    -- Auto-size if no width specified
    if not width then
        local textWidth = label:GetStringWidth()
        local totalWidth = textWidth + 20 -- padding
        if icon then
            totalWidth = totalWidth + 20 -- icon width + spacing
        end
        button:SetWidth(totalWidth)
    else
        button:SetWidth(width)
    end
    
    -- State management
    button.SetActive = function(self, active)
        self.isActive = active
        if active then
            self:SetBackdropColor(UISTYLE_COLORS.SectionBg[1], UISTYLE_COLORS.SectionBg[2], UISTYLE_COLORS.SectionBg[3], 1)
            self.text:SetTextColor(1, 1, 1, 1)
            self:LockHighlight()
        else
            self:SetBackdropColor(0.05, 0.05, 0.05, 1)
            self.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
            self:UnlockHighlight()
        end
    end
    
    button.GetActive = function(self)
        return self.isActive
    end
    
    -- Hover effects (only when not active)
    button:SetScript("OnEnter", function(self)
        if not self.isActive then
            self:SetBackdropColor(0.08, 0.08, 0.08, 1)
            self.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end
    end)
    
    button:SetScript("OnLeave", function(self)
        if not self.isActive then
            self:SetBackdropColor(0.05, 0.05, 0.05, 1)
            self.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
        end
    end)
    
    -- Click effect
    button:SetScript("OnMouseDown", function(self)
        if not self.isActive then
            self:SetBackdropColor(0.03, 0.03, 0.03, 1)
        end
    end)
    
    button:SetScript("OnMouseUp", function(self)
        if not self.isActive then
            if self:IsMouseOver() then
                self:SetBackdropColor(0.08, 0.08, 0.08, 1)
            else
                self:SetBackdropColor(0.05, 0.05, 0.05, 1)
            end
        end
    end)
    
    -- Add highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlight:SetVertexColor(1, 1, 1, 0.05)
    highlight:SetPoint("TOPLEFT", 1, -1)
    highlight:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Add SetTooltip method
    button.SetTooltip = function(self, text, subtext)
        SetupTooltip(self, text, subtext)
    end
    
    return button
end

--[[
Creates a styled tab group with automatic tab switching
@param parent - Parent frame
@param tabs - Table of tab configurations: {{text="Tab1", icon=nil, tooltip="Description"}, ...}
@param width - Total width of the tab group
@param height - Total height including content area
@param orientation - "HORIZONTAL" (default) or "VERTICAL"
@param onTabChange - Optional callback function(tabIndex, tabData)
@return tabContainer, contentFrames table, tabButtons table
]]
function CreateStyledTabGroup(parent, tabs, width, height, orientation, onTabChange)
    orientation = orientation or "HORIZONTAL"
    
    -- Main container
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, height)
    
    -- Calculate dimensions based on orientation
    local tabAreaWidth, tabAreaHeight, contentWidth, contentHeight
    local tabWidth, tabHeight, tabSpacing = nil, nil, 2
    
    if orientation == "HORIZONTAL" then
        tabAreaHeight = 28
        tabAreaWidth = width
        contentWidth = width
        contentHeight = height - tabAreaHeight - 2
        tabHeight = 26
    else -- VERTICAL
        tabAreaWidth = 150
        tabAreaHeight = height
        contentWidth = width - tabAreaWidth - 2
        contentHeight = height
        tabWidth = 148
        tabHeight = 26
    end
    
    -- Tab area
    local tabArea = CreateFrame("Frame", nil, container)
    tabArea:SetSize(tabAreaWidth, tabAreaHeight)
    
    if orientation == "HORIZONTAL" then
        tabArea:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        tabArea:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    else
        tabArea:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        tabArea:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    end
    
    -- Content area
    local contentArea = CreateStyledFrame(container, UISTYLE_COLORS.OptionBg)
    contentArea:SetSize(contentWidth, contentHeight)
    
    if orientation == "HORIZONTAL" then
        contentArea:SetPoint("TOPLEFT", tabArea, "BOTTOMLEFT", 0, -2)
        contentArea:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    else
        contentArea:SetPoint("TOPLEFT", tabArea, "TOPRIGHT", 2, 0)
        contentArea:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    end
    
    -- Create tab buttons and content frames
    local tabButtons = {}
    local contentFrames = {}
    local activeTab = 1
    
    -- Scrollable tab area for vertical orientation with many tabs
    local tabScrollFrame, tabContentFrame, updateScrollBar
    if orientation == "VERTICAL" and #tabs > math.floor(tabAreaHeight / (tabHeight + tabSpacing)) then
        -- Create scrollable area
        local scrollContainer, scrollContent, scrollBar
        scrollContainer, scrollContent, scrollBar, updateScrollBar = CreateScrollableFrame(tabArea, tabAreaWidth - 2, tabAreaHeight)
        scrollContainer:SetPoint("TOPLEFT", 0, 0)
        scrollContainer:SetPoint("BOTTOMRIGHT", 0, 0)
        tabContentFrame = scrollContent
        tabScrollFrame = scrollContainer
    else
        tabContentFrame = tabArea
    end
    
    -- Create tabs
    for i, tabData in ipairs(tabs) do
        -- Create tab button
        local tabButton = CreateStyledTabButton(tabContentFrame, tabData.text, tabWidth, tabHeight, tabData.icon)
        
        -- Position tab
        if orientation == "HORIZONTAL" then
            if i == 1 then
                tabButton:SetPoint("LEFT", tabContentFrame, "LEFT", 0, 0)
            else
                tabButton:SetPoint("LEFT", tabButtons[i-1], "RIGHT", tabSpacing, 0)
            end
        else -- VERTICAL
            if i == 1 then
                tabButton:SetPoint("TOP", tabContentFrame, "TOP", 0, 0)
            else
                tabButton:SetPoint("TOP", tabButtons[i-1], "BOTTOM", 0, -tabSpacing)
            end
        end
        
        -- Set tooltip if provided
        if tabData.tooltip then
            tabButton:SetTooltip(tabData.tooltip, tabData.subtip)
        end
        
        -- Create content frame for this tab
        local contentFrame = CreateFrame("Frame", nil, contentArea)
        contentFrame:SetAllPoints(contentArea)
        contentFrame:Hide()
        
        -- Store references
        tabButton.index = i
        tabButton.contentFrame = contentFrame
        tabButtons[i] = tabButton
        contentFrames[i] = contentFrame
        
        -- Tab click handler
        tabButton:SetScript("OnClick", function(self)
            -- Switch to this tab
            for j, btn in ipairs(tabButtons) do
                btn:SetActive(j == i)
                contentFrames[j]:Hide()
            end
            
            self:SetActive(true)
            contentFrame:Show()
            activeTab = i
            
            -- Call callback if provided
            if onTabChange then
                onTabChange(i, tabData)
            end
        end)
    end
    
    -- Update scroll content height if using scroll frame
    if tabScrollFrame and tabContentFrame ~= tabArea then
        local totalHeight = #tabs * (tabHeight + tabSpacing) - tabSpacing + 4
        tabContentFrame:SetHeight(totalHeight)
        if updateScrollBar then
            updateScrollBar()
        end
    end
    
    -- Activate first tab by default
    if #tabButtons > 0 then
        tabButtons[1]:SetActive(true)
        contentFrames[1]:Show()
    end
    
    -- Helper functions
    container.SetActiveTab = function(self, index)
        if index > 0 and index <= #tabButtons then
            tabButtons[index]:Click()
        end
    end
    
    container.GetActiveTab = function(self)
        return activeTab
    end
    
    container.GetTabButton = function(self, index)
        return tabButtons[index]
    end
    
    container.GetContentFrame = function(self, index)
        return contentFrames[index]
    end
    
    return container, contentFrames, tabButtons
end

--[[
Creates a styled search box with placeholder text
@param parent - Parent frame
@param width - Search box width
@param placeholder - Placeholder text (defaults to "Search...")
@param onTextChanged - Optional callback function(text)
@return searchFrame, editBox
]]
function CreateStyledSearchBox(parent, width, placeholder, onTextChanged)
    local searchFrame = CreateStyledFrame(parent, UISTYLE_COLORS.OptionBg)
    searchFrame:SetWidth(width)
    searchFrame:SetHeight(28)
    
    -- Search icon (optional)
    local searchIcon = searchFrame:CreateTexture(nil, "ARTWORK")
    searchIcon:SetSize(16, 16)
    searchIcon:SetPoint("LEFT", 8, 0)
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    searchIcon:SetVertexColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
    
    -- Search input
    local editBox = CreateFrame("EditBox", nil, searchFrame)
    editBox:SetWidth(width - 40) -- Account for icon and padding
    editBox:SetHeight(20)
    editBox:SetPoint("LEFT", searchIcon, "RIGHT", 4, 0)
    editBox:SetPoint("RIGHT", -8, 0)
    editBox:SetFontObject("GameFontHighlight")
    editBox:SetAutoFocus(false)
    editBox:SetTextColor(UISTYLE_COLORS.White[1], UISTYLE_COLORS.White[2], UISTYLE_COLORS.White[3], 1)
    
    -- Placeholder
    local placeholderText = editBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholderText:SetPoint("LEFT", editBox, "LEFT", 2, 0)
    placeholderText:SetText(placeholder or "Search...")
    placeholderText:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 0.7)
    
    -- Clear button (X)
    local clearButton = CreateFrame("Button", nil, searchFrame)
    clearButton:SetSize(16, 16)
    clearButton:SetPoint("RIGHT", -6, 0)
    clearButton:Hide()
    
    local clearText = clearButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    clearText:SetPoint("CENTER")
    clearText:SetText("×")
    clearText:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
    clearButton.text = clearText
    
    clearButton:SetScript("OnClick", function()
        editBox:SetText("")
        editBox:ClearFocus()
    end)
    
    clearButton:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    
    clearButton:SetScript("OnLeave", function(self)
        self.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
    end)
    
    -- Edit box scripts
    editBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text == "" then
            placeholderText:Show()
            clearButton:Hide()
        else
            placeholderText:Hide()
            clearButton:Show()
        end
        
        if onTextChanged then
            onTextChanged(text)
        end
    end)
    
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    
    -- Focus effects
    editBox:SetScript("OnEditFocusGained", function(self)
        searchFrame:SetBackdropBorderColor(UISTYLE_COLORS.Blue[1], UISTYLE_COLORS.Blue[2], UISTYLE_COLORS.Blue[3], 1)
    end)
    
    editBox:SetScript("OnEditFocusLost", function(self)
        searchFrame:SetBackdropBorderColor(0, 0, 0, 1)
    end)
    
    -- Expose elements
    searchFrame.editBox = editBox
    searchFrame.placeholder = placeholderText
    searchFrame.clearButton = clearButton
    
    return searchFrame, editBox
end

--[[
Creates a styled drop zone for drag and drop operations
@param parent - Parent frame
@param width - Drop zone width
@param height - Drop zone height
@param options - Table with optional settings:
    - text: Display text (default "Drop items here")
    - icon: Icon texture path
    - instructions: Instruction text
    - onReceiveDrag: Callback function()
    - validationFunc: Function(cursorType, itemId, itemLink) returns isValid, reason
@return dropZone frame
]]
function CreateStyledDropZone(parent, width, height, options)
    options = options or {}
    
    local dropZone = CreateFrame("Frame", nil, parent)
    dropZone:SetSize(width, height)
    dropZone:EnableMouse(true)
    
    -- Background
    local bg = dropZone:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(UISTYLE_COLORS.OptionBg[1], UISTYLE_COLORS.OptionBg[2], UISTYLE_COLORS.OptionBg[3], 0.8)
    dropZone.bg = bg
    
    -- Create dashed border
    local borderFrame = CreateFrame("Frame", nil, dropZone)
    borderFrame:SetAllPoints()
    
    local borderPieces = {}
    local borderWidth = 2
    local dashSize = 10
    local gapSize = 6
    
    -- Function to create dashed border
    local function CreateDashedBorder(color)
        -- Clear existing pieces
        for _, piece in ipairs(borderPieces) do
            piece:Hide()
        end
        wipe(borderPieces)
        
        -- Top border
        local topDashes = math.floor(width / (dashSize + gapSize))
        for i = 0, topDashes do
            if i * (dashSize + gapSize) < width then
                local piece = borderFrame:CreateTexture(nil, "BORDER")
                piece:SetTexture("Interface\\Buttons\\WHITE8X8")
                piece:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
                piece:SetWidth(math.min(dashSize, width - i * (dashSize + gapSize)))
                piece:SetHeight(borderWidth)
                piece:SetPoint("TOPLEFT", borderFrame, "TOPLEFT", i * (dashSize + gapSize), 0)
                table.insert(borderPieces, piece)
            end
        end
        
        -- Bottom border
        for i = 0, topDashes do
            if i * (dashSize + gapSize) < width then
                local piece = borderFrame:CreateTexture(nil, "BORDER")
                piece:SetTexture("Interface\\Buttons\\WHITE8X8")
                piece:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
                piece:SetWidth(math.min(dashSize, width - i * (dashSize + gapSize)))
                piece:SetHeight(borderWidth)
                piece:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT", i * (dashSize + gapSize), 0)
                table.insert(borderPieces, piece)
            end
        end
        
        -- Left border
        local leftDashes = math.floor(height / (dashSize + gapSize))
        for i = 0, leftDashes do
            if i * (dashSize + gapSize) < height then
                local piece = borderFrame:CreateTexture(nil, "BORDER")
                piece:SetTexture("Interface\\Buttons\\WHITE8X8")
                piece:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
                piece:SetWidth(borderWidth)
                piece:SetHeight(math.min(dashSize, height - i * (dashSize + gapSize)))
                piece:SetPoint("TOPLEFT", borderFrame, "TOPLEFT", 0, -i * (dashSize + gapSize))
                table.insert(borderPieces, piece)
            end
        end
        
        -- Right border
        for i = 0, leftDashes do
            if i * (dashSize + gapSize) < height then
                local piece = borderFrame:CreateTexture(nil, "BORDER")
                piece:SetTexture("Interface\\Buttons\\WHITE8X8")
                piece:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
                piece:SetWidth(borderWidth)
                piece:SetHeight(math.min(dashSize, height - i * (dashSize + gapSize)))
                piece:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT", 0, -i * (dashSize + gapSize))
                table.insert(borderPieces, piece)
            end
        end
    end
    
    dropZone.borderPieces = borderPieces
    dropZone.CreateDashedBorder = CreateDashedBorder
    
    -- Create glow effect frame
    local glowFrame = CreateFrame("Frame", nil, dropZone)
    glowFrame:SetPoint("TOPLEFT", -5, 5)
    glowFrame:SetPoint("BOTTOMRIGHT", 5, -5)
    glowFrame:SetFrameLevel(dropZone:GetFrameLevel() - 1)
    glowFrame:Hide()
    
    -- Glow textures (using edge file to create a soft glow)
    local glowTextures = {}
    local glowSize = 5
    
    -- Top glow
    local topGlow = glowFrame:CreateTexture(nil, "BACKGROUND")
    topGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    topGlow:SetHeight(glowSize)
    topGlow:SetPoint("BOTTOMLEFT", glowFrame, "TOPLEFT", 0, -glowSize)
    topGlow:SetPoint("BOTTOMRIGHT", glowFrame, "TOPRIGHT", 0, -glowSize)
    topGlow:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 1, 1, 1, 0.3)
    table.insert(glowTextures, topGlow)
    
    -- Bottom glow
    local bottomGlow = glowFrame:CreateTexture(nil, "BACKGROUND")
    bottomGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    bottomGlow:SetHeight(glowSize)
    bottomGlow:SetPoint("TOPLEFT", glowFrame, "BOTTOMLEFT", 0, glowSize)
    bottomGlow:SetPoint("TOPRIGHT", glowFrame, "BOTTOMRIGHT", 0, glowSize)
    bottomGlow:SetGradientAlpha("VERTICAL", 1, 1, 1, 0.3, 0, 0, 0, 0)
    table.insert(glowTextures, bottomGlow)
    
    -- Left glow
    local leftGlow = glowFrame:CreateTexture(nil, "BACKGROUND")
    leftGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    leftGlow:SetWidth(glowSize)
    leftGlow:SetPoint("TOPRIGHT", glowFrame, "TOPLEFT", glowSize, 0)
    leftGlow:SetPoint("BOTTOMRIGHT", glowFrame, "BOTTOMLEFT", glowSize, 0)
    leftGlow:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 1, 1, 1, 0.3)
    table.insert(glowTextures, leftGlow)
    
    -- Right glow
    local rightGlow = glowFrame:CreateTexture(nil, "BACKGROUND")
    rightGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    rightGlow:SetWidth(glowSize)
    rightGlow:SetPoint("TOPLEFT", glowFrame, "TOPRIGHT", -glowSize, 0)
    rightGlow:SetPoint("BOTTOMLEFT", glowFrame, "BOTTOMRIGHT", -glowSize, 0)
    rightGlow:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0.3, 0, 0, 0, 0)
    table.insert(glowTextures, rightGlow)
    
    dropZone.glowFrame = glowFrame
    dropZone.glowTextures = glowTextures
    
    -- Initial border
    CreateDashedBorder(UISTYLE_COLORS.BorderGrey)
    
    -- Icon
    if options.icon then
        local icon = dropZone:CreateTexture(nil, "ARTWORK")
        icon:SetSize(24, 24)
        icon:SetPoint("LEFT", 15, 0)
        icon:SetTexture(options.icon)
        icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        dropZone.icon = icon
    end
    
    -- Main text
    local text = dropZone:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    if options.icon then
        text:SetPoint("LEFT", dropZone.icon, "RIGHT", 8, 0)
    else
        text:SetPoint("CENTER", 0, 4)
    end
    text:SetText(options.text or "Drop items here")
    text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
    dropZone.text = text
    
    -- Instructions
    if options.instructions then
        local instructions = dropZone:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        instructions:SetPoint("BOTTOM", 0, 4)
        instructions:SetText(options.instructions)
        instructions:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 0.7)
        dropZone.instructions = instructions
    end
    
    -- State colors
    local stateColors = {
        idle = { bg = {0.08, 0.08, 0.08, 0.8}, border = UISTYLE_COLORS.BorderGrey },
        hover = { bg = {0.1, 0.1, 0.12, 0.9}, border = {0.4, 0.4, 0.5, 1} },
        valid = { bg = {0.08, 0.12, 0.08, 0.9}, border = UISTYLE_COLORS.Green },
        invalid = { bg = {0.12, 0.08, 0.08, 0.9}, border = UISTYLE_COLORS.Red },
        validating = { bg = {0.08, 0.08, 0.10, 0.9}, border = UISTYLE_COLORS.Blue }
    }
    
    -- Animation frame for validating state
    local animFrame = CreateFrame("Frame")
    local animTime = 0
    local isValidating = false
    
    -- Update appearance function
    dropZone.SetState = function(self, state)
        local colors = stateColors[state] or stateColors.idle
        bg:SetVertexColor(colors.bg[1], colors.bg[2], colors.bg[3], colors.bg[4])
        CreateDashedBorder(colors.border)
        
        -- Show/hide glow based on state
        if state == "valid" then
            glowFrame:Show()
            -- Set glow color to match valid state
            for _, texture in ipairs(glowTextures) do
                texture:SetVertexColor(UISTYLE_COLORS.Green[1], UISTYLE_COLORS.Green[2], UISTYLE_COLORS.Green[3])
            end
        elseif state == "invalid" then
            glowFrame:Show()
            -- Set glow color to match invalid state
            for _, texture in ipairs(glowTextures) do
                texture:SetVertexColor(UISTYLE_COLORS.Red[1], UISTYLE_COLORS.Red[2], UISTYLE_COLORS.Red[3])
            end
        elseif state == "validating" then
            glowFrame:Show()
            -- Set glow color to match validating state
            for _, texture in ipairs(glowTextures) do
                texture:SetVertexColor(UISTYLE_COLORS.Blue[1], UISTYLE_COLORS.Blue[2], UISTYLE_COLORS.Blue[3])
            end
        else
            glowFrame:Hide()
        end
        
        -- Start or stop animation for validating state
        if state == "validating" then
            isValidating = true
            animTime = 0
            animFrame:SetScript("OnUpdate", function(self, elapsed)
                animTime = animTime + elapsed
                -- Pulse the border opacity
                local alpha = 0.5 + 0.5 * math.sin(animTime * 4)
                for _, piece in ipairs(borderPieces) do
                    piece:SetAlpha(alpha)
                end
                -- Also pulse the glow
                local glowAlpha = 0.2 + 0.1 * math.sin(animTime * 4)
                for _, texture in ipairs(glowTextures) do
                    texture:SetAlpha(glowAlpha)
                end
            end)
        else
            isValidating = false
            animFrame:SetScript("OnUpdate", nil)
            -- Reset border opacity
            for _, piece in ipairs(borderPieces) do
                piece:SetAlpha(1)
            end
            -- Reset glow opacity
            for _, texture in ipairs(glowTextures) do
                texture:SetAlpha(0.3)
            end
        end
    end
    
    -- Scripts
    dropZone:SetScript("OnReceiveDrag", function(self)
        if options.onReceiveDrag then
            options.onReceiveDrag()
        end
        self:SetState("idle")
    end)
    
    -- Add OnMouseUp to support click-to-drop (when item is picked up and user clicks on dropzone)
    dropZone:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and CursorHasItem() then
            -- Same behavior as OnReceiveDrag
            if options.onReceiveDrag then
                options.onReceiveDrag()
            end
            self:SetState("idle")
        end
    end)
    
    dropZone:SetScript("OnEnter", function(self)
        if CursorHasItem() and options.validationFunc then
            local cursorType, itemId, itemLink = GetCursorInfo()
            local state, reason = options.validationFunc(cursorType, itemId, itemLink)
            
            -- Handle different return types
            if type(state) == "string" then
                -- State returned directly (e.g., "validating")
                self:SetState(state)
            elseif type(state) == "boolean" then
                -- Boolean returned (true/false)
                self:SetState(state and "valid" or "invalid")
            else
                -- Invalid return
                self:SetState("invalid")
            end
            
            if self.instructions and reason then
                self.instructions:SetText(reason)
            end
        else
            self:SetState("hover")
        end
    end)
    
    dropZone:SetScript("OnLeave", function(self)
        self:SetState("idle")
        if self.instructions and options.instructions then
            self.instructions:SetText(options.instructions)
        end
    end)
    
    return dropZone
end

--[[
Creates a styled card for grid displays (items, spells, etc.)
@param parent - Parent frame
@param size - Card size (width and height)
@param data - Table with card data:
    - id: Unique identifier
    - texture: Icon texture path
    - count: Stack count (optional)
    - quality: Item quality for border color (optional)
    - name: Tooltip name (optional)
    - onClick: Click handler function(self, button)
    - onEnter: Additional OnEnter handler
    - onLeave: Additional OnLeave handler
    - onMouseWheel: Mouse wheel handler function(self, delta)
@return card button
]]
function CreateStyledCard(parent, size, data)
    local card = CreateFrame("Button", nil, parent)
    card:SetSize(size, size)
    
    -- Background
    card:SetBackdrop(UISTYLE_BACKDROPS.Frame)
    card:SetBackdropColor(UISTYLE_COLORS.OptionBg[1], UISTYLE_COLORS.OptionBg[2], UISTYLE_COLORS.OptionBg[3], 1)
    
    -- Set border color based on quality
    if data.quality and UISTYLE_COLORS[data.quality] then
        local color = UISTYLE_COLORS[data.quality]
        card:SetBackdropBorderColor(color[1], color[2], color[3], 1)
    else
        card:SetBackdropBorderColor(UISTYLE_COLORS.BorderGrey[1], UISTYLE_COLORS.BorderGrey[2], UISTYLE_COLORS.BorderGrey[3], 1)
    end
    
    -- Icon
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    if data.texture then
        icon:SetTexture(data.texture)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    card.icon = icon
    
    -- Count text
    if data.count and data.count > 1 then
        local count = card:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        count:SetPoint("BOTTOMRIGHT", -2, 2)
        count:SetText(data.count > 999 and "*" or tostring(data.count))
        count:SetTextColor(1, 1, 1, 1)
        card.count = count
    end
    
    -- Highlight
    local highlight = card:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    highlight:SetVertexColor(1, 1, 1, 0.2)
    highlight:SetPoint("TOPLEFT", 1, -1)
    highlight:SetPoint("BOTTOMRIGHT", -1, 1)
    card:SetHighlightTexture(highlight)
    
    -- Cooldown frame (optional, for future use)
    local cooldown = CreateFrame("Cooldown", nil, card, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:Hide()
    card.cooldown = cooldown
    
    -- Store data
    card.data = data
    
    -- Click handlers
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card:SetScript("OnClick", function(self, button)
        if self.data.onClick then
            self.data.onClick(self, button)
        end
    end)
    
    -- Tooltip
    card:SetScript("OnEnter", function(self)
        if self.data.name or self.data.link then
            -- Check parent frame strata for proper tooltip elevation
            local parent = self:GetParent()
            while parent and parent ~= UIParent do
                local parentStrata = parent:GetFrameStrata()
                if parentStrata == "TOOLTIP" or parentStrata == "FULLSCREEN_DIALOG" then
                    GameTooltip:SetFrameStrata("TOOLTIP")
                    GameTooltip:SetFrameLevel(parent:GetFrameLevel() + 10)
                    break
                end
                parent = parent:GetParent()
            end
            
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.data.link then
                GameTooltip:SetHyperlink(self.data.link)
            else
                GameTooltip:SetText(self.data.name, 1, 1, 1, 1)
            end
            GameTooltip:Show()
        end
        
        if self.data.onEnter then
            self.data.onEnter(self)
        end
    end)
    
    card:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        
        if self.data.onLeave then
            self.data.onLeave(self)
        end
    end)
    
    -- Mouse wheel support
    if data.onMouseWheel then
        card:EnableMouseWheel(true)
        card:SetScript("OnMouseWheel", function(self, delta)
            if self.data.onMouseWheel then
                self.data.onMouseWheel(self, delta)
            end
        end)
    end
    
    -- Update function
    card.Update = function(self, newData)
        self.data = newData
        
        -- Update icon
        if newData.texture then
            self.icon:SetTexture(newData.texture)
        end
        
        -- Update count
        if self.count then
            if newData.count and newData.count > 1 then
                self.count:SetText(newData.count > 999 and "*" or tostring(newData.count))
                self.count:Show()
            else
                self.count:Hide()
            end
        elseif newData.count and newData.count > 1 then
            local count = self:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            count:SetPoint("BOTTOMRIGHT", -2, 2)
            count:SetText(newData.count > 999 and "*" or tostring(newData.count))
            count:SetTextColor(1, 1, 1, 1)
            self.count = count
        end
        
        -- Update border color
        if newData.quality and UISTYLE_COLORS[newData.quality] then
            local color = UISTYLE_COLORS[newData.quality]
            self:SetBackdropBorderColor(color[1], color[2], color[3], 1)
        else
            self:SetBackdropBorderColor(UISTYLE_COLORS.BorderGrey[1], UISTYLE_COLORS.BorderGrey[2], UISTYLE_COLORS.BorderGrey[3], 1)
        end
        
        -- Update mouse wheel handler if provided
        if newData.onMouseWheel then
            self:EnableMouseWheel(true)
            self:SetScript("OnMouseWheel", function(self, delta)
                newData.onMouseWheel(self, delta)
            end)
        end
    end
    
    return card
end

--[[
Creates a styled context menu
@param items - Table of menu items, each with:
    - text: Display text
    - func: Click handler function
    - disabled: Boolean to disable item
    - separator: Boolean to show as separator
    - hasArrow: Boolean for submenu indicator
    - value: Optional value to pass to func
@param anchorFrame - Frame to anchor the menu to
@param anchorPoint - Anchor point (defaults to "TOPRIGHT")
@param relativePoint - Relative point (defaults to "TOPLEFT")
@param xOffset - X offset (defaults to 0)
@param yOffset - Y offset (defaults to 0)
@return menu frame
]]
function CreateStyledContextMenu(items, anchorFrame, anchorPoint, relativePoint, xOffset, yOffset)
    -- Create menu frame
    local menu = CreateStyledFrame(UIParent, UISTYLE_COLORS.DarkGrey)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetFrameLevel(100)
    
    local menuItems = {}
    local currentY = -4
    local maxWidth = 100
    
    -- Create menu items
    for i, itemData in ipairs(items) do
        if itemData.separator then
            -- Separator
            local sep = menu:CreateTexture(nil, "OVERLAY")
            sep:SetHeight(1)
            sep:SetTexture("Interface\\Buttons\\WHITE8X8")
            sep:SetVertexColor(UISTYLE_COLORS.BorderGrey[1], UISTYLE_COLORS.BorderGrey[2], UISTYLE_COLORS.BorderGrey[3], 1)
            sep:SetPoint("LEFT", 4, 0)
            sep:SetPoint("RIGHT", -4, 0)
            sep:SetPoint("TOP", 0, currentY - 4)
            currentY = currentY - 9
        else
            -- Menu item
            local item = CreateFrame("Button", nil, menu)
            item:SetHeight(20)
            item:SetPoint("LEFT", 2, 0)
            item:SetPoint("RIGHT", -2, 0)
            item:SetPoint("TOP", 0, currentY)
            
            -- Text
            local text = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            text:SetPoint("LEFT", 8, 0)
            text:SetText(itemData.text)
            item.text = text
            
            -- Arrow for submenus
            if itemData.hasArrow then
                local arrow = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                arrow:SetPoint("RIGHT", -8, 0)
                arrow:SetText(">")
                arrow:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
                item.arrow = arrow
            end
            
            -- Update max width
            local textWidth = text:GetStringWidth() + 20
            if itemData.hasArrow then
                textWidth = textWidth + 20
            end
            maxWidth = math.max(maxWidth, textWidth)
            
            -- Disabled state
            if itemData.disabled then
                text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 0.5)
                item:EnableMouse(false)
            else
                text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
                
                -- Highlight
                local highlight = item:CreateTexture(nil, "HIGHLIGHT")
                highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
                highlight:SetVertexColor(1, 1, 1, 0.1)
                highlight:SetAllPoints()
                
                -- Click handler
                item:SetScript("OnClick", function()
                    if itemData.func then
                        itemData.func(itemData.value)
                    end
                    menu:Hide()
                end)
                
                -- Hover effect
                item:SetScript("OnEnter", function(self)
                    self.text:SetTextColor(1, 1, 1, 1)
                end)
                
                item:SetScript("OnLeave", function(self)
                    self.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
                end)
            end
            
            table.insert(menuItems, item)
            currentY = currentY - 20
        end
    end
    
    -- Set menu size
    menu:SetWidth(maxWidth + 4)
    menu:SetHeight(math.abs(currentY) + 4)
    
    -- Position menu
    menu:ClearAllPoints()
    menu:SetPoint(anchorPoint or "TOPRIGHT", anchorFrame, relativePoint or "TOPLEFT", xOffset or 0, yOffset or 0)
    
    -- Close on click outside
    local closeButton = CreateFrame("Button", nil, UIParent)
    closeButton:SetAllPoints(UIParent)
    closeButton:SetFrameStrata("FULLSCREEN")
    closeButton:SetFrameLevel(99)
    closeButton:Hide()
    
    closeButton:SetScript("OnClick", function()
        menu:Hide()
        closeButton:Hide()
    end)
    
    menu:SetScript("OnShow", function()
        closeButton:Show()
    end)
    
    menu:SetScript("OnHide", function()
        closeButton:Hide()
    end)
    
    -- Store reference to close button for cleanup
    menu.closeButton = closeButton
    
    -- Add mouse-away detection
    local mouseAwayTime = 0
    local checkMouseFrame = CreateFrame("Frame")
    checkMouseFrame:SetScript("OnUpdate", function(self, elapsed)
        if menu:IsVisible() then
            -- Check if mouse is over the menu or any of its children
            local isMouseOver = menu:IsMouseOver()
            
            if not isMouseOver then
                -- Mouse is away from menu, start timer
                mouseAwayTime = mouseAwayTime + elapsed
                if mouseAwayTime > 0.5 then -- Close after 0.5 seconds
                    menu:Hide()
                    checkMouseFrame:SetScript("OnUpdate", nil)
                end
            else
                -- Mouse is over menu, reset timer
                mouseAwayTime = 0
            end
        else
            -- Menu is hidden, stop checking
            checkMouseFrame:SetScript("OnUpdate", nil)
        end
    end)
    
    -- Clean up the check frame when menu is hidden
    menu:HookScript("OnHide", function()
        checkMouseFrame:SetScript("OnUpdate", nil)
        mouseAwayTime = 0
    end)
    
    -- Start checking when menu is shown
    menu:HookScript("OnShow", function()
        mouseAwayTime = 0
        checkMouseFrame:SetScript("OnUpdate", checkMouseFrame:GetScript("OnUpdate"))
    end)
    
    return menu
end

--[[
Creates a styled edit box
@param parent - Parent frame
@param width - Edit box width
@param numeric - Boolean for numeric-only input
@param maxLetters - Maximum number of characters
@param multiLine - Boolean for multi-line support
@return editBox frame
]]
function CreateStyledEditBox(parent, width, numeric, maxLetters, multiLine)
    local container = CreateStyledFrame(parent, UISTYLE_COLORS.OptionBg)
    container:SetHeight(multiLine and 60 or 24)
    container:SetWidth(width)
    
    local editBox
    if multiLine then
        -- Create scroll frame for multi-line
        local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 4, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", -24, 4)
        
        editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetWidth(width - 28)
        editBox:SetHeight(200) -- Large height for multi-line
        scrollFrame:SetScrollChild(editBox)
        
        -- Style the scroll bar
        local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
        if scrollBar then
            scrollBar:SetWidth(16)
        end
    else
        editBox = CreateFrame("EditBox", nil, container)
        editBox:SetPoint("TOPLEFT", 4, -2)
        editBox:SetPoint("BOTTOMRIGHT", -4, 2)
    end
    
    editBox:SetFontObject("GameFontHighlight")
    editBox:SetTextColor(UISTYLE_COLORS.White[1], UISTYLE_COLORS.White[2], UISTYLE_COLORS.White[3], 1)
    editBox:SetAutoFocus(false)
    
    if numeric then
        editBox:SetNumeric(true)
    end
    
    if maxLetters then
        editBox:SetMaxLetters(maxLetters)
    end
    
    -- Focus indicator
    editBox:SetScript("OnEditFocusGained", function(self)
        container:SetBackdropBorderColor(UISTYLE_COLORS.Blue[1], UISTYLE_COLORS.Blue[2], UISTYLE_COLORS.Blue[3], 1)
    end)
    
    editBox:SetScript("OnEditFocusLost", function(self)
        container:SetBackdropBorderColor(0, 0, 0, 1)
    end)
    
    -- Clear focus on escape
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    
    -- Clear focus on enter for single-line
    if not multiLine then
        editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
    end
    
    -- Expose the edit box
    container.editBox = editBox
    
    -- Helper methods
    container.GetText = function(self)
        return self.editBox:GetText()
    end
    
    container.SetText = function(self, text)
        self.editBox:SetText(text)
    end
    
    container.ClearFocus = function(self)
        self.editBox:ClearFocus()
    end
    
    container.SetFocus = function(self)
        self.editBox:SetFocus()
    end
    
    return container
end

-- ===================================
-- ICON HELPER FUNCTIONS
-- ===================================

--[[
Safely retrieves an item's icon texture from GetItemInfo
@param itemId - The item ID to get icon for
@return texture path or fallback question mark icon
]]
function GetItemIconSafe(itemId)
    if not itemId then 
        return "Interface\\Icons\\INV_Misc_QuestionMark" 
    end
    
    local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemId)
    return texture or "Interface\\Icons\\INV_Misc_QuestionMark"
end

--[[
Safely retrieves a spell's icon texture from GetSpellInfo
@param spellId - The spell ID to get icon for
@return icon path or fallback spell book icon
]]
function GetSpellIconSafe(spellId)
    if not spellId then 
        return "Interface\\Icons\\INV_Misc_Book_09" 
    end
    
    local _, _, icon = GetSpellInfo(spellId)
    return icon or "Interface\\Icons\\INV_Misc_Book_09"
end

--[[
Creates a properly configured icon texture with border trimming
@param parent - Parent frame
@param size - Icon size (width and height)
@param iconPath - Path to icon texture (optional)
@param drawLayer - Draw layer (optional, defaults to "ARTWORK")
@return texture object
]]
function CreateIconTexture(parent, size, iconPath, drawLayer)
    local icon = parent:CreateTexture(nil, drawLayer or "ARTWORK")
    icon:SetSize(size or 32, size or 32)
    
    if iconPath then
        icon:SetTexture(iconPath)
    else
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    
    -- Trim default WoW icon borders
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    return icon
end

--[[
Creates a styled icon button with proper border trimming and highlight effects
@param parent - Parent frame
@param size - Button size
@param iconPath - Path to icon texture (optional)
@param onClick - Click handler function (optional)
@param tooltip - Tooltip text (optional)
@return button frame with icon
]]
function CreateIconButton(parent, size, iconPath, onClick, tooltip)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size or 32, size or 32)
    
    -- Icon texture
    button.icon = CreateIconTexture(button, size, iconPath)
    button.icon:SetAllPoints()
    
    -- Border backdrop
    button:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints()
    
    -- Pushed texture offset
    button:SetPushedTextureOffset(1, -1)
    
    -- Click handler
    if onClick then
        button:SetScript("OnClick", onClick)
    end
    
    -- Tooltip
    if tooltip then
        SetupTooltip(button, tooltip)
    end
    
    -- Helper methods
    button.SetIcon = function(self, newIconPath)
        if newIconPath then
            self.icon:SetTexture(newIconPath)
        else
            self.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
    end
    
    button.SetItemIcon = function(self, itemId)
        self.icon:SetTexture(GetItemIconSafe(itemId))
    end
    
    button.SetSpellIcon = function(self, spellId)
        self.icon:SetTexture(GetSpellIconSafe(spellId))
    end
    
    return button
end

--[[
Updates an existing texture to display an item icon safely
@param texture - The texture object to update
@param itemId - The item ID
]]
function SetTextureToItemIcon(texture, itemId)
    texture:SetTexture(GetItemIconSafe(itemId))
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

--[[
Updates an existing texture to display a spell icon safely
@param texture - The texture object to update
@param spellId - The spell ID
]]
function SetTextureToSpellIcon(texture, spellId)
    texture:SetTexture(GetSpellIconSafe(spellId))
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

-- Common fallback icon paths
ICON_FALLBACKS = {
    QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark",
    SPELL_BOOK = "Interface\\Icons\\INV_Misc_Book_09",
    CURRENCY = "Interface\\Icons\\INV_Misc_Coin_01",
    EMPTY_SLOT = "Interface\\PaperDoll\\UI-Backpack-EmptySlot",
    GEAR = "Interface\\Icons\\Trade_Engineering",
    POTION = "Interface\\Icons\\INV_Potion_01",
    FOOD = "Interface\\Icons\\INV_Misc_Food_01",
    WEAPON = "Interface\\Icons\\INV_Sword_01",
    ARMOR = "Interface\\Icons\\INV_Chest_Chain",
}

-- ===================================
-- DIALOG COMPONENTS
-- ===================================

--[[
Creates a styled modal dialog with customizable buttons
@param options - Dialog configuration:
  - title: Dialog title text
  - message: Main message text
  - buttons: Table of button configs {text="OK", callback=function() end}
  - width: Optional width (defaults to 400)
  - height: Optional height (auto-sizes based on content)
  - parent: Optional parent (defaults to UIParent)
  - closeOnEscape: Optional boolean (defaults to true)
@return Dialog frame with methods:
  - .Show() - Show the dialog
  - .Hide() - Hide the dialog
  - .SetMessage(text) - Update message text
]]

-- Global dialog manager to prevent multiple dialogs
local activeDialog = nil

function CreateStyledDialog(options)
    options = options or {}
    local parent = options.parent or UIParent
    
    -- Create fullscreen background overlay
    local overlay = CreateFrame("Frame", nil, parent)
    overlay:SetFrameStrata("FULLSCREEN_DIALOG")
    overlay:SetAllPoints(parent)
    overlay:EnableMouse(true)  -- Enable mouse to block clicks
    overlay:Hide()
    
    -- Semi-transparent black background
    local overlayBg = overlay:CreateTexture(nil, "BACKGROUND")
    overlayBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    overlayBg:SetVertexColor(0, 0, 0, 0.8)
    overlayBg:SetAllPoints()
    
    -- Dialog frame
    local dialog = CreateStyledFrame(overlay, UISTYLE_COLORS.DarkGrey)
    dialog:SetFrameStrata("TOOLTIP")  -- Use TOOLTIP strata to ensure it's on top
    dialog:SetWidth(options.width or 400)
    dialog:SetPoint("CENTER")
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, dialog)
    titleBar:SetHeight(30)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetFrameLevel(dialog:GetFrameLevel() + 1)
    
    titleBar:SetBackdrop(UISTYLE_BACKDROPS.Solid)
    titleBar:SetBackdropColor(UISTYLE_COLORS.SectionBg[1], UISTYLE_COLORS.SectionBg[2], UISTYLE_COLORS.SectionBg[3], 1)
    
    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER")
    title:SetText(options.title or "Dialog")
    title:SetTextColor(1, 1, 1, 1)
    
    -- Close button
    local closeButton = CreateStyledButton(titleBar, "X", 20, 20)
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        dialog:Hide()
    end)
    
    -- Message area
    local messageFrame = CreateFrame("Frame", nil, dialog)
    messageFrame:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", UISTYLE_PADDING, -UISTYLE_PADDING)
    messageFrame:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -UISTYLE_PADDING, -UISTYLE_PADDING)
    
    local message = messageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    message:SetPoint("TOPLEFT")
    message:SetPoint("TOPRIGHT")
    message:SetJustifyH("LEFT")
    message:SetJustifyV("TOP")
    message:SetText(options.message or "")
    message:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3])
    
    -- Button area
    local buttonArea = CreateFrame("Frame", nil, dialog)
    buttonArea:SetHeight(40)
    buttonArea:SetPoint("BOTTOMLEFT", UISTYLE_PADDING, UISTYLE_PADDING)
    buttonArea:SetPoint("BOTTOMRIGHT", -UISTYLE_PADDING, UISTYLE_PADDING)
    
    -- Create buttons
    local buttons = {}
    local buttonConfigs = options.buttons or {{text = "OK", callback = function() dialog:Hide() end}}
    local buttonWidth = 100
    local buttonSpacing = 10
    local totalButtonWidth = (#buttonConfigs * buttonWidth) + ((#buttonConfigs - 1) * buttonSpacing)
    
    -- Create a container frame for centering buttons
    local buttonContainer = CreateFrame("Frame", nil, buttonArea)
    buttonContainer:SetSize(totalButtonWidth, 30)
    buttonContainer:SetPoint("CENTER", buttonArea, "CENTER", 0, 0)
    
    for i, config in ipairs(buttonConfigs) do
        local button = CreateStyledButton(buttonContainer, config.text, buttonWidth, 30)
        
        if i == 1 then
            button:SetPoint("LEFT", buttonContainer, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", buttons[i-1], "RIGHT", buttonSpacing, 0)
        end
        
        button:SetScript("OnClick", function()
            if config.callback then
                config.callback()
            end
            if config.closeOnClick ~= false then
                dialog:Hide()
            end
        end)
        
        table.insert(buttons, button)
    end
    
    -- Auto-size height based on content
    local messageHeight = message:GetStringHeight()
    local totalHeight = 30 + UISTYLE_PADDING * 2 + messageHeight + UISTYLE_PADDING + 40 + UISTYLE_PADDING * 2
    dialog:SetHeight(options.height or math.max(150, totalHeight))
    
    -- Message frame height
    messageFrame:SetHeight(messageHeight + UISTYLE_PADDING)
    
    -- Escape key handling
    if options.closeOnEscape ~= false then
        dialog:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                dialog:Hide()
            end
        end)
        dialog:EnableKeyboard(true)
    end
    
    -- Click outside to close
    overlay:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            dialog:Hide()
        end
    end)
    
    -- Prevent click-through to dialog
    dialog:SetScript("OnMouseDown", function(self, button)
        -- Do nothing, stops propagation
    end)
    
    -- Methods
    dialog.Show = function(self)
        -- Close any existing dialog
        if activeDialog and activeDialog ~= dialog then
            activeDialog:Hide()
        end
        activeDialog = dialog
        overlay:Show()
    end
    
    dialog.Hide = function(self)
        overlay:Hide()
        if activeDialog == dialog then
            activeDialog = nil
        end
    end
    
    dialog.SetMessage = function(self, text)
        message:SetText(text)
        local messageHeight = message:GetStringHeight()
        messageFrame:SetHeight(messageHeight + UISTYLE_PADDING)
        local totalHeight = 30 + UISTYLE_PADDING * 2 + messageHeight + UISTYLE_PADDING + 40 + UISTYLE_PADDING * 2
        dialog:SetHeight(math.max(150, totalHeight))
    end
    
    dialog.overlay = overlay
    dialog.buttons = buttons
    
    return dialog
end

--[[
Creates a styled slider for numeric input
@param parent - Parent frame
@param width - Slider width
@param height - Optional height (defaults to 20)
@param min - Minimum value
@param max - Maximum value
@param step - Step increment
@param defaultValue - Initial value
@param orientation - "HORIZONTAL" (default) or "VERTICAL"
@return Slider frame with methods:
  - .SetValue(value) - Set current value
  - .GetValue() - Get current value
  - .SetLabel(text) - Set label text
  - .SetValueText(format) - Set value text format (e.g., "%.1f%%")
  - .SetOnValueChanged(callback) - Set callback function(value)
]]
function CreateStyledSlider(parent, width, height, min, max, step, defaultValue, orientation)
    local container = CreateFrame("Frame", nil, parent)
    local isVertical = orientation == "VERTICAL"
    
    -- Set container size based on orientation
    if isVertical then
        -- For vertical sliders, keep width reasonable, add extra height for text
        container:SetSize(math.max(60, width), height + 40) -- Min width 60 for text, extra height for label/value
    else
        container:SetSize(width, (height or 20) + 30) -- Extra height for label and value
    end
    
    -- Label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetTextColor(1, 1, 1, 1)
    
    -- Value text
    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3])
    
    -- Position label and value based on orientation
    if isVertical then
        -- Stack label and value vertically for vertical sliders
        label:SetPoint("TOP", container, "TOP", 0, 0)
        valueText:SetPoint("TOP", label, "BOTTOM", 0, -2)
    else
        -- Side by side for horizontal sliders
        label:SetPoint("TOPLEFT")
        valueText:SetPoint("TOPRIGHT")
    end
    
    -- Slider
    local slider = CreateFrame("Slider", nil, container)
    slider:SetOrientation(orientation or "HORIZONTAL")
    
    -- Position and size slider based on orientation
    if isVertical then
        slider:SetSize(width, height)
        slider:SetPoint("TOP", valueText, "BOTTOM", 0, -5)
    else
        slider:SetSize(width, height or 20)
        slider:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -20)
        slider:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -20)
    end
    slider:SetMinMaxValues(min or 0, max or 100)
    slider:SetValueStep(step or 1)
    
    -- Set initial value (inverted for vertical sliders)
    if isVertical and defaultValue then
        slider:SetValue(max - defaultValue + min)
    else
        slider:SetValue(defaultValue or min or 0)
    end
    
    -- Slider background
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    slider:SetBackdropColor(UISTYLE_COLORS.DarkGrey[1], UISTYLE_COLORS.DarkGrey[2], UISTYLE_COLORS.DarkGrey[3], 1)
    slider:SetBackdropBorderColor(UISTYLE_COLORS.BorderGrey[1], UISTYLE_COLORS.BorderGrey[2], UISTYLE_COLORS.BorderGrey[3], 1)
    
    -- Thumb
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetVertexColor(0.6, 0.6, 0.6, 1)
    
    if isVertical then
        thumb:SetSize(width - 4, 10)
    else
        thumb:SetSize(10, (height or 20) - 4)
    end
    
    slider:SetThumbTexture(thumb)
    
    -- Value format
    local valueFormat = "%.0f"
    
    -- Get actual display value (inverted for vertical sliders)
    local function GetDisplayValue()
        local value = slider:GetValue()
        if isVertical then
            -- Invert value for vertical sliders (0 at bottom, max at top)
            return max - value + min
        end
        return value
    end
    
    -- Update value text
    local function UpdateValueText()
        valueText:SetText(string.format(valueFormat, GetDisplayValue()))
    end
    
    -- Slider events
    slider:SetScript("OnValueChanged", function(self, value)
        UpdateValueText()
        if container.onValueChanged then
            container.onValueChanged(GetDisplayValue())
        end
    end)
    
    -- Hover effects
    slider:SetScript("OnEnter", function(self)
        thumb:SetVertexColor(0.8, 0.8, 0.8, 1)
    end)
    
    slider:SetScript("OnLeave", function(self)
        thumb:SetVertexColor(0.6, 0.6, 0.6, 1)
    end)
    
    -- Container methods
    container.SetValue = function(self, value)
        if isVertical then
            -- Invert value when setting for vertical sliders
            slider:SetValue(max - value + min)
        else
            slider:SetValue(value)
        end
    end
    
    container.GetValue = function(self)
        return GetDisplayValue()
    end
    
    container.SetLabel = function(self, text)
        label:SetText(text)
    end
    
    container.SetValueText = function(self, format)
        valueFormat = format or "%.0f"
        UpdateValueText()
    end
    
    container.SetOnValueChanged = function(self, callback)
        self.onValueChanged = callback
    end
    
    container.SetMinMaxValues = function(self, newMin, newMax)
        min = newMin
        max = newMax
        slider:SetMinMaxValues(newMin, newMax)
    end
    
    container.SetValueStep = function(self, newStep)
        slider:SetValueStep(newStep)
    end
    
    container.slider = slider
    container.label = label
    container.valueText = valueText
    
    -- Initial update
    UpdateValueText()
    
    return container
end

--[[
Creates a styled slider with min/max labels at the ends (enhanced version)
@param parent - Parent frame  
@param width - Slider width
@param height - Slider height (defaults to 20)
@param min - Minimum value
@param max - Maximum value
@param step - Value step
@param defaultValue - Initial value
@param labelText - Optional label text (e.g. "Level")
@return Slider container with methods:
  - .GetValue() - Get current slider value
  - .SetValue(value) - Set slider value
  - .SetLabel(text) - Update label text
  - .SetOnValueChanged(callback) - Set callback function(value)
]]
function CreateStyledSliderWithRange(parent, width, height, min, max, step, defaultValue, labelText)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 50) -- Extra height for labels
    
    -- Label (if provided)
    local label
    if labelText then
        label = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", 0, 0)
        label:SetText(labelText .. ":")
        label:SetTextColor(1, 1, 1, 1)
    end
    
    -- Current value display (centered above slider)
    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetPoint("TOP", container, "TOP", 0, -5)  -- Moved up from -15 to -5
    valueText:SetTextColor(1, 1, 1, 1)
    
    -- Slider container for proper positioning
    local sliderFrame = CreateFrame("Frame", nil, container)
    sliderFrame:SetSize(width - 40, height or 20)
    sliderFrame:SetPoint("BOTTOM", container, "BOTTOM", 0, 15)
    
    -- Min value label
    local minLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall") 
    minLabel:SetPoint("BOTTOMLEFT", sliderFrame, "BOTTOMLEFT", -20, -15)
    minLabel:SetText(tostring(min))
    minLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    
    -- Max value label
    local maxLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxLabel:SetPoint("BOTTOMRIGHT", sliderFrame, "BOTTOMRIGHT", 20, -15)
    maxLabel:SetText(tostring(max))
    maxLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    
    -- Create the actual slider
    local slider = CreateFrame("Slider", nil, sliderFrame)
    slider:SetAllPoints()
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(min or 0, max or 100)
    slider:SetValueStep(step or 1)
    slider:SetValue(defaultValue or min or 0)
    slider:EnableMouse(true)  -- Ensure mouse is enabled
    
    -- Slider background track
    local bg = slider:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.1, 0.1, 0.1, 1)
    bg:SetHeight(4)
    bg:SetPoint("LEFT", slider, "LEFT", 0, 0)
    bg:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    
    -- Slider thumb (CRITICAL - without this, slider won't be draggable!)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetVertexColor(0.8, 0.8, 0.8, 1)
    thumb:SetSize(12, 20)
    slider:SetThumbTexture(thumb)
    
    -- Update value text
    local function UpdateValue()
        local value = math.floor(slider:GetValue())
        valueText:SetText(tostring(value))
    end
    
    -- Value changed handler
    slider:SetScript("OnValueChanged", function(self, value)
        UpdateValue()
        if container.onValueChanged then
            container.onValueChanged(value)
        end
    end)
    
    -- Hover effects
    slider:SetScript("OnEnter", function(self)
        thumb:SetVertexColor(0.9, 0.9, 0.9, 1)
    end)
    
    slider:SetScript("OnLeave", function(self)
        if not self:IsMouseOver() then
            thumb:SetVertexColor(0.8, 0.8, 0.8, 1)
        end
    end)
    
    -- Initialize
    UpdateValue()
    
    -- Public methods
    container.GetValue = function(self)
        return math.floor(slider:GetValue())
    end
    
    container.SetValue = function(self, value)
        slider:SetValue(value)
    end
    
    container.SetLabel = function(self, text)
        if label then
            label:SetText(text .. ":")
        end
    end
    
    container.SetOnValueChanged = function(self, callback)
        self.onValueChanged = callback
    end
    
    -- Expose elements
    container.slider = slider
    container.label = label
    container.valueText = valueText
    container.minLabel = minLabel
    container.maxLabel = maxLabel
    
    return container
end

--[[
Creates a styled list view with selectable rows
@param parent - Parent frame
@param width - List width
@param height - List height
@param rowHeight - Height of each row (defaults to 20)
@param columns - Optional column definitions: {{key="id", text="ID", width=50}, ...}
@return List view with methods:
  - .SetData(data) - Set list data (table of items)
  - .GetSelected() - Get selected item data
  - .SetSelected(index) - Set selected row by index
  - .SetOnSelectionChanged(callback) - Set selection callback function(data, index)
  - .Refresh() - Refresh the list display
]]
function CreateStyledListView(parent, width, height, rowHeight, columns)
    rowHeight = rowHeight or 20
    
    -- Main container
    local container = CreateStyledFrame(parent, UISTYLE_COLORS.OptionBg)
    container:SetSize(width, height)
    
    -- Header (if columns defined)
    local headerHeight = 0
    local header
    if columns then
        headerHeight = 24
        header = CreateFrame("Frame", nil, container)
        header:SetHeight(headerHeight)
        header:SetPoint("TOPLEFT", 2, -2)
        header:SetPoint("TOPRIGHT", -2, -2)
        
        header:SetBackdrop(UISTYLE_BACKDROPS.Solid)
        header:SetBackdropColor(UISTYLE_COLORS.SectionBg[1], UISTYLE_COLORS.SectionBg[2], UISTYLE_COLORS.SectionBg[3], 1)
        
        -- Create column headers
        local xOffset = 0
        for i, col in ipairs(columns) do
            local colHeader = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            colHeader:SetPoint("LEFT", header, "LEFT", xOffset + 5, 0)
            colHeader:SetText(col.text or col.key)
            colHeader:SetTextColor(1, 1, 1, 1)
            colHeader:SetWidth(col.width or 100)
            colHeader:SetJustifyH(col.align or "LEFT")
            
            xOffset = xOffset + (col.width or 100)
        end
    end
    
    -- Scrollable content area
    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetPoint("TOPLEFT", 2, -(2 + headerHeight))
    scrollFrame:SetPoint("BOTTOMRIGHT", -14, 2)
    
    -- Content frame
    local content = CreateFrame("Frame", nil, container)
    content:SetWidth(width - 16)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)
    
    -- Scrollbar
    local scrollBar = CreateStyledScrollBar(container, 12, height - 4 - headerHeight)
    scrollBar:SetPoint("TOPRIGHT", -2, -(2 + headerHeight))
    scrollBar:SetPoint("BOTTOMRIGHT", -2, 2)
    
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scrollFrame:SetVerticalScroll(value)
    end)
    
    -- Mouse wheel support
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollBar:GetValue()
        local min, max = scrollBar:GetMinMaxValues()
        local step = rowHeight * 3
        
        if delta > 0 then
            scrollBar:SetValue(math.max(min, current - step))
        else
            scrollBar:SetValue(math.min(max, current + step))
        end
    end)
    
    -- Data storage
    local data = {}
    local rows = {}
    local selectedIndex = nil
    
    -- Update scrollbar
    local function UpdateScrollBar()
        local contentHeight = #data * rowHeight
        local frameHeight = scrollFrame:GetHeight()
        
        if contentHeight > frameHeight then
            local maxScroll = contentHeight - frameHeight
            scrollBar:SetMinMaxValues(0, maxScroll)
            scrollBar:Show()
            scrollFrame:SetPoint("BOTTOMRIGHT", -14, 2)
        else
            scrollBar:SetMinMaxValues(0, 0)
            scrollBar:Hide()
            scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
        end
        
        content:SetHeight(math.max(1, contentHeight))
    end
    
    -- Create row
    local function CreateRow(index)
        local row = CreateFrame("Button", nil, content)
        row:SetHeight(rowHeight)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight)
        row:SetPoint("TOPRIGHT", 0, -(index - 1) * rowHeight)
        
        -- Row background
        row:SetBackdrop(UISTYLE_BACKDROPS.Solid)
        row:SetBackdropColor(0, 0, 0, 0)
        
        -- Highlight texture
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlight:SetVertexColor(1, 1, 1, 0.1)
        highlight:SetAllPoints()
        
        -- Selection texture
        local selection = row:CreateTexture(nil, "BACKGROUND")
        selection:SetTexture("Interface\\Buttons\\WHITE8X8")
        selection:SetVertexColor(UISTYLE_COLORS.Blue[1], UISTYLE_COLORS.Blue[2], UISTYLE_COLORS.Blue[3], 0.3)
        selection:SetAllPoints()
        selection:Hide()
        row.selection = selection
        
        -- Text elements
        if columns then
            row.texts = {}
            local xOffset = 0
            for i, col in ipairs(columns) do
                local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                text:SetPoint("LEFT", row, "LEFT", xOffset + 5, 0)
                text:SetWidth(col.width or 100)
                text:SetJustifyH(col.align or "LEFT")
                text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3])
                row.texts[col.key] = text
                
                xOffset = xOffset + (col.width or 100)
            end
        else
            -- Single text for simple list
            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.text:SetPoint("LEFT", 5, 0)
            row.text:SetPoint("RIGHT", -5, 0)
            row.text:SetJustifyH("LEFT")
            row.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3])
        end
        
        -- Click handler
        row:SetScript("OnClick", function(self)
            if selectedIndex ~= index then
                -- Clear previous selection
                if selectedIndex and rows[selectedIndex] then
                    rows[selectedIndex].selection:Hide()
                end
                
                -- Set new selection
                selectedIndex = index
                self.selection:Show()
                
                -- Callback
                if container.onSelectionChanged then
                    container.onSelectionChanged(data[index], index)
                end
            end
        end)
        
        return row
    end
    
    -- Refresh list
    local function Refresh()
        -- Clear existing rows
        for i, row in ipairs(rows) do
            row:Hide()
        end
        
        -- Create/update rows
        for i, item in ipairs(data) do
            local row = rows[i]
            if not row then
                row = CreateRow(i)
                rows[i] = row
            end
            
            -- Update row content
            if columns then
                for _, col in ipairs(columns) do
                    if row.texts[col.key] then
                        local value = item[col.key] or ""
                        row.texts[col.key]:SetText(tostring(value))
                    end
                end
            else
                -- Simple list - expect string or use tostring
                local text = type(item) == "table" and (item.text or item.name or tostring(item)) or tostring(item)
                row.text:SetText(text)
            end
            
            -- Update selection state
            if i == selectedIndex then
                row.selection:Show()
            else
                row.selection:Hide()
            end
            
            row:Show()
        end
        
        UpdateScrollBar()
    end
    
    -- Container methods
    container.SetData = function(self, newData)
        data = newData or {}
        selectedIndex = nil
        Refresh()
    end
    
    container.GetSelected = function(self)
        return selectedIndex and data[selectedIndex] or nil
    end
    
    container.SetSelected = function(self, index)
        if index and index > 0 and index <= #data then
            selectedIndex = index
            Refresh()
            
            if self.onSelectionChanged then
                self.onSelectionChanged(data[index], index)
            end
        end
    end
    
    container.SetOnSelectionChanged = function(self, callback)
        self.onSelectionChanged = callback
    end
    
    container.Refresh = Refresh
    
    container.scrollFrame = scrollFrame
    container.content = content
    container.scrollBar = scrollBar
    container.data = data
    container.rows = rows
    
    return container
end

--[[
Creates a styled status bar (health/mana/etc)
@param parent - Parent frame
@param width - Bar width
@param height - Bar height (defaults to 20)
@param color - Bar color {r, g, b} or color name ("health", "mana", "energy", "rage", "focus")
@param showText - Whether to show value text (defaults to true)
@return Status bar with methods:
  - .SetMinMaxValues(min, max) - Set value range
  - .SetValue(value) - Set current value
  - .GetValue() - Get current value
  - .SetColor(r, g, b) - Set bar color
  - .SetText(text) - Set custom text (overrides auto text)
  - .SetTextFormat(format) - Set text format (e.g., "%d / %d")
]]
function CreateStyledStatusBar(parent, width, height, color, showText)
    height = height or 20
    showText = showText ~= false
    
    -- Container frame
    local container = CreateStyledFrame(parent, UISTYLE_COLORS.DarkGrey)
    container:SetSize(width, height)
    
    -- Background
    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.05, 0.05, 0.05, 1)
    bg:SetPoint("TOPLEFT", 1, -1)
    bg:SetPoint("BOTTOMRIGHT", -1, 1)
    
    -- Status bar
    local statusBar = CreateFrame("StatusBar", nil, container)
    statusBar:SetPoint("TOPLEFT", 1, -1)
    statusBar:SetPoint("BOTTOMRIGHT", -1, 1)
    statusBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    statusBar:SetMinMaxValues(0, 100)
    statusBar:SetValue(100)
    
    -- Predefined colors
    local colorPresets = {
        health = {0.12, 0.75, 0.12},
        mana = {0.31, 0.69, 0.89},
        energy = {1, 1, 0},
        rage = {0.89, 0.31, 0.31},
        focus = {1, 0.5, 0.25},
        runic = {0, 0.82, 1}
    }
    
    -- Set color
    if type(color) == "string" and colorPresets[color] then
        local c = colorPresets[color]
        statusBar:SetStatusBarColor(c[1], c[2], c[3])
    elseif type(color) == "table" then
        statusBar:SetStatusBarColor(color[1], color[2], color[3])
    else
        statusBar:SetStatusBarColor(0.12, 0.75, 0.12) -- Default to health green
    end
    
    -- Text overlay
    local text
    if showText then
        text = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("CENTER")
        text:SetTextColor(1, 1, 1, 1)
    end
    
    -- Text format
    local textFormat = "%d / %d"
    local customText = nil
    
    -- Update text
    local function UpdateText()
        if text and not customText then
            local value = statusBar:GetValue()
            local min, max = statusBar:GetMinMaxValues()
            text:SetText(string.format(textFormat, value, max))
        end
    end
    
    -- Spark effect
    local spark = statusBar:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetBlendMode("ADD")
    spark:SetWidth(10)
    spark:SetHeight(height * 1.5)
    
    -- Update spark position
    local function UpdateSpark()
        local value = statusBar:GetValue()
        local min, max = statusBar:GetMinMaxValues()
        local width = statusBar:GetWidth()
        
        if value > min and value < max then
            local percent = (value - min) / (max - min)
            spark:SetPoint("CENTER", statusBar, "LEFT", width * percent, 0)
            spark:Show()
        else
            spark:Hide()
        end
    end
    
    -- Methods
    container.SetMinMaxValues = function(self, min, max)
        statusBar:SetMinMaxValues(min, max)
        UpdateText()
        UpdateSpark()
    end
    
    container.SetValue = function(self, value)
        statusBar:SetValue(value)
        UpdateText()
        UpdateSpark()
    end
    
    container.GetValue = function(self)
        return statusBar:GetValue()
    end
    
    container.SetColor = function(self, r, g, b)
        statusBar:SetStatusBarColor(r, g, b)
    end
    
    container.SetText = function(self, newText)
        if text then
            customText = newText
            text:SetText(newText)
        end
    end
    
    container.SetTextFormat = function(self, format)
        textFormat = format
        customText = nil
        UpdateText()
    end
    
    container.ShowText = function(self, show)
        if text then
            if show then
                text:Show()
            else
                text:Hide()
            end
        end
    end
    
    container.statusBar = statusBar
    container.text = text
    container.spark = spark
    
    -- Initial update
    UpdateText()
    UpdateSpark()
    
    return container
end

--[[
Creates a styled tooltip frame with rich content support
@param parent - Parent frame to attach tooltip to
@param anchor - Anchor point ("TOPLEFT", "RIGHT", etc)
@param xOffset - X offset from anchor
@param yOffset - Y offset from anchor
@return Tooltip frame with methods:
  - .SetContent(lines) - Set tooltip content: {{text="Title", color={1,1,1}, size="large"}, ...}
  - .AddLine(text, r, g, b, size) - Add a line of text
  - .Show() - Show tooltip
  - .Hide() - Hide tooltip
  - .Clear() - Clear all content
]]
function CreateStyledTooltipFrame(parent, anchor, xOffset, yOffset)
    local tooltip = CreateStyledFrame(UIParent, UISTYLE_COLORS.DarkGrey)
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:SetFrameLevel(100)
    tooltip:Hide()
    
    -- Content area
    local content = CreateFrame("Frame", nil, tooltip)
    content:SetPoint("TOPLEFT", UISTYLE_SMALL_PADDING, -UISTYLE_SMALL_PADDING)
    content:SetPoint("TOPRIGHT", -UISTYLE_SMALL_PADDING, -UISTYLE_SMALL_PADDING)
    
    -- Line storage
    local lines = {}
    local linePool = {}
    local currentY = 0
    
    -- Get or create line
    local function GetLine()
        local line = table.remove(linePool)
        if not line then
            line = content:CreateFontString(nil, "OVERLAY")
            line:SetJustifyH("LEFT")
            line:SetJustifyV("TOP")
        end
        return line
    end
    
    -- Return line to pool
    local function ReleaseLine(line)
        line:Hide()
        line:SetText("")
        table.insert(linePool, line)
    end
    
    -- Clear all lines
    local function Clear()
        for _, line in ipairs(lines) do
            ReleaseLine(line)
        end
        wipe(lines)
        currentY = 0
    end
    
    -- Add line
    local function AddLine(text, r, g, b, size)
        local line = GetLine()
        
        -- Set font size
        if size == "large" then
            line:SetFontObject("GameFontNormalLarge")
        elseif size == "small" then
            line:SetFontObject("GameFontNormalSmall")
        else
            line:SetFontObject("GameFontHighlight")
        end
        
        line:SetText(text)
        line:SetTextColor(r or 1, g or 1, b or 1)
        line:SetPoint("TOPLEFT", 0, -currentY)
        line:SetPoint("TOPRIGHT", 0, -currentY)
        line:Show()
        
        table.insert(lines, line)
        currentY = currentY + line:GetStringHeight() + 2
        
        return line
    end
    
    -- Update size
    local function UpdateSize()
        local maxWidth = 0
        for _, line in ipairs(lines) do
            maxWidth = math.max(maxWidth, line:GetStringWidth())
        end
        
        tooltip:SetWidth(math.max(150, maxWidth + UISTYLE_SMALL_PADDING * 2))
        tooltip:SetHeight(currentY + UISTYLE_SMALL_PADDING * 2)
        content:SetHeight(currentY)
    end
    
    -- Position tooltip
    local function UpdatePosition()
        tooltip:ClearAllPoints()
        if parent then
            tooltip:SetPoint(anchor or "BOTTOMRIGHT", parent, anchor or "TOPRIGHT", xOffset or 0, yOffset or 5)
        else
            tooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 100, 100)
        end
    end
    
    -- Methods
    tooltip.SetContent = function(self, contentLines)
        Clear()
        
        for _, lineData in ipairs(contentLines) do
            local color = lineData.color or {1, 1, 1}
            AddLine(lineData.text, color[1], color[2], color[3], lineData.size)
        end
        
        UpdateSize()
        UpdatePosition()
    end
    
    tooltip.AddLine = function(self, text, r, g, b, size)
        AddLine(text, r, g, b, size)
        UpdateSize()
    end
    
    tooltip.Clear = Clear
    
    tooltip.SetAnchor = function(self, newParent, newAnchor, newXOffset, newYOffset)
        parent = newParent
        anchor = newAnchor
        xOffset = newXOffset
        yOffset = newYOffset
        UpdatePosition()
    end
    
    -- Auto-hide on parent hide
    if parent then
        parent:HookScript("OnHide", function()
            tooltip:Hide()
        end)
    end
    
    return tooltip
end

-- Toast notification stack managers for different anchor points
local ToastManagers = {}

-- Toast manager prototype with shared methods
local ToastManagerMethods = {}

-- Create a toast manager for a specific anchor
local function GetOrCreateToastManager(anchor)
    anchor = anchor or "TOP"
    
    if not ToastManagers[anchor] then
        local anchorX, anchorY = 0, -100
        
        -- Set default positions for each anchor
        if anchor == "BOTTOM" then
            anchorY = -100
        elseif anchor == "TOPRIGHT" then
            anchorX = -50
            anchorY = -100
        elseif anchor == "BOTTOMRIGHT" then
            anchorX = -50
            anchorY = -100
        elseif anchor == "TOPLEFT" then
            anchorX = 50
            anchorY = -100
        elseif anchor == "BOTTOMLEFT" then
            anchorX = 50
            anchorY = -100
        end
        
        local manager = {
            activeToasts = {},
            toastSpacing = 5,
            toastHeight = 40,
            anchorPoint = anchor,
            anchorX = anchorX,
            anchorY = anchorY,
            maxToasts = 5
        }
        
        -- Set metatable to inherit methods
        setmetatable(manager, { __index = ToastManagerMethods })
        
        ToastManagers[anchor] = manager
    end
    
    return ToastManagers[anchor]
end

-- Default manager for backward compatibility
local ToastManager = GetOrCreateToastManager("TOP")

-- Update positions of all active toasts
function ToastManagerMethods:UpdatePositions()
    local yOffset = self.anchorY
    
    for i, toastData in ipairs(self.activeToasts) do
        local toast = toastData.frame
        local targetY
        
        -- Stack direction based on anchor
        if self.anchorPoint:find("BOTTOM") then
            -- Stack upward for bottom anchors
            targetY = yOffset + (i - 1) * (toast:GetHeight() + self.toastSpacing)
        else
            -- Stack downward for top anchors
            targetY = yOffset - (i - 1) * (toast:GetHeight() + self.toastSpacing)
        end
        
        -- Animate to new position using OnUpdate
        if not toast.moveElapsed then
            toast.moveElapsed = 0
            toast.startY = select(5, toast:GetPoint())
            toast.targetY = targetY
        else
            toast.targetY = targetY
        end
        
        -- Start or update movement animation
        toast:SetScript("OnUpdate", function(self, delta)
            -- Handle both fade and movement animations
            if self.fadeElapsed then
                self.fadeElapsed = self.fadeElapsed + delta
                
                local fadeInDuration = 0.2
                local displayDuration = toastData.duration
                local fadeOutDuration = toastData.fadeTime
                local totalDuration = fadeInDuration + displayDuration + fadeOutDuration
                
                if self.fadeElapsed < fadeInDuration then
                    self:SetAlpha(self.fadeElapsed / fadeInDuration)
                elseif self.fadeElapsed < fadeInDuration + displayDuration then
                    self:SetAlpha(1)
                elseif self.fadeElapsed < totalDuration then
                    local fadeOutProgress = (self.fadeElapsed - fadeInDuration - displayDuration) / fadeOutDuration
                    self:SetAlpha(1 - fadeOutProgress)
                else
                    self:SetScript("OnUpdate", nil)
                    self:Hide()
                    -- Find and remove from the correct manager
                    for anchor, mgr in pairs(ToastManagers) do
                        for _, toastData in ipairs(mgr.activeToasts) do
                            if toastData.frame == self then
                                mgr:RemoveToast(self)
                                return
                            end
                        end
                    end
                    return
                end
            end
            
            -- Handle movement animation
            if self.moveElapsed and self.targetY and self.startY then
                self.moveElapsed = self.moveElapsed + delta
                local moveDuration = 0.2
                
                if self.moveElapsed < moveDuration then
                    local progress = self.moveElapsed / moveDuration
                    -- Smooth easing
                    progress = progress * progress * (3 - 2 * progress)
                    local currentY = self.startY + (self.targetY - self.startY) * progress
                    self:SetPoint(ToastManager.anchorPoint, UIParent, ToastManager.anchorPoint, ToastManager.anchorX, currentY)
                else
                    self:SetPoint(ToastManager.anchorPoint, UIParent, ToastManager.anchorPoint, ToastManager.anchorX, self.targetY)
                    self.moveElapsed = nil
                    self.startY = nil
                    self.targetY = nil
                end
            end
        end)
    end
end

-- Add a new toast to the stack
function ToastManagerMethods:AddToast(frame, duration, fadeTime)
    -- Remove oldest toast if at max capacity
    if #self.activeToasts >= self.maxToasts then
        local oldestToast = self.activeToasts[1].frame
        oldestToast:Hide()
        self:RemoveToast(oldestToast)
    end
    
    -- Add new toast
    table.insert(self.activeToasts, {
        frame = frame,
        duration = duration,
        fadeTime = fadeTime
    })
    
    -- Update all positions
    self:UpdatePositions()
end

-- Remove a toast from the stack
function ToastManagerMethods:RemoveToast(frame)
    for i, toastData in ipairs(self.activeToasts) do
        if toastData.frame == frame then
            table.remove(self.activeToasts, i)
            self:UpdatePositions()
            break
        end
    end
end

-- Set anchor point for toasts
function ToastManagerMethods:SetAnchor(point, x, y)
    self.anchorPoint = point or "TOP"
    self.anchorX = x or 0
    self.anchorY = y or -100
    self:UpdatePositions()
end

--[[
Creates a toast notification that appears and fades out
@param text - Notification text
@param duration - How long to show (defaults to 3 seconds)
@param fadeTime - Fade out duration (defaults to 0.5 seconds)
@param anchor - Where to show the toast (defaults to top center)
@return Toast frame
]]
function CreateStyledToast(text, duration, fadeTime, anchor)
    duration = duration or 3
    fadeTime = fadeTime or 0.5
    anchor = anchor or "TOP"
    
    -- Get the appropriate toast manager for this anchor
    local manager = GetOrCreateToastManager(anchor)
    
    -- Create toast frame uniformly for all anchors
    local toast = CreateFrame("Frame", nil, UIParent)
    toast:SetFrameStrata("TOOLTIP")
    toast:SetFrameLevel(200)
    toast:SetToplevel(true)  -- Ensure it stays on top
    
    -- Set backdrop directly to avoid any parent frame issues
    toast:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    toast:SetBackdropColor(UISTYLE_COLORS.DarkGrey[1], UISTYLE_COLORS.DarkGrey[2], UISTYLE_COLORS.DarkGrey[3], 1)
    toast:SetBackdropBorderColor(0, 0, 0, 1)
    
    -- Ensure the frame doesn't expand beyond its content
    toast:SetClampedToScreen(true)
    
    -- Text
    local message = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    message:SetPoint("CENTER", 0, 0)
    message:SetText(text)
    message:SetTextColor(1, 1, 1, 1)
    
    -- Auto-size
    local padding = 20
    toast:SetWidth(message:GetStringWidth() + padding * 2)
    toast:SetHeight(message:GetStringHeight() + padding)
    
    -- Set initial position from the manager
    toast:SetPoint(manager.anchorPoint, UIParent, manager.anchorPoint, manager.anchorX, manager.anchorY)
    toast:SetAlpha(0)
    toast:Show()
    
    -- Initialize animation values and add to manager
    toast.fadeElapsed = 0
    manager:AddToast(toast, duration, fadeTime)
    
    return toast
end

--[[
Configure toast notification settings
@param settings - Table with optional fields: maxToasts, spacing, anchorPoint, anchorX, anchorY
]]
function ConfigureToasts(settings)
    if not settings then return end
    
    if settings.maxToasts then
        ToastManager.maxToasts = settings.maxToasts
    end
    if settings.spacing then
        ToastManager.toastSpacing = settings.spacing
    end
    if settings.anchorPoint or settings.anchorX or settings.anchorY then
        ToastManager:SetAnchor(settings.anchorPoint, settings.anchorX, settings.anchorY)
    end
end

--[[
Clear all active toast notifications
]]
function ClearAllToasts()
    -- Clear toasts from all managers
    for anchor, manager in pairs(ToastManagers) do
        for i = #manager.activeToasts, 1, -1 do
            local toast = manager.activeToasts[i].frame
            toast:SetScript("OnUpdate", nil)
            toast:Hide()
        end
        manager.activeToasts = {}
    end
end

-- ===================================
-- EASYMENU SUPPORT
-- ===================================

--[[
Creates a styled EasyMenu context menu with dark theme
@param menuItems - Table of menu items (EasyMenu format)
@param menuFrame - Optional menu frame (creates one if not provided)
@param anchor - Anchor point ("cursor" or frame reference)
@param x - X offset (defaults to 0)
@param y - Y offset (defaults to 0)
@param displayMode - Display mode ("MENU" for context menu style)
@param autoHideDelay - Auto hide delay in seconds (optional)
@return menuFrame used

Example usage:
local menuItems = {
    { text = "Actions", isTitle = true },
    { text = "Spawn", func = function() print("Spawn") end },
    { text = "Delete", func = function() print("Delete") end },
    { isSeparator = true },
    {
        text = "Copy",
        hasArrow = true,
        menuList = {
            { text = "Copy ID", func = function() print("Copy ID") end },
            { text = "Copy Name", func = function() print("Copy Name") end }
        }
    },
    { text = "Cancel", func = function() end }
}
ShowStyledEasyMenu(menuItems, "cursor")
]]

--[[
Shows a fully custom styled context menu at the specified position
@param menuItems - Table of menu items
@param anchor - Anchor point (frame or "cursor") 
@param anchorPoint - Anchor point on the anchor frame (default "BOTTOMLEFT")
@param relativePoint - Relative point on the menu (default "TOPLEFT")
@param xOffset - X offset (default 0)
@param yOffset - Y offset (default 0)
@return menuFrame - The created menu frame
]]
function ShowFullyStyledContextMenu(menuItems, anchor, anchorPoint, relativePoint, xOffset, yOffset)
    -- Create unique frame name
    local menuName = "UIStyleContextMenu" .. math.random(100000, 999999)
    
    -- Menu management
    local activeMenus = {}
    local menuLevel = 0
    
    -- Create menu frame function
    local function createMenuFrame(level)
        local menuFrame = CreateStyledFrame(UIParent, UISTYLE_COLORS.DarkGrey)
        menuFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        menuFrame:SetFrameLevel(100 + level * 10)
        menuFrame:SetWidth(200) -- Default width
        menuFrame:Hide()
        
        -- Add shadow
        local shadow = menuFrame:CreateTexture(nil, "BACKGROUND")
        shadow:SetTexture("Interface\\Buttons\\WHITE8X8")
        shadow:SetVertexColor(0, 0, 0, 0.5)
        shadow:SetPoint("TOPLEFT", -3, 3)
        shadow:SetPoint("BOTTOMRIGHT", 3, -3)
        
        menuFrame.level = level
        menuFrame.items = {}
        
        return menuFrame
    end
    
    -- Process menu item (same as dropdown but without value selection)
    local function processMenuItem(itemData, parentMenu, index)
        local itemHeight = 22
        local menuItem = CreateFrame("Button", nil, parentMenu)
        menuItem:SetHeight(itemHeight)
        menuItem:SetPoint("LEFT", 2, 0)
        menuItem:SetPoint("RIGHT", -2, 0)
        
        if index == 1 then
            menuItem:SetPoint("TOP", 0, -2)
        else
            menuItem:SetPoint("TOP", parentMenu.items[index - 1], "BOTTOM", 0, 0)
        end
        
        -- Handle different item types
        if type(itemData) == "table" and itemData.isSeparator then
            -- Separator
            menuItem:SetHeight(7)
            local line = menuItem:CreateTexture(nil, "OVERLAY")
            line:SetTexture("Interface\\Buttons\\WHITE8X8")
            line:SetVertexColor(0.3, 0.3, 0.3, 0.5)
            line:SetHeight(1)
            line:SetPoint("LEFT", 10, 0)
            line:SetPoint("RIGHT", -10, 0)
            menuItem:EnableMouse(false)
            
        elseif type(itemData) == "table" and itemData.isTitle then
            -- Title
            menuItem:SetHeight(24)
            local titleText = menuItem:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            titleText:SetPoint("CENTER")
            titleText:SetText(itemData.text or "")
            titleText:SetTextColor(1, 0.82, 0, 1)
            menuItem:EnableMouse(false)
            
        else
            -- Regular item or submenu
            local itemText = ""
            local hasArrow = false
            local menuList = nil
            local icon = nil
            local isChecked = false
            local func = nil
            local disabled = false
            
            if type(itemData) == "string" then
                itemText = itemData
            elseif type(itemData) == "table" then
                itemText = itemData.text or ""
                hasArrow = itemData.hasArrow
                menuList = itemData.menuList
                icon = itemData.icon
                isChecked = itemData.checked
                func = itemData.func
                disabled = itemData.disabled
            end
            
            -- Checkbox/radio button
            if type(itemData) == "table" and (itemData.isRadio or isChecked ~= nil) then
                local check = menuItem:CreateTexture(nil, "ARTWORK")
                check:SetSize(16, 16)
                check:SetPoint("LEFT", 4, 0)
                if isChecked then
                    if itemData.isRadio then
                        check:SetTexture("Interface\\Buttons\\UI-RadioButton")
                        check:SetTexCoord(0.25, 0.5, 0, 1)
                    else
                        check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                    end
                end
                menuItem.check = check
            end
            
            -- Icon
            if icon then
                local iconTexture = menuItem:CreateTexture(nil, "ARTWORK")
                iconTexture:SetSize(16, 16)
                iconTexture:SetPoint("LEFT", menuItem.check and 24 or 4, 0)
                iconTexture:SetTexture(icon)
                menuItem.icon = iconTexture
            end
            
            -- Text
            local text = menuItem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            local leftOffset = 8
            if menuItem.check then leftOffset = leftOffset + 20 end
            if menuItem.icon then leftOffset = leftOffset + 20 end
            text:SetPoint("LEFT", leftOffset, 0)
            text:SetText(itemText)
            
            if disabled then
                text:SetTextColor(0.5, 0.5, 0.5, 1)
            else
                text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
            end
            text:SetJustifyH("LEFT")
            menuItem.text = text
            
            -- Calculate max width
            local textWidth = text:GetStringWidth() + leftOffset + 16
            if hasArrow then textWidth = textWidth + 20 end
            if textWidth > parentMenu:GetWidth() then
                parentMenu:SetWidth(textWidth)
            end
            
            -- Arrow for submenus
            if hasArrow and menuList then
                local arrowText = menuItem:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                arrowText:SetPoint("RIGHT", -8, 0)
                arrowText:SetText(">")
                arrowText:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
                menuItem.arrow = arrowText
                
                -- Adjust text width for arrow
                text:SetPoint("RIGHT", arrowText, "LEFT", -5, 0)
            else
                text:SetPoint("RIGHT", -8, 0)
            end
            
            -- Highlight
            if not disabled then
                local highlight = menuItem:CreateTexture(nil, "HIGHLIGHT")
                highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
                highlight:SetVertexColor(1, 1, 1, 0.1)
                highlight:SetPoint("LEFT", 1, 0)
                highlight:SetPoint("RIGHT", -1, 0)
                highlight:SetHeight(itemHeight - 2)
            end
            
            -- Store data
            menuItem.data = itemData
            menuItem.hasSubmenu = hasArrow and menuList
            menuItem.menuList = menuList
            menuItem.func = func
            menuItem.disabled = disabled
            
            -- Click handler
            if not disabled then
                menuItem:SetScript("OnClick", function(self)
                    if not self.hasSubmenu then
                        -- Handle checkbox toggling
                        if type(self.data) == "table" and self.data.checked ~= nil then
                            -- Toggle the checked state
                            self.data.checked = not self.data.checked
                            
                            -- Update checkbox texture
                            if self.check then
                                if self.data.checked then
                                    if self.data.isRadio then
                                        self.check:SetTexture("Interface\\Buttons\\UI-RadioButton")
                                        self.check:SetTexCoord(0.25, 0.5, 0, 1)
                                    else
                                        self.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                                    end
                                    self.check:Show()
                                else
                                    self.check:Hide()
                                end
                            end
                        end
                        
                        -- Execute item function if exists
                        if self.func then
                            self.func()
                        end
                        
                        -- Close all menus
                        for _, menu in pairs(activeMenus) do
                            menu:Hide()
                        end
                        wipe(activeMenus)
                    end
                end)
                
                -- Submenu handling
                if hasArrow and menuList then
                    local submenuTimer
                    
                    menuItem:SetScript("OnEnter", function(self)
                        self.text:SetTextColor(1, 1, 1, 1)
                        
                        -- Cancel any pending submenu close
                        if submenuTimer then
                            submenuTimer:Cancel()
                        end
                        
                        -- Close other submenus at this level
                        for level = parentMenu.level + 1, #activeMenus do
                            if activeMenus[level] then
                                activeMenus[level]:Hide()
                                activeMenus[level] = nil
                            end
                        end
                        
                        -- Show submenu
                        local submenu = activeMenus[parentMenu.level + 1] or createMenuFrame(parentMenu.level + 1)
                        
                        -- Clear existing items
                        for _, item in ipairs(submenu.items) do
                            item:Hide()
                            item:SetParent(nil)
                        end
                        wipe(submenu.items)
                        
                        -- Create submenu items
                        for i, subItemData in ipairs(self.menuList) do
                            processMenuItem(subItemData, submenu, i)
                        end
                        
                        -- Calculate submenu height
                        local totalHeight = 4
                        for _, item in ipairs(submenu.items) do
                            totalHeight = totalHeight + item:GetHeight()
                        end
                        submenu:SetHeight(totalHeight)
                        
                        -- Position submenu
                        submenu:ClearAllPoints()
                        local screenWidth = UIParent:GetWidth()
                        local menuRight = parentMenu:GetRight() + submenu:GetWidth()
                        
                        if menuRight > screenWidth then
                            -- Open to the left
                            submenu:SetPoint("TOPRIGHT", self, "TOPLEFT", -2, 0)
                        else
                            -- Open to the right
                            submenu:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, 0)
                        end
                        
                        submenu:Show()
                        activeMenus[parentMenu.level + 1] = submenu
                    end)
                    
                    menuItem:SetScript("OnLeave", function(self)
                        self.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
                        
                        -- Delay submenu closing
                        submenuTimer = CreateTimer(0.3, function()
                            -- Check if mouse is over any active menu
                            local mouseOverAnyMenu = false
                            
                            -- Check all active menus
                            for _, menu in pairs(activeMenus) do
                                if menu and menu:IsVisible() and menu:IsMouseOver() then
                                    mouseOverAnyMenu = true
                                    break
                                end
                            end
                            
                            -- Also check if mouse is over any menu item
                            if not mouseOverAnyMenu then
                                for _, menu in pairs(activeMenus) do
                                    if menu and menu.items then
                                        for _, item in ipairs(menu.items) do
                                            if item and item:IsVisible() and item:IsMouseOver() then
                                                mouseOverAnyMenu = true
                                                break
                                            end
                                        end
                                        if mouseOverAnyMenu then break end
                                    end
                                end
                            end
                            
                            -- Only close if mouse is not over any menu or menu item
                            if not mouseOverAnyMenu then
                                for level = parentMenu.level + 1, #activeMenus do
                                    if activeMenus[level] then
                                        activeMenus[level]:Hide()
                                        activeMenus[level] = nil
                                    end
                                end
                            end
                        end)
                    end)
                else
                    -- Regular item hover
                    menuItem:SetScript("OnEnter", function(self)
                        self.text:SetTextColor(1, 1, 1, 1)
                        
                        -- Close submenus if hovering over non-submenu item
                        for level = parentMenu.level + 1, #activeMenus do
                            if activeMenus[level] then
                                activeMenus[level]:Hide()
                                activeMenus[level] = nil
                            end
                        end
                    end)
                    
                    menuItem:SetScript("OnLeave", function(self)
                        self.text:SetTextColor(UISTYLE_COLORS.TextGrey[1], UISTYLE_COLORS.TextGrey[2], UISTYLE_COLORS.TextGrey[3], 1)
                    end)
                end
            end
        end
        
        table.insert(parentMenu.items, menuItem)
        return menuItem
    end
    
    -- Create main menu
    local mainMenu = createMenuFrame(0)
    activeMenus[0] = mainMenu
    
    -- Build menu items
    for i, itemData in ipairs(menuItems) do
        processMenuItem(itemData, mainMenu, i)
    end
    
    -- Calculate menu height
    local totalHeight = 4
    for _, item in ipairs(mainMenu.items) do
        totalHeight = totalHeight + item:GetHeight()
    end
    mainMenu:SetHeight(totalHeight)
    
    -- Position menu
    if anchor == "cursor" then
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        mainMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    else
        mainMenu:SetPoint(
            relativePoint or "TOPLEFT",
            anchor,
            anchorPoint or "BOTTOMLEFT",
            xOffset or 0,
            yOffset or 0
        )
    end
    
    -- Show menu
    mainMenu:Show()
    mainMenu:Raise()
    
    -- Close handler
    local closeHandler = CreateFrame("Button", nil, UIParent)
    closeHandler:SetAllPoints(UIParent)
    closeHandler:SetFrameStrata("FULLSCREEN")
    closeHandler:SetFrameLevel(mainMenu:GetFrameLevel() - 1)
    closeHandler:Show()
    
    closeHandler:SetScript("OnClick", function()
        for _, menu in pairs(activeMenus) do
            menu:Hide()
        end
        wipe(activeMenus)
        closeHandler:Hide()
    end)
    
    -- Auto-hide on menu hide
    mainMenu:HookScript("OnHide", function()
        for _, menu in pairs(activeMenus) do
            if menu ~= mainMenu then
                menu:Hide()
            end
        end
        wipe(activeMenus)
        closeHandler:Hide()
    end)
    
    return mainMenu
end

function ShowStyledEasyMenu(menuItems, anchor, x, y, displayMode, autoHideDelay, menuFrame)
    -- Use the new fully styled context menu instead of EasyMenu
    -- Convert anchor if needed
    local menuAnchor = anchor
    local anchorPoint = "BOTTOMLEFT"
    local relativePoint = "TOPLEFT" 
    local xOffset = x or 0
    local yOffset = y or 0
    
    -- Handle special anchor cases
    if anchor == "cursor" then
        menuAnchor = "cursor"
    elseif type(anchor) == "string" and _G[anchor] then
        menuAnchor = _G[anchor]
    end
    
    -- Show the styled context menu
    return ShowFullyStyledContextMenu(menuItems, menuAnchor, anchorPoint, relativePoint, xOffset, yOffset)
end

--[[
Helper function to create a standard context menu for entity actions
@param entityType - Type of entity ("npc", "gameobject", "spell", etc.)
@param entity - Entity data table
@param additionalItems - Optional additional menu items to add
@return menuItems table for use with ShowStyledEasyMenu
]]
function CreateEntityContextMenu(entityType, entity, additionalItems)
    local menuItems = {}
    
    -- Add title
    local id = entity.entry or entity.spellID or entity.id
    if id then
        table.insert(menuItems, {
            text = entityType:gsub("^%l", string.upper) .. " ID: " .. id,
            isTitle = true,
            notCheckable = true
        })
    end
    
    -- Add standard copy submenu
    local copyMenu = {}
    if id then
        table.insert(copyMenu, {
            text = "Copy ID",
            func = function()
                -- Simple copy to clipboard simulation
                local editBox = CreateFrame("EditBox")
                editBox:SetText(tostring(id))
                editBox:HighlightText()
                editBox:SetScript("OnEscapePressed", function(self) self:Hide() end)
                editBox:Show()
                editBox:SetFocus()
            end,
            notCheckable = true
        })
    end
    
    if entity.name then
        table.insert(copyMenu, {
            text = "Copy Name",
            func = function()
                local editBox = CreateFrame("EditBox")
                editBox:SetText(entity.name)
                editBox:HighlightText()
                editBox:SetScript("OnEscapePressed", function(self) self:Hide() end)
                editBox:Show()
                editBox:SetFocus()
            end,
            notCheckable = true
        })
    end
    
    if #copyMenu > 0 then
        table.insert(menuItems, {
            text = "Copy",
            hasArrow = true,
            menuList = copyMenu,
            notCheckable = true
        })
    end
    
    -- Add separator before additional items
    if additionalItems and #additionalItems > 0 then
        table.insert(menuItems, { isSeparator = true })
        for _, item in ipairs(additionalItems) do
            table.insert(menuItems, item)
        end
    end
    
    -- Add cancel at the end
    table.insert(menuItems, { isSeparator = true })
    table.insert(menuItems, {
        text = "Cancel",
        func = function() end,
        notCheckable = true
    })
    
    return menuItems
end

print("UIStyleLibrary (AIO Client) loaded successfully!")