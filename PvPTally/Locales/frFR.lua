-- PvP Tally: Français.

local _, ns = ...

if GetLocale() ~= "frFR" then
	return
end
local L = ns.L

L.COL_PLAYER = "Joueur"
L.COL_RACE = "Race"
L.COL_LEVEL = "Niv."
L.COL_GUILD = "Guilde"
L.COL_KILLS = "Victoires"
L.COL_DEATHS = "Morts"
L.COL_FIRST = "Premier combat"

L.D_RESULT = "Résultat"
L.D_DATE = "Date"
L.D_ZONE = "Zone"
L.D_OPP = "Niv. adverse"
L.D_MINE = "Mon niv."

L.DATE_SHORT = "%d/%m/%y %H:%M"
L.DATE_LONG = "%d/%m/%Y %H:%M"

L.WIN = "Victoire"
L.LOSS = "Défaite"
L.EXTRA = "%d victoires et %d morts sans détails (importées ou plus anciennes)"
L.EMPTY = "Aucun combat JcJ en extérieur enregistré pour l'instant."
L.SEARCH = "Rechercher"
L.SUMMARY = "Joueurs : %s   Victoires : %s   Morts : %s   V/M : %s"

L.IMPORT_BUTTON = "Importer depuis Spy"
L.IMPORT_TOOLTIP = "Copie les victoires et les morts que Spy a enregistrées pour ce personnage. Les combats déjà présents dans PvP Tally ne sont pas comptés deux fois."
L.IMPORT_DONE = "Importé depuis Spy : %d joueurs, %d combats avec détails."
L.IMPORT_NOTHING = "Spy n'avait rien de nouveau à importer."
L.SPY_NOT_FOUND = "Aucune donnée de Spy pour ce personnage (Spy est-il installé et activé ?)."
L.EXPAND_ALL = "Tout déplier"
L.COLLAPSE_ALL = "Tout replier"

L.NOTIFY_KILL = "Vous avez tué %s. %s"
L.NOTIFY_GROUP_KILL = "Votre groupe a tué %s. %s"
L.NOTIFY_DEATH = "%s vous a tué. %s"
L.SCORE = "(Victoires %d / Morts %d)"

L.TT_FIRST = "Premier combat"
L.TT_LAST = "Dernier combat"
L.TT_HINT = "Clic : voir les combats. Clic droit : supprimer."
L.TT_COORDS = "Coordonnées : %.1f, %.1f"

L.HOW_kill = "Le coup fatal est de vous"
L.HOW_group = "Coup fatal de votre groupe ; vous avez participé au combat"
L.HOW_recap = "Tueur lu dans le récapitulatif de mort"
L.HOW_targeting = "Tueur supposé : le seul ennemi qui vous ciblait"
L.HOW_spy = "Importé depuis Spy"

L.DELETE_CONFIRM = "Supprimer %s et tous ses combats de PvP Tally ?"
L.RESET_CONFIRM = "Supprimer TOUS les combats enregistrés par PvP Tally pour ce personnage ?"
L.RESET_DONE = "Toutes les données de ce personnage ont été supprimées."

L.SETTINGS_BUTTON = "Options"
L.SETTINGS_IN_COMBAT = "Impossible d'ouvrir les options en combat."
L.SETTINGS_UNAVAILABLE = "Ce client de jeu n'a pas de panneau d'options pour les addons."

L.MINIMAP_LEFT = "Clic gauche : ouvrir / fermer"
L.MINIMAP_RIGHT = "Clic droit : options"
L.MINIMAP_DRAG = "Glisser : déplacer ce bouton"
L.MINIMAP_HIDDEN = "Bouton de la minicarte masqué. Tapez /tally minimap pour le réafficher."

L.HELP = "Commandes : /tally (ouvrir), /tally settings (options), /tally import (importer depuis Spy), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear"
L.TEST_ADDED = "%d joueurs de test ajoutés (Test Reg et chaque race, homme et femme). Supprimez-les avec /tally test clear."
L.TEST_MALE = "homme"
L.TEST_FEMALE = "femme"
L.TEST_REMOVED = "Joueurs de test supprimés."
L.NOTIFY_ON = "Messages de discussion pour les victoires et les morts : activés."
L.NOTIFY_OFF = "Messages de discussion pour les victoires et les morts : désactivés."
