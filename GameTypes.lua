local _, Bartender4 = ...

local buildVersion = select(4, GetBuildInfo())

-- game types
Bartender4.GameType = {}
Bartender4.GameType.MainlineStandard = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) and buildVersion > 120000
Bartender4.GameType.Forever          = buildVersion >= 16001 and buildVersion < 20000 -- TODO: clean this up once it gets its own project id
Bartender4.GameType.ClassicEra       = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
Bartender4.GameType.ClassicBCC       = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
Bartender4.GameType.ClassicWrath     = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
Bartender4.GameType.ClassicCata      = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
Bartender4.GameType.ClassicMists     = (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC)

-- compound game types
Bartender4.GameType.Mainline         = Bartender4.GameType.MainlineStandard or Bartender4.GameType.Forever
Bartender4.GameType.Classic          = not Bartender4.GameType.Mainline

-- version features
Bartender4.Features = {}
Bartender4.Features.ModernArtwork = Bartender4.GameType.Mainline
Bartender4.Features.ModernButtons = Bartender4.GameType.Mainline
Bartender4.Features.MainlineBarLayout = Bartender4.GameType.Mainline

-- #region safety metatables
local gameTypeSafetyMT = {
    __index = function(t, k)
        error("Attempt to access unknown game type: " .. tostring(k), 2)
    end,
    __newindex = function(t, k, v)
        error("Attempt to set unknown game type: " .. tostring(k), 2)
    end
}
setmetatable(Bartender4.GameType, gameTypeSafetyMT)

local featureSafetyMT = {
    __index = function(t, k)
        error("Attempt to access unknown feature: " .. tostring(k), 2)
    end,
    __newindex = function(t, k, v)
        error("Attempt to set unknown feature: " .. tostring(k), 2)
    end
}
setmetatable(Bartender4.Features, featureSafetyMT)
-- #endregion
