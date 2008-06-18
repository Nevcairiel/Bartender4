--[[ $Id$ ]]
local L = LibStub("AceLocale-3.0"):NewLocale("Bartender4", "zhCN")
if not L then return end
--General 
L["Enabled"] = "开启"
L["General Settings"] = "一般设置"
-- Options.lua
L["Lock"] = "锁定"
L["Lock all bars."] = "锁定所有动作条。"
L["Bars"] = "动作条"
L["Self-Cast by modifier"] = "修改自我施法"
L["Toggle the use of the modifier-based self-cast functionality."] = "关闭/开启 自我施法功能。"
L["Right-click Self-Cast"] = "右键自我施法"
L["Toggle the use of the right-click self-cast functionality."] = "关闭/开启 使用右键点击对自己施法功能。"
L["Out of Range Indicator"] = "射程指示器"
L["Configure how the Out of Range Indicator should display on the buttons."] = "显示/隐藏 射程基本按钮着色。"
L["Colors"] = "颜色设置"
L["Out of Range Indicator"] = "射程指示器"
L["Specify the Color of the Out of Range Indicator"] = "设置射程之外的标识颜色"
L["Out of Mana Indicator"] = "低法力指示器"
L["Specify the Color of the Out of Mana Indicator"] = "设置法力不足的标识颜色"
L["Button Tooltip"] = "按钮鼠标提示"
L["Configure the Button Tooltip"] = "设置按钮的鼠标提示。"
L["FAQ"] = "帮助"
L["Frequently Asked Questions"] = "帮助信息"
--ActionBarPrototype.lua
L["Enable/Disable the bar."] = "开启/关闭 该动作条"
L["Button Grid"] = "显示空按钮"
L["Toggle the button grid."] = "勾选该选项将显示空的按钮。"
L["Buttons"] = "按钮"
L["Number of buttons."] = "设置按钮的数量。"
L["Button Look"] = "锁定按键"
L["Hide Macro Text"] = "隐藏宏名称"
L["Hide the Macro Text on the buttons of this bar."] = "在该动作条上不显示宏的名称。"
L["Hide Hotkey"] = "隐藏快捷键"
L["Hide the Hotkey on the buttons of this bar."] = "在该动作条上不显示按钮的快捷键提示。"
L["State Configuration"] = "状态配置"
--ActionBars.lua
L["Enable/Disable the bar."] = "开启/关闭 该动作条。"
L["Bar %s"] = "动作条 %s"
L["Configure Bar %s"] = "设置动作条 %s"
--ActionBarStates.lua
L["Enable State-based Button Swaping"] = "开始基于状态配置的按钮切换功能。"
L["ActionBar Switching"] = "切换动作条"
L["Enable Bar Switching based on the actionbar controls provided by the game"] = "开启游戏本身的动作条切换功能。（诸如战士的不同姿态下主动作条1的切换）"
L["Possess Bar"] = "控制栏"
L["Switch this bar to the Possess Bar when possessing a npc (eg. Mind Control)"] = "当控制某个NPC时切换该动作条至控制技能栏。（例如心灵控制）"
L["Auto-Assist"] = "自动协助"
L["Enable Auto-Assist for this bar.\n Auto-Assist will automatically try to cast on your target's target if your target is no valid target for the selected spell."] = "为该动作条开启自动协助。\n 当你所尝试使用的技能不能对你当前目标生效时，自动协助会尝试对目标的目标使用该技能。"
L["The default behaviour of this bar when no state-based paging option affects it."] = "当没有状态配置作用于该动作条时的动作条默认行为"
L["Default Bar State"] = "默认动作条状态"
L["Modifier Based Switching"] = "修改基本切换"
L["CTRL"] = "按下CTRL"
L["Configure actionbar paging when the ctrl key is down."] = "配置当按下CTRL键时动作条的页面"
L["ALT"] = "按下ALT"
L["Configure actionbar paging when the alt key is down."] = "配置当按下ALT键时动作条的页面"
L["SHIFT"] = "按下SHIFT"
L["Configure actionbar paging when the shift key is down."] = "配置当按下SHIFT键时动作条的页面"
L["Stance Configuration"] = "姿态配置"
--BagBar.lua
L["Enable the Bag Bar"] = "开启背包栏"
L["One Bag"] = "单背包"
L["Only show one Bag Button in the BagBar."] = "仅仅显示一个背包来代表背包栏。"
L["Keyring"] = "钥匙链"
L["Show the keyring button."] = "显示钥匙链"
L["Bag Bar"] = "背包栏"
L["Configure the Bag Bar"] = "设置背包栏。"
--Bar.lua
L["Show/Hide"] = "显示/隐藏"
L["Configure when to Show/Hide the bar."] = "配置何时显示/隐藏动作条。"
L["Bar Style & Layout"] = "动作条风格与布局"
L["Alpha"] = "透明度"
L["Configure the alpha of the bar."] = "设置动作条的透明度。"
L["Scale"] = "缩放"
L["Configure the scale of the bar."] = "设置动作条缩放。"
L["Fade Out"] = "淡出"
L["Enable the FadeOut mode"] = "开启淡出模式"
L["Fade Out Alpha"] = "淡出程度"
L["Fade Out Delay"] = "淡出延迟"
L["Alignment"] = "对齐"
L["The Alignment menu is still on the TODO.\n\nAs a quick preview of whats planned:\n\n\t- Absolute and relative Bar Positioning\n\t- Bars \"snapping\" together and building clusters"] = "该部分功能尚未完成"
L["Always Show"] = "始终显示"
L["Always Hide"] = "始终隐藏"
L["Show in Combat"] = "战斗中显示"
L["Hide in Combat"] = "战斗中隐藏"
--ButtonBar.lua
L["Padding"] = "间距"
L["Configure the padding of the buttons."] = "配置按钮之间的距离"
L["Zoom"] = "缩放"
L["Toggle Button Zoom\nFor more style options you need to install ButtonFacade"] = "开启/关闭 按钮缩放\n若需要进一步改变按钮风格，您需要安装插件ButtonFacade"
L["Rows"] = "行"
L["Number of rows."] = "设置行数。"
--MicroMenu.lua
L["Enabled"] = "开启"
L["Enable the Micro Menu"] = "开启微型主菜单"
L["Micro Menu"] = "微型主菜单"
L["Configure the Micro Menu"] = "配置微型主菜单"
--PetBar.lua
L["Enable the PetBar"] = "开启宠物栏"
L["Pet Bar"] = "宠物栏"
L["Configure the Pet Bar"] = "配置宠物栏"
--StanceBar.lua
L["Enable the StanceBar"] = "开启姿态栏"
L["Stance Bar"] = "姿态栏"
L["Configure  the Stance Bar"] = "配置姿态栏"

L["FAQ_TEXT"] = [[
|cffffd200
我刚刚安装了Bartender4，发现我的按键绑定似乎不太正确。
|r
Bartender4仅仅将主动作条1与Bartender4的动作条1关联起来，游戏其他动作条的设置不会转移到Bartender4上，不过您之前设置的快捷键仍然是有效的，它们仅仅是被隐藏了起来而已。

|cffffd200
我如何才能为Bartender4的按钮设置快捷键?
|r
在聊天窗口输入命令 /kb ，会弹出一个窗口，此时移动鼠标到您需要设置快捷键的按钮上，按下您需要设置的快捷键，屏幕上会显示出您将要绑定的按键，确认无误后关闭弹出的窗口即可。

|cffffd200
谁写的这个插件?
|r
Bartender4是欧洲服务器Antonidas的玩家 Nevcairiel 的作品, 该玩家同时也是Bartender3的作者!
简体中文版本是由7区加里索斯服务器联盟玩家 提珞德夜行 提供的。
]]