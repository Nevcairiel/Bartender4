-- Bartender4 Locale
-- Please use the Localization App on WoWAce to Update this
-- http://www.wowace.com/projects/bartender4/localization/ ;¶

local debug = false
--@debug@
debug = true
--@end-debug@

local L = LibStub("AceLocale-3.0"):NewLocale("Bartender4", "enUS", true, debug)

--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true)@
L["Fade Group"] = true
L["Bars sharing the same Fade Group name will fade out and restore together. Moving your mouse over any bar in the group will un-fade all of them; leave it blank for independent fading."] = true
