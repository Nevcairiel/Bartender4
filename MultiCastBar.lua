--[[
	Copyright (c) 2009-2012, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]

local _, Bartender4 = ...

if Bartender4.GameType.MainlineStandard or not HasMultiCastActionBar or not MultiCastActionBarFrame or select(2, UnitClass("player")) ~= "SHAMAN" then return end

-- fetch upvalues
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local Bar = Bartender4.Bar.prototype
local KeyBound = LibStub("LibKeyBound-1.0")

local defaults = { profile = Bartender4.Util:Merge({
	enabled = true,
}, Bartender4.Bar.defaults) }

-- register module
local MultiCastMod = Bartender4:NewModule("MultiCast", "AceHook-3.0")

-- create prototype information
local MultiCastBar = setmetatable({}, {__index = Bar})

function MultiCastMod:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("MultiCast", defaults)
	self:SetEnabledState(self.db.profile.enabled)
end

function MultiCastMod:OnEnable()
	if not self.bar then
		self.bar = setmetatable(Bartender4.Bar:Create("MultiCast", self.db.profile, L["Totem Bar"]), {__index = MultiCastBar})
		self.bar.content = MultiCastActionBarFrame

		-- remove EditMode hooks
		self.bar.content.ClearAllPoints = nil
		self.bar.content.SetPoint = nil
		self.bar.content.SetScale = nil

		self.bar.content:SetScript("OnShow", nil)
		self.bar.content:SetScript("OnHide", nil)
		self.bar.content:SetScript("OnUpdate", nil)
		self.bar.content.ignoreFramePositionManager = true

		self.bar.content:SetParent(self.bar)
		self.bar.content:Show()
		self.bar.content:SetFrameLevel(self.bar:GetFrameLevel() + 1)

		self:CreateBindingButtons()
	end
	self.bar:Enable()
	self:ToggleOptions()
	self:ApplyConfig()
	self.bindingUpdater:Show()

	if MultiCastActionBarFrame and MultiCastActionBarFrame.ApplySystemAnchor then
		self:SecureHook(MultiCastActionBarFrame, "ApplySystemAnchor")
		self:SecureHook(MultiCastActionBarFrame, "HighlightSystem")
	end

	if EditModeManagerFrame and EditModeManagerFrame.UpdateBottomActionBarPositions then
		self:SecureHook(EditModeManagerFrame, "UpdateBottomActionBarPositions", "ApplySystemAnchor")
	end

	if UIParentBottomManagedFrameContainer then
		UIParentBottomManagedFrameContainer.showingFrames[MultiCastActionBarFrame] = nil
	end
end

function MultiCastMod:OnDisable()
	Bartender4.modulePrototype.OnDisable(self)
	if self.bindingUpdater then
		self:UpdateBindingButtons()
	end
end

function MultiCastMod:ApplySystemAnchor()
	self.bar:PerformLayout()
end

function MultiCastMod:HighlightSystem()
	if MultiCastActionBarFrame.Selection then
		MultiCastActionBarFrame.Selection:Hide()
	end
	EditModeMagnetismManager:UnregisterFrame(MultiCastActionBarFrame)
end

function MultiCastMod:ApplyConfig()
	if not self:IsEnabled() then return end
	self.bar:ApplyConfig(self.db.profile)
end

function MultiCastBar:ApplyConfig(config)
	Bar.ApplyConfig(self, config)

	self:PerformLayout()
end

function MultiCastBar:PerformLayout()
	self:SetSize(230, 40)
	local bar = self.content
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", self, "TOPLEFT", 3, 1)
end

--------------------------------------------------------------------------------
-- Keybindings
--
-- The totem bar is Blizzard's own frame, so its buttons are left untouched.
-- Every bindable action gets a hidden secure button which mirrors whatever the
-- matching totem bar button currently does, and keys are bound to that button.
-- A non-interactive overlay on top of each totem bar button implements the
-- LibKeyBound interface and shows the hotkey.
--------------------------------------------------------------------------------

local NUM_SLOTS, NUM_PAGES = 4, 3

local BINDINGS = {
	{ id = "Summon" },
	{ id = "Slot1", slot = 1 },
	{ id = "Slot2", slot = 2 },
	{ id = "Slot3", slot = 3 },
	{ id = "Slot4", slot = 4 },
	{ id = "Recall" },
}

local function GetCurrentPage()
	local page = MultiCastActionBarFrame.currentPage
	if type(page) == "number" and page >= 1 and page <= NUM_PAGES then
		return page
	end
	for p = 1, NUM_PAGES do
		local button = _G["MultiCastActionButton" .. ((p - 1) * NUM_SLOTS + 1)]
		if button and button:IsShown() then
			return p
		end
	end
	return 1
end

-- the totem bar button a binding currently refers to
local function GetTarget(info)
	if info.id == "Summon" then
		return _G.MultiCastSummonSpellButton
	elseif info.id == "Recall" then
		return _G.MultiCastRecallSpellButton
	end
	return _G["MultiCastActionButton" .. ((GetCurrentPage() - 1) * NUM_SLOTS + info.slot)]
end

local OverlayPrototype = {}

function OverlayPrototype:GetBindingAction()
	return "CLICK " .. self.binder:GetName() .. ":LeftButton"
end

function OverlayPrototype:GetHotkey()
	local key = GetBindingKey(self:GetBindingAction())
	return key and KeyBound:ToShortKey(key)
end

-- returns the name of what else the key is bound to, if anything (it gets replaced by SetKey)
function OverlayPrototype:FreeKey(key)
	local action = GetBindingAction(key)
	if action and action ~= "" and action ~= self:GetBindingAction() then
		return _G["BINDING_NAME_" .. action] or action
	end
end

function OverlayPrototype:SetKey(key)
	SetBindingClick(key, self.binder:GetName(), "LeftButton")
end

function OverlayPrototype:ClearBindings()
	local binding = self:GetBindingAction()
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
end

function OverlayPrototype:GetBindings()
	local keys = ""
	local binding = self:GetBindingAction()
	for i = 1, select("#", GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys ~= "" then
			keys = keys .. ", "
		end
		keys = keys .. GetBindingText(hotKey, "KEY_")
	end
	return keys
end

function OverlayPrototype:GetActionName()
	return _G["BINDING_NAME_" .. self:GetBindingAction()]
end

function OverlayPrototype:UpdateHotkey()
	self.hotkey:SetText(self:GetHotkey() or "")
end

function MultiCastMod:CreateBindingButtons()
	local content = self.bar.content
	for _, info in ipairs(BINDINGS) do
		local binder = CreateFrame("Button", "BT4TotemButton" .. info.id, UIParent, "SecureActionButtonTemplate")
		binder:RegisterForClicks("AnyDown")
		binder:SetAttribute("pressAndHoldAction", true)
		binder:Hide()
		info.binder = binder

		-- parented to the totem bar so it hides along with it
		-- LibKeyBound needs a named frame to check for existing bindings on a key
		local overlay = Mixin(CreateFrame("Frame", "BT4TotemButton" .. info.id .. "Overlay", content), OverlayPrototype)
		overlay.info, overlay.binder = info, binder
		overlay:EnableMouse(false)
		overlay:SetFrameLevel(content:GetFrameLevel() + 10)
		overlay.hotkey = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
		overlay.hotkey:SetPoint("TOPRIGHT", -1, -3)
		overlay:Hide()
		info.overlay = overlay
	end

	-- updates are batched and run once on the next frame
	local updater = CreateFrame("Frame")
	updater:Hide()
	updater:SetScript("OnUpdate", function(frame)
		frame:Hide()
		self:UpdateBindingButtons()
	end)
	self.bindingUpdater = updater
	local function queueUpdate() updater:Show() end

	-- only post-hooks on the Blizzard buttons, nothing on them is modified
	local function hookButton(button, info)
		if not button then return end
		button:HookScript("OnEnter", function() KeyBound:Set(info.overlay) end)
		button:HookScript("OnShow", queueUpdate)
		button:HookScript("OnHide", queueUpdate)
	end
	hookButton(_G.MultiCastSummonSpellButton, BINDINGS[1])
	hookButton(_G.MultiCastRecallSpellButton, BINDINGS[#BINDINGS])
	for i = 1, NUM_SLOTS * NUM_PAGES do
		hookButton(_G["MultiCastActionButton" .. i], BINDINGS[((i - 1) % NUM_SLOTS) + 2])
	end

	updater:RegisterEvent("PLAYER_ENTERING_WORLD")
	updater:RegisterEvent("PLAYER_REGEN_ENABLED")
	updater:RegisterEvent("SPELLS_CHANGED")
	updater:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	updater:RegisterEvent("UPDATE_BINDINGS")
	if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("UPDATE_MULTI_CAST_ACTIONBAR") then
		updater:RegisterEvent("UPDATE_MULTI_CAST_ACTIONBAR")
	end
	updater:SetScript("OnEvent", function(_, event, arg1)
		if event == "UPDATE_BINDINGS" then
			for _, info in ipairs(BINDINGS) do
				info.overlay:UpdateHotkey()
			end
		elseif event == "PLAYER_REGEN_ENABLED" then
			if self.bindingsDirty then
				queueUpdate()
			end
		elseif event == "ACTIONBAR_SLOT_CHANGED" then
			-- only the action slots the binding buttons currently use
			for _, info in ipairs(BINDINGS) do
				if arg1 == 0 or arg1 == info.binder:GetAttribute("action") then
					queueUpdate()
					break
				end
			end
		else
			queueUpdate()
		end
	end)
end

-- Point every binding button at what its totem bar button currently does, or
-- at nothing while the module is disabled.
-- Secure attributes cannot change in combat, so this waits until combat ends.
function MultiCastMod:UpdateBindingButtons()
	if InCombatLockdown() then
		self.bindingsDirty = true
		return
	end
	self.bindingsDirty = nil

	local enabled = self:IsEnabled()
	for _, info in ipairs(BINDINGS) do
		local binder, overlay = info.binder, info.overlay
		local target = enabled and GetTarget(info)
		local action = target and (target:GetAttribute("action") or target.action)
		local spell = target and target:GetAttribute("spell")

		binder:SetAttribute("action", nil)
		binder:SetAttribute("spell", nil)
		binder:SetAttribute("clickbutton", nil)
		if type(action) == "number" and action > 0 then
			binder:SetAttribute("type", "action")
			binder:SetAttribute("action", action)
		elseif spell then
			binder:SetAttribute("type", "spell")
			binder:SetAttribute("spell", spell)
		elseif target then
			binder:SetAttribute("type", "click")
			binder:SetAttribute("clickbutton", target)
		else
			binder:SetAttribute("type", nil)
		end

		overlay:ClearAllPoints()
		if target and target:IsShown() then
			overlay:SetAllPoints(target)
			overlay:Show()
		else
			overlay:Hide()
		end
		overlay:UpdateHotkey()
	end
end
