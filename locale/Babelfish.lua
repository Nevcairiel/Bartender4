#!/usr/local/bin/lua

-- CONFIG --

--[[
	The name of the AceLocale-3.0 Category, as being used in :NewLocale and :GetLocale
]]
local localeName = "Bartender4"

--[[
	Prefix to all files if this script is run from a subdir, for example
]]
local filePrefix = "../"

--[[
	List of all files to parse
]]
local files = {
	"ActionBar.lua",
	"ActionBars.lua",
	"ActionBarStates.lua",
	"ActionButton.lua",
	"BagBar.lua",
	"Bar.lua",
	"Bartender4.lua",
	"ButtonBar.lua",
	"MicroMenu.lua",
	"PetBar.lua",
	"PetButton.lua",
	"RepXPBar.lua",
	"StanceBar.lua",
	"VehicleBar.lua",
	--
	"Options/ActionBar.lua",
	"Options/ActionBarStates.lua",
	"Options/BagBar.lua",
	"Options/Bar.lua",
	"Options/ButtonBar.lua",
	"Options/MicroMenu.lua",
	"Options/PetBar.lua",
	"Options/RepXPBar.lua",
	"Options/StanceBar.lua",
	"Options/Options.lua",
	"Options/VehicleBar.lua",
}

local out = "Strings.lua"
-- CODE --

local strings = {}

-- extract data from specified lua files
for idx,filename in pairs(files) do
	local file = io.open(string.format("%s%s", filePrefix or "", filename), "r")
	assert(file, "Could not open " .. filename)
	local text = file:read("*all")

	for match in string.gmatch(text, "L%[\"(.-)\"%]") do
		strings[match] = true
	end
end

local work = {}

for k,v in pairs(strings) do table.insert(work, k) end
table.sort(work)

-- Write locale files
local file = io.open(out, "w")
for idx, match in ipairs(work) do
	file:write(string.format("L[\"%s\"] = true\n", match))
end
file:close()
