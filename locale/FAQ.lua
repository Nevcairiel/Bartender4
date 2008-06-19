--[[ $Id$ ]]
local L = LibStub("AceLocale-3.0"):NewLocale("Bartender4_FAQ", "enUS", true)
if not L then return end

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

-- koKR
local L = LibStub("AceLocale-3.0"):NewLocale("Bartender4_FAQ", "koKR")
if L then
	L["FAQ_TEXT"] = [[
|cffffd200
방금 Bartender4를 설치했습니다. 그런데 단축키가 표시되지 않거나 전부 작동하지 않아요.
|r
Bartender4는 직접적으로 사용할 수 있는 1번 바의 단축키만 적용됩니다. 다른 바는 Bartender4의 단축키에 영향 받습니다. 단축키를 정상적으로 설정했다면 버튼에 단축키가 표시됩니다. 버튼에 단축키가 전부 정상적으로 표시된다면 모든 기능은 정상적으로 작동할 것입니다.

|cffffd200
그러면 어떻게 Bartender4의 단축키를 변경할 수 있나요?
|r
미니맵/FuBar/기타의 빠른 설정이 적용되기 전까지 |cffffff78/kb|r 명령어를 사용해 단축키를 설정할 수 있습니다. 

간편하게 단축키를 설정하기 위해서 버튼위에 마우스를 올려 놓고 설정할 키를 누르면 됩니다. 이미 버튼에 단축키가 지정되어 있거나 단축키 지정이 성공적으로 완료되면 keyBound 툴팁과 화면에 이를 표시합니다.

|cffffd200
버그를 발견했습니다! 리포팅 할려면 어떻게 해야 하나요?
|r
버고 보고나 제안은 |cffffff78http://www.wowace.com/forums/index.php?topic=13258.0|r로 하실 수 있습니다.

또한 |cffffff78irc://irc.freenode.org/wowace|r에서 저희를 만나실 수 있습니다.

버그를 리포팅 하실 때 가능하다면 |cffffff78영어 또는 기타|r의 클라이언트를 사용하는지의 상황과 더불어 |cffffff78버그가 어떻게 발생하는지 단계적 내용|r과 어떤 |cffffff78오류 메세지|r가 중복 기록되는지를 발생한 Bartender4의 |cffffff78revision 숫자|r를 포함하여 알려주시기 바랍니다.

|cffffd200
누가 이 멋진 애드온을 만들었나요?
|r
Bartender4는 EU-Antonidas의 Nevcairiel가 만들었습니다. 바로 Bartender3의 제작자입니다!
]]
end

-- zhCN
local L = LibStub("AceLocale-3.0"):NewLocale("Bartender4_FAQ", "zhCN")
if L then
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
end
