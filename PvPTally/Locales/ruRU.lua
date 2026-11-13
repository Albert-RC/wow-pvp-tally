-- PvP Tally: Русский.

local _, ns = ...

if GetLocale() ~= "ruRU" then
	return
end
local L = ns.L

L.COL_PLAYER = "Игрок"
L.COL_RACE = "Раса"
L.COL_LEVEL = "Ур."
L.COL_GUILD = "Гильдия"
L.COL_KILLS = "Убийства"
L.COL_DEATHS = "Смерти"
L.COL_FIRST = "Первый бой"

L.D_RESULT = "Итог"
L.D_DATE = "Дата"
L.D_ZONE = "Зона"
L.D_OPP = "Ур. врага"
L.D_MINE = "Мой ур."

L.DATE_SHORT = "%d.%m.%y %H:%M"
L.DATE_LONG = "%d.%m.%Y %H:%M"

L.WIN = "Победа"
L.LOSS = "Поражение"
L.EXTRA = "Убийств: %d, смертей: %d без подробностей (импортированные или старые бои)"
L.EMPTY = "Боев в открытом мире пока не записано."
L.SEARCH = "Поиск"
L.SUMMARY = "Игроков: %s   Убийств: %s   Смертей: %s   У/С: %s"

L.IMPORT_BUTTON = "Импорт из Spy"
L.IMPORT_TOOLTIP = "Копирует убийства и смерти, записанные Spy для этого персонажа. Бои, которые уже есть в PvP Tally, не учитываются дважды."
L.IMPORT_DONE = "Импортировано из Spy: игроков — %d, боев с подробностями — %d."
L.IMPORT_NOTHING = "В Spy нет ничего нового для импорта."
L.SPY_NOT_FOUND = "Данные Spy для этого персонажа не найдены (Spy установлен и включен?)."
L.EXPAND_ALL = "Развернуть все"
L.COLLAPSE_ALL = "Свернуть все"

L.NOTIFY_KILL = "Вы убили: %s. %s"
L.NOTIFY_GROUP_KILL = "Ваша группа убила: %s. %s"
L.NOTIFY_DEATH = "Вас убил: %s. %s"
L.SCORE = "(Убийств %d / Смертей %d)"

L.TT_FIRST = "Первый бой"
L.TT_LAST = "Последний бой"
L.TT_HINT = "Щелчок: показать бои. Правый щелчок: удалить."
L.TT_COORDS = "Координаты: %.1f, %.1f"

L.HOW_kill = "Ваш смертельный удар"
L.HOW_group = "Смертельный удар вашей группы; вы участвовали в бою"
L.HOW_recap = "Убийца взят из сводки о смерти"
L.HOW_targeting = "Предполагаемый убийца: единственный враг, который держал вас в цели"
L.HOW_spy = "Импортировано из Spy"

L.DELETE_CONFIRM = "Удалить %s и все бои с этим игроком из PvP Tally?"
L.RESET_CONFIRM = "Удалить ВСЕ бои, записанные PvP Tally для этого персонажа?"
L.RESET_DONE = "Все данные этого персонажа удалены."

L.SETTINGS_BUTTON = "Настройки"
L.SETTINGS_IN_COMBAT = "Настройки нельзя открыть в бою."
L.SETTINGS_UNAVAILABLE = "В этом клиенте игры нет панели настроек для модификаций."

L.MINIMAP_LEFT = "Левый щелчок: открыть / закрыть"
L.MINIMAP_RIGHT = "Правый щелчок: настройки"
L.MINIMAP_DRAG = "Перетаскивание: переместить кнопку"
L.MINIMAP_HIDDEN = "Кнопка у мини-карты скрыта. Введите /tally minimap, чтобы вернуть ее."

L.HELP = "Команды: /tally (открыть), /tally settings (настройки), /tally import (импорт из Spy), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear"
L.TEST_ADDED = "Добавлено тестовых игроков: %d (Test Reg и каждая раса, мужчина и женщина). Удалить: /tally test clear."
L.TEST_MALE = "мужчина"
L.TEST_FEMALE = "женщина"
L.TEST_REMOVED = "Тестовые игроки удалены."
L.NOTIFY_ON = "Сообщения в чате об убийствах и смертях: включены."
L.NOTIFY_OFF = "Сообщения в чате об убийствах и смертях: выключены."
