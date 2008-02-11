--[[
	Generic Bar Frame Template
]]

--[[ $Id$ ]]

local Bar = CreateFrame("Button")
local Bar_MT = {__index = Bar}

--[[===================================================================================
	Universal Bar Contructor
===================================================================================]]--

local defaults = {
	['**'] = {
		scale = 1,
		alpha = 1,
		show = true,
	}
}

local barregistry = {}
Bartender4.Bar = {}
Bartender4.Bar.defaults = defaults
Bartender4.Bar.prototype = Bar
Bartender4.Bar.barregistry = barregistry
function Bartender4.Bar:Create(id, template, config)
	id = tostring(id)
	assert(not barregistry[id], "duplicated entry in barregistry.")
	
	local bar = setmetatable(CreateFrame("Button", ("BT4Bar%s"):format(id), UIParent, template), Bar_MT)
	barregistry[id] = bar
	bar.id = id
	
	bar:EnableMouse(false)
	bar:SetMovable(true)
	bar:RegisterForDrag("LeftButton")
	bar:RegisterForClicks("RightButtonDown", "LeftButtonUp")
	bar:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = {left = 5, right = 3, top = 3, bottom = 5}
	})
	bar:SetBackdropColor(0, 0, 0, 0)
	bar:SetBackdropBorderColor(0.5, 0.5, 0, 0)
	bar.Text = bar:CreateFontString(nil, "ARTWORK")
	bar.Text:SetFontObject(GameFontNormal)
	bar.Text:SetText("Bar "..id)
	bar.Text:Hide()
	bar.Text:ClearAllPoints()
	bar.Text:SetPoint("CENTER", bar, "CENTER")
	
	bar.config = config
	
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
	}
	
	-- retrieves a valid bar object from the barregistry table
	function getBar(id)
		local bar = barregistry[tostring(id)]
		assert(bar, "Invalid bar id in options table.")
		return bar
	end
	
	-- calls a function on the bar
	function callFunc(bar, type, option, ...)
		local func = type .. (optionMap[option] or option)
		assert(bar[func], "Invalid get/set function.")
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

local options
function Bar:GetOptionObject()
	if not options then
		local otbl = {
			general = {
				type = "group",
				cmdInline = true,
				name = "General Settings",
				order = 1,
				args = {
					show = {
						order = 5,
						type = "toggle",
						name = "Show",
						desc = "Show/Hide the bar.",
						get = optGetter,
						set = optSetter,
					},
					styleheader = {
						order = 10,
						type = "header",
						name = "Bar Style & Layout",
					},
					alpha = {
						order = 20,
						name = "Alpha",
						desc = "Configure the alpha of the bar.",
						type = "range",
						min = .1, max = 1, bigStep = 0.1,
						get = optGetter,
						set = optSetter,
					},
					scale = {
						order = 30,
						name = "Scale",
						desc = "Configure the scale of the bar.",
						type = "range",
						min = .1, max = 2, step = 0.05, bigStep = 0.1,
						get = optGetter,
						set = optSetter,
					},
				},
			},
			align = {
				type = "group",
				cmdInline = true,
				name = "Alignment",
				order = 10,
				args = {},
			}
		}
		options = Bartender4:NewOptionObject(otbl)
	end
	
	return options
end

--[[===================================================================================
	Universal Bar Prototype
===================================================================================]]--

local barOnEnter, barOnLeave, barOnDragStart, barOnDragStop, barOnClick
do
	function barOnEnter(self)
		self:SetBackdropBorderColor(0.5, 0.5, 0, 1)
	end

	function barOnLeave(self)
		self:SetBackdropBorderColor(0, 0, 0, 0)
	end

	function barOnDragStart(self)
		self:StartMoving()
		self:SetBackdropBorderColor(0, 0, 0, 0)
		self.isMoving = true
	end

	function barOnDragStop(self)
		if self.isMoving then
			self:StopMovingOrSizing()
			self:SavePosition()
		end
	end
	
	function barOnClick(self)
		-- TODO: Hide/Show bar on Click
		-- TODO: Once dropdown config is stable, show dropdown on rightclick
	end
end

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
end

function Bar:Unlock()
	if self.disabled or self.unlocked then return end
	self.unlocked = true
	self:EnableMouse(true)
	self:SetScript("OnEnter", barOnEnter)
	self:SetScript("OnLeave", barOnLeave)
	self:SetScript("OnDragStart", barOnDragStart)
	self:SetScript("OnDragStop", barOnDragStop)
	self:SetScript("OnClick", barOnClick)
	self.Text:Show()
	
	self:Show()
	self:SetFrameLevel(5)
	if not self.config.show then
		self:SetBackdropColor(1, 0, 0, 0.5)
	else
		self:SetBackdropColor(0, 1, 0, 0.5)
	end
end

function Bar:Lock()
	if self.disabled or not self.unlocked then return end
	self.unlocked = nil
	barOnDragStop(self)
	self:EnableMouse(false)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnDragStart", nil)
	self:SetScript("OnDragStop", nil)
	self:SetScript("OnClick", nil)
	self.Text:Hide()
	
	if not self.config.show then
		self:Hide()
	end
	
	self:SetBackdropColor(0, 0, 0, 0)
	self:SetBackdropBorderColor(0, 0, 0, 0)
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
		self[self.config.show and "Show" or "Hide"](self)
	else
		if not self.config.show then
			self:SetBackdropColor(1, 0, 0, 0.5)
		else
			self:SetBackdropColor(0, 1, 0, 0.5)
		end
	end
end

function Bar:GetConfigAlpha()
	return self.config.alpha
end

function Bar:SetConfigAlpha(alpha)
	if alpha then
		self.config.alpha = alpha
	end
	self:SetAlpha(self.config.alpha)
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

--[[
	Lazyness functions
]]
function Bar:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end
