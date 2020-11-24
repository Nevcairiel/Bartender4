--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")

local ExtraActionBarMod = Bartender4:GetModule("ExtraActionBar", true)
if not ExtraActionBarMod then return end

-- fetch upvalues
local Bar = Bartender4.Bar.prototype

function ExtraActionBarMod:SetupOptions()
	if not self.options then
		self.optionobject = Bar:GetOptionObject()
		local enabled = {
			type = "toggle",
			order = 1,
			name = L["Enabled"],
			desc = L["Enable the Extra Action Bar"],
			get = function() return self.db.profile.enabled end,
			set = "ToggleModule",
			handler = self,
		}
		self.optionobject:AddElement("general", "enabled", enabled)

		local hideArtwork = {
			type = "toggle",
			order = 80,
			name = L["Hide Artwork"],
			desc = L["Hide the Extra Action Button artwork."],
			get = function() return self.db.profile.hideArtwork end,
			set = function(info, state) self.db.profile.hideArtwork = state; self:UpdateArtwork() end,
		}
		self.optionobject:AddElement("general", "hideArtwork", hideArtwork)

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
			name = L["Extra Action Bar"],
			desc = L["Configure the Extra Action Bar"],
			childGroups = "tab",
		}
		Bartender4:RegisterBarOptions("ExtraActionBar", self.options)
	end
	self.options.args = self:IsEnabled() and self.optionobject.table or self.disabledoptions
end
