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

local GMUtils = _G.GMUtils
local GMConfig = _G.GMConfig
local MenuItems = GMMenus.MenuItems
local MENU_CONFIG = GMConfig.MENU_CONFIG

-- Menu Factory
local MenuFactory = {}
GMMenus.MenuFactory = MenuFactory

function MenuFactory.createNpcMenu(entity)
    local trimmedEntry = GMUtils.trimSpaces(entity.entry)
    return {
        MenuItems.createTitle("Creature ID: " .. trimmedEntry),
        {
            text = "Spawn",
            func = function()
                local trimmedEntry = tonumber(GMUtils.trimSpaces(entity.entry))
                if trimmedEntry then
                    print("Spawning NPC with ID: " .. trimmedEntry)
                    AIO.Handle("GameMasterSystem", "spawnNpcEntity", trimmedEntry)
                else
                    print("Invalid NPC ID")
                end
            end,
            notCheckable = true,
        },
        MenuItems.createDelete(MENU_CONFIG.TYPES.NPC, trimmedEntry, function(entry)
            AIO.Handle("GameMasterSystem", "deleteNpcEntity", entry)
        end),
        MenuItems.createCopyMenu(entity),
        {
            text = "Morphing",
            hasArrow = true,
            menuList = MenuFactory.createMorphingSubmenu(entity),
            notCheckable = true,
        },
        {
            text = "Duplicate to Database",
            func = function()
                print("Duplicating NPC with ID: " .. trimmedEntry)
                AIO.Handle("GameMasterSystem", "duplicateNpcEntity", trimmedEntry)
            end,
            notCheckable = true,
            tooltipTitle = "Duplicate to Database",
            tooltipText = "Duplicate this NPC to the database.\n\n"
                .. "This will create a new entry in the database with the same data as this NPC.\n\n"
                .. "You can then modify the new entry as needed.",
            tooltipOnButton = true,
        },
        MenuItems.CANCEL,
    }
end

function MenuFactory.createMorphingSubmenu(entity)
    local submenu = {
        {
            text = "Demorph",
            func = function()
                AIO.Handle("GameMasterSystem", "demorphNpcEntity")
            end,
            notCheckable = true,
        },
    }

    -- Add model IDs
    for i, modelId in ipairs(entity.modelid) do
        table.insert(submenu, 1, {
            text = "Model ID " .. i .. ": " .. modelId,
            func = function()
                AIO.Handle("GameMasterSystem", "morphNpcEntity", GMUtils.trimSpaces(modelId))
            end,
            notCheckable = true,
        })
    end

    return submenu
end

function MenuFactory.createGameObjectMenu(entity)
    local trimmedEntry = GMUtils.trimSpaces(entity.entry)
    return {
        MenuItems.createTitle("GameObject ID: " .. trimmedEntry),
        {
            text = "Spawn",
            func = function()
                local trimmedEntry = tonumber(GMUtils.trimSpaces(entity.entry))
                if trimmedEntry then
                    print("Spawning GameObject with ID: " .. trimmedEntry)
                    AIO.Handle("GameMasterSystem", "spawnGameObject", trimmedEntry)
                else
                    print("Invalid GameObject ID")
                end
            end,
            notCheckable = true,
        },
        MenuItems.createDelete(MENU_CONFIG.TYPES.GAMEOBJECT, trimmedEntry, function(entry)
            AIO.Handle("GameMasterSystem", "deleteGameObjectEntity", entry)
        end),
        MenuItems.createCopyMenu(entity),
        {
            text = "Duplicate to Database",
            func = function()
                print("Duplicating GameObject with ID: " .. trimmedEntry)
                AIO.Handle("GameMasterSystem", "duplicateGameObjectEntity", trimmedEntry)
            end,
            notCheckable = true,
            tooltipTitle = "Duplicate to Database",
            tooltipText = "Duplicate this GameObject to the database.\n\n"
                .. "This will create a new entry in the database with the same data as this GameObject.\n\n"
                .. "You can then modify the new entry as needed.",
            tooltipOnButton = true,
        },
        MenuItems.CANCEL,
    }
end

function MenuFactory.createSpellMenu(entity)
    local trimmedEntry = GMUtils.trimSpaces(entity.spellID)
    return {
        MenuItems.createTitle("Spell ID: " .. trimmedEntry),
        {
            text = "Learn",
            func = function()
                AIO.Handle("GameMasterSystem", "learnSpellEntity", trimmedEntry)
            end,
            notCheckable = true,
        },
        MenuItems.createDelete(MENU_CONFIG.TYPES.SPELL, trimmedEntry, function(entry)
            AIO.Handle("GameMasterSystem", "deleteSpellEntity", entry)
        end),
        {
            text = "Cast on Self",
            func = function()
                AIO.Handle("GameMasterSystem", "castSelfSpellEntity", trimmedEntry)
            end,
            notCheckable = true,
        },
        {
            text = "Cast from Target",
            func = function()
                AIO.Handle("GameMasterSystem", "castTargetSpellEntity", trimmedEntry)
            end,
            notCheckable = true,
        },
        {
            text = "Copy Icon",
            func = function()
                GMMenus.copyIcon(entity)
            end,
            notCheckable = true,
        },
        MenuItems.createCopyMenu(entity),
        MenuItems.CANCEL,
    }
end

function MenuFactory.createSpellVisualMenu(entity)
    local trimmedEntry = GMUtils.trimSpaces(entity.spellVisualID)
    return {
        MenuItems.createTitle("SpellVisual ID: " .. trimmedEntry),
        {
            text = "Copy spellVisual",
            func = function()
                GMMenus.copyToClipboard(entity.FilePath, "SpellVisual Path")
            end,
            notCheckable = true,
        },
        MenuItems.createCopyMenu(entity),
        MenuItems.CANCEL,
    }
end

function MenuFactory.createItemMenu(entity)
    local trimmedEntry = GMUtils.trimSpaces(entity.entry)
    return {
        MenuItems.createTitle("Item ID: " .. trimmedEntry),
        {
            text = "Add Item to Player",
            func = function()
                AIO.Handle("GameMasterSystem", "addItemEntity", trimmedEntry, 1)
            end,
            notCheckable = true,
            tooltipTitle = "Add Item",
            tooltipText = "Adds this item to yourself or your target",
        },
        {
            text = "Add Item (5)",
            func = function()
                AIO.Handle("GameMasterSystem", "addItemEntity", trimmedEntry, 5)
            end,
            notCheckable = true,
        },
        {
            text = "Add Item (Max Stack)",
            func = function()
                AIO.Handle("GameMasterSystem", "addItemEntityMax", trimmedEntry)
            end,
            notCheckable = true,
            tooltipTitle = "Add Max Stack",
            tooltipText = "Adds the maximum stack size of this item",
        },
        {
            text = "Duplicate to Database",
            func = function()
                print("Duplicating Item with ID: " .. trimmedEntry)
                AIO.Handle("GameMasterSystem", "duplicateItemEntity", trimmedEntry)
            end,
            notCheckable = true,
            tooltipTitle = "Duplicate to Database",
            tooltipText = "Duplicate this Item to the database.\n\n"
                .. "This will create a new entry in the database with the same data as this Item.\n\n"
                .. "You can then modify the new entry as needed.",
            tooltipOnButton = true,
        },
        MenuItems.createCopyMenu(entity),
        MenuItems.CANCEL,
    }
end

function MenuFactory.createPlayerMenu(entity)
    local playerName = GMUtils.trimSpaces(entity.name)
    return {
        MenuItems.createTitle("Player: " .. playerName),
        {
            text = "Give Gold",
            func = function()
                -- Open dialog to give gold
                StaticPopup_Show("GM_GIVE_PLAYER_GOLD", playerName, nil, {name = playerName})
            end,
            notCheckable = true,
        },
        {
            text = "Give Item",
            func = function()
                -- Open new item selection modal
                if GMMenus.ItemSelection then
                    GMMenus.ItemSelection.createDialog(playerName)
                end
            end,
            notCheckable = true,
        },
        {
            text = "Buffs & Auras",
            hasArrow = true,
            menuList = MenuFactory.createBuffSubmenu(playerName),
            notCheckable = true,
        },
        {
            text = "Cast Spell",
            hasArrow = true,
            menuList = {
                {
                    text = "Make Player Cast on Self",
                    func = function()
                        if GMMenus.SpellSelection then
                            GMMenus.SpellSelection.createDialog(playerName, "self")
                        end
                    end,
                    notCheckable = true,
                    tooltipTitle = "Cast on Self",
                    tooltipText = "Make the player cast a spell on themselves",
                },
                {
                    text = "Make Player Cast on Target",
                    func = function()
                        if GMMenus.SpellSelection then
                            GMMenus.SpellSelection.createDialog(playerName, "target")
                        end
                    end,
                    notCheckable = true,
                    tooltipTitle = "Cast on Target",
                    tooltipText = "Make the player cast a spell on their current target",
                },
                {
                    text = "Cast Spell on Player",
                    func = function()
                        if GMMenus.SpellSelection then
                            GMMenus.SpellSelection.createDialog(playerName, "onplayer")
                        end
                    end,
                    notCheckable = true,
                    tooltipTitle = "Cast on Player",
                    tooltipText = "You cast a spell on the player",
                },
                {
                    text = "Custom Spell ID...",
                    func = function()
                        StaticPopup_Show("GM_PLAYER_CAST_SELF", playerName, nil, {name = playerName})
                    end,
                    notCheckable = true,
                    tooltipTitle = "Custom Spell",
                    tooltipText = "Enter a custom spell ID to cast",
                },
            },
            notCheckable = true,
        },
        {
            text = "Full Heal & Restore",
            func = function()
                AIO.Handle("GameMasterSystem", "healAndRestorePlayer", playerName)
            end,
            notCheckable = true,
            tooltipTitle = "Full Restore",
            tooltipText = "Fully heal and restore the player's health, mana, and remove debuffs",
        },
        {
            text = "Remove All Auras",
            func = function()
                AIO.Handle("GameMasterSystem", "removePlayerAuras", playerName)
            end,
            notCheckable = true,
            tooltipTitle = "Remove Auras",
            tooltipText = "Remove all buffs and debuffs from the player",
        },
        {
            text = "Send Mail",
            func = function()
                -- Open mail composition dialog
                if GameMasterSystem.OpenMailDialog then
                    GameMasterSystem.OpenMailDialog(playerName)
                end
            end,
            notCheckable = true,
        },
        {
            text = "Teleport To Player",
            func = function()
                AIO.Handle("GameMasterSystem", "teleportToPlayer", playerName)
            end,
            notCheckable = true,
        },
        {
            text = "Summon Player",
            func = function()
                AIO.Handle("GameMasterSystem", "summonPlayer", playerName)
            end,
            notCheckable = true,
        },
        {
            text = "Kick Player",
            func = function()
                StaticPopup_Show("GM_KICK_PLAYER", playerName, nil, {name = playerName})
            end,
            notCheckable = true,
        },
        {
            text = "Ban Player",
            hasArrow = true,
            menuList = {
                {
                    text = "Ban Account",
                    func = function()
                        if GameMasterSystem.ShowBanDialog then
                            GameMasterSystem.ShowBanDialog(playerName, 0)
                        end
                    end,
                    notCheckable = true,
                    tooltipTitle = "Ban Account",
                    tooltipText = "Ban all characters on this player's account",
                },
                {
                    text = "Ban Character",
                    func = function()
                        if GameMasterSystem.ShowBanDialog then
                            -- Check if character bans are supported
                            if GMData.ServerCapabilities and not GMData.ServerCapabilities.supportsCharacterBan then
                                CreateStyledToast("Character bans are not supported on this server. Use Account ban instead.", 3, 0.5)
                                return
                            end
                            GameMasterSystem.ShowBanDialog(playerName, 1)
                        end
                    end,
                    notCheckable = true,
                    tooltipTitle = "Ban Character", 
                    tooltipText = GMData.ServerCapabilities and not GMData.ServerCapabilities.supportsCharacterBan 
                        and "NOT SUPPORTED - Character bans are not available on this server" 
                        or "Ban only this specific character",
                    disabled = GMData.ServerCapabilities and not GMData.ServerCapabilities.supportsCharacterBan,
                },
                {
                    text = "Ban IP",
                    func = function()
                        if GameMasterSystem.ShowBanDialog then
                            GameMasterSystem.ShowBanDialog(playerName, 2)
                        end
                    end,
                    notCheckable = true,
                    tooltipTitle = "Ban IP",
                    tooltipText = "Ban this player's IP address",
                },
            },
            notCheckable = true,
            tooltipTitle = "Ban Player",
            tooltipText = "Choose ban type: Account, Character, or IP",
        },
        MenuItems.createCopyMenu(entity),
        MenuItems.CANCEL,
    }
end

function MenuFactory.createBuffSubmenu(playerName)
    local submenu = {}
    
    -- Add buff categories from config
    for _, category in ipairs(GMConfig.SPELL_CATEGORIES) do
        local categoryMenu = {
            text = category.name,
            hasArrow = true,
            menuList = {},
            notCheckable = true,
        }
        
        -- Add spells in this category
        for _, spell in ipairs(category.spells) do
            table.insert(categoryMenu.menuList, {
                text = spell.name,
                func = function()
                    AIO.Handle("GameMasterSystem", "applyBuffToPlayer", playerName, spell.spellId)
                end,
                notCheckable = true,
                icon = spell.icon,
            })
        end
        
        table.insert(submenu, categoryMenu)
    end
    
    -- Add custom spell options
    table.insert(submenu, {
        text = "Browse All Buffs...",
        func = function()
            if GMMenus.SpellSelection then
                GMMenus.SpellSelection.createDialog(playerName, "buff")
            end
        end,
        notCheckable = true,
        tooltipTitle = "Browse Buffs",
        tooltipText = "Open spell browser to select from all available buffs",
    })
    
    table.insert(submenu, {
        text = "Custom Spell ID...",
        func = function()
            StaticPopup_Show("GM_APPLY_CUSTOM_BUFF", playerName, nil, {name = playerName})
        end,
        notCheckable = true,
        tooltipTitle = "Custom ID",
        tooltipText = "Enter a specific spell ID to apply",
    })
    
    return submenu
end

-- Main menu show function
function MenuFactory.ShowMenu(menuType, anchor, entity)
    local menuCreators = {
        npc = MenuFactory.createNpcMenu,
        gameobject = MenuFactory.createGameObjectMenu,
        spell = MenuFactory.createSpellMenu,
        spellvisual = MenuFactory.createSpellVisualMenu,
        item = MenuFactory.createItemMenu,
        player = MenuFactory.createPlayerMenu,
    }

    local menuCreator = menuCreators[menuType]
    if menuCreator then
        -- Use styled EasyMenu for consistent dark theme
        ShowStyledEasyMenu(menuCreator(entity), "cursor")
    end
end

-- Menu factory module loaded