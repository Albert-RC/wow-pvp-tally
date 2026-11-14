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
L.COL_NOTE = "Notiz"

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
L.HOW_test = "Zum Testen von Hand hinzugefügt (/tally skull)"

L.DELETE_CONFIRM = "%s und alle Kämpfe gegen diesen Spieler aus PvP Tally löschen?"
L.RESET_CONFIRM = "ALLE Kämpfe löschen, die PvP Tally für diesen Charakter aufgezeichnet hat?"
L.RESET_DONE = "Alle Daten dieses Charakters wurden gelöscht."

L.NOTE_ADD_HINT = "Klicken, um eine Notiz zu diesem Spieler zu schreiben."
L.NOTE_EDIT_HINT = "Klicken: Notiz bearbeiten. Umschalt + Rechtsklick: löschen."
L.TOOLTIP_NOTE = "PvP-Tally-Notiz:"
L.NOTE_SAVE = "Speichern"
L.NOTE_PLACEHOLDER = "Schreib auf, was du dir über diesen Spieler merken willst: wie er kämpft, wo er lauert, mit wem er unterwegs ist..."
L.NOTE_COUNT = "%d / %d"

L.SETTINGS_BUTTON = "Optionen"
L.SETTINGS_CHAT_HEADER = "Chat"
L.SETTINGS_NOTIFY_KILLS = "Bei jedem Sieg (deinem oder dem deiner Gruppe) eine Chatnachricht anzeigen"
L.SETTINGS_NOTIFY_DEATHS = "Bei jedem Tod eine Chatnachricht anzeigen"
L.SETTINGS_SKULL_HEADER = "Totenkopf"
L.SETTINGS_NAMEPLATE_MARKS = "Einen Totenkopf auf der Namensplakette jedes Spielers deiner Liste anzeigen"
L.SETTINGS_MARK_SIZE = "Größe des Totenkopfs"
L.SETTINGS_MARK_SIZE_SMALL = "Klein"
L.SETTINGS_MARK_SIZE_MEDIUM = "Mittel"
L.SETTINGS_MARK_SIZE_LARGE = "Groß"
L.SETTINGS_PORTRAIT_MARKS = "Totenkopf auf dem Porträt von Ziel und Fokus"
L.SETTINGS_PORTRAIT_MARKS_NOTE = "Falls ein anderes Addon die Namensplaketten ersetzt: verdeckt das Porträt der Spieler deiner Liste."
L.SETTINGS_NAMEPLATE_MARKS_NOTE = "Nur auf Namensplaketten, die das Spiel anzeigt: Aktiviere feindliche und freundliche Namensplaketten in den Spieloptionen."
L.SETTINGS_IN_COMBAT = "Die Optionen können im Kampf nicht geöffnet werden."
L.SETTINGS_UNAVAILABLE = "Dieser Spielclient hat kein Optionsfenster für Addons."

L.MINIMAP_LEFT = "Linksklick: öffnen / schließen"
L.MINIMAP_RIGHT = "Rechtsklick: Optionen"
L.MINIMAP_DRAG = "Ziehen: diese Schaltfläche verschieben"
L.MINIMAP_HIDDEN = "Minikarten-Schaltfläche ausgeblendet. Mit /tally minimap wird sie wieder angezeigt."

L.HELP = "Befehle: /tally (öffnen), /tally settings (Optionen), /tally import (aus Spy importieren), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear, /tally skull"
L.TEST_ADDED = "%d Testspieler hinzugefügt (Test Reg und jedes Volk, männlich und weiblich). Entferne sie mit /tally test clear."
L.TEST_MALE = "männlich"
L.TEST_FEMALE = "weiblich"
L.TEST_REMOVED = "Testspieler entfernt."
L.SKULL_ADDED = "%s als Testspieler hinzugefügt: Die Namensplakette zeigt jetzt den Totenkopf. Entfernen mit /tally test clear."
L.SKULL_EXISTS = "%s ist bereits in deiner Liste."
L.SKULL_USAGE = "Verwendung: /tally skull Vorname Nachname (wie im Spiel geschrieben), oder einen Spieler anvisieren und /tally skull eingeben."
L.NOTIFY_ON = "Chatnachrichten zu Siegen und Toden: an."
L.NOTIFY_OFF = "Chatnachrichten zu Siegen und Toden: aus."
