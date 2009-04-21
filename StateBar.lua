--[[
	Copyright (c) 2009, Hendrik "Nevcairiel" Leppkes < h.leppkes at gmail dot com >
	All rights reserved.
]]
--[[ Generic Template for a ButtonBar with state control ]]

local ButtonBar = Bartender4.ButtonBar.prototype
local StateBar = setmetatable({}, {__index = ButtonBar})
local StateBar_MT = {__index = StateBar}

local defaults = Bartender4:Merge({
	autoassist = false,
	states = {
		enabled = false,
		possess = false,
		actionbar = false,
		default = 0,
		ctrl = 0,
		alt = 0,
		shift = 0,
		stance = {
			['*'] = {
			},
		},
	},
}, Bartender4.ButtonBar.defaults)

Bartender4.StateBar = {}
Bartender4.StateBar.prototype = StateBar
Bartender4.StateBar.defaults = defaults

function Bartender4.StateBar:Create(id, config, name)
	local bar = setmetatable(Bartender4.ButtonBar:Create(id, config, name), StateBar_MT)

	return bar
end

StateBar.BT4BarType = "StateBar"

function StateBar:ApplyConfig(config)
	ButtonBar.ApplyConfig(self, config)
	-- We cannot call UpdateStates or UpdateSelfCast now, because the buttons are not yet created *sad*
end

--------------------------------------------------------------
-- Stance Management

local table_insert = table.insert
local table_concat = table.concat
local fmt = string.format

local modifiers = { "ctrl", "alt", "shift" }

local _, playerclass = UnitClass("player")

-- specifiy the available stances for each class
local DefaultStanceMap = setmetatable({}, { __index = function(t,k)
	local newT = nil
	if k == "WARRIOR" then
		newT = {
			{ id = "battle", name = GetSpellInfo(2457), index = 1},
			{ id = "def", name = GetSpellInfo(71), index = 2 },
			{ id = "berserker", name = GetSpellInfo(2458), index = 3 },
		}
	elseif k == "DRUID" then
		newT = {
			{ id = "bear", name = GetSpellInfo(5487), index = 3 },
			{ id = "cat", name = GetSpellInfo(768), index = 1 },
				-- prowl is virtual, no real stance
			{ id = "prowl", name = ("%s (%s)"):format((GetSpellInfo(768)), (GetSpellInfo(5215))), index = false},
			{ id = "moonkin", name = GetSpellInfo(24858), index = 4 },
			{ id = "treeoflife", name = GetSpellInfo(33891), index = 2 },
		}
	elseif k == "ROGUE" then
		newT = {
			{ id = "stealth", name = GetSpellInfo(1784), index = 1 },
			{ id = "shadowdance", name = GetSpellInfo(51713), index = 2 },
		}
	elseif k == "PRIEST" then
		newT = {
			{ id = "shadowform", name = GetSpellInfo(15473), index = 1 },
		}
	elseif k == "WARLOCK" then
		newT = {
			{ id = "metamorphosis", name = GetSpellInfo(59672), index = 2, type = "form"},
		}
	end
	rawset(t, k, newT)

	return newT
end})
Bartender4.StanceMap = DefaultStanceMap

local stancemap
function StateBar:UpdateStates(returnOnly)
	if not self.buttons then return end
	self.statebutton = {}
	if not stancemap and DefaultStanceMap[playerclass] then
		stancemap = DefaultStanceMap[playerclass]
	end

	local statedriver
	if not self:GetStateOption("enabled") then
		statedriver = "0"
	elseif returnOnly or not self:GetStateOption("customEnabled") then
		statedriver = {}
		local stateconfig = self.config.states
		-- arguments will be parsed from left to right, so we have a priority here

		-- possessing will always be the most important change, if enabled
		if self:GetStateOption("possess") then
			table_insert(statedriver, "[bonusbar:5]11")
		end

		-- highest priority have our temporary quick-swap keys
		for _,v in pairs(modifiers) do
			local page = self:GetStateOption(v)
			if page and page ~= 0 then
				table_insert(statedriver, fmt("[mod:%s]%s", v, page))
			end
		end

		-- second priority the manual changes using the ActionBar options
		if self:GetStateOption("actionbar") then
			for i=2,6 do
				table_insert(statedriver, fmt("[bar:%s]%s", i, i))
			end
		end

		-- third priority the stances
		if stancemap then
			if not stateconfig.stance[playerclass] then stateconfig.stance[playerclass] = {} end
			for i,v in pairs(stancemap) do
				local state = self:GetStanceState(v)
				if state and state ~= 0 and v.index then
					-- hack for druid prowl, since its no real "stance", but we want to handle it anyway
					if playerclass == "DRUID" and v.id == "cat" then
						local prowl = self:GetStanceState("prowl")
						if prowl and prowl ~= 0 then
							table_insert(statedriver, fmt("[bonusbar:%s,stealth:1]%s", v.index, prowl))
						end
					end
					table_insert(statedriver, fmt("[%s:%s]%s", v.type or "bonusbar", v.index, state))
				end
			end
		end

		table_insert(statedriver, tostring(self:GetDefaultState() or 0))
		statedriver = table_concat(statedriver, ";")
		if returnOnly then
			return statedriver
		end
	else
		statedriver = self:GetStateOption("custom")
	end

	self:SetAttribute("_onstate-page", [[
		self:SetAttribute("state", newstate)
		control:ChildUpdate("state", newstate)
	]])

	UnregisterStateDriver(self, "page")
	self:SetAttribute("state-page", "0")

	RegisterStateDriver(self, "page", statedriver or "0")

	self:SetAttribute("_onstate-assist-help", [[
		local state = (newstate ~= "nil") and newstate or nil
		control:ChildUpdate("assist-help", state)
	]])

	self:SetAttribute("_onstate-assist-harm", [[
		local state = (newstate ~= "nil") and newstate or nil
		control:ChildUpdate("assist-harm", state)
	]])

	local preSelf = ""
	if Bartender4.db.profile.selfcastmodifier then
		preSelf = "[mod:SELFCAST]player;"
	end

	local preFocus = ""
	if Bartender4.db.profile.focuscastmodifier then
		preFocus = "[mod:FOCUSCAST,target=focus,exists,nodead]focus;"
	end

	UnregisterStateDriver(self, "assist-help")
	self:SetAttribute("state-assist-help", "nil")
	UnregisterStateDriver(self, "assist-harm")
	self:SetAttribute("state-assist-harm", "nil")

	if self.config.autoassist then
		RegisterStateDriver(self, "assist-help", ("%s%s[help]nil; [target=targettarget, help]targettarget; nil"):format(preSelf, preFocus))
		RegisterStateDriver(self, "assist-harm", ("%s[harm]nil; [target=targettarget, harm]targettarget; nil"):format(preFocus))
	end

	self:ForAll("UpdateStates")
	self:Execute([[
		control:ChildUpdate("init")
	]])
end

function StateBar:GetStanceState(stance)
	local stanceconfig = self.config.states.stance[playerclass]
	if type(stance) == "table" then
		state = stanceconfig[stance.id]
	else
		state = stanceconfig[stance]
	end
	return state or 0
end

function StateBar:GetStanceStateOption(stance)
	local state = self:GetStanceState(stance)
	return state
end

function StateBar:SetStanceStateOption(stance, state)
	local stanceconfig = self.config.states.stance[playerclass]
	stanceconfig[stance] = state
	self:UpdateStates()
end

function StateBar:GetStateOption(key)
	return self.config.states[key]
end

function StateBar:SetStateOption(key, value)
	self.config.states[key] = value
	self:UpdateStates()
end

function StateBar:GetDefaultState()
	return self.config.states.default
end

function StateBar:SetDefaultState(_, value)
	self.config.states.default = value
	self:UpdateStates()
end

function StateBar:GetConfigAutoAssist()
	return self.config.autoassist
end

function StateBar:SetConfigAutoAssist(_, value)
	if value ~= nil then
		self.config.autoassist = value
	end
	self:UpdateStates()
end

function StateBar:SetCopyCustomConditionals()
	self.config.states.custom = self:UpdateStates(true)
	self:UpdateStates()
end

function StateBar:UpdateSelfCast()
	self:ForAll("UpdateSelfCast")
	self:UpdateStates()
end
