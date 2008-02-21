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
local num_shapeshift_forms

local function createOptionGroup(k, id)
	local tbl = {
		order = 10 * k,
		type = "select",
		arg = "stance",
		get = optGetter,
		set = optSetter,
		values = validStanceTable,
		name = module.DefaultStanceMap[playerclass][k].name or module.DefaultStanceMap[playerclass][k].match or "BUG",
		hidden = function() return not module.stancemap[k].position end,
	}
	return tbl
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
		},
		stances = {
			order = 20,
			type = "group",
			inline = true,
			name = "",
			hidden = function() return not hasStances end,
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

local S = LibStub("AceLocale-3.0"):GetLocale("BT4Stances")

-- specifiy the available stances for each class
module.DefaultStanceMap = {
	WARRIOR = {
		{ id = "battle", match = S["Battle Stance"] },
		{ id = "def", match = S["Defensive Stance"] },
		{ id = "berserker", match = S["Berserker Stance"] },
	},
	DRUID = {
		{ id = "bear", match = S["Bear Form"], match2 = S["Dire Bear Form"] },
		{ id = "cat", match = S["Cat Form"] },
			-- prowl is virtual, no real stance
		{ id = "prowl", virtual = true, name = "Cat Form (Prowl)", depend = "cat" },
		{ id = "moonkin", match = S["Moonkin Form"] },
		{ id = "tree", match = S["Tree of Life"] },
	},
	ROGUE = {
		{ id = "stealth", match = S["Stealth"] },
	},
	PRIEST = { --shadowform gets a position override because it doesnt have a real stance position .. and priests dont have other stances =)
		{ id = "shadowform", virtual = true, name = "Shadowform", position = 1 },
	}
}

local searchFunc = function(h, n) return (h.match == n or h.match2 == n or h.id == n) end
function module:CreateStanceMap()
	local defstancemap = self.DefaultStanceMap[playerclass]
	if not defstancemap then return end
	
	self.stancemap = {}
	
	num_shapeshift_forms = GetNumShapeshiftForms()
	
	for k,v in pairs(defstancemap) do
		local entry = { id = v.id, match = v.match, match2 = v.match2, virtual = v.virtual, depend = v.depend, position = v.position }
		if not v.virtual and type(v.match) == "string" then
			entry.name = v.match
		elseif not v.virtual and type(v.match) == "table" then
			entry.name = v.match[1]
		else
			entry.name = v.name
		end
		table_insert(self.stancemap, entry)
	end
	
	for i = 1, num_shapeshift_forms do
		local _, name = GetShapeshiftFormInfo(i)
		local index = tfind(self.stancemap, name, searchFunc)
		if index then
			self.stancemap[index].position = i
			if self.stancemap[index].id == "cat" then
				local prowl = tfind(self.stancemap, "prowl", searchFunc)
				self.stancemap[prowl].position = i
			end
		end
	end
	hasStances = (num_shapeshift_forms > 0)
end

function ActionBar:UpdateStates()
	if not module.stancemap and module.DefaultStanceMap[playerclass] then module:CreateStanceMap() end
	for i=0,10 do
		self:AddButtonStates(i)
	end
	
	local statedriver = {}
	if self.id == 1 then
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
		if self.id == 1 then
			for i=2,6 do
				table_insert(statedriver, fmt("[actionbar:%s]%s", i, i))
			end
		end
		
		-- third priority the stances
		if not stateconfig.stance[playerclass] then stateconfig.stance[playerclass] = {} end
		if module.stancemap then
			for i,v in pairs(module.stancemap) do
				local state = self:GetStanceState(v)
				if state and state ~= 0 and v.position then
					if playerclass == "DRUID" and v.id == "cat" then
						local prowl = self:GetStanceState("prowl")
						if prowl then
							table_insert(statedriver, fmt("[stance:%s,stealth:1]%s", v.position, prowl))
						end
					end
					table_insert(statedriver, fmt("[stance:%s]%s", v.position, state))
				end
			end
		end
	end
	
	table_insert(statedriver, "0")
	
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
	return state
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
	
	self:SetAttribute("unit-S" .. state .. "2", target)
end

function ActionBar:ApplyStateButton()
	local states1, states2 = {}, {}
	for _,v in pairs(self.statebutton) do
		table_insert(states1, fmt("%s:S%s1;", v, v))
		table_insert(states2, fmt("%s:S%s2;", v, v))
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
	return self.config.states.stance.default
end

function ActionBar:SetDefaultState(_, value)
	self.config.states.stance.default = value
	self:UpdateStates()
end
