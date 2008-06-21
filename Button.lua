--[[
	Action Button Template
]]

--[[ $Id$ ]]

local Button = CreateFrame("CheckButton")
Button.BT4 = true
local Button_MT = {__index = Button}

local onEnter, onUpdate

-- upvalues
local _G = _G
local format = string.format
local IsUsableAction = IsUsableAction
local IsActionInRange = IsActionInRange

local LBF = LibStub("LibButtonFacade", true)
local KeyBound = LibStub("LibKeyBound-1.0")

Bartender4.Button = {}
Bartender4.Button.prototype = Button
function Bartender4.Button:Create(id, parent)
	local absid = (parent.id - 1) * 12 + id
	local name =  ("BT4Button%d"):format(absid)
	local button = setmetatable(CreateFrame("CheckButton", name, parent, "ActionBarButtonTemplate"), Button_MT)
	button.rid = id
	button.id = absid
	button.parent = parent
	
	button.hotkey = _G[("%sHotKey"):format(name)]
	button.icon = _G[("%sIcon"):format(name)]
	button.flash = _G[("%sFlash"):format(name)]
	button.macroName = _G[("%sName"):format(name)]
	
	button:SetNormalTexture("")
	local oldNT = _G[("%sNormalTexture"):format(name)]
	oldNT:Hide()
	
	button.normalTexture = button:CreateTexture(("%sBTNT"):format(name))
	button.normalTexture:SetAllPoints(oldNT)
	button.SetNormalTexture = function(...) button.normalTexture:SetTexture(...) end
	button.GetNormalTexture = function() return button.normalTexture end
	
	button:SetAttribute("action", absid)
	button:SetID(0)
	button:ClearAllPoints()
	button:SetAttribute("useparent-unit", true)
	button:SetAttribute("useparent-statebutton", true)
	button:SetAttribute("useparent-actionbar", nil)
	button:SetScript('OnEnter', onEnter)
	button:SetScript('OnUpdate', onUpdate)
	
	if LBF and parent.LBFGroup then
		parent.LBFGroup:AddButton(button)
	end
	
	button:Update()
	button:UpdateHotkey()
	
	return button
end

function onEnter(self)
	if not (Bartender4.db.profile.tooltip == "nocombat" and InCombatLockdown()) and Bartender4.db.profile.tooltip ~= "disabled" then
		ActionButton_SetTooltip(self)
	end
	KeyBound:Set(self)
end

local oor, oorcolor, oomcolor

function onUpdate(self, elapsed)
	if ( self.flashing == 1 ) then
		self.flashtime = self.flashtime - elapsed;
		if ( self.flashtime <= 0 ) then
			local overtime = -self.flashtime
			if ( overtime >= ATTACK_BUTTON_FLASH_TIME ) then
				overtime = 0
			end
			self.flashtime = ATTACK_BUTTON_FLASH_TIME - overtime

			local flashTexture = self.flash
			if ( flashTexture:IsShown() ) then
				flashTexture:Hide()
			else
				flashTexture:Show()
			end
		end
	end
	
	if ( self.rangeTimer ) then
		self.rangeTimer = self.rangeTimer - elapsed
		
		if self.rangeTimer <= 0 then
			local valid = IsActionInRange(self.action)
			local shown = (self.hotkey:GetText() == RANGE_INDICATOR and oor == "hotkey")
			if valid and shown then 
				self.hotkey:Show() 
			elseif shown then
				self.hotkey:Hide()
			end
			self.outOfRange = (valid == 0)
			self:UpdateUsable()
			self.rangeTimer = TOOLTIP_UPDATE_TIME
		end
	end
end

function Button:SetStateAction(state, action)
	
	self:SetAttribute(("*type-S%d"):format(state), "action")
	self:SetAttribute(("*type-S%dRight"):format(state), "action")
	
	if self.parent.config.autoassist then
		local type, id, subtype = GetActionInfo(action)
		if type == "spell" then
			local spellName, spellRank = GetSpellInfo(id, subtype)
			
			local macroText
			if IsHelpfulSpell(id, subtype) then
				macroText = "/cast %s[help] [target=targettarget, help] [target=none]"
				
				-- Hack to get Selfcast working with macrotext syntax
				local selfcast = ""
				if Bartender4.db.profile.selfcastrightclick then
					selfcast = selfcast .. "[button:2, target=player]"
				end
				if Bartender4.db.profile.selfcastmodifier then
					selfcast = selfcast .. "[modifier:".. GetModifiedClick("SELFCAST").. ", target=player]"
				end
				macroText = macroText:format(selfcast)
			elseif IsHarmfulSpell(id, subtype) then
				macroText = "/cast [harm] [target=targettarget, harm] [target=none]"
			end
			
			if macroText then
				self:SetAttribute(("*type-S%d"):format(state), "macro")
				self:SetAttribute(("*type-S%dRight"):format(state), "macro")
				macroText = ("%s%s(%s)"):format(macroText, spellName, spellRank)
			
				self:SetAttribute(("*macrotext-S%d"):format(state), macroText)
				self:SetAttribute(("*macrotext-S%dRight"):format(state), macroText)
			end
		end
	end
	
	self:SetAttribute(("*action-S%d"):format(state), action)
	self:SetAttribute(("*action-S%dRight"):format(state), action)
end

function Button:GetActionID()
	return self.action
end

function Button:BlizzCall(func, ...)
	local oldThis = this
	this = self
	func(...)
	this = oldThis
end

orig_ActionButton_UpdateUsable = ActionButton_UpdateUsable
ActionButton_UpdateUsable = function(...) if this.BT4 then this:UpdateUsable() else return orig_ActionButton_UpdateUsable(...) end end
function Button:UpdateUsable()
	local isUsable, notEnoughMana = IsUsableAction(self.action)
	local icon, hotkey = self.icon, self.hotkey
	if not oor then 
		oor = Bartender4.db.profile.outofrange
		oorcolor, oomcolor = Bartender4.db.profile.colors.range, Bartender4.db.profile.colors.mana
	end
	
	if oor == "button" and self.outOfRange then
		icon:SetVertexColor(oorcolor.r, oorcolor.g, oorcolor.b)
		hotkey:SetVertexColor(1.0, 1.0, 1.0)
	else
		if oor == "hotkey" and self.outOfRange then
			hotkey:SetVertexColor(oorcolor.r, oorcolor.g, oorcolor.b)
		else
			hotkey:SetVertexColor(1.0, 1.0, 1.0)
		end
		
		if isUsable then
			icon:SetVertexColor(1.0, 1.0, 1.0)
		elseif notEnoughMana then
			icon:SetVertexColor(oomcolor.r, oomcolor.g, oomcolor.b)
		else
			icon:SetVertexColor(0.4, 0.4, 0.4)
		end
	end
end

function Button:Update()
	oor = nil
	self:BlizzCall(ActionButton_Update)
	if self.parent.config.hidemacrotext then
		self.macroName:Hide()
	else
		self.macroName:Show()
	end
end

orig_ActionButton_UpdateHotkeys = ActionButton_UpdateHotkeys
ActionButton_UpdateHotkeys = function(...) if this.BT4 then Button.UpdateHotkey(this) else orig_ActionButton_UpdateHotkeys(...) end end
function Button:UpdateHotkey()
	local key = self:GetHotkey() or ""
	local hotkey = self.hotkey
	
	if key == "" or self.parent.config.hidehotkey or not HasAction(self.action) then
		hotkey:SetText(RANGE_INDICATOR)
		hotkey:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -2)
		hotkey:Hide()
	else
		hotkey:SetText(key)
		hotkey:SetPoint("TOPLEFT", self, "TOPLEFT", -2, -2)
		hotkey:Show()
	end
end

function Button:GetHotkey()
	local key = ((self.id <= 12) and GetBindingKey(format("ACTIONBUTTON%d", self.id))) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
	return key and KeyBound:ToShortKey(key)
end

function Button:GetBindings()
	local keys, binding = ""
	
	if self.id <= 12 then
		binding = format("ACTIONBUTTON%d", self.id)
		for i = 1, select('#', GetBindingKey(binding)) do
			local hotKey = select(i, GetBindingKey(binding))
			if keys ~= "" then
				keys = keys .. ', ' 
			end
			keys = keys .. GetBindingText(hotKey,'KEY_')
		end
	end
	
	binding = "CLICK "..self:GetName()..":LeftButton"
	for i = 1, select('#', GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys ~= "" then
			keys = keys .. ', ' 
		end
		keys = keys .. GetBindingText(hotKey,'KEY_')
	end

	return keys
end

function Button:SetKey(key)
	if self.id <= 12 then
		SetBinding(key, format("ACTIONBUTTON%d", self.id))
	else
		SetBindingClick(key, self:GetName(), 'LeftButton')
	end
end

function Button:ClearBindings()
	if self.id <= 12 then
		local binding = format("ACTIONBUTTON%d", self.id)
		while GetBindingKey(binding) do
			SetBinding(GetBindingKey(binding), nil)
		end
	end
	local binding = "CLICK "..self:GetName()..":LeftButton"
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
end

local actionTmpl = "BT4 Bar %d Button %d"
function Button:GetActionName()
	return format(actionTmpl, self.parent.id, self.rid)
end

function Button:ShowGrid()
	if not self.gridShown then
		self.gridShown = true
		self:SetAttribute("showgrid", self:GetAttribute("showgrid") + 1)
	end
	ActionButton_ShowGrid(self)
end

function Button:HideGrid()
	if self.gridShown then
		self.gridShown = nil
		self:SetAttribute("showgrid", self:GetAttribute("showgrid") - 1)
	end
	ActionButton_HideGrid(self)
end

function Button:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end
