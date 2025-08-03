-- Utility functions
local utils = {
	escapeString = function(str)
		local replacements = {
			["\\"] = "\\\\",
			["'"] = "\\'",
			['"'] = '\\"',
			["%"] = "\\%",
			["_"] = "\\_",
		}
		return str:gsub("[\\'\"%%_]", replacements)
	end,

	debugMessage = function(...)
		if config.debug then
			print("DEBUG:", ...)
		end
	end,

	validatePageSize = function(pageSize)
		local minPageSize = 10
		local maxPageSize = 500
		return math.min(math.max(pageSize, minPageSize), maxPageSize)
	end,

	validateSortOrder = function(order)
		local validOrders = {
			ASC = true,
			DESC = true,
		}
		return validOrders[order:upper()] and order:upper() or "ASC"
	end,

	calculatePosition = function(player, distance)
		local angle = player:GetO()
		local x = player:GetX() + distance * math.cos(angle)
		local y = player:GetY() + distance * math.sin(angle)
		local z = player:GetZ()
		local oppositeAngle = angle + math.pi
		return x, y, z, oppositeAngle
	end,

	-- Enhanced messaging system
	sendMessage = function(player, messageType, message)
		if not player or not message then
			return
		end

		-- Define message types with their prefixes and colors
		local messageTypes = {
			error = { prefix = "Error: ", color = "|cFFFF0000" }, -- Red
			success = { prefix = "Success: ", color = "|cFF00FF00" }, -- Green
			info = { prefix = "Info: ", color = "|cFF00FFFF" }, -- Cyan
			warning = { prefix = "Warning: ", color = "|cFFFFFF00" }, -- Yellow
		}

		local typeInfo = messageTypes[messageType:lower()]
		if not typeInfo then
			-- Default to info if unknown type
			typeInfo = messageTypes.info
		end

		-- Construct the full message with color and prefix
		local fullMessage = string.format("%s%s%s|r", typeInfo.color, typeInfo.prefix, message)

		-- Send the broadcast message to the player
		player:SendBroadcastMessage(fullMessage)

		-- Log the message to the server logs with timestamp
		local timestamp = os.date("%Y-%m-%d %H:%M:%S")
		local logMessage = string.format("[%s] %s: %s", timestamp, messageType:upper(), message)
		print(logMessage) -- Assuming 'print' sends to server console/log
	end,
}

return utils
