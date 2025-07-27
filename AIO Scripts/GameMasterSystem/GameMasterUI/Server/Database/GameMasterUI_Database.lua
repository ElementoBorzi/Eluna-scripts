local queries = {
	TrinityCore = {
		loadCreatureDisplays = function()
			return [[
                SELECT `entry`, `name`, `subname`, `IconName`, `type_flags`, `type`, `family`, `rank`, `KillCredit1`, `KillCredit2`, `HealthModifier`, `ManaModifier`, `RacialLeader`, `MovementType`, `modelId1`, `modelId2`, `modelId3`, `modelId4`
                FROM `creature_template`
            ]]
		end,
		npcData = function(sortOrder, pageSize, offset)
			return string.format(
				[[
                SELECT entry, modelid1, modelid2, modelid3, modelid4, name, subname, type
                FROM creature_template
                WHERE modelid1 != 0 OR modelid2 != 0 OR modelid3 != 0 OR modelid4 != 0
                ORDER BY entry %s
                LIMIT %d OFFSET %d;
            ]],
				sortOrder,
				pageSize,
				offset
			)
		end,
		gobData = function(sortOrder, pageSize, offset)
			return string.format(
				[[
            SELECT g.entry, g.displayid, g.name, m.ModelName
            FROM gameobject_template g
            LEFT JOIN gameobjectdisplayinfo m ON g.displayid = m.ID
            ORDER BY g.entry %s
            LIMIT %d OFFSET %d;
            ]],
				sortOrder,
				pageSize,
				offset
			)
		end,
		spellData = function(sortOrder, pageSize, offset)
			return string.format(
				[[
            SELECT id, spellName0, spellDescription0, spellToolTip0
            FROM spell
            ORDER BY id %s
            LIMIT %d OFFSET %d;
            ]],
				sortOrder,
				pageSize,
				offset
			)
		end,
		searchNpcData = function(query, typeId, sortOrder, pageSize, offset)
			return string.format(
				[[
                SELECT entry, modelid1, modelid2, modelid3, modelid4, name, subname, type
                FROM creature_template
                WHERE name LIKE '%%%s%%' OR subname LIKE '%%%s%%' OR entry LIKE '%%%s%%' %s
                ORDER BY entry %s
                LIMIT %d OFFSET %d;
            ]],
				query,
				query,
				query,
				typeId and string.format("OR type = %d", typeId) or "",
				sortOrder,
				pageSize,
				offset * pageSize
			)
		end,
		searchGobData = function(query, typeId, sortOrder, pageSize, offset)
			return string.format(
				[[
                SELECT g.entry, g.displayid, g.name, g.type, m.ModelName
                FROM gameobject_template g
                LEFT JOIN gameobjectdisplayinfo m ON g.displayid = m.ID
                WHERE g.name LIKE '%%%s%%' OR g.entry LIKE '%%%s%%' %s
                ORDER BY g.entry %s
                LIMIT %d OFFSET %d;
            ]],
				query,
				query,
				typeId and string.format("OR g.type = %d", typeId) or "",
				sortOrder,
				pageSize,
				offset * pageSize
			)
		end,
		searchSpellData = function(query, sortOrder, pageSize, offset)
			return string.format(
				[[
                SELECT id, spellName0, spellDescription0, spellToolTip0
                FROM spell
                WHERE spellName0 LIKE '%%%s%%' OR id LIKE '%%%s%%'
                ORDER BY id %s
                LIMIT %d OFFSET %d;
            ]],
				query,
				query,
				sortOrder,
				pageSize,
				offset * pageSize
			)
		end,

		spellVisualData = function(sortOrder, pageSize, offset)
			return string.format(
				[[
            SELECT ID, Name, FilePath, AreaEffectSize, Scale, MinAllowedScale, MaxAllowedScale
            FROM spellvisualeffectname
            ORDER BY ID %s
            LIMIT %d OFFSET %d;
            ]],
				sortOrder,
				pageSize,
				offset
			)
		end,
		searchSpellVisualData = function(query, sortOrder, pageSize, offset)
			return string.format(
				[[
            SELECT ID, Name, FilePath, AreaEffectSize, Scale, MinAllowedScale, MaxAllowedScale
            FROM spellvisualeffectname
            WHERE Name LIKE '%%%s%%' OR ID LIKE '%%%s%%'
            ORDER BY ID %s
            LIMIT %d OFFSET %d;
            ]],
				query,
				query,
				sortOrder,
				pageSize,
				offset * pageSize
			)
		end,
		itemData = function(sortOrder, pageSize, offset, inventoryType)
			local whereClause = ""
			if inventoryType then
				whereClause = string.format("WHERE InventoryType = %d", inventoryType)
			end

			return string.format(
				[[SELECT entry, name, COALESCE(description, ''), displayid, Quality, InventoryType, ItemLevel, class, subclass
				FROM item_template
				%s
				ORDER BY entry %s
				LIMIT %d OFFSET %d;]],
				whereClause,
				sortOrder,
				pageSize,
				offset
			)
		end,

		searchItemData = function(query, sortOrder, pageSize, offset, inventoryType)
			local whereClause = [[WHERE (name LIKE '%%%s%%' OR entry LIKE '%%%s%%')]]
			if inventoryType then
				whereClause = whereClause .. string.format(" AND InventoryType = %d", inventoryType)
			end

			return string.format(
				[[SELECT entry, name, COALESCE(description, ''), displayid, Quality, InventoryType, ItemLevel, class, subclass
				FROM item_template
				%s
				ORDER BY entry %s
				LIMIT %d OFFSET %d;]],
				string.format(whereClause, escapeString(query), escapeString(query)),
				sortOrder,
				pageSize,
				offset
			)
		end,
	},
	AzerothCore = {
		loadCreatureDisplays = function()
			return [[
                SELECT ct.`entry`, ct.`name`, ct.`subname`, ct.`IconName`, ct.`type_flags`, ct.`type`, ct.`family`, ct.`rank`, ct.`KillCredit1`, ct.`KillCredit2`, ct.`HealthModifier`, ct.`ManaModifier`, ct.`RacialLeader`, ct.`MovementType`, ctm.`CreatureDisplayID`
                FROM `creature_template` ct
                LEFT JOIN `creature_template_model` ctm ON ct.`entry` = ctm.`CreatureID`
            ]]
		end,
		npcData = function(sortOrder, pageSize, offset)
			return string.format(
				[[
                SELECT ct.entry, ctm.CreatureDisplayID, ct.name, ct.subname, ct.type
                FROM creature_template ct
                LEFT JOIN creature_template_model ctm ON ct.entry = ctm.CreatureID
                ORDER BY ct.entry %s
                LIMIT %d OFFSET %d;
            ]],
				sortOrder,
				pageSize,
				offset
			)
		end,
		gobData = function(sortOrder, pageSize, offset)
			return string.format(
				[[
            SELECT g.entry, g.displayid, g.name, m.ModelName
            FROM gameobject_template g
            LEFT JOIN gameobjectdisplayinfo m ON g.displayid = m.ID
            ORDER BY g.entry %s
            LIMIT %d OFFSET %d;
            ]],
				sortOrder,
				pageSize,
				offset
			)
		end,
		spellData = function(sortOrder, pageSize, offset)
			return string.format(
				[[
                SELECT id, spellName0, spellDescription0, spellToolTip0
                FROM spell
                ORDER BY id %s
                LIMIT %d OFFSET %d;
            ]],
				sortOrder,
				pageSize,
				offset
			)
		end,
		searchNpcData = function(query, typeId, sortOrder, pageSize, offset)
			return string.format(
				[[
                SELECT ct.entry, ctm.CreatureDisplayID, ct.name, ct.subname, ct.type
                FROM creature_template ct
                LEFT JOIN creature_template_model ctm ON ct.entry = ctm.CreatureID
                WHERE ct.name LIKE '%%%s%%' OR ct.subname LIKE '%%%s%%' OR ct.entry LIKE '%%%s%%' %s
                ORDER BY ct.entry %s
                LIMIT %d OFFSET %d;
            ]],
				escapeString(query),
				escapeString(query),
				escapeString(query),
				typeId and string.format("OR ct.type = %d", typeId) or "",
				sortOrder,
				pageSize,
				offset
			)
		end,
		searchGobData = function(query, typeId, sortOrder, pageSize, offset)
			return string.format(
				[[
                SELECT g.entry, g.displayid, g.name, g.type, m.ModelName
                FROM gameobject_template g
                LEFT JOIN gameobjectdisplayinfo m ON g.displayid = m.ID
                WHERE g.name LIKE '%%%s%%' OR g.entry LIKE '%%%s%%' %s
                ORDER BY g.entry %s
                LIMIT %d OFFSET %d;
            ]],
				query,
				query,
				typeId and string.format("OR g.type = %d", typeId) or "",
				sortOrder,
				pageSize,
				offset * pageSize
			)
		end,
		searchSpellData = function(query, sortOrder, pageSize, offset)
			return string.format(
				[[
                SELECT id, spellName0, spellDescription0, spellToolTip0
                FROM spell
                WHERE spellName0 LIKE '%%%s%%' OR id LIKE '%%%s%%'
                ORDER BY id %s
                LIMIT %d OFFSET %d;
            ]],
				query,
				query,
				sortOrder,
				pageSize,
				offset * pageSize
			)
		end,
		itemData = function(sortOrder, pageSize, offset, inventoryType)
			local whereClause = ""
			if inventoryType then
				whereClause = string.format("WHERE InventoryType = %d", inventoryType)
			end

			return string.format(
				[[
                SELECT entry, name, description, displayid, InventoryType, Quality, ItemLevel, class, subclass
                FROM item_template
                %s
                ORDER BY entry %s
                LIMIT %d OFFSET %d;
            ]],
				whereClause,
				sortOrder,
				pageSize,
				offset
			)
		end,

		searchItemData = function(query, sortOrder, pageSize, offset, inventoryType)
			local whereClause = [[WHERE (name LIKE '%%%s%%' OR entry LIKE '%%%s%%')]]
			if inventoryType then
				whereClause = whereClause .. string.format(" AND InventoryType = %d", inventoryType)
			end

			return string.format(
				[[
                SELECT entry, name, description, displayid, InventoryType, Quality, ItemLevel, class, subclass
                FROM item_template
                %s
                ORDER BY entry %s
                LIMIT %d OFFSET %d;
            ]],
				string.format(whereClause, query, query),
				sortOrder,
				pageSize,
				offset * pageSize
			)
		end,
	},
}
-- Function to get the appropriate query based on the core name
local function getQuery(coreName, queryType)
    return queries[coreName] and queries[coreName][queryType] or nil
end

return {
    queries = queries,
    getQuery = getQuery,
}
