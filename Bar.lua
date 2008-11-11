--[[
	Generic Bar Frame Template
]]
local Bar = CreateFrame("Button")
local Bar_MT = {__index = Bar}

local table_concat, table_insert = table.concat, table.insert

--[[===================================================================================
	Universal Bar Contructor
===================================================================================]]--

local defaults = {
	scale = 1,
	alpha = 1,
	fadeout = false,
	fadeoutalpha = 0.1,
	fadeoutdelay = 0.2,
	visibility = {
		possess = true,
		stance = {},
	},
}

local Sticky = LibStub("LibSimpleSticky-1.0")
local snapBars = { WorldFrame, UIParent }

local barOnEnter, barOnLeave, barOnDragStart, barOnDragStop, barOnClick, barOnUpdateFunc, barOnAttributeChanged
do
	function barOnEnter(self)
		if not self:GetParent().isMoving then
			self:SetBackdropBorderColor(0.5, 0.5, 0, 1)
		end
	end

	function barOnLeave(self)
		self:SetBackdropBorderColor(0, 0, 0, 0)
	end

	function barOnDragStart(self)
		local parent = self:GetParent()
		if Bartender4.db.profile.snapping then
			local offset = 8 - (parent.config.padding or 0)
			Sticky:StartMoving(parent, snapBars, offset, offset, offset, offset)
		else
			parent:StartMoving()
		end
		self:SetBackdropBorderColor(0, 0, 0, 0)
		parent.isMoving = true
	end

	function barOnDragStop(self)
		local parent = self:GetParent()
		if parent.isMoving then
			if Bartender4.db.profile.snapping then
				local sticky, stickTo = Sticky:StopMoving(parent)
				--Bartender4:Print(sticky, stickTo and stickTo:GetName() or nil)
			else
				parent:StopMovingOrSizing()
			end
			parent:SavePosition()
			parent.isMoving = nil
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
	
	function barOnAttributeChanged(self, attribute, value)
		if attribute == "fade" then
			if value then
				self:SetScript("OnUpdate", barOnUpdateFunc)
				self:ControlFadeOut()
			else
				self:SetScript("OnUpdate", nil)
				self.faded = nil
				self:SetConfigAlpha()
			end
		end
	end
end

local barregistry = {}
Bartender4.Bar = {}
Bartender4.Bar.defaults = defaults
Bartender4.Bar.prototype = Bar
Bartender4.Bar.barregistry = barregistry
function Bartender4.Bar:Create(id, config, name)
	id = tostring(id)
	assert(not barregistry[id], "duplicated entry in barregistry.")
	
	local bar = setmetatable(CreateFrame("Frame", ("BT4Bar%s"):format(id), UIParent, "SecureHandlerStateTemplate"), Bar_MT)
	barregistry[id] = bar
	table_insert(snapBars, bar)
	
	bar.id = id
	bar.name = name or id
	bar:SetMovable(true)
	bar:HookScript("OnAttributeChanged", barOnAttributeChanged)
	
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
	overlay:SetBackdropColor(0, 1, 0, 0.5)
	overlay:SetBackdropBorderColor(0.5, 0.5, 0, 0)
	overlay.Text = overlay:CreateFontString(nil, "ARTWORK")
	overlay.Text:SetFontObject(GameFontNormal)
	overlay.Text:SetText(name)
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
	bar.hidedriver = {}
	
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
	Universal Bar Prototype
===================================================================================]]--

function Bar:ApplyConfig(config)
	if config then
		self.config = config
	end
	if self.disabled then return end
	if Bartender4.Locked then
		self:Lock()
	else
		self:Unlock()
	end
	self:LoadPosition()
	self:SetConfigScale()
	self:SetConfigAlpha()
	self:InitVisibilityDriver()
end

function Bar:Unlock()
	if self.disabled or self.unlocked then return end
	self.unlocked = true
	self:DisableVisibilityDriver()
	self:Show()
	self.overlay:Show()
end

function Bar:Lock()
	if self.disabled or not self.unlocked then return end
	self.unlocked = nil
	self:StopDragging()
	
	self:ApplyVisibilityDriver()
	
	self.overlay:Hide()
end

function Bar:StopDragging()
	barOnDragStop(self.overlay)
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
		self:InitVisibilityDriver()
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
	if self.faded and MouseIsOver(self) then
		self:SetAlpha(self.config.alpha)
		self.faded = nil
	elseif not self.faded and not MouseIsOver(self) then
		local fade = self:GetAttribute("fade")
		if tonumber(fade) then
			fade = min(max(fade, 0), 100) / 100
			self:SetAlpha(fade)
		else
			self:SetAlpha(self.config.fadeoutalpha)
		end
		self.faded = true
	end
end

local directVisCond = {
	pet = true,
	nopet = true,
	combat = true,
	nocombat = true,
	mounted = true,
}
function Bar:InitVisibilityDriver(returnOnly)
	local tmpDriver
	if returnOnly then
		tmpDriver = self.hidedriver
	else
		UnregisterStateDriver(self, 'vis')
	end
	self.hidedriver = {}
		
	self:SetAttribute("_onstate-vis", [[
		if not newstate then return end
		if newstate == "show" then
			self:Show()
			self:SetAttribute("fade", false)
		elseif strsub(newstate, 1, 4) == "fade" then
			self:Show()
			self:SetAttribute("fade", (newstate == "fade") and true or strsub(newstate, 6))
		elseif newstate == "hide" then
			self:Hide()
		end
	]])
	
	if self.config.visibility.custom and not returnOnly then
		table_insert(self.hidedriver, self.config.visibility.customdata or "")
	else
		for key, value in pairs(self.config.visibility) do
			if value then
				if key == "always" then
					table_insert(self.hidedriver, "hide")
				elseif key == "possess" then
					table_insert(self.hidedriver, "[bonusbar:5]hide")
				elseif directVisCond[key] then
					table_insert(self.hidedriver, ("[%s]hide"):format(key))
				elseif key == "stance" then
					for k,v in pairs(value) do
						if v then
							table_insert(self.hidedriver, ("[stance:%d]hide"):format(k))
						end
					end
				elseif key == "custom" or key == "customdata" then
					-- do nothing
				else
					Bartender4:Print("Invalid visibility state: "..key)
				end
			end
		end
	end
	table_insert(self.hidedriver, self.config.fadeout and "fade" or "show")
	
	if not returnOnly then
		self:ApplyVisibilityDriver()
	else
		self.hidedriver, tmpDriver = tmpDriver, self.hidedriver
		return table_concat(tmpDriver, ";")
	end
end

function Bar:ApplyVisibilityDriver()
	if self.unlocked then return end
	-- default state is shown
	local driver = table_concat(self.hidedriver, ";")
	RegisterStateDriver(self, "vis", driver)
end

function Bar:DisableVisibilityDriver()
	UnregisterStateDriver(self, "vis")
	self:SetAttribute("state-vis", "show")
	self:Show()
end

function Bar:GetVisibilityOption(option, index)
	if option == "stance" then
		return self.config.visibility.stance[index]
	else
		return self.config.visibility[option]
	end
end

function Bar:SetVisibilityOption(option, value, arg)
	if option == "stance" then
		self.config.visibility.stance[value] = arg
	else
		self.config.visibility[option] = value
	end
	self:InitVisibilityDriver()
end

function Bar:CopyCustomConditionals()
	self.config.visibility.customdata = self:InitVisibilityDriver(true)
	self:InitVisibilityDriver()
end

function Bar:Enable()
	if not self.disabled then return end
	self.disabled = nil
end

function Bar:Disable()
	if self.disabled then return end
	self:Lock()
	self.disabled = true
	self:UnregisterAllEvents()
	self:DisableVisibilityDriver()
	self:SetAttribute("state-vis", nil)
	self:Hide()
end

--[[
	Lazyness functions
]]
function Bar:ClearSetPoint(...)
	self:ClearAllPoints()
	self:SetPoint(...)
end
