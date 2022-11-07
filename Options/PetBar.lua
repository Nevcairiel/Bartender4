--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local PetBarMod = Bartender4:GetModule("PetBar")

local WoW10 = select(4, GetBuildInfo()) >= 100000

-- fetch upvalues
local ButtonBar = Bartender4.ButtonBar.prototype

function PetBarMod:SetupOptions()
	if not self.options then
		self.optionobject = ButtonBar:GetOptionObject()

		self.optionobject.table.general.args.rows.max = 10

		local enabled = {
			type = "toggle",
			order = 1,
			name = L["Enabled"],
			desc = L["Enable the Pet Bar"],
			get = function() return self.db.profile.enabled end,
			set = "ToggleModule",
			handler = self,
			width = "full",
		}

		local cat_general = {
			enabled = enabled,
			grid = {
				order = 79,
				type = "toggle",
				name = L["Button Grid"],
				desc = L["Toggle the button grid."],
				set = function(info, ...) PetBarMod:SetGrid(...) end,
				get = function(info) return PetBarMod:GetGrid() end,
			},
			border = {
				order = 84,
				type = "toggle",
				name = L["Hide Border"],
				desc = L["Hide the border around the action button."],
				set = function(info, ...) PetBarMod:SetHideBorder(...) end,
				get = function(info) return PetBarMod:GetHideBorder() end,
				hidden = not WoW10,
			},
		}
		self.optionobject:AddElementGroup("general", cat_general)

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
			name = L["Pet Bar"],
			desc = L["Manage the abilities of your trusted companion"],
			childGroups = "tab",
		}
		Bartender4:RegisterActionBarOptions("PetBar", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end
