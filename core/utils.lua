local _, ns = ...
local E, C, A = ns.E, ns.C, ns.A

-- Lua
local floor = math.floor
local modf = math.modf
local infinity = math.huge

-- constants
local CLASSIFICATION = "|c%s%s |r"
local MILLION = 1E6
local THOUSAND = 1E3

local round = function(value)
	return floor(value + 0.5)
end

-- return short value of a number!
E.ShortValue = function(value)
	local v = math.abs(value)
	if (v >= 1E6) then
		return ("%.1fm"):format(value / 1E6):gsub("%.?0+([km])$", "%1")
	elseif (v >= 1E3) then
		return ("%.1fk"):format(value / 1E3):gsub("%.?0+([km])$", "%1")
	end
	return value
end

-- format seconds to minutes, hours or days
E.FormatTime = function(value)
	value = tonumber(value)
	if (not value or value == infinity) then return end

	local day, hour, minute = 86400, 3600, 60

	if (value >= day) then
		return format("%dd", ceil(value / day))
	elseif (value >= hour) then
		return format("%dh", ceil(value / hour))
	elseif (value >= minute) then
		return format("%dm", ceil(value / minute))
	elseif (value >= minute / 12) then
		return ceil(value)
	end
	return format("%.1f", value)
end

E.UTF8Sub = function(value, i, dots)
	if not value then return end

	local bytes = value:len()
	if (bytes <= i) then
		return value
	else
		local length, position = 0, 1
		while(position <= bytes) do
			length = length + 1
			local c = value:byte(position)
			if (c > 0 and c <= 127) then
				position = position + 1
			elseif (c >= 192 and c <= 223) then
				position = position + 2
			elseif (c >= 224 and c <= 239) then
				position = position + 3
			elseif (c >= 240 and c <= 247) then
				position = position + 4
			end
			if (length == i) then break end
		end

		if (length == i and position <= bytes) then
			return value:sub(1, position - 1) .. (dots and "..." or "")
		else
			return value
		end
	end
end

--[[ Function: E.CalcSegmentsSizes(num, width, spacing)
    Calculates the sizes of segmented elements with equal spacing.

    * num     - Number of segments to divide the width into.
    * width   - Total width to be divided among segments and spacing.
    * spacing - Spacing between each segment.

    Returns a table of sizes where each segment, separated by spacing,
    sums up to the given width while ensuring each segment size is an integer.
--]]
E.CalcSegmentsSizes = function(num, width, spacing)
    -- Calculate the base size of each segment without spacing
    local baseSize = floor((width - (num - 1) * spacing) / num)
    
    -- Calculate the remainder left after distributing base sizes
    local remainder = floor(width - (baseSize * num) - ((num - 1) * spacing))
    
    -- Initialize the table to store segment sizes
    local sizes = {}
    
    -- Assign base sizes to segments
    for i = 1, num do
        sizes[i] = baseSize
    end
    
    -- Distribute remainder across segments to ensure sum equals width
    for i = 1, remainder do
        sizes[i] = sizes[i] + 1
    end
    
    return sizes
end

--[[ Function: E.CalcSegmentsNumber(width, size, spacing)
    Calculate the number of segmented elements with equal spacing and containted in a element of width.

    * width   - Total width to be divided among segments and spacing.
    * size 	  - Segment size.
    * spacing - Spacing between each segment.

    Returns an integer.
--]]
E.CalcSegmentsNumber = function(width, size, spacing)
	return floor((width + spacing) / (size + spacing))
end

--[[ Function: E.GetClassification(value)
    Returns a classification symbol based on unit classification.

    * value   - unit classification from `UnitClassification(unit)`.

    Returns an string.
--]]
E.GetClassification = function(value)
	local color = E.colors.classification[value]
	if (value == "worldboss") then
		return CLASSIFICATION:format(color.hex, "B") -- "|cffff0000B |r"
	elseif (value == "rareelite") then
		return CLASSIFICATION:format(color.hex, "R+") -- "|cffff4500R+ |r"
	elseif (value == "elite") then
		return CLASSIFICATION:format(color.hex, "+") -- "|cffffa500+ |r"
	elseif (value == "rare") then
		return CLASSIFICATION:format(color.hex, "R") -- "|cffffff00R |r"
	elseif (value == "minus") then
		return CLASSIFICATION:format(color.hex, "-") -- "|cff888888- |r"
	end
	return ""
end

E.Round = round
