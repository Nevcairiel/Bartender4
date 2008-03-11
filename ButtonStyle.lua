--[[
	Button Style Template
]]

--[[ $Id$ ]]

Bartender4.ButtonStyle = {}

local styles = {
	["default"] = "Default",
	["zoom"] = "Full Zoom",
	["dream"] = "Dreamlayout",
}

local styledata = {
	["default"] = {},
	["zoom"] = { texCoord = {0.07, 0.93, 0.07, 0.93} },
	["dream"] = { 
		texCoord = {0.08,0.92,0.08,0.92},
		padding = 3,
		overlay = true,
		FrameFunc = function(button) 
			local name = button:GetName().."DreamLayout"
			local frame = _G[name] or CreateFrame("Frame", name, button)
			frame:ClearAllPoints()
			frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 1, edgeFile = "", edgeSize = 0, insets = {left = 0, right = 0, top = 0, bottom = 0},})
			frame:SetBackdropColor(0, 0, 0, 0.6)
			frame:SetAllPoints(button)
			frame:SetFrameLevel(button:GetFrameLevel() - 2)
			frame:Show()
			frame.type = "dream"
			frame.hidegrid = true
			return frame
		end,
	},
}

local cydb

function Bartender4.ButtonStyle.ApplyStyle(button, styleName)
	if not button.icon then return end
	local style = styledata[styleName]
	
	local cy = cydb and cydb.profile[button:GetParent().id]
	--DevTools_Dump(cydb and cydb.profile)
	
	if cy then
		style = styledata.default
		if button.overlay then
			button.overlay:Hide()
		end
		button.overlay = _G[button:GetName() .. "Overlay"]
		button.overlay.type = "cy"
	end
	
	if style.overlay and style.FrameFunc then
		if not button.overlay or button.overlay.type ~= styleName then 
			if button.overlay then button.overlay:Hide() end
			button.overlay = style.FrameFunc(button)
		end
	else
		if button.overlay and button.overlay.type ~= "cy" then 
			button.overlay:Hide()
			button.overlay = nil
		end
	end
	
	if cy then return end
	
	if style.texCoord then
		button.icon:SetTexCoord(unpack(style.texCoord))
	else
		button.icon:SetTexCoord(0,1,0,1)
	end
	
	button.icon:ClearAllPoints()
	if style.padding then
		button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", style.padding, -style.padding)
		button.icon:SetPoint("BOTTOMRIGHT",button, "BOTTOMRIGHT",  -style.padding, style.padding)
	else
		button.icon:SetAllPoints(button)
	end
end

function Bartender4.ButtonStyle:GetStyles()
	return styles
end

function Bartender4:cyLoaded()
	cydb = cyCircled_Bartender4 and cyCircled_Bartender4.db
	Bartender4.Bar:ForAll("ApplyConfig")
end
