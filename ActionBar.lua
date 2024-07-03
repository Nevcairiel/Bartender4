--[[
	Copyright (c) 2009-2017, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
local _, Bartender4 = ...
local StateBar = Bartender4.StateBar.prototype
local ActionBar = setmetatable({}, {__index = StateBar})
Bartender4.ActionBar = ActionBar

local LAB10 = LibStub("LibActionButton-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
local WoW10 = select(4, GetBuildInfo()) >= 100000

local tonumber, format, min = tonumber, format, min

local GetSpellBookItemInfo = GetSpellBookItemInfo
if C_SpellBook and C_SpellBook.GetSpellBookItemType then
	GetSpellBookItemInfo = function(index, book) assert(book == "spell") return C_SpellBook.GetSpellBookItemType(index, Enum.SpellBookSpellBank.Player) end
end

-- GLOBALS: UIParent, VehicleExit

--[[===================================================================================
	ActionBar Prototype
===================================================================================]]--

local initialPosition
do
	-- Sets the Bar to its initial Position in the Center of the Screen
	function initialPosition(bar)
		local offset = type(bar.id) == "number" and bar.id or 1
		bar:ClearSetPoint("CENTER", 0, -250 + (offset-1) * 38)
		bar:SavePosition()
	end
end

local function WoW10Migration(config)
	-- migrate scale/padding to WoW 10.0 layout, as the action buttons increased in size
	if config and not config.WoW10Layout and config.position.x then
		config.position.scale = config.position.scale * 0.8
		config.padding = config.padding / 0.8
		config.WoW10Layout = true
	end
end

-- Apply the specified config to the bar and refresh all settings
function ActionBar:ApplyConfig(config)
	if WoW10 then
		WoW10Migration(config or self.config)
	end

	StateBar.ApplyConfig(self, config)

	if not self.config.position.x then initialPosition(self) end

	self:SetupSmartTarget()
	self:UpdateButtons()
	self:UpdateButtonConfig()
end

function ActionBar:SavePosition()
	StateBar.SavePosition(self)

	-- when we change a manual layout change, flag it for WoW10
	if WoW10 then
		self.config.WoW10Layout = true
	end
end

function ActionBar:OnEvent(event, ...)
	if event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
		if InCombatLockdown() then
			self.updateSmartTargetOnOutOfCombat = true
		else
			self:SetupSmartTarget()
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if self.updateSmartTargetOnOutOfCombat and not InCombatLockdown() then
			self.updateSmartTargetOnOutOfCombat = nil
			self:SetupSmartTarget()
		end
	end

	StateBar.OnEvent(self, event, ...)
end

local function updateTextElementConfig(buttonConfig, config)
	buttonConfig.font.font = LSM:Fetch("font", config.font, true)
	buttonConfig.font.size = config.fontSize
	buttonConfig.font.flags = config.fontFlags
	buttonConfig.color = config.fontColor
	buttonConfig.position.anchor = config.textAnchor
	buttonConfig.position.relAnchor = config.textAnchor
	buttonConfig.position.offsetX = config.textOffsetX
	buttonConfig.position.offsetY = config.textOffsetY
	buttonConfig.justifyH = config.textJustifyH
end

function ActionBar:UpdateButtonConfig()
	StateBar.UpdateButtonConfig(self)
	if not self.buttonConfig then self.buttonConfig = { colors = { range = {}, mana = {} }, hideElements = {}, text = { hotkey = { font = {}, position = {} }, count = { font = {}, position = {} }, macro = { font = {}, position = {} } } } end
	self.buttonConfig.outOfRangeColoring = Bartender4.db.profile.outofrange
	self.buttonConfig.tooltip = Bartender4.db.profile.tooltip
	self.buttonConfig.colors.range[1], self.buttonConfig.colors.range[2], self.buttonConfig.colors.range[3] = Bartender4.db.profile.colors.range.r, Bartender4.db.profile.colors.range.g, Bartender4.db.profile.colors.range.b
	self.buttonConfig.colors.mana[1], self.buttonConfig.colors.mana[2], self.buttonConfig.colors.mana[3] = Bartender4.db.profile.colors.mana.r, Bartender4.db.profile.colors.mana.g, Bartender4.db.profile.colors.mana.b

	self.buttonConfig.hideElements.macro = self.config.hidemacrotext and true or false
	self.buttonConfig.hideElements.hotkey = self.config.hidehotkey and true or false
	self.buttonConfig.hideElements.equipped = self.config.hideequipped and true or false
	self.buttonConfig.hideElements.border = (self.config.hideborder or self.config.skin.Zoom) and true or false

	self.buttonConfig.showGrid = self.config.showgrid
	self.buttonConfig.clickOnDown = Bartender4.db.profile.onkeydown
	self.buttonConfig.flyoutDirection = self.config.flyoutDirection

	self.buttonConfig.keyBoundClickButton = "Keybind"

	updateTextElementConfig(self.buttonConfig.text.hotkey, self.config.elements.hotkey)
	updateTextElementConfig(self.buttonConfig.text.count, self.config.elements.count)
	updateTextElementConfig(self.buttonConfig.text.macro, self.config.elements.macro)

	if self.bindingmapping then
		for i, button in self:GetAll() do
			self.buttonConfig.keyBoundTarget = self.bindingmapping:format(i)
			button:UpdateConfig(self.buttonConfig)
		end
	else
		self:ForAll("UpdateConfig", self.buttonConfig)
	end

	self:ForAll("SetAttribute", "smarttarget", self.config.autoassist or self.config.mouseover)
	-- self casting
	self:UpdateSelfCast()
	-- button lock
	self:ForAll("SetAttribute", "buttonlock", Bartender4.db.profile.buttonlock)
	self:ForAll("SetAttribute", "unlockedpreventdrag", true)
	-- update state
	self:ForAll("UpdateState")
end

function ActionBar:UpdateSelfCast()
	StateBar.UpdateSelfCast(self)

	-- self casting
	self:ForAll("SetAttribute", "checkselfcast", Bartender4.db.profile.selfcastmodifier and true or nil)
	self:ForAll("SetAttribute", "checkfocuscast", Bartender4.db.profile.focuscastmodifier and true or nil)
	self:ForAll("SetAttribute", "*unit2", Bartender4.db.profile.selfcastrightclick and "player" or nil)
end

local UpdateSmartTarget = [[
	local state, type, action = ...
	self:SetAttribute("targettype", nil)
	self:SetAttribute("unit", nil)
	if self:GetAttribute("smarttarget") then
		if type == "action" then
			type, action = GetActionInfo(action)
		end
		if type == "spell" and action > 0 then
			if BT_Spell_Overrides[action] then action = BT_Spell_Overrides[action] end
			if IsSpellHarmful and IsSpellHelpful then
				if IsSpellHelpful(action) == IsSpellHarmful(action) then
					self:SetAttribute("targettype", 3)
					self:SetAttribute("unit", self:GetAttribute("target_all"))
				elseif IsSpellHelpful(action) then
					self:SetAttribute("targettype", 1)
					self:SetAttribute("unit", self:GetAttribute("target_help"))
				elseif IsSpellHarmful(action) then
					self:SetAttribute("targettype", 2)
					self:SetAttribute("unit", self:GetAttribute("target_harm"))
				end
			else
				local id, subtype = FindSpellBookSlotBySpellID(action), "spell"
				if id and id > 0 then
					if IsHelpfulSpell(id, subtype) == IsHarmfulSpell(id, subtype) then
						self:SetAttribute("targettype", 3)
						self:SetAttribute("unit", self:GetAttribute("target_all"))
					elseif IsHelpfulSpell(id, subtype) then
						self:SetAttribute("targettype", 1)
						self:SetAttribute("unit", self:GetAttribute("target_help"))
					elseif IsHarmfulSpell(id, subtype) then
						self:SetAttribute("targettype", 2)
						self:SetAttribute("unit", self:GetAttribute("target_harm"))
					end
				end
			end
		end
	end
]]

function ActionBar:SetupSmartTarget()
	local s = [[
		BT_Spell_Overrides = newtable()
		BT_Spell_Overrides[16979] = 102401 -- wild charge (bear)
		BT_Spell_Overrides[49376] = 102401 -- wild charge (cat)
	]]

	local i = 1
	local subtype, action, spellId = GetSpellBookItemInfo(i, "spell")
	while subtype do
		if subtype == "SPELL" then
			if not (C_SpellBook and C_SpellBook.GetSpellBookItemType) then
				spellId = select(7, GetSpellInfo(i, "spell"))
			end
			if spellId and spellId ~= action then
				s = s .. "\n" .. ([[ BT_Spell_Overrides[%d] = %d ]]):format(spellId, action)
			end
		end

		i = i + 1
		subtype, action, spellId = GetSpellBookItemInfo(i, "spell")
	end

	self:Execute(s)

	self:SetAttribute("ChildUpdateSmartTarget", UpdateSmartTarget)
end

function ActionBar:SetupSmartButton(button)
	button:SetAttribute("OnStateChanged", [[
		if self:GetAttribute("statehidden") then return end
		local header = self:GetParent()
		header:RunFor(self, header:GetAttribute("ChildUpdateSmartTarget"), ...)
	]])

	button:SetAttribute("_childupdate-target-help", [[
		self:SetAttribute("target_help", message)
		if self:GetAttribute("targettype") == 1 then
			self:SetAttribute("unit", message)
		end
	]])

	button:SetAttribute("_childupdate-target-harm", [[
		self:SetAttribute("target_harm", message)
		if self:GetAttribute("targettype") == 2 then
			self:SetAttribute("unit", message)
		end
	]])

	button:SetAttribute("_childupdate-target-all", [[
		self:SetAttribute("target_all", message)
		if self:GetAttribute("targettype") == 3 then
			self:SetAttribute("unit", message)
		end
	]])
end

local customExitButton = {
	func = function(button)
		VehicleExit()
	end,
	texture = "Interface\\AddOns\\Bartender4\\Artwork\\LeaveVehicle.tga", --"Interface\\Icons\\Spell_Shadow_SacrificialShield",
	tooltip = LEAVE_VEHICLE,
}

-- Update the number of buttons in our bar, creating new ones if necessary
function ActionBar:UpdateButtons(numbuttons, offset)
	if numbuttons then
		self.config.buttons = min(numbuttons, 12)
	else
		numbuttons = min(self.config.buttons, 12)
	end

	local buttons = self.buttons or {}

	if offset then
		self.config.buttonOffset = min(offset, 11)
	else
		offset = min(self.config.buttonOffset, 11)
	end

	local updateStartValue = #buttons + 1
	if self.currentButtonOffset ~= offset then
		updateStartValue = 1
	end

	local updateBindings = (numbuttons > #buttons)
	-- create more buttons if needed
	for i = updateStartValue, numbuttons do
		local absid = (self.id - 1) * 12 + i
		if buttons[i] == nil then
			buttons[i] = LAB10:CreateButton(absid, format("BT4Button%d", absid), self, nil)
		end
		local offsetid = (i + offset - 1) % 12 + 1
		for k = 1,18 do
			buttons[i]:SetState(k, "action", (k - 1) * 12 + offsetid)
		end
		buttons[i]:SetState(0, "action", (self.id - 1) * 12 + offsetid)

		if self.MasqueGroup then
			buttons[i]:AddToMasque(self.MasqueGroup)
		end

		self:SetupSmartButton(buttons[i])

		if i == 12 then
			if WoW10 then
				buttons[i]:SetState(16, "custom", customExitButton)
				buttons[i]:SetState(17, "custom", customExitButton)
				buttons[i]:SetState(18, "custom", customExitButton)
			else
				buttons[i]:SetState(11, "custom", customExitButton)
				buttons[i]:SetState(12, "custom", customExitButton)
			end
		end
	end

	-- show active buttons
	for i = 1, numbuttons do
		buttons[i]:SetParent(self)
		buttons[i]:Show()
		buttons[i]:SetAttribute("statehidden", nil)
		buttons[i]:UpdateAction()
	end

	-- hide inactive buttons
	for i = (numbuttons + 1), #buttons do
		buttons[i]:Hide()
		buttons[i]:SetParent(UIParent)
		buttons[i]:SetAttribute("statehidden", true)
	end

	self.numbuttons = numbuttons
	self.buttons = buttons
	self.currentButtonOffset = offset

	self:UpdateButtonLayout()
	self:SetGrid()
	if updateBindings and self.id == "1" then
		self.module:ReassignBindings()
	end

	-- need to re-set clickthrough after creating new buttons
	self:SetClickThrough()
	self:UpdateSelfCast() -- update selfcast and states
end

--[[===================================================================================
	ActionBar Config Interface
===================================================================================]]--


-- get the current number of buttons
function ActionBar:GetButtons()
	return self.config.buttons
end

-- get the current number of buttons
function ActionBar:GetButtonOffset()
	return self.config.buttonOffset
end

-- set the number of buttons and refresh layout
ActionBar.SetButtons = ActionBar.UpdateButtons

function ActionBar:SetButtonOffset(offset)
	return self:UpdateButtons(nil, offset)
end

function ActionBar:GetEnabled()
	return true
end

function ActionBar:SetEnabled(state)
	if not state then
		self.module:DisableBar(self.id)
	end
end

function ActionBar:GetGrid()
	return self.config.showgrid
end

function ActionBar:SetGrid(state)
	if state ~= nil then
		self.config.showgrid = state
	end
	self:UpdateButtonConfig()
end

function ActionBar:GetFlyoutDirection()
	return self.config.flyoutDirection
end

function ActionBar:SetFlyoutDirection(state)
	if state ~= nil then
		self.config.flyoutDirection = state
	end
	self:UpdateButtonConfig()
end

function ActionBar:GetStyleFont(element)
	return self.config.elements[element].font
end

function ActionBar:SetStyleFont(element, font)
	self.config.elements[element].font = font
	self:UpdateButtonConfig()
end

function ActionBar:GetStyleFontSize(element)
	return self.config.elements[element].fontSize
end

function ActionBar:SetStyleFontSize(element, size)
	self.config.elements[element].fontSize = size
	self:UpdateButtonConfig()
end

function ActionBar:GetStyleFontFlags(element)
	return self.config.elements[element].fontFlags
end

function ActionBar:SetStyleFontFlags(element, flags)
	self.config.elements[element].fontFlags = flags
	self:UpdateButtonConfig()
end

function ActionBar:GetStyleFontColor(element)
	return unpack(self.config.elements[element].fontColor)
end

function ActionBar:SetStyleFontColor(element, r, g, b)
	self.config.elements[element].fontColor = {r, g, b}
	self:UpdateButtonConfig()
end

function ActionBar:GetStyleTextAnchor(element)
	return self.config.elements[element].textAnchor
end

function ActionBar:SetStyleTextAnchor(element, anchor)
	self.config.elements[element].textAnchor = anchor
	self:UpdateButtonConfig()
end

function ActionBar:GetStyleTextOffsetX(element)
	return self.config.elements[element].textOffsetX
end

function ActionBar:SetStyleTextOffsetX(element, offset)
	self.config.elements[element].textOffsetX = offset
	self:UpdateButtonConfig()
end

function ActionBar:GetStyleTextOffsetY(element)
	return self.config.elements[element].textOffsetY
end

function ActionBar:SetStyleTextOffsetY(element, offset)
	self.config.elements[element].textOffsetY = offset
	self:UpdateButtonConfig()
end

function ActionBar:GetStyleTextJustifyH(element)
	return self.config.elements[element].textJustifyH
end

function ActionBar:SetStyleTextJustifyH(element, justify)
	self.config.elements[element].textJustifyH = justify
	self:UpdateButtonConfig()
end
