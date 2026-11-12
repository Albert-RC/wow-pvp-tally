# PvP Tally

Addon para **World of Warcraft: Forever** que registra cada kill y cada muerte en PvP de mundo.

- Una fila por jugador enemigo con el que te has enfrentado: icono de clase, raza (con insignia de bando para los Cielonato, que pueden ser Alianza u Horda), nivel, hermandad, **Kills**, **Deaths** y fecha del primer encuentro.
- Al hacer clic en una fila se despliega cada enfrentamiento: resultado, fecha y hora local, zona y subzona, nivel del rival y tu nivel.
- Se puede ordenar por cualquier columna, buscar por nombre, hermandad o zona, borrar un jugador con clic derecho y redimensionar la ventana (dentro de unos límites).
- Interfaz con las plantillas de Blizzard: `ButtonFrameTemplate`, cabeceras de la lista de Quién, `ScrollBox`.
- Panel propio en Opciones > AddOns del juego, con el botón **Importar de Spy** (activo solo cuando Spy está cargado). En la lista de addons aparece en la categoría **Combate**.
- **Sin dependencias.** PvP Tally no necesita ningún otro addon ni librería. Si Spy está activo, la primera vez se ofrece importar lo que Spy registró; sin Spy, el addon funciona igual.

## Instalación

Copia (o enlaza) la carpeta `PvPTally/` en `World of Warcraft\_forever_\Interface\AddOns\`. Si cambia el `.toc` (archivos nuevos), hay que reiniciar el juego; `/reload` no basta.

## Comandos

| Comando | Qué hace |
| --- | --- |
| `/tally` | Abre o cierra la ventana (también desde el botón del minimapa o el menú de addons) |
| `/tally settings` | Abre las opciones en Opciones > AddOns (también `options`, `config`, el botón "Opciones" de la ventana o clic derecho en el botón del minimapa). No se pueden abrir en combate |
| `/tally import` | Importa o sincroniza los datos de Spy (igual que el botón de Opciones) |
| `/tally notify` | Activa o desactiva los avisos de kill/muerte en el chat |
| `/tally minimap` | Muestra u oculta el botón del minimapa |
| `/tally reset` | Borra todos los datos de este personaje |
| `/tally debug` | Muestra por qué se contó o no la última kill o muerte |
| `/tally test` | Añade jugadores de prueba (Test Reg y todas las razas en hombre y mujer) |
| `/tally test clear` | Borra los jugadores de prueba |

## Cómo detecta las kills y muertes

En Forever el combat log está cerrado a los addons:

- **Kill**: el evento `PARTY_KILL` con tu golpe de gracia o el de tu mascota.
- **Muerte**: `PLAYER_DEAD`. El asesino se lee del resumen de muerte (`C_DeathRecap`). Si no se puede, cuenta el único enemigo que te tenía en el objetivo en los 6 segundos anteriores.
- Los datos del rival se leen de las placas de nombre, el objetivo, el foco y el mouseover.
- Solo cuenta el mundo abierto: ni campos de batalla, ni arenas, ni instancias.

## Arquitectura

```
PvPTally/
  Locales.lua              textos (inglés y español)
  Core/                    lógica pura: no llama a la API del juego
    Util.lua               valores secretos, textos, fechas, colores
    Events.lua             bus publicar/suscribir entre módulos
    Settings.lua           ajustes de cuenta (PvPTallyDB)
    Store.lua              jugadores y enfrentamientos (PvPTallyCharDB), migraciones
    Races.lua              razas, iconos e insignias de bando (como descriptores)
  Game/
    WowApi.lua             adaptador: la única capa que lee la API de WoW
    Tracker.lua            detección de kills y muertes (recibe el adaptador inyectado)
  Features/
    SpyImport.lua          importación opcional de los SavedVariables de Spy
    TestData.lua           jugadores de prueba
    Notifications.lua      avisos en el chat (escucha el bus)
  UI/
    Columns.lua            columnas, anchos y posiciones (puro)
    ListModel.lua          filtrar, ordenar y aplanar en filas (puro)
    Rows.lua               widgets de cada fila y tooltips
    Window.lua             ventana, cabeceras, búsqueda, redimensionado
    MinimapButton.lua      botón del minimapa
    SettingsPanel.lua      panel en Opciones > AddOns (API Settings de Blizzard)
  Commands.lua             comandos /tally y popups de confirmación
  Init.lua                 arranque: crea los objetos y los conecta
```

Reglas:

- **Las dependencias van hacia dentro.** `Core` no conoce a nadie. `Game`, `Features` y `UI` usan `Core`. Solo `Init.lua` conoce todos los módulos y los conecta.
- **Una sola puerta al juego.** Toda lectura de la API pasa por `Game/WowApi.lua`, que filtra los valores secretos. El `Tracker` recibe ese adaptador por parámetro, así que en los tests se le pasa un juego falso.
- **Un solo dueño de los datos.** Solo `Store` escribe en `PvPTallyCharDB`. Avisa de los cambios por el bus (`DATA_CHANGED`, `ENCOUNTER_ADDED`), y la ventana y el chat escuchan sin que el almacén sepa que existen.
- **Lógica separada de los widgets.** Lo que se puede decidir sin dibujar (columnas, orden, filtros, iconos) es puro y está testeado; los widgets solo pintan.
- **Datos guardados versionados.** `Store.Migrate` actualiza los datos de versiones anteriores paso a paso y descarta lo mal formado.
- **Sin globales propias** salvo los SavedVariables, los comandos `/tally` y la función del menú de addons; cada módulo cuelga del espacio de nombres del addon.

Las normas para implementar cambios (pensadas para agentes de IA, pero válidas para cualquiera) están en [AGENTS.md](AGENTS.md).

## Documentación

- [docs/forever-client-ui.md](docs/forever-client-ui.md): cómo es la interfaz del cliente de Forever ("Camelot", atlas de la ventana de Habilidades, plantillas disponibles, comportamientos del cliente y cómo investigar en el juego).
- [docs/forever-theme.md](docs/forever-theme.md): el tema "Forever" (en pausa). Diseño, lo aprendido al probarlo y el prototipo archivado en `docs/archive/forever-theme-v1/`.

## Tests

La suite no necesita nada más que un intérprete Lua 5.1 (LuaJIT o Lua 5.1, el Lua de WoW). Desde la raíz del repositorio:

```bash
luajit tests/run.lua
```

- `tests/lib/test.lua`: mini framework (`describe`, `it`, `before_each`, aserciones).
- `tests/lib/wow.lua`: un WoW simulado (frames que registran lo que se les hace, eventos, temporizadores, valores secretos).
- `tests/lib/addon.lua`: carga los archivos del addon en un entorno aislado, como hace el cliente.
- `tests/lib/fake_game.lua`: un adaptador de juego falso para el `Tracker`.
- `tests/spec/*_spec.lua`: un archivo por módulo. `addon_spec.lua` comprueba además:
  - que el TOC no declara dependencias y que no se crean globales inesperadas;
  - el arranque con y sin Spy y la migración de datos antiguos;
  - una kill de principio a fin;
  - la ventana: listar, desplegar, ordenar, buscar y redimensionar.

Lint:

```bash
luacheck .
```
