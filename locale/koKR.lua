--[[ $Id$ ]]
local L = LibStub("AceLocale-3.0"):NewLocale("Bartender4", "koKR")
if not L then return end

-- Options.lua
L["Lock"] = "고정"
L["Lock all bars"] = "모든 바를 고정합니다."
L["Bars"] = "바"
L["Self-Cast by modifier"] = "기능키로 자신에게 시전"
L["Toggle the use of the modifier-based self-cast functionality"] = "기능키를 이용하여 자신에게 주문을 시전합니다."
L["Right-click Self-Cast"] = "오른쪽 클릭 자신에게 시전"
L["Toggle the use of the right-click self-cast functionality"] = "마우스 오른쪽 버튼을 클릭하여 자신에게 주문을 시전합니다."
L["Out of Range Indicator"] = "사거리 표시"
L["Configure how the Out of Range Indicator should display on the buttons"] = "주문이나 기술의 사거리에 따른 버튼의 지시기에 관한 설정입니다."
L["Colors"] = "색상"
L["Out of Range Indicator"] = "사거리 표시"
L["Specify the Color of the Out of Range Indicator"] = "사거리 표시를 색상화 합니다."
L["Out of Mana Indicator"] = "마나 표시"
L["Specify the Color of the Out of Mana Indicator"] = "마나 표시를 색상화 합니다."
L["Button Tooltip"] = "버튼 툴팁"
L["Configure the Button Tooltip"] = "버튼에 표시되는 툴팁에 관한 설정입니다."
--L["FAQ"] = "FAQ"
--L["Frequently Asked Questions"] = "Frequently Asked Questions"

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
