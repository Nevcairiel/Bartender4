--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...

local WoW10 = select(4, GetBuildInfo()) >= 100000
if WoW10 then return end

local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
-- register module
local BagBarMod = Bartender4:NewModule("BagBar", "AceHook-3.0")

-- fetch upvalues
local ButtonBar = Bartender4.ButtonBar.prototype
local Masque = LibStub("Masque", true)

local _G = _G
local next, pairs, setmetatable = next, pairs, setmetatable
local table_insert, table_remove = table.insert, table.remove

-- GLOBALS: UIParent, MainMenuBarBackpackButton, CharacterBag0Slot, CharacterBag1Slot, CharacterBag2Slot, CharacterBag3Slot, KeyRingButton

-- create prototype information
local BagBar = setmetatable({}, {__index = ButtonBar})

local defaults = { profile = Bartender4.Util:Merge({
	enabled = true,
	verticalAlignment = "BOTTOM",
	keyring = true,
	onebag = false,
	visibility = {
		possess = false,
	},
}, Bartender4.ButtonBar.defaults) }

function BagBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("BagBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

local noopFunc = function() end

function BagBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.ButtonBar:Create("BagBar", self.db.profile, L["Bag Bar"]), {__index = BagBar})
	end
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()
end

function BagBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

function BagBar:ApplyConfig(config)
	ButtonBar.ApplyConfig(self, config)

	if not self.config.position.x then
		self:ClearSetPoint("CENTER", 142, -18)
		self:SavePosition()
	end

	self:FeedButtons()
	self:UpdateButtonLayout()
end

local function clearSetPoint(btn, ...)
	btn:ClearAllPoints()
	btn:SetPoint(...)
end

BagBar.button_width = 37
BagBar.button_height = 37
BagBarMod.button_count = 5
function BagBar:FeedButtons()
	local count = 1
	if self.buttons then
		while next(self.buttons) do
			local btn = table_remove(self.buttons)
			btn:Hide()
			btn:SetParent(UIParent)
			btn:ClearSetPoint("CENTER")

			if btn ~= KeyRingButton then
				if btn.MasqueButtonData then
					local group = self.MasqueGroup
					group:RemoveButton(btn)
				end
			end
		end
	else
		self.buttons = {}
	end

	if KeyRingButton and self.config.keyring then
		table_insert(self.buttons, KeyRingButton)
		count = count + 1
	elseif KeyRingButton then
		KeyRingButton:Hide()
		KeyRingButton:ClearAllPoints()
	end

	if not self.config.onebag then
		table_insert(self.buttons, CharacterBag3Slot)
		table_insert(self.buttons, CharacterBag2Slot)
		table_insert(self.buttons, CharacterBag1Slot)
		table_insert(self.buttons, CharacterBag0Slot)
		count = count + 4
	end

	table_insert(self.buttons, MainMenuBarBackpackButton)

	for i,v in pairs(self.buttons) do
		v:SetParent(self)
		v:Show()
		if v ~= KeyRingButton then
			v:SetNormalTexture("")

			if Masque then
				local group = self.MasqueGroup
				if not v.MasqueButtonData then
					v.MasqueButtonData = {
						Button = v,
						Icon = _G[v:GetName() .. "IconTexture"],
					}
				end
				group:AddButton(v, v.MasqueButtonData, "Item")
			end
		end

		v.ClearSetPoint = clearSetPoint
	end

	BagBarMod.button_count = count
	if BagBarMod.optionobject then
		BagBarMod.optionobject.table.general.args.rows.max = count
	end
end
