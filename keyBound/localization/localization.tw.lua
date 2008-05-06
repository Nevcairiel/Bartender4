--[[
	KeyBound localization file
		Traditional Chinese
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('KeyBound', 'zhTW')
if not L then return end

L.Enabled = "按鍵綁定模式已啟用"
L.Disabled = "按鍵綁定模式已禁用"
L.ClearTip = format("按 %s 清除所有綁定", GetBindingText("ESCAPE", "KEY_"))
L.NoKeysBoundTip = "目前没有綁定按鍵"
L.ClearedBindings = "從 %s 移除按鍵綁定"
L.BoundKey = "設置 %s 到 %s"
L.UnboundKey = "取消綁定 %s 从 %s"
L.CannotBindInCombat = "不能在戰鬥狀態綁定按鍵"
L.CombatBindingsEnabled = "離開戰鬥狀態, 按鍵綁定模式已啟用"
L.CombatBindingsDisabled = "進入戰鬥狀態, 按鍵綁定模式已禁用"