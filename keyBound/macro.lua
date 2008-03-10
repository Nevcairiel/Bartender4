local MacroButton = CreateFrame('Frame')

function MacroButton:Load()
	local i = 1
	local button
	repeat
		button = getglobal(format('MacroButton%d', i))
		if button then
			local OnEnter = button:GetScript('OnEnter')
			button:SetScript('OnEnter', function(self)
				KeyBound:Set(self)
				return OnEnter and OnEnter(self)
			end)

			button.GetBindAction = self.GetBindAction
			button.GetActionName = self.GetActionName
			button.SetKey = self.SetKey
			button.GetHotkey = self.GetHotkey
			button.ClearBindings = self.ClearBindings
			button.GetBindings = self.GetBindings
			i = i + 1
		end
	until not button
end

function MacroButton:OnEnter()
	KeyBound:Set(self)
end

function MacroButton:GetActionName()
	return GetMacroInfo(MacroFrame.macroBase + self:GetID())
end

-- returns the keybind action of the given button
function MacroButton:GetBindAction()
	return format('MACRO %d', MacroFrame.macroBase + self:GetID())
end

-- binds the given key to the given button
function MacroButton:SetKey(key)
	SetBindingMacro(key, MacroFrame.macroBase + self:GetID())
end

-- removes all keys bound to the given button
function MacroButton:ClearBindings()
	local binding = self:GetBindAction()
	while GetBindingKey(binding) do
		SetBinding(GetBindingKey(binding), nil)
	end
end

-- returns a string listing all bindings of the given button
function MacroButton:GetBindings()
	local keys
	local binding = self:GetBindAction()
	for i = 1, select('#', GetBindingKey(binding)) do
		local hotKey = select(i, GetBindingKey(binding))
		if keys then
			keys = keys .. ', ' .. GetBindingText(hotKey, 'KEY_')
		else
			keys = GetBindingText(hotKey, 'KEY_')
		end
	end
	return keys
end

function MacroButton:GetHotkey()
	return KeyBound:ToShortKey(GetBindingKey(self:GetBindAction()))
end

do
	MacroButton:SetScript('OnEvent', function(self, event, addon)
		if addon == 'Blizzard_MacroUI' then
			self:UnregisterAllEvents()
			self:Load()
		end
	end)
	MacroButton:RegisterEvent('ADDON_LOADED')
end