--[[
	Generic Bar Frame Template
]]

--[[ $Id$ ]]

local Bar = CreateFrame("Frame")
local Bar_MT = {__index = Bar}

local function createOptions(id)
	
end

Bartender4.Bar = {}
function Bartender4.Bar:Create(id, template)
	local bar = setmetatable(CreateFrame("Frame", ("BT4Bar%s"):format(id), UIParent, template), Bar_MT)
	
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
	bar.Text = frame:CreateFontString(nil, "ARTWORK")
	bar.Text:SetFontObject(GameFontNormal)
	bar.Text:SetText("Bar "..id)
	bar.Text:Hide()
	bar.Text:ClearAllPoints()
	bar.Text:SetPoint("CENTER", bar, "CENTER")
	
	bar.options = createOptions(id)
	
	return bar
end

local barOnEnter, barOnLeave, barOnDragStart, barOnDragStop
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
	end

	function barOnDragStop(self)
		self:StopMovingOrSizing()
		self:SavePosition()
	end
end

function Bar:Unlock()
	self:EnableMouse(true)
	self:SetScript("OnEnter", barOnEnter)
	self:SetScript("OnLeave", barOnLeave)
	self:SetScript("OnDragStart", barOnDragStart)
	self:SetScript("OnDragStop", barOnDragStop)
	self:SetScript("OnClick", nil)
	self.Text:Show()
	
	self:SetFrameLevel(5)
	if self.config.Hide then
		self:SetBackdropColor(1, 0, 0, 0.5)
	else
		self:SetBackdropColor(0, 1, 0, 0.5)
	end
end

function Bar:Lock()
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
	local x, y, s = self.config.PosX, self.config.PosY, self:GetEffectiveScale()
	x, y = x/s, y/s
	self:ClearAllPoints()
	self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
end

function Bar:SavePosition()
	local x, y = self:GetLeft(), self:GetBottom()
	local s = self:GetEffectiveScale()
	x, y = x*s, y*s
	self.config.PosX = x
	self.config.PosY = y
end
