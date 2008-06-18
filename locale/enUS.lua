--[[ $Id$ ]]
local L = LibStub("AceLocale-3.0"):NewLocale("Bartender4", "enUS", true)
if not L then return end
--General 
L["Enabled"] = true
L["General Settings"] = true
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
--ActionBarPrototype.lua
L["Enable/Disable the bar."] = true
L["Button Grid"] = true
L["Toggle the button grid."] = true
L["Buttons"] = true
L["Number of buttons."] = true
L["Button Look"] = true
L["Hide Macro Text"] = true
L["Hide the Macro Text on the buttons of this bar."] = true
L["Hide Hotkey"] = true
L["Hide the Hotkey on the buttons of this bar."] = true
L["State Configuration"] = true
--ActionBars.lua
L["Enable/Disable the bar."] = true
L["Bar %s"] = true
L["Configure Bar %s"] = true
--ActionBarStates.lua
L["Enable State-based Button Swaping"] = true
L["ActionBar Switching"] = true
L["Enable Bar Switching based on the actionbar controls provided by the game."] = true
L["Possess Bar"] = true
L["Switch this bar to the Possess Bar when possessing a npc (eg. Mind Control)"] = true
L["Auto-Assist"] = true
L["Enable Auto-Assist for this bar.\n Auto-Assist will automatically try to cast on your target's target if your target is no valid target for the selected spell."] = true
L["The default behaviour of this bar when no state-based paging option affects it."] = true
L["Default Bar State"] = true
L["Modifier Based Switching"] = true
L["CTRL"] = true
L["Configure actionbar paging when the ctrl key is down."] = true
L["ALT"] = true
L["Configure actionbar paging when the alt key is down."] = true
L["SHIFT"] = true
L["Stance Configuration"] = true
--BagBar.lua
L["Enable the Bag Bar"] = true
L["One Bag"] = true
L["Only show one Bag Button in the BagBar."] = true
L["Keyring"] = true
L["Show the keyring button."] = true
L["Bag Bar"] = true
L["Configure the Bag Bar"] = true
--Bar.lua
L["Show/Hide"] = true
L["Configure when to Show/Hide the bar."] = true
L["Bar Style & Layout"] = true
L["Alpha"] = true
L["Configure the alpha of the bar."] = true
L["Scale"] = true
L["Configure the scale of the bar."] = true
L["Fade Out"] = true
L["Enable the FadeOut mode"] = true
L["Fade Out Alpha"] = true
L["Fade Out Delay"] = true
L["Alignment"] = true
L["The Alignment menu is still on the TODO.\n\nAs a quick preview of whats planned:\n\n\t- Absolute and relative Bar Positioning\n\t- Bars \"snapping\" together and building clusters"] = true
L["Always Show"] = true
L["Always Hide"] = true
L["Show in Combat"] = true
L["Hide in Combat"] = true
--ButtonBar.lua
L["Padding"] = true
L["Configure the padding of the buttons."] = true
L["Zoom"] = true
L["Toggle Button Zoom\nFor more style options you need to install ButtonFacade"] = true
L["Rows"] = true
L["Number of rows."] = true
--MicroMenu.lua
L["Enable the Micro Menu"] = true
L["Micro Menu"] = true
L["Configure the Micro Menu"] = true
--PetBar.lua
L["Enable the PetBar"] = true
L["Pet Bar"] = true
L["Configure the Pet Bar"] = true
--StanceBar.lua
L["Enable the StanceBar"] = true
L["Stance Bar"] = true
L["Configure  the Stance Bar"] = true


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
