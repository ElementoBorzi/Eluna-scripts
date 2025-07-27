
local config = {
    debug = false,
    defaultPageSize = 100,
    removeFromWorld = true,
    REQUIRED_GM_LEVEL = 2,
}

-- NPC type mappings
local npcTypes = {
	["none"] = 0,
	["beast"] = 1,
	["dragonkin"] = 2,
	["demon"] = 3,
	["elemental"] = 4,
	["giant"] = 5,
	["undead"] = 6,
	["humanoid"] = 7,
	["critter"] = 8,
	["mechanical"] = 9,
	["not specified"] = 10,
	["totem"] = 11,
	["non-combat pet"] = 12,
	["gas cloud"] = 13,
	["wild pet"] = 14,
	["aberration"] = 15,
}

-- GameObject type mappings
local gameObjectTypes = {
	["door"] = 0,
	["button"] = 1,
	["questgiver"] = 2,
	["chest"] = 3,
	["binder"] = 4,
	["generic"] = 5,
	["trap"] = 6,
	["chair"] = 7,
	["spell focus"] = 8,
	["text"] = 9,
	["goober"] = 10,
	["transport"] = 11,
	["areadamage"] = 12,
	["camera"] = 13,
	["map object"] = 14,
	["mo transport"] = 15,
	["duel arbiter"] = 16,
	["fishingnode"] = 17,
	["summoning ritual"] = 18,
	["mailbox"] = 19,
	["do not use"] = 20,
	["guardpost"] = 21,
	["spellcaster"] = 22,
	["meetingstone"] = 23,
	["flagstand"] = 24,
	["fishinghole"] = 25,
	["flagdrop"] = 26,
	["mini game"] = 27,
	["do not use 2"] = 28,
	["capture point"] = 29,
	["aura generator"] = 30,
	["dungeon difficulty"] = 31,
	["barber chair"] = 32,
	["destructible_building"] = 33,
	["guild bank"] = 34,
	["trapdoor"] = 35,
}


-- Merge all configuration into a single table for easier access
local module = {}
for k, v in pairs(config) do
    module[k] = v
end
module.npcTypes = npcTypes
module.gameObjectTypes = gameObjectTypes

return module
