--[[
	Generic Bar Frame Template
]]

--[[ $Id$ ]]
local L = LibStub("AceLocale-3.0"):GetLocale("Bartender4")
local Bar = CreateFrame("Button")
local Bar_MT = {__index = Bar}

--[[===================================================================================
	Universal Bar Contructor
===================================================================================]]--

local defaults = {
	scale = 1,
	alpha = 1,
	fadeout = false,
	fadeoutalpha = 0.1,
	fadeoutdelay = 0.2,
	show = "alwaysshow",
}

local barOnEnter, barOnLeave, barOnDragStart, barOnDragStop, barOnClick, barOnUpdateFunc
do
	function barOnEnter(self)
		self:SetBackdropBorderColor(0.5, 0.5, 0, 1)
	end

	function barOnLeave(self)
		self:SetBackdropBorderColor(0, 0, 0, 0)
	end

	function barOnDragStart(self)
		local parent = self:GetParent()
		parent:StartMoving()
		self:SetBackdropBorderColor(0, 0, 0, 0)
		parent.isMoving = true
	end

	function barOnDragStop(self)
		local parent = self:GetParent()
		if parent.isMoving then
			parent:StopMovingOrSizing()
			parent:SavePosition()
		end
	end
	
	function barOnClick(self)
		-- TODO: Hide/Show bar on Click
		-- TODO: Once dropdown config is stable, show dropdown on rightclick
	end
	
	function barOnUpdateFunc(self, elapsed) 
		self.elapsed = self.elapsed + elapsed
		if self.elapsed > self.config.fadeoutdelay then
			self:ControlFadeOut(self.elapsed)
			self.elapsed = 0
		end
	end
end

local barregistry = {}
Bartender4.Bar = {}
Bartender4.Bar.defaults = defaults
Bartender4.Bar.prototype = Bar
Bartender4.Bar.barregistry = barregistry
function Bartender4.Bar:Create(id, config)
	id = tostring(id)
	assert(not barregistry[id], "duplicated entry in barregistry.")
	
	local bar = setmetatable(CreateFrame("Frame", ("BT4Bar%s"):format(id), UIParent, "SecureStateHeaderTemplate"), Bar_MT)
	barregistry[id] = bar
	bar.id = id
	bar:SetMovable(true)
	
	local overlay = CreateFrame("Button", bar:GetName() .. "Overlay", bar)
	bar.overlay = overlay
	overlay:EnableMouse(true)
	overlay:RegisterForDrag("LeftButton")
	overlay:RegisterForClicks("LeftButtonUp")
	overlay:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = {left = 5, right = 3, top = 3, bottom = 5}
	})
	overlay:SetBackdropColor(0, 0, 0, 0)
	overlay:SetBackdropBorderColor(0.5, 0.5, 0, 0)
	overlay.Text = overlay:CreateFontString(nil, "ARTWORK")
	overlay.Text:SetFontObject(GameFontNormal)
	overlay.Text:SetText(tonumber(id) and L["Bar "]..id or L[id.." Bar"])
	overlay.Text:Show()
	overlay.Text:ClearAllPoints()
	overlay.Text:SetPoint("CENTER", overlay, "CENTER")
	
	overlay:SetScript("OnEnter", barOnEnter)
	overlay:SetScript("OnLeave", barOnLeave)
	overlay:SetScript("OnDragStart", barOnDragStart)
	overlay:SetScript("OnDragStop", barOnDragStop)
	overlay:SetScript("OnClick", barOnClick)
	
	overlay:SetFrameLevel(bar:GetFrameLevel() + 10)
	overlay:ClearAllPoints()
	overlay:SetAllPoints(bar)
	overlay:Hide()
	
	bar.config = config
	bar.elapsed = 0
	
	return bar
end

function Bartender4.Bar:GetAll()
	return pairs(barregistry)
end

function Bartender4.Bar:ForAll(method, ...)
	for _,bar in self:GetAll() do
		local func = bar[method]
		if func then
			func(bar, ...)
		end
	end
end

--[[===================================================================================
	Bar Options
===================================================================================]]--

-- option utilty functions
local optGetter, optSetter
do
	local getBar, optionMap, callFunc
	-- maps option keys to function names
	optionMap = {
		alpha = "ConfigAlpha",
		scale = "ConfigScale",
		show = "Show",
		fadeout = "FadeOut",
		fadeoutalpha = "FadeOutAlpha",
		fadeoutdelay = "FadeOutDelay",
	}
	
	-- retrieves a valid bar object from the barregistry table
	function getBar(id)
		local bar = barregistry[tostring(id)]
		assert(bar, ("Invalid bar id in options table. (%s)"):format(id))
		return bar
	end
	
	-- calls a function on the bar
	function callFunc(bar, type, option, ...)
		local func = type .. (optionMap[option] or option)
		assert(bar[func], ("Invalid get/set function %s in bar %s."):format(func, bar.id))
		return bar[func](bar, ...)
	end
	
	-- universal function to get a option
	function optGetter(info)
		local bar = getBar(info[2])
		local option = info[#info]
		return callFunc(bar, "Get", option)
	end
	
	-- universal function to set a option
	function optSetter(info, ...)
		local bar = getBar(info[2])
		local option = info[#info]
		return callFunc(bar, "Set", option, ...)
	end
end

local showOptions = { alwaysshow = L["Always Show"], alwayshide = L["Always Hide"], combatshow = L["Show in Combat"], combathide = L["Hide in Combat"] }

local options
function Bar:GetOptionObject()
	local otbl = {
		general = {
			type = "group",
			cmdInline = true,
			name = L["General Settings"],
			order = 1,
			args = {
				show = {
					order = 5,
					type = "select",
					name = L["Show/Hide"],
					desc = L["Configure when to Show/Hide the bar."],
					get = optGetter,
					set = optSetter,
					values = showOptions,
				},
				styleheader = {
					order = 10,
					type = "header",
					name = L["Bar Style & Layout"],
				},
				alpha = {
					order = 20,
					name = L["Alpha"],
					desc = L["Configure the alpha of the bar."],
					type = "range",
					min = .1, max = 1, bigStep = 0.1,
					get = optGetter,
					set = optSetter,
				},
				scale = {
					order = 30,
					name = L["Scale"],
					desc = L["Configure the scale of the bar."],
					type = "range",
					min = .1, max = 2, step = 0.05,
					get = optGetter,
					set = optSetter,
				},
				fadeout = {
					order = 100,
					name = L["Fade Out"],
					desc = L["Enable the FadeOut mode"],
					type = "toggle",
					get = optGetter,
					set = optSetter,
					width = "full",
				},
				fadeoutalpha = {
					order = 101,
					name = L["Fade Out Alpha"],
					desc = L["Enable the FadeOut mode"],
					type = "range",
					min = 0, max = 1, step = 0.05,
					get = optGetter,
					set = optSetter,
					disabled = function(info) return not barregistry[info[2]]:GetFadeOut() end,
				},
				fadeoutdelay = {
					order = 102,
					name = L["Fade Out Delay"],
					desc = L["Enable the FadeOut mode"],
					type = "range",
					min = 0, max = 1, step = 0.01,
					get = optGetter,
					set = optSetter,
					disabled = function(info) return not barregistry[info[2]]:GetFadeOut() end,
				},
			},
		},
		align = {
			type = "group",
			cmdInline = true,
			name = L["Alignment"],
			order = 10,
			args = {
				info = {
					order = 1,
					type = "description",
					name = L["The Alignment menu is still on the TODO.\n\nAs a quick preview of whats planned:\n\n\t- Absolute and relative Bar Positioning\n\t- Bars \"snapping\" together and building clusters"],
				},
			},
		}
	}
	return Bartender4:NewOptionObject(otbl)
end

--[[===================================================================================
	Universal Bar Prototype
===================================================================================]]--

function Bar:ApplyConfig(config)
	if config then
		self.config = config
	end
	if self.disabled then return end
	self:SetShow()
	self:Lock()
	self:LoadPosition()
	self:SetConfigScale()
	self:SetConfigAlpha()
	self:SetFadeOut()
end

function Bar:Unlock()
	if self.disabled or self.unlocked then return end
	self.unlocked = true
	UnregisterStateDriver(self, "visibility")
	self:Show()
	self.overlay:Show()
	if self.config.show == "alwayshide" then
		self.overlay:SetBackdropColor(1, 0, 0, 0.5)
	else
		self.overlay:SetBackdropColor(0, 1, 0, 0.5)
	end
	if self.config.fadeout then
		self:SetScript("OnUpdate", nil)
		self.faded = nil
		self:SetConfigAlpha()
	end
end

function Bar:Lock()
	if self.disabled or not self.unlocked then return end
	self.unlocked = nil
	barOnDragStop(self.overlay)
	
	self:ConfigureShowStates()
	
	self.overlay:Hide()
	
	self:SetFadeOut()
end

function Bar:LoadPosition()
	if not self.config.position then return end
	local pos = self.config.position
	local x, y, s = pos.x, pos.y, self:GetEffectiveScale()
	local point, relPoint = pos.point, pos.relPoint
	x, y = x/s, y/s
	self:ClearSetPoint(point, UIParent, relPoint, x, y)
end

function Bar:SavePosition()
	if not self.config.position then self.config.position = {} end
	local pos = self.config.position
	local point, parent, relPoint, x, y = self:GetPoint()
	local s = self:GetEffectiveScale()
	x, y = x*s, y*s
	pos.x, pos.y = x, y
	pos.point, pos.relPoint = point, relPoint
end

function Bar:SetSize(width, height)
	self:SetWidth(width)
	self:SetHeight(height or width)
end

function Bar:GetShow()
	return self.config.show
end

function Bar:SetShow(show)
	if show ~= nil then
		self.config.show = show
	end
	if not self.unlocked then
		self:ConfigureShowStates()
	else
		self:Show()
		if self.config.show == "alwayshide" then
			self.overlay:SetBackdropColor(1, 0, 0, 0.5)
		else
			self.overlay:SetBackdropColor(0, 1, 0, 0.5)
		end
	end
end

function Bar:ConfigureShowStates()
	UnregisterStateDriver(self, 'visibility')
	local conditions
	if self.config.show == "alwaysshow" or self.config.show == true then
		self:Show()
	elseif self.config.show == "alwayshide" or self.config.show == false then
		self:Hide()
	elseif self.config.show == "combatshow" then
		RegisterStateDriver(self, 'visibility', '[combat]show;hide')
	elseif self.config.show == "combathide" then
		RegisterStateDriver(self, 'visibility', '[combat]hide;show')
	end
end

function Bar:GetConfigAlpha()
	return self.config.alpha
end

function Bar:SetConfigAlpha(alpha)
	if alpha then
		self.config.alpha = alpha
	end
	if not self.faded then
		self:SetAlpha(self.config.alpha)
	end
end

function Bar:GetConfigScale()
	return self.config.scale
end

function Bar:SetConfigScale(scale)
	if scale then
		self.config.scale = scale
	end
	self:SetScale(self.config.scale)
	self:LoadPosition()
end

function Bar:GetFadeOut()
	return self.config.fadeout
end

function Bar:SetFadeOut(fadeout)
	if fadeout ~= nil then
		self.config.fadeout = fadeout
	end
	if self.config.fadeout then
		self:SetScript("OnUpdate", barOnUpdateFunc)
		self:ControlFadeOut()
	else
		self:SetScript("OnUpdate", nil)
		self.faded = nil
		self:SetConfigAlpha()
	end
end

function Bar:GetFadeOutAlpha()
	return self.config.fadeoutalpha
end

function Bar:SetFadeOutAlpha(fadealpha)
	if fadealpha ~= nil then
		self.config.fadeoutalpha = fadealpha
	end
	if self.faded then
		self:SetAlpha(self.config.fadeoutalpha)
	end
end

function Bar:GetFadeOutDelay()
	return self.config.fadeoutdelay
end

function Bar:SetFadeOutDelay(delay)
	if delay ~= nil then
		self.config.fadeoutdelay = delay
	end
end

function Bar:ControlFadeOut()
	if self.config.fadeout then
		if self.faded and MouseIsOver(self) then
			self:SetAlpha(self.config.alpha)
			self.faded = nil
		elseif not self.faded and not MouseIsOver(self) then
			self:SetAlpha(self.config.fadeoutalpha)
			self.faded = true
		end
	end
end

--[[
	Lazyness functions
]]
function Bar:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end
