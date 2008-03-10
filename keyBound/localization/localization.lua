--[[
	KeyBound localization file
		English (default)
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('KeyBound', 'enUS', true)

L.Enabled = 'Bindings mode enabled'
L.Disabled = 'Bindings mode disabled'
L.ClearTip = format('Press %s to clear all bindings', GetBindingText('ESCAPE', 'KEY_'))
L.NoKeysBoundTip = 'No current bindings'
L.ClearedBindings = 'Removed all bindings from %s'
L.BoundKey = 'Set %s to %s'
L.UnboundKey = 'Unbound %s from %s'
L.CannotBindInCombat = 'Cannot bind keys in combat'
L.CombatBindingsEnabled = 'Exiting combat, keybinding mode enabled'
L.CombatBindingsDisabled = 'Entering combat, keybinding mode disabled'
L.BindingsHelp = "Hover over a button, then press a key to set its binding.  To clear a button's current keybinding, press %s."