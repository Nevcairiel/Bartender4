--[[
	Copyright (c) 2009, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]

if not HasMultiCastActionBar or select(2, UnitClass("player")) ~= "SHAMAN" then return end

-- fetch upvalues
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local Bar = Bartender4.Bar.prototype

local MultiCastMod = Bartender4:GetModule("MultiCast")

function MultiCastMod:SetupOptions()
	if not self.options then
		self.optionobject = Bar:GetOptionObject()
		local enabled = {
			type = "toggle",
			order = 1,
			name = L["Enabled"],
			desc = L["Enable the Totem Bar"],
			get = function() return self.db.profile.enabled end,
			set = "ToggleModule",
			handler = self,
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
		Bartender4:RegisterBarOptions("MultiCast", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end
