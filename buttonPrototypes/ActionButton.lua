--[[
	Action Button Template
]]

--[[ $Id$ ]]

local Button = CreateFrame("CheckButton")
local Button_MT = {__index = Button}

local onEnter, onLeave, onUpdate, onDragStart, onReceiveDrag

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
	local button = setmetatable(CreateFrame("CheckButton", name.."Secure", parent, "SecureActionButtonTemplate"), Button_MT)
	button.rid = id
	button.id = absid
	button.parent = parent
	button.stateactions = {}
	
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(parent:GetFrameLevel() + 2)
	button:SetWidth(36)
	button:SetHeight(36)
	
	button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	button:GetHighlightTexture():SetBlendMode("ADD")
	button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
	button:GetCheckedTexture():SetBlendMode("ADD")
	button:SetNormalTexture("")
	
	button.Proxy = CreateFrame("CheckButton", name, button, "ActionButtonTemplate")
	button.Proxy:SetFrameStrata("MEDIUM")
	button.Proxy:SetFrameLevel(parent:GetFrameLevel() + 1)
	button.Proxy:ClearAllPoints()
	button.Proxy:SetAllPoints(button)
	button.Proxy:SetPushedTexture("")
	button.Proxy:SetHighlightTexture("")
	button.Proxy:SetCheckedTexture("")
	button.Proxy:Show()
	button.Proxy.Secure = button
	
	local NormalTexture = button.Proxy:GetNormalTexture()
	NormalTexture:SetWidth(66)
	NormalTexture:SetHeight(66)
	NormalTexture:ClearAllPoints()
	NormalTexture:SetPoint("CENTER", 0, -1)
	NormalTexture:Show()
	
	button.normalTexture = NormalTexture
	button.pushedTexture = button:GetPushedTexture()
	button.highlightTexture = button:GetHighlightTexture()
	
	button:SetScript("OnEvent", button.EventHandler)
	button:SetScript("OnUpdate", onUpdate)
	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)
	button:SetScript("OnAttributeChanged", button.UpdateAction)
	button:SetScript("OnDragStart", onDragStart)
	button:SetScript("OnReceiveDrag", onReceiveDrag)
	button:SetScript("PostClick", button.UpdateState)
	
	button.icon = _G[("%sIcon"):format(name)]
	button.border = _G[("%sBorder"):format(name)]
	button.cooldown = _G[("%sCooldown"):format(name)]
	button.macroName = _G[("%sName"):format(name)]
	button.hotkey = _G[("%sHotKey"):format(name)]
	button.count = _G[("%sCount"):format(name)]
	button.flash = _G[("%sFlash"):format(name)]
	button.flash:Hide()
	
	button.textureCache = {}
	button.textureCache.pushed = button.pushedTexture:GetTexture()
	button.textureCache.highlight = button.highlightTexture:GetTexture()
	
	button:SetAttribute("type", "action")
	button:SetAttribute("action", absid)
	
	button:SetAttribute("useparent-unit", true)
	--button:SetAttribute("hidestates", "-1")
	
	parent:SetAttribute('_adopt', button)
	button:SetAttribute('_childupdate-state', [[
		-- evil hack due to bug in the code
		scriptid, message = message, scriptid
		self:SetAttribute("state", message)
		local type = self:GetAttribute("type--" .. message)
		if type == "macro" then
			self:SetAttribute("macrotext", self:GetAttribute("macrotext--" .. message))
		end
		self:SetAttribute("type", type)
		self:SetAttribute("action", self:GetAttribute("action--" .. message))
	]])
	
	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks("AnyUp")
	
	button.showgrid = 0
	button.flashing = 0
	button.flashtime = 0
	
	button:RegisterButtonEvents()
	
	if LBF and parent.LBFGroup then
		local group = parent.LBFGroup
		button.LBFButtonData = {
			Button = button.Proxy,
			Highlight = button:GetHighlightTexture(),
			Pushed = button:GetPushedTexture(),
			Checked = button:GetCheckedTexture(),
		}
		group:AddButton(button.Proxy, button.LBFButtonData)
	end
	return button
end

function Button:SetLevels()
	local parent = self:GetParent()
	self:SetFrameLevel(parent:GetFrameLevel() + 3)
	self.Proxy:SetFrameLevel(parent:GetFrameLevel() + 2)
end

function onDragStart(self)
	if InCombatLockdown() then return end
	if not Bartender4.db.profile.buttonlock or IsModifiedClick("PICKUPACTION") then
		PickupAction(self.action)
		self:UpdateState()
		self:UpdateFlash()
		self:RefreshStateAction()
	end
end

function onReceiveDrag(self)
	if InCombatLockdown() then return end
	PlaceAction(self.action)
	self:UpdateState()
	self:UpdateFlash()
	self:RefreshStateAction()
end

function onEnter(self)
	if not (Bartender4.db.profile.tooltip == "nocombat" and InCombatLockdown()) and Bartender4.db.profile.tooltip ~= "disabled" then
		self:SetTooltip()
	end
	KeyBound:Set(self)
end

function onLeave()
	GameTooltip:Hide()
end

local oor, oorcolor, oomcolor

function onUpdate(self, elapsed)
	if self.flashing == 1 then
		self.flashtime = self.flashtime - elapsed
		if self.flashtime <= 0 then
			local overtime = -self.flashtime
			if overtime >= ATTACK_BUTTON_FLASH_TIME then
				overtime = 0
			end
			self.flashtime = ATTACK_BUTTON_FLASH_TIME - overtime
			
			local flashTexture = self.flash
			if flashTexture:IsVisible() then
				flashTexture:Hide()
			else
				flashTexture:Show()
			end
		end
	end
	
	if self.rangeTimer then
		self.rangeTimer = self.rangeTimer - elapsed
		if self.rangeTimer <= 0 then
			local valid = IsActionInRange(self.action)
			local hotkey = self.hotkey
			local hkshown = (hotkey:GetText() == RANGE_INDICATOR and oor == "hotkey")
			if valid and hkshown then 
				hotkey:Show() 
			elseif hkshown then
				hotkey:Hide()
			end
			self.outOfRange = (valid == 0)
			self:UpdateUsable()
			self.rangeTimer = TOOLTIP_UPDATE_TIME
		end
	end
end

function Button:ClearStateAction()
	for state in pairs(self.stateactions) do
		self.stateactions = {}
		for i=0,10 do
			self:SetAttribute("type--" .. i, nil)
			self:SetAttribute("action--" .. i, nil)
			self:SetAttribute("macrotext--" .. i, nil)
		end
	end
end

function Button:SetStateAction(state, action)
	self.stateactions[state] = action
	self:RefreshStateAction(state)
end

function Button:RefreshAllStateActions()
	self.stateconfig = {}
	for state in pairs(self.stateactions) do
		self:RefreshStateAction(state)
	end
end

function Button:RefreshStateAction(state)
	local state = tonumber(state or self:GetAttribute("state"))
	local action = self.stateactions[state]
	self:SetAttribute("type--" .. state, "action")
	self:SetAttribute("action--" .. state, action)
	
	if self.parent.config.autoassist then
		local type, id, subtype = GetActionInfo(action)
		if type == "spell" and id > 0 then
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
				self:SetAttribute("type--" .. state, "macro")
				local macrotext = ("%s%s(%s)"):format(macroText, spellName, spellRank)
				self:SetAttribute("macrotext--" .. state, macrotext)
			end
		end
	end
end

function Button:CalculateAction()
	return SecureButton_GetModifiedAttribute(self, "action", SecureButton_GetEffectiveButton(self)) or 1
end

function Button:GetActionID()
	return self.action
end

function Button:UpdateAction(force)
	local action = self:CalculateAction()
	if action ~= self.action or force then
		self.action = action
		self:Update()
	end
end

function Button:Update()
	local action = self.action
	self:UpdateIcon()
	self:UpdateCount()
	self:UpdateHotkeys()
	if ( HasAction(action) ) then
		self:RegisterActionEvents()
		
		self:UpdateState()
		self:UpdateUsable(true)
		self:UpdateCooldown()
		self:UpdateFlash()
		
		self:ShowButton()
		self:SetScript("OnUpdate", onUpdate)
	else
		self:UnregisterActionEvents()
		
		self.cooldown:Hide()
		
		if ( self.showgrid == 0 and not self.parent.config.showgrid ) then
			self:HideButton()
		end
		
		self:SetScript("OnUpdate", nil)
	end
	
	if ( IsEquippedAction(action) ) then
		self.border:SetVertexColor(0, 1.0, 0, 0.75)
		self.border:Show()
	else
		self.border:Hide()
	end
	
	if ( GameTooltip:GetOwner() == self) then
		self:SetTooltip()
	end
	
	if not IsConsumableAction(action) and not IsStackableAction(action) and not self.parent.config.hidemacrotext then
		self.macroName:SetText(GetActionText(action))
	else
		self.macroName:SetText("")
	end
	
end

function Button:UpdateIcon()
	local texture = GetActionTexture(self.action)
	if ( texture ) then
		self.rangeTimer = -1
		self.icon:SetTexture(texture)
		self.icon:Show()
		self.normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
		self.normalTexture:SetTexCoord(0, 0, 0, 0)
		self.iconTex = texture
	else
		self.rangeTimer = nil
		self.icon:Hide()
		self.cooldown:Hide()
		self.normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot")
		self.normalTexture:SetTexCoord(-0.15, 1.15, -0.15, 1.17)
		self.hotkey:SetVertexColor(0.6, 0.6, 0.6)
		self.iconTex = nil
	end
	if self.parent.config.hidemacrotext then
		self.macroName:Hide()
	else
		self.macroName:Show()
	end
end

function Button:UpdateCount()
	local action = self.action
	if ( IsConsumableAction(action) or IsStackableAction(action) ) then
		self.count:SetText(GetActionCount(action))
	else
		self.count:SetText("")
	end
end

function Button:UpdateHotkeys()
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

function Button:UpdateState()
	local action = self.action
	if ( IsCurrentAction(action) or IsAutoRepeatAction(action) ) then
		self:SetChecked(1)
	else
		self:SetChecked(0)
	end
end

function Button:UpdateUsable(force)
	local isUsable, notEnoughMana = IsUsableAction(self.action)
	local icon, hotkey = self.icon, self.hotkey
	if force or not oor then 
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

function Button:UpdateCooldown()
	local start, duration, enable = GetActionCooldown(self.action)
	CooldownFrame_SetTimer(self.cooldown, start, duration, enable)
end

function Button:UpdateFlash()
	local action = self.action
	if ( (IsAttackAction(action) and IsCurrentAction(action)) or IsAutoRepeatAction(action) ) then
		self:StartFlash()
	else
		self:StopFlash()
	end
end

function Button:StartFlash()
	self.flashing = 1
	self.flashtime = 0
	self:UpdateState()
end

function Button:StopFlash()
	self.flashing = 0
	self.flash:Hide()
	self:UpdateState()
end

function Button:SetTooltip()
	if ( GetCVar("UberTooltips") == "1" ) then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	
	if ( GameTooltip:SetAction(self.action) ) then
		self.UpdateTooltip = self.SetTooltip
	else
		self.UpdateTooltip = nil
	end
end

function Button:ShowButton()
	if self.Proxy:IsShown() then return end
	self.pushedTexture:SetTexture(self.textureCache.pushed)
	self.highlightTexture:SetTexture(self.textureCache.highlight)
	
	self.Proxy:Show()
end

function Button:HideButton()
	if not self.Proxy:IsShown() then return end
	self.textureCache.pushed = self.pushedTexture:GetTexture()
	self.textureCache.highlight = self.highlightTexture:GetTexture()
	
	self.pushedTexture:SetTexture("")
	self.highlightTexture:SetTexture("")
	
	self.Proxy:Hide()
end

function Button:ShowGrid()
	self.showgrid = self.showgrid + 1
	
	self:ShowButton()
end

function Button:HideGrid()
	if self.showgrid > 0 then self.showgrid = self.showgrid - 1 end
	if ( self.showgrid == 0 and not HasAction(self.action) and not self.parent.config.showgrid ) then
		self:HideButton()
	end
end

function Button:RegisterButtonEvents()
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	self:RegisterEvent("ACTIONBAR_SHOWGRID")
	self:RegisterEvent("ACTIONBAR_HIDEGRID")
	self:RegisterEvent("UPDATE_BINDINGS")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
end

local actionevents = {
	"PLAYER_TARGET_CHANGED",
	"ACTIONBAR_UPDATE_STATE",
	"ACTIONBAR_UPDATE_USABLE",
	"ACTIONBAR_UPDATE_COOLDOWN",
	--"UPDATE_INVENTORY_ALERTS",
	--"PLAYER_AURAS_CHANGED",
	"CRAFT_SHOW",
	"CRAFT_CLOSE",
	"TRADE_SKILL_SHOW",
	"TRADE_SKILL_CLOSE",
	"PLAYER_ENTER_COMBAT",
	"PLAYER_LEAVE_COMBAT",
	"START_AUTOREPEAT_SPELL",
	"STOP_AUTOREPEAT_SPELL",
}

function Button:RegisterActionEvents()
	if self.eventsregistered then return end
	self.eventsregistered = true
	
	for _, event in ipairs(actionevents) do
		self:RegisterEvent(event)
	end
end

function Button:UnregisterActionEvents()
	if not self.eventsregistered then return end
	self.eventsregistered = nil
	
	for _, event in ipairs(actionevents) do
		self:UnregisterEvent(event)
	end
end

function Button:EventHandler(event, arg1)
	if ( event == "ACTIONBAR_SLOT_CHANGED" ) then
		if ( arg1 == 0 or arg1 == self.action ) then
			self:Update()
		end
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		self:Update()
	elseif ( event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" ) then
		self:UpdateAction()
	elseif ( event == "ACTIONBAR_SHOWGRID" ) then
		self:ShowGrid()
	elseif ( event == "ACTIONBAR_HIDEGRID" ) then
		self:HideGrid()
	elseif ( event == "UPDATE_BINDINGS" ) then
		self:UpdateHotkeys()
	elseif not self.eventsregistered then
		return
	-- Action Event Handlers, only set when the button actually has an action
	elseif ( event == "PLAYER_TARGET_CHANGED" ) then
		self.rangeTimer = -1
	elseif ( event == "ACTIONBAR_UPDATE_STATE" ) then
		self:UpdateState()
	elseif ( event == "ACTIONBAR_UPDATE_USABLE" ) then
		self:UpdateUsable()
	elseif ( event == "ACTIONBAR_UPDATE_COOLDOWN" ) then
		self:UpdateCooldown()
	elseif ( event == "CRAFT_SHOW" or event == "CRAFT_CLOSE" or event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_CLOSE" ) then
		self:UpdateState()
	elseif ( event == "PLAYER_ENTER_COMBAT" ) then
		if ( IsAttackAction(self.action) ) then
			self:StartFlash()
		end
	elseif ( event == "PLAYER_LEAVE_COMBAT" ) then
		if ( IsAttackAction(self.action) ) then
			self:StopFlash()
		end
	elseif ( event == "START_AUTOREPEAT_SPELL" ) then
		if ( IsAutoRepeatAction(self.action) ) then
			self:StartFlash()
		end
	elseif ( event == "STOP_AUTOREPEAT_SPELL" ) then
		if ( self.flashing == 1 and not IsAttackAction(self.action) ) then
			self:StopFlash()
		end
	end
end

function Button:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end
