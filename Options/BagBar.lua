--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local WoWClassic = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)
local WoW10 = select(4, GetBuildInfo()) >= 100000

local BagBarMod = Bartender4:GetModule("BagBar")

-- fetch upvalues
local ButtonBar = Bartender4.ButtonBar.prototype

function BagBarMod:SetupOptions()
	if not self.options then
		self.optionobject = ButtonBar:GetOptionObject()
		self.optionobject.table.general.args.rows.max = self.button_count
		local enabled = {
			type = "toggle",
			order = 1,
			name = L["Enabled"],
			desc = L["Enable the Bag Bar"],
			get = function() return self.db.profile.enabled end,
			set = "ToggleModule",
			handler = self,
			width = "full",
		}
		self.optionobject:AddElement("general", "enabled", enabled)

		local verticalAlignment = {
			type = "select",
			order = 79,
			name = L["Vertical Button Alignment"],
			desc = L["Vertical button alignment for this bar."],
			get = function() return self.db.profile.verticalAlignment end,
			set = function(info, state) self.db.profile.verticalAlignment = state; self.bar:UpdateButtonLayout() end,
			values = { TOP = L["TOP"], CENTER = L["CENTER"], BOTTOM = L["BOTTOM"] },
		}
		self.optionobject:AddElement("general", "verticalAlignment", verticalAlignment)

		local onebag = {
			type = "toggle",
			order = 80,
			name = L["One Bag"],
			desc = L["Only show one Bag Button in the BagBar."],
			get = function() return self.db.profile.onebag end,
			set = function(info, state) self.db.profile.onebag = state; self.bar:FeedButtons(); self.bar:UpdateButtonLayout() end,
		}
		self.optionobject:AddElement("general", "onebag", onebag)

		if WoW10 then
			local onebagreagents = {
				type = "toggle",
				order = 80,
				name = L["One Bag, Show Reagents"],
				desc = L["Show the Reagent Bag in One Bag mode"],
				get = function() return self.db.profile.onebagreagents end,
				width = 1.25,
				set = function(info, state) self.db.profile.onebagreagents = state; self.bar:FeedButtons(); self.bar:UpdateButtonLayout() end,
			}
			self.optionobject:AddElement("general", "onebagreagents", onebagreagents)
		end

		if WoWClassic then
			local keyring = {
				type = "toggle",
				order = 80,
				name = L["Keyring"],
				desc = L["Show the keyring button."],
				get = function() return self.db.profile.keyring end,
				set = function(info, state) self.db.profile.keyring = state; self.bar:FeedButtons(); self.bar:UpdateButtonLayout() end,
			}
			self.optionobject:AddElement("general", "keyring", keyring)
		end

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
			name = L["Bag Bar"],
			desc = L["Manages the Backpack and all the extra bags"],
			childGroups = "tab",
		}
		Bartender4:RegisterBarOptions("BagBar", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end
