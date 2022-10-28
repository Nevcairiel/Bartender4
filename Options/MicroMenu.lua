--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local MicroMenuMod = Bartender4:GetModule("MicroMenu")

-- fetch upvalues
local Bar = Bartender4.Bar.prototype
local ButtonBar = Bartender4.ButtonBar.prototype

function MicroMenuMod:SetupOptions()
	if not self.options then
		self.optionobject = ButtonBar:GetOptionObject()
		self.optionobject.table.general.args.rows.max = self.button_count
		local enabled = {
			type = "toggle",
			order = 1,
			name = L["Enabled"],
			desc = L["Enable the Micro Menu"],
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
			order = 30,
			type = "group",
			name = L["Micro Menu"],
			desc = L["Manages the Micro Menu buttons"],
			childGroups = "tab",
		}
		self.optionobject.table.general.args.padding.min = -30
		Bartender4:RegisterBarOptions("MicroMenu", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end

local QueueStatusMod = Bartender4:GetModule("QueueStatusButtonBar", true)
if QueueStatusMod then
	function QueueStatusMod:SetupOptions()
		if not self.options then
			self.optionobject = Bar:GetOptionObject()
			local enabled = {
				type = "toggle",
				order = 1,
				name = L["Enabled"],
				desc = L["Enable the Queue Status Bar"],
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
				name = L["Queue Status Bar"],
				desc = L["Contains the \"Green Eye\" when signing up for groups or raids"],
				childGroups = "tab",
			}
			Bartender4:RegisterBarOptions("QueueStatus", self.options)
		end
		self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
	end
end
