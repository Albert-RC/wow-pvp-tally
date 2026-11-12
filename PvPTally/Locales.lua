local _, ns = ...

local L = {}
ns.L = L

-- English (default) -----------------------------------------------------------------

L.TITLE = "PvP Tally"

L.COL_PLAYER = "Player"
L.COL_RACE = "Race"
L.COL_LEVEL = "Lvl"
L.COL_GUILD = "Guild"
L.COL_KILLS = "Kills"
L.COL_DEATHS = "Deaths"
L.COL_FIRST = "First fight"

L.D_RESULT = "Result"
L.D_DATE = "Date"
L.D_ZONE = "Zone"
L.D_OPP = "Their lvl"
L.D_MINE = "My lvl"

L.WIN = "Victory"
L.LOSS = "Defeat"
L.UNKNOWN_LEVEL = "??"
L.EXTRA = "%d kills and %d deaths without details (imported or older fights)"
L.EMPTY = "No world PvP fights recorded yet."
L.SEARCH = "Search"
L.SUMMARY = "Players: %s   Kills: %s   Deaths: %s   K/D: %s"

L.IMPORT_BUTTON = "Import from Spy"
L.IMPORT_TOOLTIP = "Copies the kills and deaths Spy recorded for this character. Fights already in PvP Tally are not counted twice."
L.IMPORT_DONE = "Imported from Spy: %d players, %d fights with details."
L.IMPORT_NOTHING = "Spy had nothing new to import."
L.SPY_NOT_FOUND = "Spy data not found for this character (is Spy installed and enabled?)."
L.EXPAND_ALL = "Expand all"
L.COLLAPSE_ALL = "Collapse all"

L.NOTIFY_KILL = "You killed %s. %s"
L.NOTIFY_DEATH = "%s killed you. %s"
L.SCORE = "(Kills %d / Deaths %d)"

L.TT_FIRST = "First fight"
L.TT_LAST = "Last fight"
L.TT_HINT = "Click: show fights. Right-click: delete."
L.TT_COORDS = "Coords: %.1f, %.1f"

L.HOW_kill = "Your killing blow"
L.HOW_recap = "Killer read from the death recap"
L.HOW_targeting = "Killer guessed: the only enemy who had you targeted"
L.HOW_spy = "Imported from Spy"

L.DELETE_CONFIRM = "Delete %s and all their fights from PvP Tally?"
L.RESET_CONFIRM = "Delete ALL fights recorded by PvP Tally for this character?"
L.RESET_DONE = "All data for this character was deleted."

L.SETTINGS_BUTTON = "Options"
L.SETTINGS_SPY_HEADER = "Spy"
L.SETTINGS_IN_COMBAT = "The options cannot be opened in combat."
L.SETTINGS_UNAVAILABLE = "This game client has no options panel for addons."

L.MINIMAP_LEFT = "Left-click: open / close"
L.MINIMAP_RIGHT = "Right-click: options"
L.MINIMAP_DRAG = "Drag: move this button"
L.MINIMAP_HIDDEN = "Minimap button hidden. Type /tally minimap to show it again."

L.HELP = "Commands: /tally (open), /tally settings (options), /tally import (import from Spy), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear"
L.TEST_ADDED = "%d test players added (Test Reg and every race, male and female; Skyborne on both sides). Remove them with /tally test clear."
L.TEST_MALE = "male"
L.TEST_FEMALE = "female"
L.TEST_REMOVED = "Test players removed."
L.NOTIFY_ON = "Chat messages for kills and deaths: on."
L.NOTIFY_OFF = "Chat messages for kills and deaths: off."

-- Español -------------------------------------------------------------------------------

local locale = GetLocale()
if locale == "esES" or locale == "esMX" then
	L.COL_PLAYER = "Jugador"
	L.COL_RACE = "Raza"
	L.COL_LEVEL = "Nv."
	L.COL_GUILD = "Hermandad"
	L.COL_KILLS = "Kills"
	L.COL_DEATHS = "Deaths"
	L.COL_FIRST = "Primer encuentro"

	L.D_RESULT = "Resultado"
	L.D_DATE = "Fecha"
	L.D_ZONE = "Zona"
	L.D_OPP = "Nv. rival"
	L.D_MINE = "Mi nivel"

	L.WIN = "Victoria"
	L.LOSS = "Derrota"
	L.EXTRA = "%d kills y %d deaths sin detalle (importados o antiguos)"
	L.EMPTY = "Aún no hay enfrentamientos de PvP de mundo registrados."
	L.SEARCH = "Buscar"
	L.SUMMARY = "Jugadores: %s   Kills: %s   Deaths: %s   K/D: %s"

	L.IMPORT_BUTTON = "Importar de Spy"
	L.IMPORT_TOOLTIP = "Copia las kills y muertes que Spy registró para este personaje. Los enfrentamientos que ya estén en PvP Tally no se cuentan dos veces."
	L.IMPORT_DONE = "Importado de Spy: %d jugadores, %d enfrentamientos con detalle."
	L.IMPORT_NOTHING = "Spy no tenía nada nuevo que importar."
	L.SPY_NOT_FOUND = "No hay datos de Spy para este personaje (¿está Spy instalado y activado?)."
	L.EXPAND_ALL = "Expandir todo"
	L.COLLAPSE_ALL = "Contraer todo"

	L.NOTIFY_KILL = "Has matado a %s. %s"
	L.NOTIFY_DEATH = "%s te ha matado. %s"

	L.TT_FIRST = "Primer encuentro"
	L.TT_LAST = "Último encuentro"
	L.TT_HINT = "Clic: ver enfrentamientos. Clic derecho: eliminar."
	L.TT_COORDS = "Coordenadas: %.1f, %.1f"

	L.HOW_kill = "Golpe de gracia tuyo"
	L.HOW_recap = "Asesino según el resumen de muerte"
	L.HOW_targeting = "Asesino deducido: el único enemigo que te tenía en el objetivo"
	L.HOW_spy = "Importado de Spy"

	L.DELETE_CONFIRM = "¿Eliminar a %s y todos sus enfrentamientos de PvP Tally?"
	L.RESET_CONFIRM = "¿Borrar TODOS los enfrentamientos registrados por PvP Tally para este personaje?"
	L.RESET_DONE = "Se han borrado todos los datos de este personaje."

	L.SETTINGS_BUTTON = "Opciones"
	L.SETTINGS_IN_COMBAT = "No se pueden abrir las opciones en combate."
	L.SETTINGS_UNAVAILABLE = "Este cliente del juego no tiene panel de opciones para addons."

	L.MINIMAP_LEFT = "Clic izquierdo: abrir / cerrar"
	L.MINIMAP_RIGHT = "Clic derecho: opciones"
	L.MINIMAP_DRAG = "Arrastrar: mover este botón"
	L.MINIMAP_HIDDEN = "Botón del minimapa oculto. Escribe /tally minimap para volver a mostrarlo."

	L.HELP = "Comandos: /tally (abrir), /tally settings (opciones), /tally import (importar de Spy), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear"
	L.TEST_ADDED = "%d jugadores de prueba añadidos (Test Reg y cada raza en hombre y mujer; los Cielonato, en ambos bandos). Bórralos con /tally test clear."
	L.TEST_MALE = "hombre"
	L.TEST_FEMALE = "mujer"
	L.TEST_REMOVED = "Jugadores de prueba borrados."
	L.NOTIFY_ON = "Mensajes en el chat de kills y muertes: activados."
	L.NOTIFY_OFF = "Mensajes en el chat de kills y muertes: desactivados."
end

setmetatable(L, { __index = function(_, key) return key end })
