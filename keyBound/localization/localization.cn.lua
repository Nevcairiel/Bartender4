--[[
	KeyBound localization file
		Chinese Simplified by ondh
		http://www.ondh.cn
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('KeyBound', 'zhCN')
if not L then return end

L.Enabled = "按键绑定模式已启用"
L.Disabled = "按键绑定模式已禁用"
L.ClearTip = format("按 %s 清除所有绑定", GetBindingText("ESCAPE", "KEY_"))
L.NoKeysBoundTip = "当前没有绑定按键"
L.ClearedBindings = "从 %s 移除按键绑定"
L.BoundKey = "设置 %s 到 %s"
L.UnboundKey = "取消绑定 %s 从 %s"
L.CannotBindInCombat = "不能在战斗状态绑定按键"
L.CombatBindingsEnabled = "离开战斗状态, 按键绑定模式已启用"
L.CombatBindingsDisabled = "进入战斗状态, 按键绑定模式已禁用"