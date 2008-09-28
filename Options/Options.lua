local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local FAQ = LibStub("AceLocale-3.0"):GetLocale("Bartender4_FAQ")

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

local function getOptions()
	if not Bartender4.options then
		Bartender4.options = {
			type = "group",
			name = "Bartender4",
			icon = "Interface\\Icons\\INV_Drink_05",
			childGroups = "tree",
			plugins = {},
			args = {
				lock = {
					order = 1,
					type = "toggle",
					name = L["Lock"],
					desc = L["Lock all bars."],
					get = function() return Bartender4.Locked end,
					set = function(info, value) Bartender4[value and "Lock" or "Unlock"](Bartender4) end,
				},
				buttonlock = {
					order = 2,
					type = "toggle",
					name = L["Button Lock"],
					desc = L["Lock the buttons."],
					get = getFunc,
					set = setFunc,
				},
				bars = {
					order = 20,
					type = "group",
					name = L["Bars"],
					args = {
						selfcastmodifier = {
							order = 1,
							type = "toggle",
							name = L["Self-Cast by modifier"],
							desc = L["Toggle the use of the modifier-based self-cast functionality."],
							get = getFunc,
							set = function(info, value)
								Bartender4.db.profile.selfcastmodifier = value
								Bartender4.Bar:ForAll("UpdateSelfCast")
							end,
						},
						selfcastrightclick = {
							order = 2,
							type = "toggle",
							name = L["Right-click Self-Cast"],
							desc = L["Toggle the use of the right-click self-cast functionality."],
							get = getFunc,
							set = function(info, value)
								Bartender4.db.profile.selfcastrightclick = value
								Bartender4:GetModule("ActionBars"):ForAll("ForAll", "UpdateRightClickSelfCast")
							end,
						},
						range = {
							order = 10,
							name = L["Out of Range Indicator"],
							desc = L["Configure how the Out of Range Indicator should display on the buttons."],
							type = "select",
							style = "dropdown",
							get = function()
								return Bartender4.db.profile.outofrange
							end,
							set = function(info, value) 
								Bartender4.db.profile.outofrange = value
								Bartender4.Bar:ForAll("ApplyConfig")
							end,
							values = { none = L["No Display"], button = L["Full Button Mode"], hotkey = L["Hotkey Mode"] },
						},
						colors = {
							order = 13,
							type = "group",
							guiInline = true,
							name = L["Colors"],
							get = function(info)
								local color = Bartender4.db.profile.colors[info[#info]]
								return color.r, color.g, color.b
							end,
							set = function(info, r, g, b)
								local color = Bartender4.db.profile.colors[info[#info]]
								color.r, color.g, color.b = r, g, b
								Bartender4.Bar:ForAll("ApplyConfig")
							end,
							args = {
								range = {
									order = 1,
									type = "color",
									name = L["Out of Range Indicator"],
									desc = L["Specify the Color of the Out of Range Indicator"],
								},
								mana = {
									order = 2,
									type = "color",
									name = L["Out of Mana Indicator"],
									desc = L["Specify the Color of the Out of Mana Indicator"],
								},
							},
						},
						tooltip = {
							order = 20,
							name = L["Button Tooltip"],
							type = "select",
							desc = L["Configure the Button Tooltip."],
							values = { ["disabled"] = L["Disabled"], ["nocombat"] = L["Disabled in Combat"], ["enabled"] = L["Enabled"] },
							get = function() return Bartender4.db.profile.tooltip end,
							set = function(info, value) Bartender4.db.profile.tooltip = value end,
						},
					},
				},
				faq = {
					name = L["FAQ"],
					desc = L["Frequently Asked Questions"],
					type = "group",
					order = 200,
					args = {
						faq = {
							type = "description",
							name = FAQ["FAQ_TEXT"],
						},
					},
				},
			},
		}
		Bartender4.options.plugins.profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(Bartender4.db) }
		for k,v in Bartender4:IterateModules() do
			if v.SetupOptions then
				v:SetupOptions()
			end
		end
	end
	return Bartender4.options
end

function Bartender4:SetupOptions()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Bartender4", getOptions, "bttest")
	AceConfigDialog:SetDefaultSize("Bartender4", 680,525)
	local optFunc = function() 
		if InCombatLockdown() then return end
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
	if not self.options then
		error("Options table has not been created yet, respond to the callback!", 2)
	end
	self.options.plugins[key] = { [key] = table }
end

function Bartender4:RegisterBarOptions(id, table)
	if not self.options then
		error("Options table has not been created yet, respond to the callback!", 2)
	end
	self.options.args.bars.args[id] = table
end

local optionParent = {}
function optionParent:NewCategory(category, data)
	self.table[category] = data
end

local ov = nil
function optionParent:AddElement(category, element, data, ...)
	local lvl = self.table[category]
	for i = 1, select('#', ...) do
		local key = select(i, ...)
		if not (lvl.args[key] and lvl.args[key].args) then
			error(("Sub-Level Key %s does not exist in options group or is no sub-group."):format(key), ov and 3 or 2)
		end
		lvl = lvl.args[key]
	end
	
	lvl.args[element] = data
end

function optionParent:AddElementGroup(category, data, ...)
	ov = true
	for k,v in pairs(data) do
		self:AddElement(category, k, v, ...)
	end
	ov = nil
end

function Bartender4:NewOptionObject(otbl)
	if not otbl then otbl = {} end
	local tbl = { table = otbl }
	for k, v in pairs(optionParent) do
		tbl[k] = v
	end
	
	return tbl
end
