-- PvP Tally: Deutsch.

local _, ns = ...

if GetLocale() ~= "deDE" then
	return
end
local L = ns.L

L.COL_PLAYER = "Spieler"
L.COL_RACE = "Volk"
L.COL_LEVEL = "St."
L.COL_GUILD = "Gilde"
L.COL_KILLS = "Siege"
L.COL_DEATHS = "Tode"
L.COL_FIRST = "Erster Kampf"

L.D_RESULT = "Ergebnis"
L.D_DATE = "Datum"
L.D_ZONE = "Gebiet"
L.D_OPP = "Gegner-St."
L.D_MINE = "Meine St."

L.DATE_SHORT = "%d.%m.%y %H:%M"
L.DATE_LONG = "%d.%m.%Y %H:%M"

L.WIN = "Sieg"
L.LOSS = "Niederlage"
L.EXTRA = "%d Siege und %d Tode ohne Details (importiert oder ältere Kämpfe)"
L.EMPTY = "Noch keine Welt-PvP-Kämpfe aufgezeichnet."
L.SEARCH = "Suchen"
L.SUMMARY = "Spieler: %s   Siege: %s   Tode: %s   K/D: %s"

L.IMPORT_BUTTON = "Aus Spy importieren"
L.IMPORT_TOOLTIP = "Kopiert die Siege und Tode, die Spy für diesen Charakter aufgezeichnet hat. Kämpfe, die schon in PvP Tally sind, werden nicht doppelt gezählt."
L.IMPORT_DONE = "Aus Spy importiert: %d Spieler, %d Kämpfe mit Details."
L.IMPORT_NOTHING = "Spy hatte nichts Neues zum Importieren."
L.SPY_NOT_FOUND = "Keine Spy-Daten für diesen Charakter gefunden (ist Spy installiert und aktiviert?)."
L.EXPAND_ALL = "Alle aufklappen"
L.COLLAPSE_ALL = "Alle zuklappen"

L.NOTIFY_KILL = "Du hast %s getötet. %s"
L.NOTIFY_GROUP_KILL = "Deine Gruppe hat %s getötet. %s"
L.NOTIFY_DEATH = "%s hat dich getötet. %s"
L.SCORE = "(Siege %d / Tode %d)"

L.TT_FIRST = "Erster Kampf"
L.TT_LAST = "Letzter Kampf"
L.TT_HINT = "Klick: Kämpfe anzeigen. Rechtsklick: löschen."
L.TT_COORDS = "Koordinaten: %.1f, %.1f"

L.HOW_kill = "Dein Todesstoß"
L.HOW_group = "Todesstoß deiner Gruppe; du warst am Kampf beteiligt"
L.HOW_recap = "Mörder aus der Todesübersicht"
L.HOW_targeting = "Mörder vermutet: der einzige Gegner, der dich im Ziel hatte"
L.HOW_spy = "Aus Spy importiert"

L.DELETE_CONFIRM = "%s und alle Kämpfe gegen diesen Spieler aus PvP Tally löschen?"
L.RESET_CONFIRM = "ALLE Kämpfe löschen, die PvP Tally für diesen Charakter aufgezeichnet hat?"
L.RESET_DONE = "Alle Daten dieses Charakters wurden gelöscht."

L.SETTINGS_BUTTON = "Optionen"
L.SETTINGS_IN_COMBAT = "Die Optionen können im Kampf nicht geöffnet werden."
L.SETTINGS_UNAVAILABLE = "Dieser Spielclient hat kein Optionsfenster für Addons."

L.MINIMAP_LEFT = "Linksklick: öffnen / schließen"
L.MINIMAP_RIGHT = "Rechtsklick: Optionen"
L.MINIMAP_DRAG = "Ziehen: diese Schaltfläche verschieben"
L.MINIMAP_HIDDEN = "Minikarten-Schaltfläche ausgeblendet. Mit /tally minimap wird sie wieder angezeigt."

L.HELP = "Befehle: /tally (öffnen), /tally settings (Optionen), /tally import (aus Spy importieren), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear"
L.TEST_ADDED = "%d Testspieler hinzugefügt (Test Reg und jedes Volk, männlich und weiblich). Entferne sie mit /tally test clear."
L.TEST_MALE = "männlich"
L.TEST_FEMALE = "weiblich"
L.TEST_REMOVED = "Testspieler entfernt."
L.NOTIFY_ON = "Chatnachrichten zu Siegen und Toden: an."
L.NOTIFY_OFF = "Chatnachrichten zu Siegen und Toden: aus."
