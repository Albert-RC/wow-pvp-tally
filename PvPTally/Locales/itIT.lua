-- PvP Tally: Italiano.

local _, ns = ...

if GetLocale() ~= "itIT" then
	return
end
local L = ns.L

L.COL_PLAYER = "Giocatore"
L.COL_RACE = "Razza"
L.COL_LEVEL = "Liv."
L.COL_GUILD = "Gilda"
L.COL_KILLS = "Uccisioni"
L.COL_DEATHS = "Morti"
L.COL_FIRST = "Primo scontro"
L.COL_NOTE = "Nota"

L.D_RESULT = "Risultato"
L.D_DATE = "Data"
L.D_ZONE = "Zona"
L.D_OPP = "Liv. nemico"
L.D_MINE = "Mio liv."

L.DATE_SHORT = "%d/%m/%y %H:%M"
L.DATE_LONG = "%d/%m/%Y %H:%M"

L.WIN = "Vittoria"
L.LOSS = "Sconfitta"
L.EXTRA = "%d uccisioni e %d morti senza dettagli (importate o più vecchie)"
L.EMPTY = "Ancora nessuno scontro PvP all'aperto registrato."
L.SEARCH = "Cerca"
L.SUMMARY = "Giocatori: %s   Uccisioni: %s   Morti: %s   U/M: %s"

L.IMPORT_BUTTON = "Importa da Spy"
L.IMPORT_TOOLTIP = "Copia le uccisioni e le morti che Spy ha registrato per questo personaggio. Gli scontri già presenti in PvP Tally non vengono contati due volte."
L.IMPORT_DONE = "Importato da Spy: %d giocatori, %d scontri con dettagli."
L.IMPORT_NOTHING = "Spy non aveva nulla di nuovo da importare."
L.SPY_NOT_FOUND = "Nessun dato di Spy per questo personaggio (Spy è installato e attivo?)."
L.EXPAND_ALL = "Espandi tutto"
L.COLLAPSE_ALL = "Comprimi tutto"

L.NOTIFY_KILL = "Hai ucciso %s. %s"
L.NOTIFY_GROUP_KILL = "Il tuo gruppo ha ucciso %s. %s"
L.NOTIFY_DEATH = "%s ti ha ucciso. %s"
L.SCORE = "(Uccisioni %d / Morti %d)"

L.TT_FIRST = "Primo scontro"
L.TT_LAST = "Ultimo scontro"
L.TT_HINT = "Clic: mostra gli scontri. Clic destro: elimina."
L.TT_COORDS = "Coordinate: %.1f, %.1f"

L.HOW_kill = "Colpo di grazia tuo"
L.HOW_group = "Colpo di grazia del tuo gruppo; hai partecipato allo scontro"
L.HOW_recap = "Uccisore letto dal riepilogo della morte"
L.HOW_targeting = "Uccisore dedotto: l'unico nemico che ti aveva come bersaglio"
L.HOW_spy = "Importato da Spy"
L.HOW_test = "Aggiunto a mano per le prove (/tally skull)"

L.DELETE_CONFIRM = "Eliminare %s e tutti i suoi scontri da PvP Tally?"
L.RESET_CONFIRM = "Eliminare TUTTI gli scontri registrati da PvP Tally per questo personaggio?"
L.RESET_DONE = "Tutti i dati di questo personaggio sono stati eliminati."

L.NOTE_EDIT = "Nota su %s:"
L.NOTE_ADD_HINT = "Clicca per scrivere una nota su questo giocatore."
L.NOTE_EDIT_HINT = "Clicca per modificare la nota. Salvala vuota per eliminarla."
L.TOOLTIP_NOTE = "Nota di PvP Tally: %s"

L.SETTINGS_BUTTON = "Opzioni"
L.SETTINGS_CHAT_HEADER = "Chat"
L.SETTINGS_NOTIFY_KILLS = "Mostra un messaggio in chat per ogni uccisione (tua o del tuo gruppo)"
L.SETTINGS_NOTIFY_DEATHS = "Mostra un messaggio in chat per ogni morte"
L.SETTINGS_SKULL_HEADER = "Teschio"
L.SETTINGS_NAMEPLATE_MARKS = "Mostra un teschio sulla barra del nome di ogni giocatore della tua lista"
L.SETTINGS_MARK_SIZE = "Dimensione del teschio"
L.SETTINGS_MARK_SIZE_SMALL = "Piccolo"
L.SETTINGS_MARK_SIZE_MEDIUM = "Medio"
L.SETTINGS_MARK_SIZE_LARGE = "Grande"
L.SETTINGS_PORTRAIT_MARKS = "Teschio sul ritratto di bersaglio e focus"
L.SETTINGS_PORTRAIT_MARKS_NOTE = "Se un altro addon sostituisce le barre del nome: copre il ritratto dei giocatori della tua lista."
L.SETTINGS_NAMEPLATE_MARKS_NOTE = "Solo sulle barre del nome mostrate dal gioco: attiva quelle dei nemici e degli alleati nelle opzioni del gioco."
L.SETTINGS_IN_COMBAT = "Le opzioni non si possono aprire in combattimento."
L.SETTINGS_UNAVAILABLE = "Questo client di gioco non ha un pannello delle opzioni per gli addon."

L.MINIMAP_LEFT = "Clic sinistro: apri / chiudi"
L.MINIMAP_RIGHT = "Clic destro: opzioni"
L.MINIMAP_DRAG = "Trascina: sposta questo pulsante"
L.MINIMAP_HIDDEN = "Pulsante della minimappa nascosto. Scrivi /tally minimap per mostrarlo di nuovo."

L.HELP = "Comandi: /tally (apri), /tally settings (opzioni), /tally import (importa da Spy), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear, /tally skull"
L.TEST_ADDED = "%d giocatori di prova aggiunti (Test Reg e ogni razza, maschio e femmina). Rimuovili con /tally test clear."
L.TEST_MALE = "maschio"
L.TEST_FEMALE = "femmina"
L.TEST_REMOVED = "Giocatori di prova rimossi."
L.SKULL_ADDED = "%s aggiunto come giocatore di prova: la sua barra del nome ora mostra il teschio. Rimuovilo con /tally test clear."
L.SKULL_EXISTS = "%s è già nella tua lista."
L.SKULL_USAGE = "Uso: /tally skull Nome Cognome (come scritto nel gioco), oppure seleziona un giocatore e scrivi /tally skull."
L.NOTIFY_ON = "Messaggi in chat per uccisioni e morti: attivi."
L.NOTIFY_OFF = "Messaggi in chat per uccisioni e morti: disattivati."
