-- PvP Tally: Español (España y Latinoamérica). "Kills" y "Deaths" se quedan en inglés,
-- como se dice en el juego.

local _, ns = ...

local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then
	return
end
local L = ns.L

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

L.DATE_SHORT = "%d/%m/%y %H:%M"
L.DATE_LONG = "%d/%m/%Y %H:%M"

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
L.NOTIFY_GROUP_KILL = "Tu grupo ha matado a %s. %s"
L.NOTIFY_DEATH = "%s te ha matado. %s"
L.SCORE = "(Kills %d / Deaths %d)"

L.TT_FIRST = "Primer encuentro"
L.TT_LAST = "Último encuentro"
L.TT_HINT = "Clic: ver enfrentamientos. Clic derecho: eliminar."
L.TT_COORDS = "Coordenadas: %.1f, %.1f"

L.HOW_kill = "Golpe de gracia tuyo"
L.HOW_group = "Golpe de gracia de tu grupo; participaste en la pelea"
L.HOW_recap = "Asesino según el resumen de muerte"
L.HOW_targeting = "Asesino deducido: el único enemigo que te tenía en el objetivo"
L.HOW_spy = "Importado de Spy"
L.HOW_test = "Añadido a mano para pruebas (/tally skull)"

L.DELETE_CONFIRM = "¿Eliminar a %s y todos sus enfrentamientos de PvP Tally?"
L.RESET_CONFIRM = "¿Borrar TODOS los enfrentamientos registrados por PvP Tally para este personaje?"
L.RESET_DONE = "Se han borrado todos los datos de este personaje."

L.SETTINGS_BUTTON = "Opciones"
L.SETTINGS_CHAT_HEADER = "Chat"
L.SETTINGS_NOTIFY_KILLS = "Mostrar un mensaje en el chat por cada kill (tuya o de tu grupo)"
L.SETTINGS_NOTIFY_DEATHS = "Mostrar un mensaje en el chat por cada muerte"
L.SETTINGS_SKULL_HEADER = "Calavera"
L.SETTINGS_NAMEPLATE_MARKS = "Mostrar una calavera en la placa de nombre de cada jugador de tu lista"
L.SETTINGS_MARK_SIZE = "Tamaño de la calavera"
L.SETTINGS_MARK_SIZE_SMALL = "Pequeña"
L.SETTINGS_MARK_SIZE_MEDIUM = "Mediana"
L.SETTINGS_MARK_SIZE_LARGE = "Grande"
L.SETTINGS_PORTRAIT_MARKS = "Calavera en el retrato de tu objetivo y tu foco"
L.SETTINGS_PORTRAIT_MARKS_NOTE = "Por si otro addon sustituye las placas de nombre: cubre el retrato de los jugadores de tu lista."
L.SETTINGS_NAMEPLATE_MARKS_NOTE = "Solo en las placas que muestra el juego: activa las placas de enemigos y de aliados en las opciones del juego."
L.SETTINGS_IN_COMBAT = "No se pueden abrir las opciones en combate."
L.SETTINGS_UNAVAILABLE = "Este cliente del juego no tiene panel de opciones para addons."

L.MINIMAP_LEFT = "Clic izquierdo: abrir / cerrar"
L.MINIMAP_RIGHT = "Clic derecho: opciones"
L.MINIMAP_DRAG = "Arrastrar: mover este botón"
L.MINIMAP_HIDDEN = "Botón del minimapa oculto. Escribe /tally minimap para volver a mostrarlo."

L.HELP = "Comandos: /tally (abrir), /tally settings (opciones), /tally import (importar de Spy), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear, /tally skull"
L.TEST_ADDED = "%d jugadores de prueba añadidos (Test Reg y cada raza en hombre y mujer; los Cielonato, en ambos bandos). Bórralos con /tally test clear."
L.TEST_MALE = "hombre"
L.TEST_FEMALE = "mujer"
L.TEST_REMOVED = "Jugadores de prueba borrados."
L.SKULL_ADDED = "%s añadido como jugador de prueba: su placa de nombre ya muestra la calavera. Bórralo con /tally test clear."
L.SKULL_EXISTS = "%s ya está en tu lista."
L.SKULL_USAGE = "Uso: /tally skull Nombre Apellido (tal como se escribe en el juego), o pon a un jugador en el objetivo y escribe /tally skull."
L.NOTIFY_ON = "Mensajes en el chat de kills y muertes: activados."
L.NOTIFY_OFF = "Mensajes en el chat de kills y muertes: desactivados."
