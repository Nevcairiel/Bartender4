--[[
	Copyright (c) 2009-2018, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...

-- the module is not available without the status bar templates of the Blizzard UI
local StatusBarMod = Bartender4:GetModule("StatusTrackingBar", true)
if not StatusBarMod then return end

-- fetch upvalues
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local Bar = Bartender4.Bar.prototype

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
			softMin = -4, softMax = 20, step = 1,
			get = function() return self.db.profile.barPadding end,
			set = function(info, state) self.db.profile.barPadding = state; self:AnchorTrackingContainers() end,
		}
		self.optionobject:AddElement("general", "barPadding", barPadding)

		local lockText = {
			order = 81,
			name = L["Lock Text"],
			desc = L["Always show the text of the Status Bars, instead of only when the mouse is over them"],
			type = "toggle",
			get = function() return self.db.profile.lockText end,
			set = function(info, state) self.db.profile.lockText = state; self:UpdateTextLock() end,
		}
		self.optionobject:AddElement("general", "lockText", lockText)

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
