--[[ $Id$ ]]
local L = LibStub("AceLocale-3.0"):NewLocale("Bartender4", "enUS", true)
if not L then return end

-- Options.lua
L["Lock"] = true
L["Lock all bars."] = true
L["Bars"] = true
L["Self-Cast by modifier"] = true
L["Toggle the use of the modifier-based self-cast functionality."] = true
L["Right-click Self-Cast"] = true
L["Toggle the use of the right-click self-cast functionality."] = true
L["Out of Range Indicator"] = true
L["Configure how the Out of Range Indicator should display on the buttons."] = true
L["Colors"] = true
L["Out of Range Indicator"] = true
L["Specify the Color of the Out of Range Indicator"] = true
L["Out of Mana Indicator"] = true
L["Specify the Color of the Out of Mana Indicator"] = true
L["Button Tooltip"] = true
L["Configure the Button Tooltip."] = true
L["FAQ"] = true
L["Frequently Asked Questions"] = true

L["FAQ_TEXT"] = [[
|cffffd200
I just installed Bartender4, but my keybindings do not show up on the buttons/do not work entirely.
|r
Bartender4 only converts the bindings of Bar1 to be directly usable, all other Bars will have to be re-bound to the Bartender4 keys. A direct indicator if your key-bindings are setup correctly is the hotkey display on the buttons. If the key-bindings shows correctly on your button, everything should work fine as well.

|cffffd200
How do I change the Bartender4 Keybindings then?
|r
Until some sort of quick-access menu is put in (Minimap/FuBar/etc.), you will have to use the |cffffff78/kb|r chat command to open the keyBound control. 

Once open, simply hover the button you want to bind, and press the key you want to be bound to that button. The keyBound tooltip and on-screen status will inform you about already existing bindings to that button, and the success of your binding attempt.

|cffffd200
I've found a bug! Where do I report it?
|r
You can report bugs or give suggestions at |cffffff78http://www.wowace.com/forums/index.php?topic=13258.0|r

Alternatively, you can also find us on |cffffff78irc://irc.freenode.org/wowace|r

When reporting a bug, make sure you include the |cffffff78steps on how to reproduce the bug|r, supply any |cffffff78error messages|r with stack traces if possible, give the |cffffff78revision number|r of Bartender4 the problem occured in and state whether you are using an |cffffff78English client or otherwise|r.

|cffffd200
Who wrote this cool addon?
|r
Bartender4 was written by Nevcairiel of EU-Antonidas, the author of Bartender3!
]]
