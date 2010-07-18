#!/usr/local/bin/lua

-- CONFIG --

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
	"ActionButton.lua",
	"BagBar.lua",
	"Bar.lua",
	"Bartender4.lua",
	"BlizzardArt.lua",
	"ButtonBar.lua",
	"MicroMenu.lua",
	"MultiCastBar.lua",
	"PetBar.lua",
	"PetButton.lua",
	"RepXPBar.lua",
	"StanceBar.lua",
	"StateBar.lua",
	"VehicleBar.lua",
	--
	"Options/ActionBar.lua",
	"Options/BagBar.lua",
	"Options/Bar.lua",
	"Options/BlizzardArt.lua",
	"Options/ButtonBar.lua",
	"Options/Defaults.lua",
	"Options/MicroMenu.lua",
	"Options/MultiCastBar.lua",
	"Options/Options.lua",
	"Options/PetBar.lua",
	"Options/RepXPBar.lua",
	"Options/StanceBar.lua",
	"Options/StateBar.lua",
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
