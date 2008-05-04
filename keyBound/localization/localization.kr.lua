--[[
	KeyBound localization file
		Korean by damjau
		
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('KeyBound', 'koKR')
if not L then return end

L.Enabled = '단축키 설정 기능 사용 가능'
L.Disabled = '단축키 설정 기능 사용 불가'
L.ClearTip = format('%s키를 누르면 모든 단축키가 초기화됩니다', GetBindingText('ESCAPE', 'KEY_'))
L.NoKeysBoundTip = '현재 단축키 없음'
L.ClearedBindings = '%s의 모든 단축키가 초기화 되었습니다'
L.BoundKey = '%2$s의 단축키로 %1$s|1을;를; 설정합니다.'
L.UnboundKey = '%2$s에서 %1$s의 단축키가 삭제되었습니다'
L.CannotBindInCombat = '전투 중에는 단축키를 지정할 수 없습니다'
L.CombatBindingsEnabled = '전투 종료. 단축키 설정이 가능해집니다'
L.CombatBindingsDisabled = '전투 시작. 단축키 설정이 불가능합니다'
L.BindingsHelp = "버튼 위에 마우스를 올려 놓고 지정할 키를 누르세요.  버튼의 현재 단축키를 삭제하시려면 %s|1을;를; 누르세요."