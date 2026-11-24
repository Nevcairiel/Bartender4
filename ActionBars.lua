--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local BT4ActionBars = Bartender4:NewModule("ActionBars", "AceEvent-3.0", "AceHook-3.0")

local LAB10 = LibStub("LibActionButton-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
local Masque = LibStub("Masque", true)

local abdefaults = {
	['**'] = Bartender4.Util:Merge({
		enabled = true,
		buttons = 12,
		buttonOffset = 0,
		holdToCast = true,
		hidemacrotext = false,
		showgrid = false,
		flyoutDirection = "UP",
		elements = {
			['**'] = {
				font = "Arial Narrow",
				fontSize = 13,
				fontFlags = "OUTLINE",
				fontColor = {1, 1, 1},
				textAnchor = "CENTER",
				textOffsetX = 0,
				textOffsetY = 0,
				textJustifyH = "CENTER",
			},
			hotkey = {
				fontSize = Bartender4.GameType.Mainline and 16 or 13,
				fontColor = {0.9, 0.9, 0.9},
				textAnchor = "TOPRIGHT",
				textOffsetX = -2,
				textOffsetY = -4,
				textJustifyH = "RIGHT",
			},
			count = {
				fontSize = Bartender4.GameType.Mainline and 19 or 16,
				textAnchor = "BOTTOMRIGHT",
				textOffsetX = -2,
				textOffsetY = 4,
				textJustifyH = "RIGHT",
			},
			macro = {
				font = "Friz Quadrata TT",
				fontSize = Bartender4.GameType.Mainline and 11 or 10,
				textAnchor = "BOTTOM",
				textOffsetX = 0,
				textOffsetY = 2,
			},
		},
	}, Bartender4.StateBar.defaults),
	[1] = {
		states = {
			enabled = true,
			possess = true,
			actionbar = false,
			stance = {
				DRUID = { bear = 9, cat = 7, prowl = 8 },
				ROGUE = (Bartender4.GameType.ClassicWrath or Bartender4.GameType.ClassicCata or Bartender4.GameType.ClassicMists) and { stealth = 7, shadowdance = 8 } or { stealth = 7 },
				WARRIOR = (Bartender4.GameType.Forever or (Bartender4.GameType.Classic and not Bartender4.GameType.ClassicMists)) and { battle = 7, def = 8, berserker = 9 } or nil,
				PRIEST = (Bartender4.GameType.Classic or Bartender4.GameType.Forever) and { shadowform = 7 } or nil,
				EVOKER = { soar = 7 },
				MONK = Bartender4.GameType.ClassicMists and { tiger = 7, ox = 8, serpent = 9 } or nil,
			},
		},
		visibility = {
			vehicleui = false,
			overridebar = false,
		},
	},
	[7] = {
		enabled = false,
	},
	[8] = {
		enabled = false,
	},
	[9] = {
		enabled = false,
	},
	[10] = {
		enabled = false,
	},
	[13] = {
		enabled = false,
	},
	[14] = {
		enabled = false,
	},
	[15] = {
		enabled = false,
	},
}

local LIST_ACTIONBARS = Bartender4.Features.MainlineBarLayout and { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 14, 15 } or { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
BT4ActionBars.LIST_ACTIONBARS = LIST_ACTIONBARS

local BINDING_MAPPINGS = {
	[1] = "ACTIONBUTTON%d",
	[3] = "MULTIACTIONBAR3BUTTON%d",
	[4] = "MULTIACTIONBAR4BUTTON%d",
	[5] = "MULTIACTIONBAR2BUTTON%d",
	[6] = "MULTIACTIONBAR1BUTTON%d",
	[13] = "MULTIACTIONBAR5BUTTON%d",
	[14] = "MULTIACTIONBAR6BUTTON%d",
	[15] = "MULTIACTIONBAR7BUTTON%d",
}

local NATIVE_BAR_NAMES = {
	[1] = "Action",
	[3] = "MultiBarRight",
	[4] = "MultiBarLeft",
	[5] = "MultiBarBottomRight",
	[6] = "MultiBarBottomLeft",
	[13] = "MultiBar5",
	[14] = "MultiBar6",
	[15] = "MultiBar7",
}

local NATIVE_BAR_IDS = {}
for id, name in pairs(NATIVE_BAR_NAMES) do
	NATIVE_BAR_IDS[name] = id
end


local defaults = {
	profile = {
		actionbars = abdefaults,
	}
}

local ActionBar_MT = {__index = Bartender4.ActionBar}

-- export defaults for other modules
Bartender4.ActionBar.defaults = abdefaults['**']

function BT4ActionBars:OnInitialize()
	self.db = Bartender4.db:RegisterNamespace("ActionBars", defaults)
end

-- setup the 10 actionbars
local first = true
function BT4ActionBars:OnEnable()
	if first then
		self.playerclass = select(2, UnitClass("player"))
		self.actionbars = {}

		for _, i in ipairs(LIST_ACTIONBARS) do
			local config = self.db.profile.actionbars[i]
			if config.enabled then
				self.actionbars[i] = self:Create(i, config, BINDING_MAPPINGS[i])
			else
				self:CreateBarOption(i, self.disabledoptions)
			end
		end

		first = nil
	end

	self:RegisterEvent("UPDATE_BINDINGS", "ReassignBindings")
	if Bartender4.Features.HoldToCast then
		self:RegisterEvent("CVAR_UPDATE")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:ReassignBindings()

	LSM.RegisterCallback(self, "LibSharedMedia_Registered", function(mtype, key)
		if mtype == "font" then
			for k, bar in pairs(self.actionbars) do
				if bar.config.elements.hotkey.font == key or bar.config.elements.count.font == key or bar.config.elements.macro.font == key then
					bar:UpdateButtonConfig()
				end
			end
		end
	end)

	if Masque then
		self.MasqueFlyoutGroup = Masque:Group("Bartender4", "Flyout")
		for _, button in pairs(LAB10.FlyoutButtons) do
			button:AddToMasque(self.MasqueFlyoutGroup)
		end

		LAB10:RegisterCallback("OnFlyoutButtonCreated", function(event, button) button:AddToMasque(self.MasqueFlyoutGroup) end)
	end

	if EventRegistry then
		EventRegistry:RegisterCallback("HouseEditor.StateUpdated", function(_, state) self:HousingStateChanged(state) end, self)
	end
end

function BT4ActionBars:SetupOptions()
	if not self.options then
		-- empty table to hold the bar options
		self.options = {}

		-- template for disabled bars
		self.disabledoptions = {
			general = {
				type = "group",
				name = L["General Settings"],
				cmdInline = true,
				order = 1,
				args = {
					enabled = {
						type = "toggle",
						name = L["Enabled"],
						desc = L["Enable/Disable the bar."],
						set = function(info, v) if v then BT4ActionBars:EnableBar(info[2]) end end,
						get = function() return false end,
					}
				}
			}
		}

		-- iterate over bars and create their option tables
		for _, i in ipairs(LIST_ACTIONBARS) do
			local config = self.db.profile.actionbars[i]
			if config.enabled then
				self:CreateBarOption(i)
			else
				self:CreateBarOption(i, self.disabledoptions)
			end
		end
	end
end

-- Applys the config in the current profile to all active Bars
function BT4ActionBars:ApplyConfig()
	for _, i in ipairs(LIST_ACTIONBARS) do
		local config = self.db.profile.actionbars[i]
		-- make sure the bar has its current config object if it exists already
		if self.actionbars[i] then
			self.actionbars[i].config = config
		end
		if config.enabled then
			self:EnableBar(i)
		else
			self:DisableBar(i)
		end
	end

	if LibStub("LibActionButton-1.0").flyoutHandler then
		LibStub("LibActionButton-1.0").flyoutHandler.Background:SetShown(Bartender4.db.profile.flyoutBackground)
	end

	if Bartender4.Features.HoldToCast then
		self:ReassignBindings()
	end
end

-- we do not allow to disable the actionbars module
function BT4ActionBars:ToggleModule()
	return
end

function BT4ActionBars:UpdateButtons(force)
	for i,v in ipairs(self.actionbars) do
		for j,button in ipairs(v.buttons) do
			button:UpdateAction(force)
		end
	end
end

local function MigrateKeybindBindings(target, ...)
	local needSaving = false
	for k=1, select('#', ...) do
		local key = select(k, ...)
		if key and key ~= "" then
			SetBindingClick(key, target, "Keybind")
			needSaving = true
		end
	end
	return needSaving
end

function BT4ActionBars:HousingStateChanged(state)
	self.InHousing = state
	if state and self.actionbars then
		for id in pairs(BINDING_MAPPINGS) do
			local frame = self.actionbars[id]
			if frame then
				ClearOverrideBindings(frame)
			end
		end
	elseif not state then
		self:ReassignBindings()
	end
end

function BT4ActionBars:SupportsNativeHoldToCast(id)
	local prefix = NATIVE_BAR_NAMES[tonumber(id)]
	return (prefix and _G[prefix .. "Button1"] ~= nil) or false
end

function BT4ActionBars:IsNativeHoldToCastBlocked(bar)
	local config = bar and bar.config
	return (config and (config.mouseover or config.autoassist or (config.buttonOffset or 0) > 0)) or false
end

-- Press and Hold Casting (ActionButtonUseKeyHeldSpell) only runs its repeat
-- loop on Blizzard's native ACTIONBUTTON / MULTIACTIONBAR bindings. When active,
-- leave supported bars on their native bindings (unless disabled per-bar or using
-- BT4-only features like mouseover, auto-assist, or button offset) and mirror
-- the pressed state.
function BT4ActionBars:UseNativeHoldToCast(bar)
	if not (Bartender4.Features.HoldToCast
		and Bartender4.db.profile.nativeHoldToCast
		and GetCVarBool("ActionButtonUseKeyHeldSpell")) then
		return false
	end
	if bar then
		if bar.disabled then return false end
		if not self:SupportsNativeHoldToCast(bar.id) then return false end
		if bar.config and bar.config.holdToCast == false then return false end
		if self:IsNativeHoldToCastBlocked(bar) then return false end
	end
	return true
end

local function SetAttributeIfChanged(frame, name, value)
	if frame:GetAttribute(name) ~= value then
		frame:SetAttribute(name, value)
	end
end

function BT4ActionBars:SyncNativeHoldAttributes(bar, restore)
	local prefix = NATIVE_BAR_NAMES[tonumber(bar.id)]
	if not prefix then return end
	local checkSelf = restore or (Bartender4.db.profile.selfcastmodifier and true or nil)
	local checkFocus = restore or (Bartender4.db.profile.focuscastmodifier and true or nil)
	local checkMouseover = restore and true or nil
	for i = 1, 12 do
		local button = _G[prefix .. "Button" .. i]
		if button then
			SetAttributeIfChanged(button, "checkselfcast", checkSelf)
			SetAttributeIfChanged(button, "checkfocuscast", checkFocus)
			SetAttributeIfChanged(button, "checkmouseovercast", checkMouseover)
		end
	end
end

function BT4ActionBars:SyncNativeHoldBar(bar, active)
	if active then
		local barNum = tonumber(bar.id)
		local prefix = NATIVE_BAR_NAMES[barNum]
		if not (prefix and _G[prefix .. "Button1"]) then return end

		if not bar.nativeHoldRefsAttached then
			for i = 1, 12 do
				bar:SetFrameRef("nativebutton" .. i, _G[prefix .. "Button" .. i])
			end
			bar:SetAttribute("nativepage", barNum)
			bar.nativeHoldRefsAttached = true
		end

		SetAttributeIfChanged(bar, "nativebuttons", 12)

		local page = tonumber(bar:GetAttribute("state"))
		if not page or page == 0 then
			page = barNum
		end
		for i = 1, 12 do
			local button = _G[prefix .. "Button" .. i]
			if button then
				SetAttributeIfChanged(button, "actionpage", page)
			end
		end
		self:SyncNativeHoldAttributes(bar, false)
		bar.nativeHoldActive = true
	elseif bar.nativeHoldActive then
		SetAttributeIfChanged(bar, "nativebuttons", nil)
		self:SyncNativeHoldAttributes(bar, true)
		if bar.buttons then
			for _, button in ipairs(bar.buttons) do
				if button.BT4NativePushedOverlay then
					button.BT4NativePushedOverlay:Hide()
				end
			end
		end
		bar.nativeHoldActive = nil
	end
end

function BT4ActionBars:UpdateNativeHoldHooks(active)
	if active then
		if ActionButtonDown and ActionButtonUp then
			if not self:IsHooked("ActionButtonDown") then
				self:SecureHook("ActionButtonDown")
			end
			if not self:IsHooked("ActionButtonUp") then
				self:SecureHook("ActionButtonUp")
			end
		end
		if MultiActionButtonDown and MultiActionButtonUp then
			if not self:IsHooked("MultiActionButtonDown") then
				self:SecureHook("MultiActionButtonDown")
			end
			if not self:IsHooked("MultiActionButtonUp") then
				self:SecureHook("MultiActionButtonUp")
			end
		end
	else
		if self:IsHooked("ActionButtonDown") then self:Unhook("ActionButtonDown") end
		if self:IsHooked("ActionButtonUp") then self:Unhook("ActionButtonUp") end
		if self:IsHooked("MultiActionButtonDown") then self:Unhook("MultiActionButtonDown") end
		if self:IsHooked("MultiActionButtonUp") then self:Unhook("MultiActionButtonUp") end
	end
end

-- Mirror the pressed look with a texture overlay rather than SetButtonState:
-- changing button state during the hold loop causes repeated click sounds.
local function ShowNativePushedOverlay(button)
	local overlay = button.BT4NativePushedOverlay
	if overlay and overlay:IsShown() then return end

	local pushed = button:GetPushedTexture()
	if not pushed then return end

	if not overlay then
		overlay = button:CreateTexture(nil, "ARTWORK")
		button.BT4NativePushedOverlay = overlay
	end

	local layer, sublevel = pushed:GetDrawLayer()
	overlay:SetDrawLayer(layer or "ARTWORK", sublevel or 0)
	local atlas = pushed.GetAtlas and pushed:GetAtlas()
	if atlas then
		overlay:SetAtlas(atlas)
	else
		overlay:SetTexture(pushed:GetTexture())
		overlay:SetTexCoord(pushed:GetTexCoord())
	end
	overlay:SetBlendMode(pushed:GetBlendMode())
	overlay:SetVertexColor(pushed:GetVertexColor())
	overlay:SetAlpha(pushed:GetAlpha())
	overlay:ClearAllPoints()
	overlay:SetAllPoints(pushed:GetNumPoints() > 0 and pushed or button)
	overlay:Show()
end

function BT4ActionBars:MirrorNativeButtonState(barId, id, down)
	local bar = self.actionbars and self.actionbars[barId]
	local button = bar and bar.buttons and bar.buttons[id]
	if not button then return end

	local barBlocked = (barId == 1)
		and ((C_PetBattles and C_PetBattles.IsInBattle()) or (OverrideActionBar and OverrideActionBar:IsVisible()))
	if down and not barBlocked and self:UseNativeHoldToCast(bar) then
		ShowNativePushedOverlay(button)
	elseif button.BT4NativePushedOverlay then
		button.BT4NativePushedOverlay:Hide()
	end
end

function BT4ActionBars:ActionButtonDown(id)
	self:MirrorNativeButtonState(1, id, true)
end

function BT4ActionBars:ActionButtonUp(id)
	self:MirrorNativeButtonState(1, id, false)
end

function BT4ActionBars:MultiActionButtonDown(barName, id)
	local barId = NATIVE_BAR_IDS[barName]
	if barId then
		self:MirrorNativeButtonState(barId, id, true)
	end
end

function BT4ActionBars:MultiActionButtonUp(barName, id)
	local barId = NATIVE_BAR_IDS[barName]
	if barId then
		self:MirrorNativeButtonState(barId, id, false)
	end
end

function BT4ActionBars:CVAR_UPDATE(_, cvar)
	if cvar and cvar:lower() == "actionbuttonusekeyheldspell" then
		self:ReassignBindings()
	end
end

function BT4ActionBars:PLAYER_REGEN_ENABLED()
	if self.pendingReassignBindings then
		self:ReassignBindings()
	end
end

local s_inReassignBindings = false
function BT4ActionBars:ReassignBindings()
	if InCombatLockdown() then
		self.pendingReassignBindings = true
		return
	end
	if s_inReassignBindings or self.InHousing then return end
	self.pendingReassignBindings = nil
	s_inReassignBindings = true

	if self.actionbars then
		local anyNativeHold = false
		for id, mapping in pairs(BINDING_MAPPINGS) do
			local frame = self.actionbars[id]
			if frame then
				ClearOverrideBindings(frame)
				local useNative = self:UseNativeHoldToCast(frame)
				self:SyncNativeHoldBar(frame, useNative)
				if useNative then
					anyNativeHold = true
				else
					for i = 1, min(#frame.buttons, 12) do
						local button, real_button = mapping:format(i), frame.buttons[i]:GetName()
						for k=1, select('#', GetBindingKey(button)) do
							local key = select(k, GetBindingKey(button))
							if key and key ~= "" then
								SetOverrideBindingClick(frame, false, key, real_button, "Keybind")
							end
						end
					end
				end
			end
		end
		if Bartender4.Features.HoldToCast then
			self:UpdateNativeHoldHooks(anyNativeHold)
		end
	end

	-- re-assign bindings from LeftButton to Keybind buttons
	local needSaving = false
	for i = 1,180 do
		local button = ("BT4Button%d"):format(i)
		local clickbutton = ("CLICK %s:LeftButton"):format(button)
		if MigrateKeybindBindings(button, GetBindingKey(clickbutton)) then
			needSaving = true
		end
	end

	if needSaving then
		SaveBindings(GetCurrentBindingSet())
	end

	s_inReassignBindings = false
end

BT4ActionBars.BLIZZARD_BAR_MAP = {
	[6] = 2,
	[5] = 3,
	[3] = 4,
	[4] = 5,
	[13] = 6,
	[14] = 7,
	[15] = 8,
}

function BT4ActionBars:GetBarName(id)
	if Bartender4.Features.MainlineBarLayout then
		local barID = tonumber(id)
		if barID == 7 or barID == 8 or barID == 9 or barID == 10 then
			return (L["Class Bar %d"]):format(barID - 6)
		elseif self.BLIZZARD_BAR_MAP[barID] then
			return (L["Bar %s"]):format(tostring(self.BLIZZARD_BAR_MAP[barID]))
		elseif barID == 2 then
			return L["Bonus Action Bar"]
		end
	end
	return (L["Bar %s"]):format(id)
end

-- Creates a new bar object based on the id and the specified config
function BT4ActionBars:Create(id, config, bindingmapping)
	id = tostring(id)
	local bar = setmetatable(Bartender4.StateBar:Create(id, config, self:GetBarName(id)), ActionBar_MT)
	bar.module = self
	bar.bindingmapping = bindingmapping

	bar:SetScript("OnEvent", bar.OnEvent)
	if not Bartender4.GameType.Classic or Bartender4.GameType.ClassicCata or Bartender4.GameType.ClassicMists then
		bar:RegisterEvent("PLAYER_TALENT_UPDATE")
		bar:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	end

	bar:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")
	bar:RegisterEvent("PLAYER_REGEN_ENABLED")

	self:CreateBarOption(id)

	bar:ApplyConfig()

	return bar
end

function BT4ActionBars:DisableBar(id)
	id = tonumber(id)
	local bar = self.actionbars[id]
	if not bar then return end

	bar.config.enabled = false
	bar:Disable()
	self:CreateBarOption(id, self.disabledoptions)
	if Bartender4.Features.HoldToCast then
		self:ReassignBindings()
	end
end

function BT4ActionBars:EnableBar(id)
	id = tonumber(id)
	local bar = self.actionbars[id]
	local config = self.db.profile.actionbars[id]
	config.enabled = true
	if not bar then
		bar = self:Create(id, config, BINDING_MAPPINGS[id])
		self.actionbars[id] = bar
	else
		bar.disabled = nil
		self:CreateBarOption(id)
		bar:ApplyConfig(config)
	end
	if Bartender4.Features.HoldToCast then
		self:ReassignBindings()
	end
	if not Bartender4.Locked then
		bar:Unlock()
	end
end

function BT4ActionBars:GetAll()
	return pairs(self.actionbars)
end

function BT4ActionBars:ForAll(method, ...)
	for _, bar in self:GetAll() do
		local func = bar[method]
		if func then
			func(bar, ...)
		end
	end
end

function BT4ActionBars:ForAllButtons(...)
	self:ForAll("ForAll", ...)
end
