--[[
	KeyBound
		An intuitive keybindings sytem
		Based off of ClickBinder by Gello and TrinityBinder by Maul

		Functions needed to implement
			button:GetHotkey() - returns the current hotkey assigned to the given button

		Functions to implemnt if using a custom keybindings system:
			button:SetKey(key) - binds the given key to the given button
			button:FreeKey(key) - unbinds the given key from all other buttons
			button:ClearBindings() - removes all keys bound to the given button
			button:GetBindings() - returns a string listing all bindings of the given button
			button:GetActionName() - what we're binding to, used for printing
--]]


KeyBound = LibStub('AceAddon-3.0'):NewAddon('KeyBound', 'AceEvent-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale('KeyBound')
local Binder = {}

--[[ KeyBound ]]--

--events
function KeyBound:OnEnable()
	do
		local f = CreateFrame('Frame', 'KeyboundDialog', UIParent)
		f:SetFrameStrata('DIALOG')
		f:SetToplevel(true); f:EnableMouse(true)
		f:SetWidth(320); f:SetHeight(96)
		f:SetBackdrop{
			bgFile='Interface\\DialogFrame\\UI-DialogBox-Background' ,
			edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',
			tile = true,
			insets = {11, 12, 12, 11},
			tileSize = 32,
			edgeSize = 32,
		}
		f:SetPoint('TOP', 0, -24)
		f:Hide()

		local text = f:CreateFontString('ARTWORK')
		text:SetFontObject('GameFontHighlight')
		text:SetPoint('TOP', 0, -16)
		text:SetWidth(252); text:SetHeight(0)
		text:SetText(format(L.BindingsHelp, GetBindingText('ESCAPE','KEY_')))
		
		local close = CreateFrame('Button', f:GetName() .. 'Close', f, 'UIPanelCloseButton')
		close:SetPoint('TOPRIGHT', -3, -3)

		-- per character bindings checkbox
		local perChar = CreateFrame('CheckButton', 'KeyboundDialogCheck', f, 'OptionsCheckButtonTemplate')
		getglobal(perChar:GetName() .. 'Text'):SetText(CHARACTER_SPECIFIC_KEYBINDINGS)
		perChar:SetPoint('BOTTOMLEFT', 12, 8)
		
		perChar:SetScript('OnShow', function(self)
			self.current = GetCurrentBindingSet()
			self:SetChecked(GetCurrentBindingSet() == 2)
		end)

		perChar:SetScript('OnHide', function(self)
			KeyBound:Deactivate()
				
			if InCombatLockdown() then
				self:RegisterEvent('PLAYER_REGEN_ENABLED')
			else
				SaveBindings(self.current)
			end
		end)

		perChar:SetScript('OnEvent', function(self, event)
			SaveBindings(self.current)
			self:UnregisterEvent(event)
		end)

		perChar:SetScript('OnClick', function(self)
			self.current = (self:GetChecked() and 2) or 1
			LoadBindings(self.current)
		end)

		self.dialog = f
	end

	SlashCmdList['KeyBoundSlashCOMMAND'] = function() self:Toggle() end
	SLASH_KeyBoundSlashCOMMAND1 = '/keybound'
	SLASH_KeyBoundSlashCOMMAND2 = '/kb'

	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
end

function KeyBound:PLAYER_REGEN_ENABLED()
	if self.enabled then
		UIErrorsFrame:AddMessage(L.CombatBindingsEnabled, 1, 0.3, 0.3, 1, UIERRORS_HOLD_TIME)
		self.dialog:Hide()
	end
end

function KeyBound:PLAYER_REGEN_DISABLED()
	if self.enabled then
		self:Set(nil)
		UIErrorsFrame:AddMessage(L.CombatBindingsDisabled, 1, 0.3, 0.3, 1, UIERRORS_HOLD_TIME)
		self.dialog:Show()
	end
end

function KeyBound:Toggle()
	if self:IsShown() then
		self:Deactivate()
	else
		self:Activate()
	end
end

function KeyBound:Activate()
	if not self:IsShown() then
		if InCombatLockdown() then
			UIErrorsFrame:AddMessage(L.CannotBindInCombat, 1, 0.3, 0.3, 1, UIERRORS_HOLD_TIME)
		else
			self.enabled = true
			if not self.frame then
				self.frame = Binder:Create()
			end
			self:Set(nil)
			self.dialog:Show()
			self:SendMessage('KEYBOUND_ENABLED')
		end
	end
end

function KeyBound:Deactivate()
	if self:IsShown() then
		self.enabled = nil
		self:Set(nil)
		self.dialog:Hide()

		self:SendMessage('KEYBOUND_DISABLED')
	end
end

function KeyBound:IsShown()
	return self.enabled
end

function KeyBound:Set(button)
	local bindFrame = self.frame

	if button and self:IsShown() and not InCombatLockdown() then
		bindFrame.button = button
		bindFrame:SetAllPoints(button)

		bindFrame.text:SetFontObject('GameFontNormalLarge')
		bindFrame.text:SetText(button:GetHotkey())
		if bindFrame.text:GetStringWidth() > bindFrame:GetWidth() then
			bindFrame.text:SetFontObject('GameFontNormal')
		end
		bindFrame:Show()
		bindFrame:OnEnter()
	elseif bindFrame then
		bindFrame.button = nil
		bindFrame:ClearAllPoints()
		bindFrame:Hide()
	end
end

function KeyBound:ToShortKey(key)
	if key then
		key = key:upper()
		key = key:gsub(' ', '')
		key = key:gsub('ALT%-', 'A')
		key = key:gsub('CTRL%-', 'C')
		key = key:gsub('SHIFT%-', 'S')

		key = key:gsub('NUMPAD', 'N')

		key = key:gsub('BACKSPACE', 'BS')
		key = key:gsub('PLUS', '%+')
		key = key:gsub('MINUS', '%-')
		key = key:gsub('MULTIPLY', '%*')
		key = key:gsub('DIVIDE', '%/')
		key = key:gsub('HOME', 'HN')
		key = key:gsub('INSERT', 'Ins')
		key = key:gsub('DELETE', 'Del')
		key = key:gsub('BUTTON3', 'M3')
		key = key:gsub('BUTTON4', 'M4')
		key = key:gsub('BUTTON5', 'M5')
		key = key:gsub('MOUSEWHEELDOWN', 'WD')
		key = key:gsub('MOUSEWHEELUP', 'WU')
		key = key:gsub('PAGEDOWN', 'PD')
		key = key:gsub('PAGEUP', 'PU')

		return key
	end
end


--[[ Binder Widget ]]--

function Binder:Create()
	local binder = CreateFrame('Button')
	binder:RegisterForClicks('anyUp')
	binder:SetFrameStrata('DIALOG')
	binder:EnableKeyboard(true)
	binder:EnableMouseWheel(true)

	for k,v in pairs(self) do
		binder[k] = v
	end

	local bg = binder:CreateTexture()
	bg:SetTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(binder)

	local text = binder:CreateFontString('OVERLAY')
	text:SetFontObject('GameFontNormalLarge')
	text:SetTextColor(0, 1, 0)
	text:SetAllPoints(binder)
	binder.text = text

	binder:SetScript('OnClick', self.OnKeyDown)
	binder:SetScript('OnKeyDown', self.OnKeyDown)
	binder:SetScript('OnMouseWheel', self.OnMouseWheel)
	binder:SetScript('OnEnter', self.OnEnter)
	binder:SetScript('OnLeave', self.OnLeave)
	binder:SetScript('OnHide', self.OnHide)
	binder:Hide()

	return binder
end

function Binder:OnHide()
	KeyBound:Set(nil)
end

function Binder:OnKeyDown(key)
	local button = self.button
	if not button then return end

	if (key == 'UNKNOWN' or key == 'LSHIFT' or key == 'RSHIFT' or
		key == 'LCTRL' or key == 'RCTRL' or key == 'LALT' or key == 'RALT' or
		key == 'LeftButton' or key == 'RightButton') then
		return
	end

	local screenshotKey = GetBindingKey('SCREENSHOT')
	if screenshotKey and key == screenshotKey then
		Screenshot()
		return
	end

	local openChatKey = GetBindingKey('OPENCHAT')
	if openChatKey and key == openChatKey then
		ChatFrameEditBox:Show()
		return
	end

	if key == 'MiddleButton' then
		key = 'BUTTON3'
	elseif key == 'Button4' then
		key = 'BUTTON4'
	elseif key == 'Button5' then
		key = 'BUTTON5'
	end

	if key == 'ESCAPE' then
		self:ClearBindings(button)
		KeyBound:Set(button)
		return
	end

	if IsShiftKeyDown() then
		key = 'SHIFT-' .. key
	end
	if IsControlKeyDown() then
		key = 'CTRL-' .. key
	end
	if IsAltKeyDown() then
		key = 'ALT-' .. key
	end

	if MouseIsOver(button) then
		self:SetKey(button, key)
		KeyBound:Set(button)
	end
end

function Binder:OnMouseWheel(arg1)
	if arg1 > 0 then
		self:OnKeyDown('MOUSEWHEELUP')
	else
		self:OnKeyDown('MOUSEWHEELDOWN')
	end
end

function Binder:OnEnter()
	local button = self.button
	if button and not InCombatLockdown() then
		if self:GetRight() >= (GetScreenWidth() / 2) then
			GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
		else
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		end

		if button.GetActionName then
			GameTooltip:SetText(button:GetActionName(), 1, 1, 1)
		else
			GameTooltip:SetText(button:GetName(), 1, 1, 1)
		end

		local bindings = self:GetBindings(button)
		if bindings then
			GameTooltip:AddLine(bindings, 0, 1, 0)
			GameTooltip:AddLine(L.ClearTip)
		else
			GameTooltip:AddLine(L.NoKeysBoundTip, 0, 1, 0)
		end
		GameTooltip:Show()
	else
		GameTooltip:Hide()
	end
end

function Binder:OnLeave()
	KeyBound:Set(nil)
	GameTooltip:Hide()
end


--[[ Update Functions ]]--

function Binder:ToBinding(button)
	return format('CLICK %s:LeftButton', button:GetName())
end

function Binder:FreeKey(button, key)
	local msg
	if button.FreeKey then
		local action = button:FreeKey(key)
		if button:FreeKey(key) then
			msg = format(L.UnboundKey, GetBindingText(key, 'KEY_'), action)
		end
	else
		local action = GetBindingAction(key)
		if action and action ~= '' and action ~= self:ToBinding(button) then
			msg = format(L.UnboundKey, GetBindingText(key, 'KEY_'), action)
		end
	end

	if msg then
		UIErrorsFrame:AddMessage(msg, 1, 0.82, 0, 1, UIERRORS_HOLD_TIME)
	end
end

function Binder:SetKey(button, key)
	if InCombatLockdown() then
		UIErrorsFrame:AddMessage(L.CannotBindInCombat, 1, 0.3, 0.3, 1, UIERRORS_HOLD_TIME)
	else
		self:FreeKey(button, key)

		if button.SetKey then
			button:SetKey(key)
		else
			SetBindingClick(key, button:GetName(), 'LeftButton')
		end

		local msg
		if button.GetActionName then
			msg = format(L.BoundKey, GetBindingText(key, 'KEY_'), button:GetActionName())
		else
			msg = format(L.BoundKey, GetBindingText(key, 'KEY_'), button:GetName())
		end
		SaveBindings(GetCurrentBindingSet())
		UIErrorsFrame:AddMessage(msg, 1, 1, 1, 1, UIERRORS_HOLD_TIME)
	end
end

function Binder:ClearBindings(button)
	if InCombatLockdown() then
		UIErrorsFrame:AddMessage(L.CannotBindInCombat, 1, 0.3, 0.3, 1, UIERRORS_HOLD_TIME)
	else
		if button.ClearBindings then
			button:ClearBindings()
		else
			local binding = self:ToBinding(button)
			while GetBindingKey(binding) do
				SetBinding(GetBindingKey(binding), nil)
			end
		end

		local msg
		if button.GetActionName then
			msg = format(L.ClearedBindings, button:GetActionName())
		else
			msg = format(L.ClearedBindings, button:GetName())
		end
		SaveBindings(GetCurrentBindingSet())
		UIErrorsFrame:AddMessage(msg, 1, 1, 1, 1, UIERRORS_HOLD_TIME)
	end
end

function Binder:GetBindings(button)
	if button.GetBindings then
		return button:GetBindings()
	end

	local keys
	local binding = self:ToBinding(button)
	for i = 1, select('#', GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys then
			keys = keys .. ', ' .. GetBindingText(hotKey,'KEY_')
		else
			keys = GetBindingText(hotKey,'KEY_')
		end
	end

	return keys
end