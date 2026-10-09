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
			width = "full",
		}
		self.optionobject:AddElement("general", "enabled", enabled)

		if not Bartender4.GameType.Classic then
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
		end

		local barPadding = {
			order = 80.5,
			name = L["Bar Padding"],
			desc = L["Padding between the Status Bars"],
			type = "range",
			softMin = 0, softMax = 20, step = 1,
			get = function() return self.db.profile.barPadding end,
			set = function(info, state) self.db.profile.barPadding = state; self:AnchorTrackingContainers() end,
		}
		self.optionobject:AddElement("general", "barPadding", barPadding)

		local xpOnTop = {
			order = 81,
			name = "XP container on top (Secondary on Forever)",
			desc = "On WoW Forever, place the secondary (usually XP) container above the main (usually reputation) container.",
			type = "toggle",
			get = function() return self.db.profile.xpOnTop end,
			set = function(info, state) self.db.profile.xpOnTop = state; self:AnchorTrackingContainers() end,
		}
		self.optionobject:AddElement("general", "xpOnTop", xpOnTop)

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
