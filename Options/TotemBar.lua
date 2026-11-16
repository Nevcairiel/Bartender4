--[[
	Copyright (c) 2009-2012, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]

local _, Bartender4 = ...

local TotemBarMod = Bartender4:GetModule("TotemBar", true)
if not TotemBarMod then return end

-- fetch upvalues
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local ButtonBar = Bartender4.ButtonBar.prototype

function TotemBarMod:SetupOptions()
	if not self.options then
		self.optionobject = ButtonBar:GetOptionObject()
		-- the bar is always a single row growing down, and its buttons show neither macros nor equipped items
		local general = self.optionobject.table.general.args
		general.rows = nil
		general.vgrowth = nil
		general.macrotext = nil
		general.equipped = nil

		local enabled = {
			type = "toggle",
			order = 1,
			name = L["Enabled"],
			desc = L["Enable the Totem Bar"],
			get = function() return self.db.profile.enabled end,
			set = "ToggleModule",
			handler = self,
			width = "full",
		}
		self.optionobject:AddElement("general", "enabled", enabled)

		self.disabledoptions = {
			general = {
				type = "group",
				name = L["General Settings"],
				cmdInline = true,
				order = 1,
				args = {
					enabled = enabled,
				}
			}
		}
		self.options = {
			order = 100,
			type = "group",
			name = L["Totem Bar"],
			desc = L["Configure the Totem Bar"],
			childGroups = "tab",
		}
		Bartender4:RegisterBarOptions("TotemBar", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end
