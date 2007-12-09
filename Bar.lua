--[[
	Generic Bar Frame Template
]]

--[[ $Id$ ]]

local Bar = CreateFrame("Button")
local Bar_MT = {__index = Bar}

local barregistry = {}

local defaults = {
	['**'] = {
		Enabled = true,
		Scale = 1,
		Alpha = 1,
	}
}

Bartender4.Bar = {}
Bartender4.Bar.defaults = defaults
Bartender4.Bar.prototype = Bar
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

local getBar, optGetter, optSetter, optionMap, callFunc
do
	optionMap = {
		alpha = "ConfigAlpha",
		scale = "ConfigScale",
	}
	
	function getBar(id)
		local bar = barregistry[tostring(id)]
		assert(bar, "Invalid bar id in options table.")
		return bar
	end
	
	function callFunc(bar, type, option, ...)
		local func = type .. (optionMap[option] or option)
		assert(bar[func], "Invalid get/set function.")
		return bar[func](bar, ...)
	end
	
	function optGetter(info)
		local bar = getBar(info[2])
		local option = info[#info]
		return callFunc(bar, "Get", option)
	end
	
	function optSetter(info, ...)
		local bar = getBar(info[2])
		local option = info[#info]
		return callFunc(bar, "Set", option, ...)
	end
end

function Bartender4.Bar:GetOptionTable()
	if not self.options then
		self.options = {
			general = {
				type = "group",
				cmdInline = true,
				name = "General Settings",
				order = 1,
				args = {
					style = {
						type = "group",
						name = "Style",
						inline = true,
						order = 5,
						args = {
							alpha = {
								name = "Alpha",
								desc = "Configure the alpha of the bar.",
								type = "range",
								min = .1, max = 1, bigStep = 0.1,
								get = optGetter,
								set = optSetter,
							},
							scale = {
								name = "Scale",
								desc = "Configure the scale of the bar.",
								type = "range",
								min = .1, max = 2, step = 0.05, bigStep = 0.1,
								get = optGetter,
								set = optSetter,
							},
						},
					},
				},
			},
			align = {
				type = "group",
				cmdInline = true,
				name = "Alignment",
				order = 10,
				args = {
				
				},
			},
		}
	end
	
	return self.options
end

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
	self:Lock()
	self:LoadPosition()
end

function Bar:Unlock()
	self:EnableMouse(true)
	self:SetScript("OnEnter", barOnEnter)
	self:SetScript("OnLeave", barOnLeave)
	self:SetScript("OnDragStart", barOnDragStart)
	self:SetScript("OnDragStop", barOnDragStop)
	self:SetScript("OnClick", barOnClick)
	self.Text:Show()
	
	self:SetFrameLevel(5)
	if self.config.Hide then
		self:SetBackdropColor(1, 0, 0, 0.5)
	else
		self:SetBackdropColor(0, 1, 0, 0.5)
	end
end

function Bar:Lock()
	barOnDragStop(self)
	self:EnableMouse(false)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnDragStart", nil)
	self:SetScript("OnDragStop", nil)
	self:SetScript("OnClick", nil)
	self.Text:Hide()
	
	self:SetBackdropColor(0, 0, 0, 0)
	self:SetBackdropBorderColor(0, 0, 0, 0)
end

function Bar:LoadPosition()
	if not self.config.Position then return end
	local pos = self.config.Position
	local x, y, s = pos.x, pos.y, self:GetEffectiveScale()
	local point, relPoint = pos.point, pos.relPoint
	x, y = x/s, y/s
	self:ClearSetPoint(point, UIParent, relPoint, x, y)
end

function Bar:SavePosition()
	if not self.config.Position then self.config.Position = {} end
	local pos = self.config.Position
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

function Bar:GetConfigAlpha()
	return self.config.Alpha
end

function Bar:SetConfigAlpha(alpha)
	if alpha then
		self.config.Alpha = alpha
	end
	self:SetAlpha(self.config.Alpha)
end

function Bar:GetConfigScale()
	return self.config.Scale
end

function Bar:SetConfigScale(scale)
	if scale then
		self.config.Scale = scale
	end
	self:SetScale(self.config.Scale)
	self:LoadPosition()
end

--[[
	Lazyness functions
]]
function Bar:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end
