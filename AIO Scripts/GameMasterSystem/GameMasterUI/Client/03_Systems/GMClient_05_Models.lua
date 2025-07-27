-- GMClient_05_Models.lua
-- Model management and interaction for Game Master UI client
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

-- Get module references
local GMModels = _G.GMModels

-- Import namespaces
local GMUtils = _G.GMUtils
local GMData = _G.GMData
local GMConfig = _G.GMConfig
local GMUI = _G.GMUI

-- Constants for model management
local MODEL_CONFIG = {
    POSITION = {
        SPEED = {
            X = 0.005,
            Y = 0,
            Z = 0.005,
        },
        DEFAULT = {
            X = 0,
            Y = 0,
            Z = 0,
        }
    },
    ROTATION = {
        SPEED = 0.010
    },
    SCALE = {
        MIN = 0.5,
        MAX = 2.0,
        STEP = 0.05
    }
}

local ITEM_MODEL_CONFIG = {
    DELAY = 0.01,
    POOL_SIZE = 15,
    ROTATION = 0.4,
    ZOOM = {
        MIN = 0.5,
        MAX = 2.0,
        STEP = 0.1,
        DEFAULT = 1.0,
    },
    POSITION = { X = 0, Y = 0, Z = 0 },
    SIZE = {
        WIDTH_OFFSET = 20,
        HEIGHT_FACTOR = 0.6,
    },
}

local VIEW_CONFIG = {
    ICONS = {
        MAGNIFIER = "Interface\\Icons\\INV_Misc_Spyglass_03",
        INFO = "Interface\\Icons\\INV_Misc_Book_09",
    },
    TEXTURES = {
        BACKDROP = "Interface\\DialogFrame\\UI-DialogBox-Background",
        BORDER = "Interface\\Tooltips\\UI-Tooltip-Border",
    },
    SIZES = {
        ICON = 16,
        FULL_VIEW = 400,
        TILE = 16,
        INSETS = 5,
    },
}

-- Initialize model pool
local modelFrameCache = {}
local initializedPool = false

-- Utility: Clamp helper (WoW 3.3.5 doesn't have math.clamp)
local function Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Initialize model pool
function GMModels.initializeModelPool()
    if not initializedPool then
        for i = 1, ITEM_MODEL_CONFIG.POOL_SIZE do
            local model = CreateFrame("DressUpModel")
            model:SetUnit("player")
            model:Undress()
            model:Hide()
            model.initialized = true
            table.insert(modelFrameCache, model)
        end
        initializedPool = true
        GMUtils.debug("Model pool initialized with", ITEM_MODEL_CONFIG.POOL_SIZE, "models")
    end
end

-- Release model back to pool
function GMModels.releaseModel(model)
    if model then
        model:ClearModel()
        model:SetUnit("player")
        model:Undress()
        model:Hide()
        model:ClearAllPoints()
        model:SetParent(nil)
        table.insert(modelFrameCache, model)
    end
end

-- Acquire model from pool
function GMModels.acquireModel()
    GMModels.initializeModelPool()
    local model = table.remove(modelFrameCache)
    if not model then
        model = CreateFrame("DressUpModel")
        model.initialized = true
    end

    -- Reset model state completely
    model:ClearModel()
    model:SetUnit("player")
    model:Undress()
    model:SetRotation(ITEM_MODEL_CONFIG.ROTATION)
    model:Show()

    return model
end

-- Handle model rotation
local function handleModelRotation(model, mouseX, dragStartX, initialFacing)
    local deltaX = (mouseX - dragStartX) * (MODEL_CONFIG.ROTATION.SPEED or 1)
    local newFacing = initialFacing + deltaX
    model:SetFacing(newFacing)
    return newFacing
end

-- Handle model position (X, Y, Z movement)
local function handleModelPosition(model, mouseX, mouseY, dragStartX, dragStartY, initialPosition)
    if not model or not initialPosition then return end

    local speed = MODEL_CONFIG.POSITION.SPEED or {}
    local speedX = speed.X or 1
    local speedY = speed.Y or 1
    local speedZ = speed.Z or 1

    local deltaX = (mouseX - dragStartX) * speedX
    local deltaY = 0 -- update if you want horizontal drag to affect Y
    local deltaZ = (mouseY - dragStartY) * speedZ

    local newX = initialPosition.x + deltaX
    local newY = initialPosition.y + deltaY
    local newZ = initialPosition.z + deltaZ

    model:SetPosition(newX, newY, newZ)

    return { x = newX, y = newY, z = newZ }
end

-- Handle model scale (zoom)
local function handleModelScale(model, delta, currentScale)
    local minScale = MODEL_CONFIG.SCALE.MIN or 0.5
    local maxScale = MODEL_CONFIG.SCALE.MAX or 2.0
    local step = MODEL_CONFIG.SCALE.STEP or 0.05

    local newScale = currentScale
    if delta > 0 and currentScale < maxScale then
        newScale = Clamp(currentScale + step, minScale, maxScale)
    elseif delta < 0 and currentScale > minScale then
        newScale = Clamp(currentScale - step, minScale, maxScale)
    end

    model:SetModelScale(newScale)
    return newScale
end

-- Setup model mouse interaction
function GMModels.setupModelInteraction(model)
    if not model then return end

    local state = {
        facing = model:GetFacing(),
        position = {
            x = MODEL_CONFIG.POSITION.DEFAULT.X or 0,
            y = MODEL_CONFIG.POSITION.DEFAULT.Y or 0,
            z = MODEL_CONFIG.POSITION.DEFAULT.Z or 0,
        },
        isDragging = false,
        dragStart = { x = 0, y = 0 },
    }

    -- Set initial position
    model:SetPosition(state.position.x, state.position.y, state.position.z)

    model:EnableMouse(true)
    model:SetMovable(false)

    -- Middle mouse drag
    model:SetScript("OnMouseDown", function(_, button)
        if button == "MiddleButton" then
            state.isDragging = true
            state.dragStart.x, state.dragStart.y = GetCursorPosition()
        end
    end)

    model:SetScript("OnMouseUp", function(_, button)
        if button == "MiddleButton" then
            state.isDragging = false
        end
    end)

    model:SetScript("OnUpdate", function(self)
        if state.isDragging then
            local mouseX, mouseY = GetCursorPosition()

            -- Update rotation
            state.facing = handleModelRotation(self, mouseX, state.dragStart.x, state.facing)

            -- Update position
            state.position = handleModelPosition(self, mouseX, mouseY, state.dragStart.x, state.dragStart.y, state.position)

            -- Update drag start
            state.dragStart.x, state.dragStart.y = mouseX, mouseY
        end
    end)

    -- Mouse wheel zoom
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseWheel", function(self, delta)
        local currentScale = self:GetModelScale()
        handleModelScale(self, delta, currentScale)
    end)
end

-- Create full view frame
function GMModels.createFullViewFrame(index)
    local frame = CreateStyledFrame(UIParent, UISTYLE_COLORS.DarkGrey)
    frame:SetSize(VIEW_CONFIG.SIZES.FULL_VIEW, VIEW_CONFIG.SIZES.FULL_VIEW)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    
    -- Add custom name for identification
    _G["FullViewFrame" .. index] = frame
    
    return frame
end

-- Create model view
function GMModels.createModelView(parent, entity, type, index)
    local model = CreateFrame("DressUpModel", "FullModel" .. index, parent)
    model:SetAllPoints(parent)
    model:SetFrameStrata("DIALOG")
    model:SetFrameLevel(parent:GetFrameLevel() + 1)
    model:EnableMouse(true)
    model:SetMovable(true)
    model:ClearModel()

    -- Set up drag functionality
    model:RegisterForDrag("LeftButton")
    model:SetScript("OnDragStart", function()
        parent:StartMoving()
    end)
    model:SetScript("OnDragStop", function()
        parent:StopMovingOrSizing()
    end)

    -- Set model based on type
    local modelSetters = {
        NPC = function()
            model:SetCreature(entity.entry)
        end,
        GameObject = function()
            model:SetModel(entity.modelName)
        end,
        Spell = function()
            model:SetSpellVisualKit(entity.spellID)
        end,
        SpellVisual = function()
            model:SetModel(entity.FilePath)
        end,
        Item = function()
            model:Undress() -- Ensure clean state
            model:TryOn(entity.entry)
        end,
    }

    if modelSetters[type] then
        modelSetters[type]()
    end

    model:SetRotation(math.rad(30))
    GMModels.setupModelInteraction(model)

    return model
end

-- Main function to add magnifier icon
function GMModels.addMagnifierIcon(card, entity, index, type)
    local button = CreateFrame("Button", "MagnifierButton" .. index, card)
    button:SetSize(VIEW_CONFIG.SIZES.ICON, VIEW_CONFIG.SIZES.ICON)
    button:SetPoint("TOPRIGHT", card, "TOPRIGHT", -5, -5)
    button:SetNormalTexture(VIEW_CONFIG.ICONS.MAGNIFIER)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    button:GetHighlightTexture():SetBlendMode("ADD")

    button:SetScript("OnClick", function()
        local fullViewFrame = GMModels.createFullViewFrame(index)
        
        -- Close button
        local closeButton = CreateFrame("Button", nil, fullViewFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", fullViewFrame, "TOPRIGHT")
        closeButton:SetFrameLevel(fullViewFrame:GetFrameLevel() + 2)

        -- Info button if createInfoButton exists
        if GMUI.createInfoButton then
            local infoButton = GMUI.createInfoButton(fullViewFrame, entity, type)
        end
        
        -- Model view
        local modelView = GMModels.createModelView(fullViewFrame, entity, type, index)
    end)

    return button
end

-- Store ModelManager functions in GMData
GMData.models = GMData.models or {}
GMData.models.ModelManager = {
    acquireModel = GMModels.acquireModel,
    releaseModel = GMModels.releaseModel,
}

GMUtils.debug("Models module loaded")