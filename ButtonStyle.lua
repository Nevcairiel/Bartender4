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
	["zoom"] = { texCoord = {0.06, 0.94, 0.06, 0.94} },
	["dream"] = { 
		texCoord = {0.08,0.92,0.08,0.92},
		padding = 3,
		overlay = true,
		FrameFunc = function(button) 
			local frame = CreateFrame("Frame", button:GetName().."DreamLayout", button)
			frame:ClearAllPoints()
			frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 1, edgeFile = "", edgeSize = 0, insets = {left = 0, right = 0, top = 0, bottom = 0},})
			frame:SetBackdropColor(0, 0, 0, 0.6)
			frame:SetAllPoints(button)
			frame:SetFrameLevel(0)
			return frame
		end,
	},
}

function Bartender4.ButtonStyle.ApplyStyle(button, style)
	if not button.icon then return end
	local style = styledata[style]
	
	if style.overlay and style.FrameFunc and (not button.overlay or button.overlay.type ~= style) then 
		if button.overlay then button.overlay:Hide() end
		button.overlay = style.FrameFunc(button)
	else
		if button.overlay then 
			button.overlay:Hide()
			button.overlay = nil
		end
	end

	
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
