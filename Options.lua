--[[ $Id$ ]]

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local getFunc, setFunc
do
	function getFunc(info)
		return (info.arg and Bartender4.db.profile[info.arg] or Bartender4.db.profile[info[#info]])
	end
	
	function setFunc(info, value)
		local key = info.arg or info[#info]
		Bartender4.db.profile[key] = value
	end
end

local getProfilesOptionsTable
do
	local defaultProfiles
	--[[ Utility functions ]]
	-- get exisiting profiles + some default entries
	local tmpprofiles = {}
	local function getProfileList(db, common, nocurrent)
		-- clear old profile table
		local profiles = {}
		
		-- copy existing profiles into the table
		local curr = db:GetCurrentProfile()
		for i,v in pairs(db:GetProfiles(tmpprofiles)) do if not (nocurrent and v == curr) then profiles[v] = v end end
		
		-- add our default profiles to choose from
		for k,v in pairs(defaultProfiles) do
			if (common or profiles[k]) and not (k == curr and nocurrent) then
				profiles[k] = v
			end
		end
		return profiles
	end
	
	function getProfilesOptionsTable(db)
		defaultProfiles = {
			["Default"] = "Default",
			[db.keys.char] = "Char: " .. db.keys.char,
			[db.keys.realm] = "Realm: " .. db.keys.realm,
			[db.keys.class] = "Class: " .. UnitClass("player")
		}
		
		local tbl = {
			profiles = {
				type = "group",
				name = "Profiles",
				desc = "Manage Profiles",
				args = {
					reset = {
						order = 1,
						type = "execute",
						name = "Reset Profile",
						desc = "Reset the current profile to the default",
						func = function() db:ResetProfile() end,
					},
					spacer1 = {
						order = 2,
						type = "header",
						name = "Choose a Profile",
						desc = "Set the active profile of this character.",
					},
					new = {
						name = "New",
						type = "input",
						order = 3,
						get = function() return false end,
						set = function(info, value) db:SetProfile(value) end,
					},
					choose = {
						name = "Current",
						type = "select",
						order = 4,
						get = function() return db:GetCurrentProfile() end,
						set = function(info, value) db:SetProfile(value) end,
						values = function() return getProfileList(db, true) end,
					},
					spacer2 = {
						type = "header",
						order = 5,
						name = "Copy a Profile",
					},
					copyfrom = {
						order = 6,
						type = "select",
						name = "Copy From",
						desc = "Copy the settings from another profile",
						get = function() return false end,
						set = function(info, value) db:CopyProfile(value) end,
						values = function() return getProfileList(db, nil, true) end,
					},
					spacer3 = {
						type = "header",
						order = 7,
						name = "Delete a Profile",
					},
					delete = {
						order = 8,
						type = "select",
						name = "Delete a Profile",
						desc = "Deletes a profile from the database.",
						get = function() return false end,
						set = function(info, value) db:DeleteProfile(value) end,
						values = function() return getProfileList(db, nil, true) end,
						confirm = true,
						confirmText = "Are you sure you want to delete the selected profile?",
					},
				},
			},
		}
		return tbl
	end
end

function Bartender4:SetupOptions()
	self.options = {
		type = "group",
		name = "Bartender4",
		icon = "Interface\\Icons\\INV_Drink_05",
		childGroups = "tree",
		plugins = {},
		args = {
			lock = {
				order = 1,
				type = "toggle",
				name = "Lock",
				desc = "Lock all bars.",
				get = function() return Bartender4.Locked end,
				set = function(info, value) Bartender4[value and "Lock" or "Unlock"](Bartender4) end,
			},
			buttonlock = {
				order = 2,
				type = "toggle",
				name = "Button Lock",
				desc = "Lock the buttons.",
				get = getFunc,
				set = setFunc,
			},
		},
	}
	
	self.options.plugins.profiles = getProfilesOptionsTable(Bartender4.db)
	
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Bartender4", self.options, "bttest")
	local optFunc = function() 
		AceConfigDialog:Open("Bartender4") 
	--[[ 
		local status = AceConfigDialog:GetStatusTable("Bartender4")
		if not status.groups then status.groups = {} end 
		if not status.groups.groups then status.groups.groups = {} end 
		status.groups.groups["actionbars"] = true 
	]]
	end
	LibStub("AceConsole-3.0"):RegisterChatCommand( "bar", optFunc)
	LibStub("AceConsole-3.0"):RegisterChatCommand( "bt", optFunc)
	LibStub("AceConsole-3.0"):RegisterChatCommand( "bt4", optFunc)
end

function Bartender4:RegisterModuleOptions(key, table)
	self.options.plugins[key] = { [key] = table }
end

local optionParent = {}
function optionParent:NewCategory(category, data)
	self.table[category] = data
end

function optionParent:AddElement(category, element, data, ...)
	local lvl = self.table[category]
	for i = 1, select('#', ...) do
		local key = select(i, ...)
		if not (lvl.args[key] and lvl.args[key].args) then
			error(("Sub-Level Key %s does not exist in options group or is no sub-group."):format(key), 2)
		end
		lvl = lvl.args[key]
	end
	
	lvl.args[element] = data
end

function optionParent:AddElementGroup(category, group_desc, data, ...)
	local lvl = self.table[category]
	for i = 1, select('#', ...) do
		local key = select(i, ...)
		if not (lvl.args[key] and lvl.args[key].args) then
			error(("Sub-Level Key %s does not exist in options group or is no sub-group."):format(key), 2)
		end
		lvl = lvl.args[key]
	end
	
	if not lvl.plugins then
		lvl.plugins = {}
	end
	lvl.plugins[group_desc] = data
end

function Bartender4:NewOptionObject(otbl)
	if not otbl then otbl = {} end
	local tbl = { table = otbl }
	for k, v in pairs(optionParent) do
		tbl[k] = v
	end
	
	return tbl
end
