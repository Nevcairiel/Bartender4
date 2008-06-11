--[[ $Id$ ]]

local ActionBar = Bartender4.ActionBar

local module = Bartender4:GetModule("ActionBars")

local table_insert = table.insert
local table_concat = table.concat
local fmt = string.format

local modifiers = { "ctrl", "alt", "shift" }

local function tfind(haystack, needle, searchfunc)
	for i,v in pairs(haystack) do
		if (searchfunc and searchfunc(v, needle) or (v == needle)) then return i end
	end
	return nil
end

local optGetter, optSetter
do
	local getBar, optionMap, callFunc
	
	optionMap = {
		stance = "StanceStateOption",
		enabled = "StateOption",
		def_state = "DefaultState",
		states = "StateOption",
		actionbar = "StateOption",
		possess = "StateOption",
		autoassist = "ConfigAutoAssist",
	}
	-- retrieves a valid bar object from the modules actionbars table
	function getBar(id)
		local bar = module.actionbars[tonumber(id)]
		assert(bar, "Invalid bar id in options table.")
		return bar
	end
	
	-- calls a function on the bar
	function callFunc(bar, type, option, ...)
		local func = type .. (optionMap[option] or option)
		assert(bar[func], "Invalid get/set function."..func)
		return bar[func](bar, ...)
	end
	
	-- universal function to get a option
	function optGetter(info)
		local bar = getBar(info[2])
		local option = info.arg or info[#info]
		return callFunc(bar, "Get", option, info[#info])
	end
	
	-- universal function to set a option
	function optSetter(info, ...)
		local bar = getBar(info[2])
		local option = info.arg or info[#info]
		return callFunc(bar, "Set", option, info[#info], ...)
	end
end


local hasStances

--local validStanceTable = { ["-1"] = "Hide", ["0"] = "Don't Page", ["1"] = ("Page  %d"):format(1), ["2"] = ("Page  %d"):format(2), ["3"] = ("Page  %d"):format(3), ["4"] = ("Page  %d"):format(4), ["5"] = ("Page  %d"):format(5), ["6"] = ("Page  %d"):format(6), ["7"] = ("Page  %d"):format(7), ["8"] = ("Page  %d"):format(8), ["9"] = ("Page  %d"):format(9), ["10"] = ("Page  %d"):format(10) }

local validStanceTable = { 
	[-1] = "Hide", 
	[0] = "Don't Page", 
	("Page %2d"):format(1),
	("Page %2d"):format(2), 
	("Page %2d"):format(3), 
	("Page %2d"):format(4), 
	("Page %2d"):format(5), 
	("Page %2d"):format(6), 
	("Page %2d"):format(7), 
	("Page %2d"):format(8),
	("Page %2d"):format(9), 
	("Page %2d"):format(10) 
}


local _, playerclass = UnitClass("player")

local function createOptionGroup(k, id)
	local tbl = {
		order = 10 * k,
		type = "select",
		arg = "stance",
		values = validStanceTable,
		name = module.DefaultStanceMap[playerclass][k].name,
	}
	return tbl
end

local disabledFunc = function(info)
	local bar = module.actionbars[tonumber(info[2])]
	return not bar:GetStateOption("enabled")
end

function module:GetStateOptionsTable()
	local options = {
		enabled = {
			order = 1,
			type = "toggle",
			name = "Enabled",
			desc = "Enable State-based Button Swaping",
			get = optGetter,
			set = optSetter,
		},
		sep1 = {
			order = 2,
			type = "description",
			name = "",
		},
		actionbar = {
			order = 5,
			type = "toggle",
			name = "ActionBar Switching",
			desc = "Enable Bar Switching based on the actionbar controls provided by the game.",
			get = optGetter,
			set = optSetter,
		},
		possess = {
			order = 5,
			type = "toggle",
			name = "Possess Bar",
			desc = "Switch this bar to the Possess Bar when possessing a npc (eg. Mind Control)",
			get = optGetter,
			set = optSetter,
			width = "half",
		},
		autoassist = {
			order = 6,
			type = "toggle",
			name = "Auto-Assist",
			desc = "Enable Auto-Assist for this bar.\n Auto-Assist will automatically try to cast on your target's target if your target is no valid target for the selected spell.",
			get = optGetter,
			set = optSetter,
			width = "half",
		},
		def_desc = {
			order = 10,
			type = "description",
			name = "The default behaviour of this bar when no state-based paging option affects it.",
		},
		def_state = {
			order = 11,
			type = "select",
			name = "Default Bar State",
			values = validStanceTable,
			get = optGetter,
			set = optSetter,
			disabled = disabledFunc,
		},
		modifiers = {
			order = 30,
			type = "group",
			inline = true,
			name = "",
			get = optGetter,
			set = optSetter,
			disabled = disabledFunc,
			args = {
				header = {
					order = 1,
					type = "header",
					name = "Modifier Based Switching",
				},
				ctrl = {
					order = 10,
					type = "select",
					name = "CTRL",
					arg = "states",
					values = validStanceTable,
					desc = "Configure actionbar paging when the ctrl key is down.",
					--width = "half",
				},
				alt = {
					order = 15,
					type = "select",
					name = "ALT",
					arg = "states",
					values = validStanceTable,
					desc = "Configure actionbar paging when the alt key is down.",
					--width = "half",
				},
				shift = {
					order = 20,
					type = "select",
					name = "SHIFT",
					arg = "states",
					values = validStanceTable,
					desc = "Configure actionbar paging when the shift key is down.",
					--width = "half",
				},
			},
		},
		stances = {
			order = 20,
			type = "group",
			inline = true,
			name = "",
			hidden = function() return not (module.DefaultStanceMap[playerclass]) end,
			get = optGetter,
			set = optSetter,
			disabled = disabledFunc,
			args = {
				stance_header = {
					order = 1,
					type = "header",
					name = "Stance Configuration",
				},
			},
		},
	}
	
	do
		local defstancemap = self.DefaultStanceMap[playerclass]
		if defstancemap then
			for k,v in pairs(defstancemap) do
				if not options.stances.args[v.id] then
					options.stances.args[v.id] = createOptionGroup(k, v.id)
				end
			end
		end
	end
	
	return options
end

-- specifiy the available stances for each class
module.DefaultStanceMap = setmetatable({}, { __index = function(t,k)
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
			{ id = "moonkintree", name = ("%s/%s"):format((GetSpellInfo(24858)), (GetSpellInfo(33891))), index = 2 },
		}
	elseif k == "ROGUE" then
		newT = {
			{ id = "stealth", name = GetSpellInfo(1784), index = 1 },
		}
	elseif k == "PRIEST" then
		newT = {
			{ id = "shadowform", name = GetSpellInfo(15473), index = 1 },
		}
	end
	rawset(t, k, newT)
	
	return newT
end})

local searchFunc = function(h, n) return (h.match == n or h.match2 == n or h.id == n) end
function module:CreateStanceMap()
	local defstancemap = self.DefaultStanceMap[playerclass]
	if not defstancemap then return end
	
	self.stancemap = defstancemap
end

function ActionBar:UpdateStates()
	self.statebutton = {}
	if not module.stancemap and module.DefaultStanceMap[playerclass] then 
		module.stancemap = module.DefaultStanceMap[playerclass]
	end
	for i=0,10 do
		self:AddButtonStates(i)
	end
	
	local statedriver = {}
	if self:GetStateOption("possess") then
		self:AddButtonStates(11)
		table_insert(statedriver, "[bonusbar:5]11")
	end
	
	local stateconfig = self.config.states
	if self:GetStateOption("enabled") then
		-- arguments will be parsed from left to right, so we have a priority here
		
		-- highest priority have our temporary quick-swap keys
		for _,v in pairs(modifiers) do
			local page = self:GetStateOption(v)
			if page and page ~= 0 then
				table_insert(statedriver, fmt("[modifier:%s]%s", v, page)) 
			end
		end
		
		-- second priority the manual changes using the actionbar options
		if self:GetStateOption("actionbar") then
			for i=2,6 do
				table_insert(statedriver, fmt("[actionbar:%s]%s", i, i))
			end
		end
		
		-- third priority the stances
		if module.stancemap then
			if not stateconfig.stance[playerclass] then stateconfig.stance[playerclass] = {} end
			for i,v in pairs(module.stancemap) do
				local state = self:GetStanceState(v)
				if state and state ~= 0 and v.index then
					if playerclass == "DRUID" and v.id == "cat" then
						local prowl = self:GetStanceState("prowl")
						if prowl then
							table_insert(statedriver, fmt("[bonusbar:%s,stealth:1]%s", v.index, prowl))
						end
					end
					table_insert(statedriver, fmt("[bonusbar:%s]%s", v.index, state))
				end
			end
		end
	end
	
	table_insert(statedriver, tostring(self:GetDefaultState() or 0))
	
	RegisterStateDriver(self, "page", table_concat(statedriver, ";"))
	self:SetAttribute("statemap-page", "$input")
	self:SetAttribute("state", self:GetAttribute("state-page"))
	
	self:ApplyStateButton()
	
	SecureStateHeader_Refresh(self)
end

function ActionBar:GetStanceState(stance)
	local stanceconfig = self.config.states.stance[playerclass]
	if type(stance) == "table" then 
		state = stanceconfig[stance.id]
	else
		state = stanceconfig[stance]
	end
	return state or 0
end

function ActionBar:GetStanceStateOption(stance)
	local state = self:GetStanceState(stance)
	return state
end

function ActionBar:SetStanceStateOption(stance, state)
	local stanceconfig = self.config.states.stance[playerclass]
	stanceconfig[stance] = state
	self:UpdateStates()
end

function ActionBar:AddButtonStates(state, page)
	if not page then page = state end
	for _, button in self:GetAll() do
		local action = (page == 0) and button.id or (button.rid + (page - 1) * 12)
		button:SetStateAction(state, action)
	end
	self:AddRightClickState(state)
	self:AddToStateButton(state)
end

function ActionBar:AddToStateButton(state)
	if not self.statebutton then self.statebutton = {} end
	if not tfind(self.statebutton, state) then 
		table_insert(self.statebutton, state)
	end
end

function ActionBar:AddRightClickState(state)
	local scrc = Bartender4.db.profile.selfcastrightclick
	local target = scrc and "player" or nil
	
	self:SetAttribute("unit-S" .. state .. "Right", target)
end

function ActionBar:ApplyStateButton()
	local states1, states2 = {}, {}
	for _,v in pairs(self.statebutton) do
		table_insert(states1, fmt("%s:S%s;", v, v))
		table_insert(states2, fmt("%s:S%sRight;", v, v))
	end
	self:SetAttribute("statebutton", table_concat(states1, ""))
	self:SetAttribute("statebutton2", table_concat(states2, ""))
end

function ActionBar:GetStateOption(key)
	return self.config.states[key]
end

function ActionBar:SetStateOption(key, value)
	self.config.states[key] = value
	self:UpdateStates()
end

function ActionBar:GetDefaultState()
	return self.config.states.default
end

function ActionBar:SetDefaultState(_, value)
	self.config.states.default = value
	self:UpdateStates()
end

function ActionBar:GetConfigAutoAssist()
	return self.config.autoassist
end

function ActionBar:SetConfigAutoAssist(_, value)
	if value ~= nil then
		self.config.autoassist = value
	end
	self:UpdateStates()
end
