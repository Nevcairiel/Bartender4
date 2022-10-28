--[[
	Copyright (c) 2009-2018, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...

-- only in 8.0
if not StatusTrackingBarManager then return end

local WoW10 = select(4, GetBuildInfo()) >= 100000

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
			width = "full",
		}
		self.optionobject:AddElement("general", "enabled", enabled)

		local width = {
			order = 80,
			name = L["Width"],
			desc = L["Width of the Status Bars"],
			type = "range",
			min = 10, softMin = 200, softMax = 2000, step = 1,
			get = function() return self.db.profile.width end,
			set = function(info, state) self.db.profile.width = state; self.bar:PerformLayout() end,
		}
		self.optionobject:AddElement("general", "width", width)

		local sections = {
			type = "toggle",
			order = 81,
			name = L["Use twenty sections"],
			desc = L["Divide the bar into 20 sections, instead of only 10, for long status bars."],
			get = function() return self.db.profile.twentySections end,
			set = function(info, state) self.db.profile.twentySections = state; self.bar:PerformLayout() end,
			hidden = WoW10,
		}
		self.optionobject:AddElement("general", "twentySections", sections)

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
			desc = L["The Status Tracking Bar combines XP/Reputation/Honor into one bar, stacking up to two tracked elements"],
			childGroups = "tab",
		}
		Bartender4:RegisterBarOptions("Status", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end
