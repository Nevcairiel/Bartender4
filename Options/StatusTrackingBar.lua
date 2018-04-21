--[[
	Copyright (c) 2009-2018, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...

-- only in 8.0
if not StatusTrackingBarManager then return end

-- fetch upvalues
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local Bar = Bartender4.Bar.prototype

local StatusBarMod = Bartender4:GetModule("StatusTrackingBar")

function StatusBarMod:SetupOptions()
	if not self.options then
		self.optionobject = Bar:GetOptionObject()
		local enabled = {
			type = "toggle",
			order = 1,
			name = L["Enabled"],
			desc = L["Enable the Status Tracking Bar"],
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
			name = L["Status Tracking Bar"],
			desc = L["Configure the Status Tracking Bar"],
			childGroups = "tab",
		}
		Bartender4:RegisterBarOptions("Status", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end
