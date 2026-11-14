# PvP Tally

Addon para **World of Warcraft: Forever** que registra cada kill y cada muerte en PvP de mundo.

- Una fila por jugador enemigo con el que te has enfrentado: icono de clase, raza (con insignia de bando para los Cielonato, que pueden ser Alianza u Horda), nivel, hermandad, **Kills**, **Deaths** y fecha del primer encuentro.
- Al hacer clic en una fila se despliega cada enfrentamiento: resultado, fecha y hora local, zona y subzona, nivel del rival y tu nivel.
- Se puede ordenar por cualquier columna, buscar por nombre, hermandad o zona, borrar un jugador con clic derecho y redimensionar la ventana (dentro de unos límites).
- **Notas:** cada jugador tiene un icono de nota en la última columna, apagado si no tiene nota y encendido si la tiene. Al hacer clic se abre un panel al lado de la ventana con una caja de texto de varias líneas (hasta 1000 caracteres, con contador) y los botones Guardar y Cancelar; guardarla vacía la borra y Escape cancela. **Mayús + clic derecho** en el icono borra la nota al momento (un clic derecho solo no hace nada). La nota sale entera en el tooltip de la fila y, resumida (4 líneas), en el tooltip del juego cuando pasas el ratón por ese jugador en el mundo o por su retrato. Ordenar por la columna pone primero a los que tienen nota.
- **Calavera en las placas de nombre:** los jugadores que ya están en tu lista llevan una calavera a la izquierda del nombre en su placa, sean enemigos o no, en el mundo y en los campos de batalla. Solo se ve en las placas que muestra el juego (hay que tener activadas las de enemigos y aliados). Se puede desactivar o cambiar de tamaño en Opciones.
- **Calavera en el retrato:** como alternativa por si otro addon sustituye las placas de nombre (y con ellas la calavera), el retrato de tu objetivo y de tu foco se cubre con una calavera cuando ese jugador está en tu lista. Se puede desactivar en Opciones.
- Interfaz con las plantillas de Blizzard: `ButtonFrameTemplate`, cabeceras de la lista de Quién, `ScrollBox`.
- Panel propio en Opciones > AddOns del juego con:
  - **Chat:** una casilla para los mensajes de kills (tuyas o de tu grupo) y otra para los de muertes;
  - **Calavera:** una casilla para la de las placas de nombre y su tamaño (pequeña, mediana o grande: 22, 28 o 36 píxeles; mediana por defecto), y otra para la del retrato del objetivo y el foco;
  - **Spy:** el botón **Importar de Spy** (activo solo cuando Spy está cargado).
- En la lista de addons aparece en la categoría **Combate**.
- **En el idioma del cliente:** inglés, alemán, español (España y Latinoamérica), francés, italiano, portugués, ruso, coreano y chino simplificado y tradicional. Las fechas siguen el orden de cada idioma y la clase sale en femenino cuando el idioma lo tiene.
- **Sin dependencias.** PvP Tally no necesita ningún otro addon ni librería. Si Spy está activo, la primera vez se ofrece importar lo que Spy registró; sin Spy, el addon funciona igual.

## Instalación

Copia (o enlaza) la carpeta `PvPTally/` en `World of Warcraft\_forever_\Interface\AddOns\`. Si cambia el `.toc` (archivos nuevos), hay que reiniciar el juego; `/reload` no basta.

## Comandos

| Comando | Qué hace |
| --- | --- |
| `/tally` | Abre o cierra la ventana (también desde el botón del minimapa o el menú de addons) |
| `/tally settings` | Abre las opciones en Opciones > AddOns (también `options`, `config`, el botón "Opciones" de la ventana o clic derecho en el botón del minimapa). No se pueden abrir en combate |
| `/tally import` | Importa o sincroniza los datos de Spy (igual que el botón de Opciones) |
| `/tally notify` | Activa o desactiva a la vez los avisos de kills y de muertes en el chat. Cada uno por separado se elige en Opciones |
| `/tally minimap` | Muestra u oculta el botón del minimapa |
| `/tally reset` | Borra todos los datos de este personaje |
| `/tally debug` | Muestra por qué se contó o no la última kill o muerte |
| `/tally test` | Añade jugadores de prueba (Test Reg, con una nota, y todas las razas en hombre y mujer) |
| `/tally test clear` | Borra los jugadores de prueba (también los de `/tally skull`) |
| `/tally skull Nombre Apellido` | Añade ese jugador a la lista como jugador de prueba (con una kill inventada aquí y ahora) para ver la calavera en su placa sin pelear. Sin nombre, usa el jugador que tengas en el objetivo, aliado o enemigo. Un jugador que ya está en la lista no se toca |

## Cómo detecta las kills y muertes

En Forever el combat log está cerrado a los addons:

- **Kill**: el evento `PARTY_KILL` con tu golpe de gracia o el de tu mascota.
- **Kill de tu grupo**: el golpe de gracia de un compañero de grupo o banda, o de su mascota, cuenta si participaste en la pelea. Participar es que en los 10 segundos anteriores tuvieras al enemigo en tu objetivo o foco, él te tuviera en el suyo, o estuvieras en combate con él a la vista. En el detalle sale como "Golpe de gracia de tu grupo". Cada jugador necesita tener PvP Tally instalado.
- **Muerte**: `PLAYER_DEAD`. El asesino se lee del resumen de muerte (`C_DeathRecap`). Si no se puede, cuenta el único enemigo que te tenía en el objetivo en los 6 segundos anteriores.
- Los datos del rival se leen de las placas de nombre, el objetivo, el foco y el mouseover.
- Solo cuenta el mundo abierto: ni campos de batalla, ni arenas, ni instancias. Las calaveras de las placas y del retrato sí se muestran en los campos de batalla, porque no registran nada.

## Arquitectura

```
PvPTally/
  Locales/                 textos: enUS.lua (base) y un archivo por idioma del cliente
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
    TestData.lua           jugadores de prueba (/tally test y /tally skull)
    Notifications.lua      avisos en el chat (escucha el bus)
  UI/
    Columns.lua            columnas, anchos y posiciones (puro)
    ListModel.lua          filtrar, ordenar y aplanar en filas (puro)
    Rows.lua               widgets de cada fila y tooltips
    Window.lua             ventana, cabeceras, búsqueda, redimensionado
    NoteEditor.lua         panel para escribir la nota de un jugador
    MinimapButton.lua      botón del minimapa
    NameplateMarks.lua     calavera en las placas de los jugadores de la lista
    PortraitMarks.lua      calavera sobre el retrato del objetivo y el foco
    TooltipNotes.lua       la nota del jugador en el tooltip del juego
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

## Publicar una versión

Las versiones se publican en GitHub Releases y el zip se sube a CurseForge a mano:

1. Sube `## Version` en `PvPTally/PvPTally.toc` y añade la sección `## vX.Y.Z (fecha)` a `CHANGELOG.md`.
2. Haz commit en una rama y abre un pull request: `CI` ejecuta luacheck, los tests y construye el zip (queda como artefacto para probarlo en el juego).
3. Al fusionar en `main`, `Release` repite las comprobaciones y publica la release `vX.Y.Z` con el zip y las notas. Si la versión ya está publicada, no hace nada.
4. Sube ese zip a CurseForge. La descripción de la ficha está en [docs/curseforge/PvPTally.md](docs/curseforge/PvPTally.md).

En local: `./scripts/test.ps1` (tests) y `./scripts/package.ps1` (zip y notas en `.release/`; exige que `PvPTally/`, `CHANGELOG.md` y `LICENSE` estén en un commit).

## Documentación

- [docs/forever-client-ui.md](docs/forever-client-ui.md): cómo es la interfaz del cliente de Forever ("Camelot", atlas de la ventana de Habilidades, plantillas disponibles, placas de nombre y retratos: cómo son y cómo añadirles iconos, el panel de Opciones, comportamientos del cliente y cómo investigar en el juego).
- [docs/nameplate-marks.md](docs/nameplate-marks.md): la calavera en las placas de nombre y en el retrato del objetivo y el foco. Cómo está hecha, las decisiones, las pruebas en el juego y lo pendiente.
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
  - la calavera de las placas: al aparecer, tras un `/reload`, con una kill nueva, en campos de batalla y con la opción;
  - la ventana: listar, desplegar, ordenar, buscar y redimensionar;
  - las notas: el botón de cada fila, el panel para escribirlas y el tooltip del juego.

Lint:

```bash
luacheck .
```
