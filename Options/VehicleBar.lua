--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local VehicleBarMod = Bartender4:GetModule("Vehicle", true)
if not VehicleBarMod then return end

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

function VehicleBarMod:SetupOptions()
	if not self.options then
		self.optionobject = Bar:GetOptionObject()
		local enabled = {
			type = "toggle",
			order = 1,
			name = L["Enabled"],
			desc = L["Enable the Vehicle Bar"],
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
			order = 30,
			type = "group",
			name = L["VehicleBar"],
			desc = L["Configure the VehicleBar"],
			childGroups = "tab",
		}
		Bartender4:RegisterBarOptions("Vehicle", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end
