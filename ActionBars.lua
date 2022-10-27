--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local BT4ActionBars = Bartender4:NewModule("ActionBars", "AceEvent-3.0")

local select, ipairs, pairs, tostring, tonumber, min, setmetatable = select, ipairs, pairs, tostring, tonumber, min, setmetatable

local WoWClassic = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)
local WoWWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local WoW10 = select(4, GetBuildInfo()) >= 100000

-- GLOBALS: UnitClass, InCombatLockdown, GetBindingKey, ClearOverrideBindings, SetOverrideBindingClick

local abdefaults = {
	['**'] = Bartender4:Merge({
		enabled = true,
		buttons = 12,
		buttonOffset = 0,
		hidemacrotext = false,
		showgrid = false,
		flyoutDirection = "UP",
	}, Bartender4.StateBar.defaults),
	[1] = {
		states = {
			enabled = true,
			possess = true,
			actionbar = false,
			stance = {
				DRUID = { bear = 9, cat = 7, prowl = 8 },
				ROGUE = WoWWrath and { stealth = 7, shadowdance = 8 } or { stealth = 7 },
				WARRIOR = WoWClassic and { battle = 7, def = 8, berserker = 9 } or nil,
				PRIEST = WoWClassic and { shadowform = 7 } or nil,
			},
		},
		visibility = {
			vehicleui = false,
			overridebar = false,
		},
	},
	[7] = {
		enabled = false,
	},
	[8] = {
		enabled = false,
	},
	[9] = {
		enabled = false,
	},
	[10] = {
		enabled = false,
	},
	[13] = {
		enabled = false,
	},
	[14] = {
		enabled = false,
	},
	[15] = {
		enabled = false,
	},
}

local LIST_ACTIONBARS = WoW10 and { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 14, 15 } or { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
BT4ActionBars.LIST_ACTIONBARS = LIST_ACTIONBARS

local BINDING_MAPPINGS = {
	[1] = "ACTIONBUTTON%d",
	[3] = "MULTIACTIONBAR3BUTTON%d",
	[4] = "MULTIACTIONBAR4BUTTON%d",
	[5] = "MULTIACTIONBAR2BUTTON%d",
	[6] = "MULTIACTIONBAR1BUTTON%d",
	[13] = "MULTIACTIONBAR5BUTTON%d",
	[14] = "MULTIACTIONBAR6BUTTON%d",
	[15] = "MULTIACTIONBAR7BUTTON%d",
}


local defaults = {
	profile = {
		actionbars = abdefaults,
	}
}

local ActionBar_MT = {__index = Bartender4.ActionBar}

-- export defaults for other modules
Bartender4.ActionBar.defaults = abdefaults['**']

function BT4ActionBars:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("ActionBars", defaults)
end

-- setup the 10 actionbars
local first = true
function BT4ActionBars:OnEnable()
	if first then
		self.playerclass = select(2, UnitClass("player"))
		self.actionbars = {}

		for _, i in ipairs(LIST_ACTIONBARS) do
			local config = self.db.profile.actionbars[i]
			if config.enabled then
				self.actionbars[i] = self:Create(i, config, BINDING_MAPPINGS[i])
			else
				self:CreateBarOption(i, self.disabledoptions)
			end
		end

		first = nil
	end

	self:RegisterEvent("UPDATE_BINDINGS", "ReassignBindings")
	self:ReassignBindings()
end

function BT4ActionBars:SetupOptions()
	if not self.options then
		-- empty table to hold the bar options
		self.options = {}

		-- template for disabled bars
		self.disabledoptions = {
			general = {
				type = "group",
				name = L["General Settings"],
				cmdInline = true,
				order = 1,
				args = {
					enabled = {
						type = "toggle",
						name = L["Enabled"],
						desc = L["Enable/Disable the bar."],
						set = function(info, v) if v then BT4ActionBars:EnableBar(info[2]) end end,
						get = function() return false end,
					}
				}
			}
		}

		-- iterate over bars and create their option tables
		for _, i in ipairs(LIST_ACTIONBARS) do
			local config = self.db.profile.actionbars[i]
			if config.enabled then
				self:CreateBarOption(i)
			else
				self:CreateBarOption(i, self.disabledoptions)
			end
		end
	end
end

-- Applys the config in the current profile to all active Bars
function BT4ActionBars:ApplyConfig()
	for _, i in ipairs(LIST_ACTIONBARS) do
		local config = self.db.profile.actionbars[i]
		-- make sure the bar has its current config object if it exists already
		if self.actionbars[i] then
			self.actionbars[i].config = config
		end
		if config.enabled then
			self:EnableBar(i)
		else
			self:DisableBar(i)
		end
	end
end

-- we do not allow to disable the actionbars module
function BT4ActionBars:ToggleModule()
	return
end

function BT4ActionBars:UpdateButtons(force)
	for i,v in ipairs(self.actionbars) do
		for j,button in ipairs(v.buttons) do
			button:UpdateAction(force)
		end
	end
end

local function MigrateKeybindBindings(target, ...)
	local needSaving = false
	for k=1, select('#', ...) do
		local key = select(k, ...)
		if key and key ~= "" then
			SetBindingClick(key, target, "Keybind")
			needSaving = true
		end
	end
	return needSaving
end

local s_inReassignBindings = false
function BT4ActionBars:ReassignBindings()
	if InCombatLockdown() or s_inReassignBindings then return end
	s_inReassignBindings = true

	if self.actionbars then
		for id, mapping in pairs(BINDING_MAPPINGS) do
			local frame = self.actionbars[id]
			if frame then
				ClearOverrideBindings(frame)
				for i = 1,min(#frame.buttons, 12) do
					local button, real_button = mapping:format(i), frame.buttons[i]:GetName()
					for k=1, select('#', GetBindingKey(button)) do
						local key = select(k, GetBindingKey(button))
						if key and key ~= "" then
							SetOverrideBindingClick(frame, false, key, real_button, "Keybind")
						end
					end
				end
			end
		end
	end

	-- re-assign bindings from LeftButton to Keybind buttons
	local needSaving = false
	for i = 1,180 do
		local button = ("BT4Button%d"):format(i)
		local clickbutton = ("CLICK %s:LeftButton"):format(button)
		if MigrateKeybindBindings(button, GetBindingKey(clickbutton)) then
			needSaving = true
		end
	end

	if needSaving then
		SaveBindings(GetCurrentBindingSet())
	end

	s_inReassignBindings = false
end

BT4ActionBars.BLIZZARD_BAR_MAP = {
	[6] = 2,
	[5] = 3,
	[3] = 4,
	[4] = 5,
	[13] = 6,
	[14] = 7,
	[15] = 8,
}

function BT4ActionBars:GetBarName(id)
	if WoW10 then
		local barID = tonumber(id)
		if barID == 7 or barID == 8 or barID == 9 or barID == 10 then
			return (L["Class Bar %d"]):format(barID - 6)
		elseif self.BLIZZARD_BAR_MAP[barID] then
			return (L["Bar %s"]):format(tostring(self.BLIZZARD_BAR_MAP[barID]))
		elseif barID == 2 then
			return L["Bonus Action Bar"]
		end
	end
	return (L["Bar %s"]):format(id)
end

-- Creates a new bar object based on the id and the specified config
function BT4ActionBars:Create(id, config, bindingmapping)
	id = tostring(id)
	local bar = setmetatable(Bartender4.StateBar:Create(id, config, self:GetBarName(id)), ActionBar_MT)
	bar.module = self
	bar.bindingmapping = bindingmapping

	bar:SetScript("OnEvent", bar.OnEvent)
	if not WoWClassic then
		bar:RegisterEvent("PLAYER_TALENT_UPDATE")
		bar:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	end
	bar:RegisterEvent("LEARNED_SPELL_IN_TAB")
	bar:RegisterEvent("PLAYER_REGEN_ENABLED")

	self:CreateBarOption(id)

	bar:ApplyConfig()

	return bar
end

function BT4ActionBars:DisableBar(id)
	id = tonumber(id)
	local bar = self.actionbars[id]
	if not bar then return end

	bar.config.enabled = false
	bar:Disable()
	self:CreateBarOption(id, self.disabledoptions)
end

function BT4ActionBars:EnableBar(id)
	id = tonumber(id)
	local bar = self.actionbars[id]
	local config = self.db.profile.actionbars[id]
	config.enabled = true
	if not bar then
		bar = self:Create(id, config, BINDING_MAPPINGS[id])
		self.actionbars[id] = bar
	else
		bar.disabled = nil
		self:CreateBarOption(id)
		bar:ApplyConfig(config)
	end
	if not Bartender4.Locked then
		bar:Unlock()
	end
end

function BT4ActionBars:GetAll()
	return pairs(self.actionbars)
end

function BT4ActionBars:ForAll(method, ...)
	for _, bar in self:GetAll() do
		local func = bar[method]
		if func then
			func(bar, ...)
		end
	end
end

function BT4ActionBars:ForAllButtons(...)
	self:ForAll("ForAll", ...)
end
