--[[
	Action Button Template
]]

--[[ $Id$ ]]

local Button = CreateFrame("CheckButton")
local Button_MT = {__index = Button}

local onLeave, onUpdate

Bartender4.Button = {}
Bartender4.Button.prototype = Button
function Bartender4.Button:Create(id, parent)
	local absid = (parent.id - 1) * 12 + id
	local name =  ("BT4Button%d"):format(absid)
	local button = setmetatable(CreateFrame("CheckButton", name, parent, "SecureActionButtonTemplate, ActionButtonTemplate"), Button_MT)
	button.parent = parent
	button.settings = parent.module.db
	
	button:SetScript("OnEvent", button.EventHandler)
	button:SetScript("OnUpdate", onUpdate)
	button:SetScript("OnEnter", button.SetTooltip)
	button:SetScript("OnLeave", onLeave)
	button:SetScript("OnAttributeChanged", button.UpdateAction)
	--button:SetScript("OnDragStart", button.OnDragStart)
	button:SetScript("PostClick", button.UpdateState)
	
	button.icon = _G[("%sIcon"):format(name)]
	button.border = _G[("%sBorder"):format(name)]
	button.cooldown = _G[("%sCooldown"):format(name)]
	button.macroName = _G[("%sName"):format(name)]
	button.hotkey = _G[("%sHotKey"):format(name)]
	button.count = _G[("%sCount"):format(name)]
	button.flash = _G[("%sFlash"):format(name)]
	button.flash:Hide()
	
	--button:SetNormalTexture("")
	--local realNormalTexture = _G[("%sNormalTexture"):format(name)]
	
	--button.normalTexture = button:CreateTexture(("%sBT4NormalTexture"):format(name))
	--button.normalTexture:SetAllPoints(realNormalTexture)
	
	--realNormalTexture:Hide()
	
	button.normalTexture = button:GetNormalTexture() -- _G[("%sNormalTexture"):format(name)]
	button.pushedTexture = button:GetPushedTexture()
	button.highlightTexture = button:GetHighlightTexture()
	
	button.textureCache = {}
	button.textureCache.pushed = button.pushedTexture:GetTexture()
	button.textureCache.highlight = button.highlightTexture:GetTexture()
	
	parent:SetAttribute("addchild", button)
	
	button:SetAttribute("type", "action")
	button:SetAttribute("action", absid)
	
	button:SetAttribute("useparent-unit", true)
	button:SetAttribute("useparent-statebutton", true)
	
	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks("AnyUp")
	
	button.showgrid = 0
	button.flashing = 0
	button.flashtime = 0
	
	button:RegisterButtonEvents()
	
	button:Show()
	button:UpdateAction(true)
	
	return button
end

function onLeave()
	GameTooltip:Hide()
end

function onUpdate(self, elapsed)
	if not self.iconTex then self:UpdateIcon() end
	
	if ( self.flashing == 1 ) then
		self.flashtime = self.flashtime - elapsed;
		if ( self.flashtime <= 0 ) then
			local overtime = -self.flashtime;
			if ( overtime >= ATTACK_BUTTON_FLASH_TIME ) then
				overtime = 0;
			end
			self.flashtime = ATTACK_BUTTON_FLASH_TIME - overtime
			
			local flashTexture = self.flash
			if ( flashTexture:IsVisible() ) then
				flashTexture:Hide()
			else
				flashTexture:Show()
			end
		end
	end
	
	if ( self.rangeTimer ) then
		self.rangeTimer = self.rangeTimer - elapsed
		if ( self.rangeTimer <= 0 ) then
			local valid = IsActionInRange(self.action)
			local hotkey = self.hotkey
			local hkshown = (hotkey:GetText() == RANGE_INDICATOR and self.settings.profile.outofrange == "hotkey")
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

function Button:CalculateAction()
	return SecureButton_GetModifiedAttribute(self, "action", SecureButton_GetEffectiveButton(self)) or 1
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
		self:UpdateUsable()
		self:UpdateCooldown()
		self:UpdateFlash()
		
		self:ShowButton()
		self:SetScript("OnUpdate", onUpdate)
	else
		self:UnregisterActionEvents()
		
		if ( self.showgrid == 0 and not self.parent.config.showgrid ) then
			self.normalTexture:Hide()
			if self.overlay then
				self.overlay:Hide()
			end
		else
			self.normalTexture:Show()
			if self.overlay then
				self.overlay:Show()
			end
		end
		
		self.cooldown:Hide()
		
		self:HideButton()
		self:SetScript("OnUpdate", nil)
	end
	
	if ( IsEquippedAction(action) ) then
		self.border:SetVertexColor(0, 1.0, 0, 0.75)
		self.border:Show()
	else
		self.border:Hide()
	end
	
	if ( GameTooltip:IsOwned(self) ) then
		self:SetTooltip()
	else
		self.UpdateTooltip = nil
	end
	
	if self.parent.config.hidemacrotext then
		self.macroName:SetText("")
	else
		self.macroName:SetText(GetActionText(action))
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
		self.hotkey:SetVertexColor(0.6, 0.6, 0.6)
		self.normalTexture:SetTexCoord(-0.1, 1.1, -0.1, 1.12)
		self.iconTex = nil
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
	-- TODO
end

function Button:UpdateState()
	local action = self.action
	if ( IsCurrentAction(action) or IsAutoRepeatAction(action) ) then
		self:SetChecked(1)
	else
		self:SetChecked(0)
	end
end

function Button:UpdateUsable()
	local oor = self.settings.profile.outofrange
	local isUsable, notEnoughMana = IsUsableAction(self.action)
	local oorcolor, oomcolor = self.settings.profile.colors.range, self.settings.profile.colors.mana
	if ( oor ~= "button" or not self.outOfRange) then
		if ( oor == "none" or not self.outOfRange) then
			self.hotkey:SetVertexColor(1.0, 1.0, 1.0)
		elseif ( oor == "hotkey" ) then
			self.hotkey:SetVertexColor(oorcolor.r, oorcolor.g, oorcolor.b)
		end
		
		if ( isUsable ) then
			self.icon:SetVertexColor(1.0, 1.0, 1.0);
		elseif ( notEnoughMana ) then
			self.icon:SetVertexColor(oomcolor.r, oomcolor.g, oomcolor.b)
		else
			self.icon:SetVertexColor(0.4, 0.4, 0.4);
		end
	elseif ( oor == "button" ) then
		self.icon:SetVertexColor(oorcolor.r, oorcolor.g, oorcolor.b)
		self.hotkey:SetVertexColor(1.0, 1.0, 1.0)
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
	if self.overlay then return end
	
	self.pushedTexture:SetTexture(self.textureCache.pushed)
	self.highlightTexture:SetTexture(self.textureCache.highlight)
end

function Button:HideButton()
	if self.overlay then return end
	
	self.pushedTexture:SetTexture("")
	self.highlightTexture:SetTexture("")
end

function Button:ShowGrid()
	self.showgrid = self.showgrid+1
	self.normalTexture:Show()
	
	if self.overlay then
		self.overlay:Show()
	end
end

function Button:HideGrid()
	local button = self.frame
	self.showgrid = self.showgrid-1
	if ( self.showgrid == 0 and not HasAction(self.action) and not self.parent.config.showgrid ) then
		self.normalTexture:Hide()
		if self.overlay then
			self.overlay:Hide()
		end
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
		if ( self:IsFlashing() and not IsAttackAction(self.action) ) then
			self:StopFlash()
		end
	end
end

function Button:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end
