--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
--[[
	Pet Button template
]]
local _, Bartender4 = ...
local PetButtonPrototype = CreateFrame("CheckButton")
local PetButton_MT = {__index = PetButtonPrototype}

local Masque = LibStub("Masque", true)
local KeyBound = LibStub("LibKeyBound-1.0")

local WoWRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

-- upvalues
local _G = _G
local format, select, setmetatable = string.format, select, setmetatable

-- GLOBALS: InCombatLockdown, CreateFrame, SetDesaturation, IsModifiedClick, GetBindingKey, GetBindingText, SetBinding
-- GLOBALS: AutoCastShine_AutoCastStop, AutoCastShine_AutoCastStart, CooldownFrame_Set
-- GLOBALS: PickupPetAction, , GetPetActionInfo, GetPetActionsUsable, GetPetActionCooldown

local function onEnter(self, ...)
	if not (Bartender4.db.profile.tooltip == "nocombat" and InCombatLockdown()) and Bartender4.db.profile.tooltip ~= "disabled" then
		self:OnEnter(...)
	end
	KeyBound:Set(self)
end

local function onDragStart(self)
	if InCombatLockdown() then return end
	if not Bartender4.db.profile.buttonlock or IsModifiedClick("PICKUPACTION") then
		self:SetChecked(false)
		PickupPetAction(self.id)
		self:Update()
	end
end

local function onReceiveDrag(self)
	if InCombatLockdown() then return end
	if GetCursorInfo() == "petaction" then
		self:SetChecked(false)
		PickupPetAction(self.id)
		self:Update()
	end
end

Bartender4.PetButton = {}
Bartender4.PetButton.prototype = PetButtonPrototype
function Bartender4.PetButton:Create(id, parent)
	local name = "BT4PetButton" .. id
	local button = setmetatable(CreateFrame("CheckButton", name, parent, "PetActionButtonTemplate"), PetButton_MT)
	button.showgrid = 0
	button.id = id
	button.parent = parent

	button:SetFrameStrata("MEDIUM")
	button:SetID(id)

	button:UnregisterAllEvents()
	button:SetScript("OnEvent", nil)

	button.OnEnter = button:GetScript("OnEnter")
	button:SetScript("OnEnter", onEnter)

	button:SetScript("OnDragStart", onDragStart)
	button:SetScript("OnReceiveDrag", onReceiveDrag)

	if not WoWRetail then
		button.NormalTexture = button:GetNormalTexture()
	end

	if Masque then
		local group = parent.MasqueGroup
		group:AddButton(button, nil, "Pet")
	end
	return button
end

function PetButtonPrototype:Update()
	local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(self.id)

	if not isToken then
		self.icon:SetTexture(texture)
		self.tooltipName = name
	else
		self.icon:SetTexture(_G[texture])
		self.tooltipName = _G[name]
	end

	self.isToken = isToken

	if spellID then
		local spell = Spell:CreateFromSpellID(spellID)
		self.spellDataLoadedCancelFunc = spell:ContinueWithCancelOnSpellLoad(function()
			self.tooltipSubtext = spell:GetSpellSubtext()
		end)
	end

	if isActive then
		if IsPetAttackAction(self.id) then
			if self.StartFlash then
				self:StartFlash()
			end
			-- the checked texture looks a little confusing at full alpha (looks like you have an extra ability selected)
			self:GetCheckedTexture():SetAlpha(0.5)
		else
			if self.StopFlash then
				self:StopFlash()
			end
			self:GetCheckedTexture():SetAlpha(1.0)
		end
		self:SetChecked(not self.parent.config.hideequipped)
	else
		if self.StopFlash then
			self:StopFlash()
		end
		self:SetChecked(false)
	end

	if autoCastAllowed then
		self.AutoCastable:Show()

		if autoCastEnabled then
			AutoCastShine_AutoCastStart(self.AutoCastShine)
		else
			AutoCastShine_AutoCastStop(self.AutoCastShine)
		end
	else
		self.AutoCastable:Hide()
		AutoCastShine_AutoCastStop(self.AutoCastShine)
	end

	if texture then
		if GetPetActionsUsable() then
			SetDesaturation(self.icon, nil)
		else
			SetDesaturation(self.icon, 1)
		end
		self.icon:Show()


		if not self.parent.MasqueGroup then
			if WoWRetail then
				self.SlotBackground:Hide()
				if self.parent.config.hideborder then
					self.NormalTexture:SetTexture()
					self.icon:RemoveMaskTexture(self.IconMask)
					self.HighlightTexture:SetSize(34, 33)
					self.HighlightTexture:SetPoint("TOPLEFT", self, "TOPLEFT", -1.5, 1.5)
					self.CheckedTexture:SetSize(34, 33)
					self.CheckedTexture:SetPoint("TOPLEFT", self, "TOPLEFT", -1.5, 1.5)
					self.cooldown:ClearAllPoints()
					self.cooldown:SetAllPoints()
				else
					self:SetNormalAtlas("UI-HUD-ActionBar-IconFrame-AddRow")
					self.icon:AddMaskTexture(self.IconMask)
					self.HighlightTexture:SetSize(31.6, 30.9)
					self.HighlightTexture:SetPoint("TOPLEFT")
					self.CheckedTexture:SetSize(31.6, 30.9)
					self.CheckedTexture:SetPoint("TOPLEFT")
					self.cooldown:ClearAllPoints()
					self.cooldown:SetPoint("TOPLEFT", self, "TOPLEFT", 1.7, -1.7)
					self.cooldown:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1)
				end
			else
				self.NormalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
				self.NormalTexture:SetTexCoord(0, 0, 0, 0)
			end
		end
		self:ShowButton()
		if self.overlay then
			self.overlay:Show()
		end
	else
		self.icon:Hide()

		if not self.parent.MasqueGroup then
			if WoWRetail then
				self.SlotBackground:Show()
				self:SetNormalAtlas("UI-HUD-ActionBar-IconFrame-AddRow")
			else
				self.NormalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot")
				self.NormalTexture:SetTexCoord(-0.1, 1.1, -0.1, 1.12)
			end
		end
		self:HideButton()
		if self.showgrid == 0 and not self.parent.config.showgrid then
			if self.overlay then
				self.overlay:Hide()
			end
		end
	end

	self:UpdateCooldown()
	self:UpdateHotkeys()
end

function PetButtonPrototype:UpdateHotkeys()
	local key = self:GetHotkey() or ""
	local hotkey = self.HotKey

	if key == "" or self.parent.config.hidehotkey then
		hotkey:Hide()
	else
		hotkey:SetText(key)
		hotkey:Show()
	end
end

-- override the mixin hotkey function
PetButtonPrototype.SetHotkeys = PetButtonPrototype.UpdateHotkeys

function PetButtonPrototype:ShowButton()
	self:SetAlpha(1.0)
end

function PetButtonPrototype:HideButton()
	if self.showgrid == 0 and not self.parent.config.showgrid then
		self:SetAlpha(0.0)
	end
end

function PetButtonPrototype:ShowGrid()
	self.showgrid = self.showgrid + 1
	self:SetAlpha(1.0)
end

function PetButtonPrototype:HideGrid()
	if self.showgrid > 0 then self.showgrid = self.showgrid - 1 end
	if self.showgrid == 0  and not (GetPetActionInfo(self.id)) and not self.parent.config.showgrid then
		self:SetAlpha(0.0)
	end
end

function PetButtonPrototype:UpdateCooldown()
	local start, duration, enable = GetPetActionCooldown(self.id)
	CooldownFrame_Set(self.cooldown, start, duration, enable)

	if not GameTooltip:IsForbidden() and GameTooltip:GetOwner() == self then
		self:OnEnter()
	end
end

function PetButtonPrototype:GetHotkey()
	local key = GetBindingKey(format("BONUSACTIONBUTTON%d", self.id)) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
	return key and KeyBound:ToShortKey(key)
end

function PetButtonPrototype:GetBindings()
	local keys, binding = ""

	binding = format("BONUSACTIONBUTTON%d", self.id)
	for i = 1, select('#', GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys ~= "" then
			keys = keys .. ', '
		end
		keys = keys .. GetBindingText(hotKey,'KEY_')
	end

	binding = "CLICK "..self:GetName()..":LeftButton"
	for i = 1, select('#', GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys ~= "" then
			keys = keys .. ', '
		end
		keys = keys.. GetBindingText(hotKey,'KEY_')
	end

	return keys
end

function PetButtonPrototype:SetKey(key)
	SetBinding(key, format("BONUSACTIONBUTTON%d", self.id))
end

function PetButtonPrototype:ClearBindings()
	local binding = format("BONUSACTIONBUTTON%d", self:GetID())
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end

	binding = "CLICK "..self:GetName()..":LeftButton"
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
end

local actionTmpl = "Pet Button %d (%s)"
function PetButtonPrototype:GetActionName()
	local id = self.id
	local name, _, _, token = GetPetActionInfo(id)
	if token and name then name = _G[name] end
	return format(actionTmpl, id, name or "empty")
end

function PetButtonPrototype:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end
