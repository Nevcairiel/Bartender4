--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...

local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
-- register module
local BagBarMod = Bartender4:NewModule("BagBar")

-- fetch upvalues
local ButtonBar = Bartender4.ButtonBar.prototype
local Masque = LibStub("Masque", true)

-- create prototype information
local BagBar = setmetatable({}, {__index = ButtonBar})

local defaults = { profile = Bartender4.Util:Merge({
	enabled = true,
	verticalAlignment = "CENTER",
	onebag = false,
	onebagreagents = true,
	keyring = true,
	visibility = {
		possess = false,
	},
}, Bartender4.ButtonBar.defaults) }

function BagBarMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("BagBar", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

local noopFunc = function() end

-- anchor a bag button through the original functions of its frame type, see detachButtonFromBagsBar
local function clearSetPoint(btn, ...)
	local methods = getmetatable(btn).__index
	methods.ClearAllPoints(btn)
	methods.SetPoint(btn, ...)
end

-- The bags bar of the Blizzard UI anchors every bag button to itself whenever it runs its layout: on every update of
-- the edit mode layout, when the bag bar expands or collapses, and from callbacks that hold on to the layout function
-- directly, which cannot be hooked. Instead of moving the buttons back afterwards, they are made immune to it, once:
-- their SetPoint and ClearAllPoints do nothing, and the bar positions them through the original functions.
local function detachButtonFromBagsBar(button)
	button.SetPoint = noopFunc
	button.ClearAllPoints = noopFunc
	button.ClearSetPoint = clearSetPoint

	-- the bag bar of the Blizzard UI hides the bag slots when it is collapsed
	if button.SetBarExpanded then
		button.SetBarExpanded = noopFunc
	end

	-- The layout also rotates the keyring to follow the orientation of the edit mode. Reset it to the horizontal
	-- orientation, in case a vertical layout was applied already, and keep it there. The keyring is only set up for
	-- this on clients that use it.
	if button.UpdateOrientation and button.initialWidth then
		button:UpdateOrientation(true)
		button.UpdateOrientation = noopFunc
	end
end

function BagBarMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.ButtonBar:Create("BagBar", self.db.profile, L["Bag Bar"]), {__index = BagBar})

		detachButtonFromBagsBar(MainMenuBarBackpackButton)
		detachButtonFromBagsBar(CharacterBag0Slot)
		detachButtonFromBagsBar(CharacterBag1Slot)
		detachButtonFromBagsBar(CharacterBag2Slot)
		detachButtonFromBagsBar(CharacterBag3Slot)
		if CharacterReagentBag0Slot then
			detachButtonFromBagsBar(CharacterReagentBag0Slot)
		end
		if KeyRingButton then
			detachButtonFromBagsBar(KeyRingButton)
		end
	end

	if Bartender4.Features.Keyring and KeyRingButton then
		KeyRingButton:SetScript("OnShow", nil)
	end

	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()
end

function BagBarMod:ApplyConfig()
	self.bar:ApplyConfig(self.db.profile)
end

function BagBar:ApplyConfig(config)
	ButtonBar.ApplyConfig(self, config)

	if not self.config.position.x then
		self:ClearSetPoint("CENTER", 142, -18)
		self:SavePosition()
	end

	self:FeedButtons()
	self:UpdateButtonLayout()
end

local function MasqueButtonType(button)
	if button == CharacterReagentBag0Slot then
		return "ReagentBag"
	elseif button == MainMenuBarBackpackButton then
		return "Backpack"
	else
		return "BagSlot"
	end
end

BagBar.button_width = CharacterBag0Slot:GetWidth()
BagBar.button_height = CharacterBag0Slot:GetHeight()
BagBarMod.button_count = 6
function BagBar:FeedButtons()
	local count = 1
	local group = self.MasqueGroup

	if self.buttons then
		while next(self.buttons) do
			local btn = table.remove(self.buttons)
			-- park it on the hidden frame, so that it stays invisible even if the Blizzard UI shows it again
			btn:Hide()
			btn:SetParent(Bartender4.UIHider)

			if btn ~= KeyRingButton then
				if group and btn.MasqueButtonData then
					group:RemoveButton(btn)
				end
			end
		end
	else
		self.buttons = {}
	end

	if Bartender4.Features.Keyring and KeyRingButton and self.config.keyring then
		table.insert(self.buttons, KeyRingButton)
		count = count + 1
	elseif KeyRingButton then
		-- the classic clients show the keyring again on every bag update
		KeyRingButton:Hide()
		KeyRingButton:SetParent(Bartender4.UIHider)
	end

	if Bartender4.Features.ReagentBag and CharacterReagentBag0Slot and (not self.config.onebag or self.config.onebagreagents) then
		table.insert(self.buttons, CharacterReagentBag0Slot)
		count = count + 1
	end

	if not self.config.onebag then
		table.insert(self.buttons, CharacterBag3Slot)
		table.insert(self.buttons, CharacterBag2Slot)
		table.insert(self.buttons, CharacterBag1Slot)
		table.insert(self.buttons, CharacterBag0Slot)

		count = count + 4
	end

	table.insert(self.buttons, MainMenuBarBackpackButton)

	for i,v in pairs(self.buttons) do
		v:SetParent(self)
		v:Show()

		if v ~= KeyRingButton then
			if not Bartender4.GameType.Mainline then
				v:ClearNormalTexture()
			end

			if group then
				if not v.MasqueButtonData then
					v.MasqueButtonData = {
						Button = v,
						Icon = v.icon
					}
				end
				group:AddButton(v, v.MasqueButtonData, MasqueButtonType(v))
			end
		end
	end

	BagBarMod.button_count = count
	if BagBarMod.optionobject then
		BagBarMod.optionobject.table.general.args.rows.max = count
	end
end

function BagBar:UpdateButtonLayout()
	ButtonBar.UpdateButtonLayout(self)

	-- the backpack button is oversized, account for it here
	if Bartender4.GameType.MainlineStandard then
		local w, h = self:GetSize()
		self:SetSize(w + 14, h)
	end
end
