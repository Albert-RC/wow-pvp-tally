-- PvP Tally: 한국어.

local _, ns = ...

if GetLocale() ~= "koKR" then
	return
end
local L = ns.L

L.COL_PLAYER = "플레이어"
L.COL_RACE = "종족"
L.COL_LEVEL = "레벨"
L.COL_GUILD = "길드"
L.COL_KILLS = "처치"
L.COL_DEATHS = "죽음"
L.COL_FIRST = "첫 전투"

L.D_RESULT = "결과"
L.D_DATE = "날짜"
L.D_ZONE = "지역"
L.D_OPP = "상대 레벨"
L.D_MINE = "내 레벨"

L.DATE_SHORT = "%y.%m.%d %H:%M"
L.DATE_LONG = "%Y.%m.%d %H:%M"

L.WIN = "승리"
L.LOSS = "패배"
L.EXTRA = "세부 정보 없는 처치 %d회, 죽음 %d회 (가져왔거나 이전 전투)"
L.EMPTY = "아직 기록된 야외 PvP 전투가 없습니다."
L.SEARCH = "검색"
L.SUMMARY = "플레이어: %s   처치: %s   죽음: %s   K/D: %s"

L.IMPORT_BUTTON = "Spy에서 가져오기"
L.IMPORT_TOOLTIP = "Spy가 이 캐릭터에 대해 기록한 처치와 죽음을 복사합니다. 이미 PvP Tally에 있는 전투는 두 번 세지 않습니다."
L.IMPORT_DONE = "Spy에서 가져옴: 플레이어 %d명, 세부 정보가 있는 전투 %d회."
L.IMPORT_NOTHING = "Spy에서 새로 가져올 것이 없습니다."
L.SPY_NOT_FOUND = "이 캐릭터의 Spy 데이터를 찾을 수 없습니다 (Spy가 설치되고 활성화되어 있나요?)."
L.EXPAND_ALL = "모두 펼치기"
L.COLLAPSE_ALL = "모두 접기"

L.NOTIFY_KILL = "처치: %s. %s"
L.NOTIFY_GROUP_KILL = "파티 처치: %s. %s"
L.NOTIFY_DEATH = "%s에게 죽었습니다. %s"
L.SCORE = "(처치 %d / 죽음 %d)"

L.TT_FIRST = "첫 전투"
L.TT_LAST = "마지막 전투"
L.TT_HINT = "클릭: 전투 보기. 오른쪽 클릭: 삭제."
L.TT_COORDS = "좌표: %.1f, %.1f"

L.HOW_kill = "내 결정타"
L.HOW_group = "파티의 결정타 (전투에 참여함)"
L.HOW_recap = "죽음 요약에서 읽은 처치자"
L.HOW_targeting = "추정 처치자: 나를 대상으로 잡고 있던 유일한 적"
L.HOW_spy = "Spy에서 가져옴"

L.DELETE_CONFIRM = "PvP Tally에서 %s 및 모든 전투를 삭제할까요?"
L.RESET_CONFIRM = "PvP Tally가 이 캐릭터에 대해 기록한 모든 전투를 삭제할까요?"
L.RESET_DONE = "이 캐릭터의 모든 데이터를 삭제했습니다."

L.SETTINGS_BUTTON = "설정"
L.SETTINGS_CHAT_HEADER = "대화"
L.SETTINGS_NOTIFY_KILLS = "처치할 때마다 대화창에 메시지 표시 (나 또는 파티)"
L.SETTINGS_NOTIFY_DEATHS = "죽을 때마다 대화창에 메시지 표시"
L.SETTINGS_IN_COMBAT = "전투 중에는 설정을 열 수 없습니다."
L.SETTINGS_UNAVAILABLE = "이 게임 클라이언트에는 애드온 설정 창이 없습니다."

L.MINIMAP_LEFT = "왼쪽 클릭: 열기 / 닫기"
L.MINIMAP_RIGHT = "오른쪽 클릭: 설정"
L.MINIMAP_DRAG = "끌기: 이 버튼 이동"
L.MINIMAP_HIDDEN = "미니맵 버튼을 숨겼습니다. /tally minimap 을 입력하면 다시 표시됩니다."

L.HELP = "명령어: /tally (열기), /tally settings (설정), /tally import (Spy에서 가져오기), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear"
L.TEST_ADDED = "테스트 플레이어 %d명 추가 (Test Reg 및 모든 종족의 남성과 여성). /tally test clear 로 삭제하세요."
L.TEST_MALE = "남성"
L.TEST_FEMALE = "여성"
L.TEST_REMOVED = "테스트 플레이어를 삭제했습니다."
L.NOTIFY_ON = "처치 및 죽음 채팅 메시지: 켜짐."
L.NOTIFY_OFF = "처치 및 죽음 채팅 메시지: 꺼짐."
