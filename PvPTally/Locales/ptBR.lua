-- PvP Tally: Português (Brasil). The Portuguese client of Portugal (ptPT) uses it too.

local _, ns = ...

local locale = GetLocale()
if locale ~= "ptBR" and locale ~= "ptPT" then
	return
end
local L = ns.L

L.COL_PLAYER = "Jogador"
L.COL_RACE = "Raça"
L.COL_LEVEL = "Nív."
L.COL_GUILD = "Guilda"
L.COL_KILLS = "Abates"
L.COL_DEATHS = "Mortes"
L.COL_FIRST = "Primeiro combate"

L.D_RESULT = "Resultado"
L.D_DATE = "Data"
L.D_ZONE = "Zona"
L.D_OPP = "Nív. rival"
L.D_MINE = "Meu nív."

L.DATE_SHORT = "%d/%m/%y %H:%M"
L.DATE_LONG = "%d/%m/%Y %H:%M"

L.WIN = "Vitória"
L.LOSS = "Derrota"
L.EXTRA = "%d abates e %d mortes sem detalhes (importados ou antigos)"
L.EMPTY = "Nenhum combate de PvP mundial registrado ainda."
L.SEARCH = "Buscar"
L.SUMMARY = "Jogadores: %s   Abates: %s   Mortes: %s   A/M: %s"

L.IMPORT_BUTTON = "Importar do Spy"
L.IMPORT_TOOLTIP = "Copia os abates e as mortes que o Spy registrou para este personagem. Combates que já estão no PvP Tally não são contados duas vezes."
L.IMPORT_DONE = "Importado do Spy: %d jogadores, %d combates com detalhes."
L.IMPORT_NOTHING = "O Spy não tinha nada novo para importar."
L.SPY_NOT_FOUND = "Nenhum dado do Spy para este personagem (o Spy está instalado e ativado?)."
L.EXPAND_ALL = "Expandir tudo"
L.COLLAPSE_ALL = "Recolher tudo"

L.NOTIFY_KILL = "Você matou %s. %s"
L.NOTIFY_GROUP_KILL = "Seu grupo matou %s. %s"
L.NOTIFY_DEATH = "%s matou você. %s"
L.SCORE = "(Abates %d / Mortes %d)"

L.TT_FIRST = "Primeiro combate"
L.TT_LAST = "Último combate"
L.TT_HINT = "Clique: ver combates. Clique direito: excluir."
L.TT_COORDS = "Coordenadas: %.1f, %.1f"

L.HOW_kill = "Golpe final seu"
L.HOW_group = "Golpe final do seu grupo; você participou do combate"
L.HOW_recap = "Assassino lido no resumo da morte"
L.HOW_targeting = "Assassino deduzido: o único inimigo que tinha você como alvo"
L.HOW_spy = "Importado do Spy"

L.DELETE_CONFIRM = "Excluir %s e todos os seus combates do PvP Tally?"
L.RESET_CONFIRM = "Excluir TODOS os combates registrados pelo PvP Tally para este personagem?"
L.RESET_DONE = "Todos os dados deste personagem foram excluídos."

L.SETTINGS_BUTTON = "Opções"
L.SETTINGS_IN_COMBAT = "Não é possível abrir as opções em combate."
L.SETTINGS_UNAVAILABLE = "Este cliente do jogo não tem painel de opções para addons."

L.MINIMAP_LEFT = "Clique esquerdo: abrir / fechar"
L.MINIMAP_RIGHT = "Clique direito: opções"
L.MINIMAP_DRAG = "Arrastar: mover este botão"
L.MINIMAP_HIDDEN = "Botão do minimapa oculto. Digite /tally minimap para mostrá-lo de novo."

L.HELP = "Comandos: /tally (abrir), /tally settings (opções), /tally import (importar do Spy), /tally minimap, /tally notify, /tally reset, /tally debug, /tally test, /tally test clear"
L.TEST_ADDED = "%d jogadores de teste adicionados (Test Reg e cada raça, masculino e feminino). Remova-os com /tally test clear."
L.TEST_MALE = "masculino"
L.TEST_FEMALE = "feminino"
L.TEST_REMOVED = "Jogadores de teste removidos."
L.NOTIFY_ON = "Mensagens no chat para abates e mortes: ativadas."
L.NOTIFY_OFF = "Mensagens no chat para abates e mortes: desativadas."
