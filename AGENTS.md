# Normas para agentes de IA

Este archivo dice cómo implementar cambios en **PvP Tally** siguiendo el estilo del repositorio. Léelo entero antes de tocar código. Las normas marcadas como **[OBLIGATORIA]** no se pueden saltar sin permiso del usuario (ver [Protocolo de bloqueo](#protocolo-de-bloqueo)).

## 0. Protocolo de bloqueo

Si una norma de este archivo impide hacer lo que el usuario pide, o solo se podría cumplir el encargo rompiéndola:

1. **Para antes de implementar la parte afectada.** No la rodees en silencio, no hagas una versión a medias que "casi" cumple y no relajes un test para que pase.
2. **Informa al usuario** con:
   - la norma concreta (sección y texto);
   - por qué bloquea lo que pide, con el ejemplo concreto (archivo, API o dato);
   - las opciones: **añadir una excepción**, **ignorar la norma solo esta vez**, o una **alternativa que sí cumple**, con su coste;
   - tu recomendación.
3. **Espera su decisión.** Puedes seguir con las partes del encargo que no dependen del bloqueo.
4. Si el usuario aprueba una excepción permanente, **apúntala** en [Excepciones aprobadas](#excepciones-aprobadas) con la fecha, el alcance y el motivo. Una autorización de "ignorar esta vez" no se apunta y no vale para cambios futuros.

Ejemplos típicos de bloqueo: hace falta una librería u otro addon; hay que crear una global nueva; una API del juego no se puede testear con los fakes; un cambio rompe datos guardados sin migración posible; hay que borrar o debilitar un test existente.

## 1. Contexto del proyecto

- Addon para **World of Warcraft: Forever**: cliente moderno (`## Interface: 16001`) sobre el mundo de Vanilla. El Lua es **5.1**.
- **El combat log está cerrado a los addons.** Las kills se detectan con `PARTY_KILL` y las muertes con `PLAYER_DEAD` + `C_DeathRecap`, con la fallback del único enemigo que te tenía en el objetivo.
- **Valores secretos:** el cliente puede devolver valores opacos que no se pueden comparar ni usar como clave. Todo valor leído del juego pasa por `Util.Readable`.
- **Nombres:** los personajes tienen nombre y apellido. La clave de un jugador es `"Nombre-Apellido"` (la misma que usa Spy) y se muestra con espacio.
- **Razas:** las de Vanilla más **Skyborne** (Cielonato de la Orden Eminente), que puede ser Alianza (raza 95) u Horda (96).
- **Iconos de clase:** en Forever, cada clase se dibuja con su arma característica (bastón para sacerdote, arco para cazador, espada para guerrero…). Es el estilo del cliente, no un error: lo muestran igual los atlas `classicon-<clase>` y la hoja clásica `Icons-Classes`. Usa `races:ClassIcon(class)`, que prueba los atlas y deja la hoja clásica como último recurso.
- **El tamaño de un frame se notifica más tarde:** en el cliente, leer `GetWidth()` o `GetHeight()` puede disparar `OnSizeChanged` en ese mismo momento. Un código que cambia el estado de la ventana (columnas, cabeceras…) debe leer el tamaño antes de empezar, y `OnSizeChanged` no debe actuar a medio cambio. El WoW simulado de los tests lo reproduce.
- **Interfaz del cliente:** antes de tocar el aspecto de la ventana, lee [docs/forever-client-ui.md](docs/forever-client-ui.md). Recoge qué es "Camelot", el mapa de atlas de la ventana de Habilidades, qué plantillas están disponibles y cómo investigar en el juego.
- **Tema "Forever" en pausa:** hubo un selector de estilo Classic / Forever que se retiró para rediseñarlo. No lo reintroduzcas sin que el usuario lo pida; el diseño, lo aprendido y el código archivado están en [docs/forever-theme.md](docs/forever-theme.md).
- Antes de usar una API, plantilla, textura o atlas, comprueba que existe en este cliente. Las fuentes fiables son el código de Blizzard o los addons de Forever instalados (por ejemplo, el port de Spy en `Spy/Forever.lua`). Si no puedes comprobarlo, protégelo con `pcall` o con una comprobación de existencia, y pon una alternativa.

## 2. Restricciones duras

- **[OBLIGATORIA] Sin dependencias.** Nada de `## Dependencies`, `## RequiredDeps`, `## OptionalDeps` ni `## LoadWith` en el TOC. Tampoco LibStub, librerías embebidas, XML, llamadas a código de otros addons, `IsAddOnLoaded` ni `LoadAddOn`. La única relación con otro addon es leer los SavedVariables de Spy (`SpyPerCharDB`), y solo dentro de `Features/SpyImport.lua`.
- **[OBLIGATORIA] Sin globales nuevas.** Las únicas globales que escribe el addon son: `PvPTallyDB`, `PvPTallyCharDB`, `SLASH_PVPTALLY1`, `SLASH_PVPTALLY2`, `PvPTally_OnAddonCompartmentClick` y las entradas `PVPTALLY_*` de `StaticPopupDialogs` y `SlashCmdList`. Los frames con nombre (`PvPTallyFrame`, `PvPTallyMinimapButton`) se crean con `CreateFrame`. Todo lo demás cuelga del espacio de nombres `ns`.
- **[OBLIGATORIA] Solo PvP de mundo.** No se registra nada en campos de batalla, arenas ni instancias (`WowApi.IsWorldPvP`).
- **[OBLIGATORIA] No toques datos del usuario.** No edites ni borres archivos de `WTF/` (SavedVariables) ni datos guardados del juego. Para probar con datos reales, cárgalos en memoria con el entorno de tests.

## 3. Arquitectura

```
Locales.lua         textos
Core/               lógica pura: Util, Events, Settings, Store, Races
Game/               WowApi (adaptador del juego) y Tracker (detección)
Features/           SpyImport, TestData, Notifications
UI/                 Columns y ListModel (puros), Rows, Window, MinimapButton, SettingsPanel (widgets)
Commands.lua        /tally y popups
Init.lua            arranque y conexión de módulos
```

- **[OBLIGATORIA] Las dependencias van hacia dentro.** `Core` no usa `Game`, `Features`, `UI` ni la API de WoW. `Game`, `Features` y `UI` pueden usar `Core`. `UI` no usa `Game/Tracker`. **Solo `Init.lua`** conoce y conecta todos los módulos.
- **[OBLIGATORIA] Una sola puerta al juego.** Toda lectura de la API de WoW para obtener datos (unidades, zona, mapas, death recap, razas, atlas) va en `Game/WowApi.lua`, que filtra los valores secretos con `Util.Readable`. Los módulos de `UI/` sí pueden llamar a las APIs de widgets (`CreateFrame`, texturas, `GameTooltip`, sonidos).
- **[OBLIGATORIA] Un solo dueño de los datos.** Solo `Core/Store.lua` escribe en `PvPTallyCharDB` (y `Settings` en `PvPTallyDB`). Los demás usan los métodos de `Store` (`AddEncounter`, `EnsureTotals`, `DeleteWhere`, `MarkImported`...). La excepción son los campos informativos de un jugador mediante `Store.UpdateInfo`.
- **Comunicación por el bus.** Los cambios se anuncian con `ns.bus` (`DATA_CHANGED`, `ENCOUNTER_ADDED`), y quien necesite reaccionar se suscribe en `Init.lua`. El almacén nunca llama a la UI ni al chat. Si añades un evento, decláralo como constante en `Core/Events.lua` y documenta sus argumentos.
- **Inyección de dependencias.** Lo que tiene estado se crea con un constructor `X.New(...)` que recibe sus colaboradores, como `Tracker.New(game, store)` o `Races.NewResolver(getRaceInfo, atlasExists)`. No se busca nada en globales desde dentro.
- **Lógica separada de los widgets.** Lo que se puede decidir sin dibujar (anchos, orden, filtros, textos, qué icono toca) va en un módulo puro y testeado. Los widgets solo pintan. Los iconos se devuelven como descriptores (`{ atlas = ... }` o `{ file = ..., coords = ... }`) y `Rows.ApplyIcon` los dibuja.

### Dónde va el código nuevo

| Si la feature... | Va en |
| --- | --- |
| lee algo nuevo del juego | una función en `Game/WowApi.lua` (+ la misma en `tests/lib/fake_game.lua` si la usa el Tracker) |
| cambia cómo se detectan kills o muertes | `Game/Tracker.lua` |
| guarda un dato nuevo | `Core/Store.lua` (con migración, ver §5) |
| es una regla de negocio sin juego ni widgets | `Core/` |
| es una funcionalidad autocontenida (importar, exportar, estadísticas...) | un archivo nuevo en `Features/` |
| cambia qué filas o columnas se muestran | `UI/ListModel.lua` o `UI/Columns.lua` |
| cambia cómo se ve una fila o la ventana | `UI/Rows.lua` o `UI/Window.lua` |
| es una opción configurable | el valor por defecto y su reparación en `Core/Settings.lua` (`PvPTallyDB`), y el control en una sección de `UI/SettingsPanel.lua`. Una opción que se retira se añade a `DISCARDED` en `Settings.lua` para limpiarla de los datos guardados |
| es una acción para el usuario que no es del día a día (importar, mantenimiento) | un botón en una sección de `UI/SettingsPanel.lua` que llama a una acción de `App` |
| es un comando | `Commands.ACTIONS` + una acción en `App` (`Init.lua`) |
| conecta módulos o reacciona a eventos del juego al arrancar | `Init.lua` |

## 4. Estilo de código

- **Cabecera:** cada archivo empieza con `-- PvP Tally: <qué hace>.` y, si hace falta, un párrafo sobre por qué está así.
- **Plantilla de módulo:**
  ```lua
  local _, ns = ...
  local L, Util, Store = ns.L, ns.Util, ns.Store   -- solo lo que se usa

  local Thing = {}
  ns.Thing = Thing
  ```
  Las "clases" usan `Thing.__index = Thing`, `setmetatable(..., Thing)`, métodos con `:` y `assert` en el constructor para los parámetros obligatorios.
- **Nombres:**
  - funciones de módulo y métodos en `PascalCase` (como la API de WoW);
  - variables y campos locales en `camelCase`;
  - constantes en `UPPER_SNAKE_CASE`;
  - identificadores y comentarios en **inglés**.
- **Formato:** tabulaciones, comillas dobles y sin `;`. Separa secciones con `-- Título ------`. Funciones cortas con retornos tempranos.
- **Comentarios:** explican el *porqué* o una peculiaridad de Forever, no lo que el código ya dice.
- **Robustez ante el cliente:**
  - toda llamada a una API que puede no existir o lanzar errores va con `pcall` o con una comprobación de existencia;
  - todo manejador de eventos del juego va envuelto (`Util.Guard` o `pcall` + `Util.ReportError`);
  - los errores se guardan para `/tally debug`, nunca se lanzan al chat.
- **Orden del TOC:** un archivo solo puede usar al cargarse módulos que estén antes en el TOC. Si se usan al llamar a una función, pueden estar después. Los archivos nuevos se añaden en su sección del TOC.
- **Efectos al cargar:** solo `Init.lua` registra eventos o crea frames al cargarse, y solo `Commands.lua` registra los popups y el comando `/tally`. El resto de módulos solo definen cosas.

## 5. Datos guardados

- `PvPTallyCharDB` (por personaje): lo gestiona `Store`, con su esquema documentado en la cabecera de `Store.lua`. `PvPTallyDB` (de cuenta): lo gestiona `Settings`.
- **[OBLIGATORIA] Todo cambio de esquema es una migración:**
  - sube `Store.SCHEMA_VERSION`;
  - añade `MIGRATIONS[n]` (de `n` a `n+1`);
  - actualiza el comentario del esquema;
  - escribe un test con datos de la versión anterior.
- Nunca renombres ni borres un campo guardado sin migración. `Store.Migrate` debe seguir aceptando datos mal formados sin lanzar errores.
- Los datos de prueba (`/tally test`) se marcan con `test = true` y se borran con `TestData.Clear`.

## 6. Textos e idiomas

- **[OBLIGATORIA]** Todo texto que vea el usuario sale de `Locales.lua` (`L.CLAVE`), en **inglés** (base) y **español** (`esES` y `esMX`). Los marcadores (`%s`, `%d`...) tienen que ser los mismos en los dos idiomas. Hay un test que lo comprueba.
- No pongas texto visible a mano en la UI. Las excepciones son los datos inventados de `TestData` y los mensajes de `/tally debug`, que van en inglés.

## 7. Interfaz (estilo Blizzard)

- Usa plantillas y recursos de Blizzard: `ButtonFrameTemplate`, `UIPanelButtonTemplate`, `SearchBoxTemplate`, `WowScrollBoxList` + `MinimalScrollBar`, `GameTooltip`, `StaticPopupDialogs`, texturas de Interface y atlas.
- Si no está garantizado que un atlas exista, compruébalo (`WowApi.AtlasExists`) y pon una textura de respaldo.
- Los colores siguen los de Blizzard: dorado para títulos, verde y rojo para victoria y derrota, color de clase en los nombres.
- La ventana redimensionable respeta `Window.MIN_*` y `Window.MAX_*`. Las columnas se calculan en `UI/Columns.lua`: si añades una, ajusta `LIST_WIDTH` para que las anchuras base sumen exactamente ese valor (hay un test que lo comprueba).
- Las filas se reciclan: `Rows.Init` debe dejar cada widget en un estado completo, sin depender del uso anterior del frame.
- La tecla Escape cierra la ventana. Ninguna acción puede depender de funciones protegidas en combate. Si algo no se puede hacer en combate (como abrir Opciones), se comprueba con `WowApi.InCombat()` y se avisa en el chat, como `App.OpenSettings`.
- Las opciones del addon viven en el panel nativo de Opciones > AddOns (`UI/SettingsPanel.lua`), no en ventanas propias.

## 8. Tests

- **[OBLIGATORIA]** Todo comportamiento nuevo o cambiado lleva tests en `tests/spec/`:
  - lógica pura → un spec del módulo;
  - Tracker → `tests/lib/fake_game.lua`;
  - lectura del juego → `wowapi_spec.lua` con la API simulada de `tests/lib/wow.lua`;
  - arranque y ventana → `addon_spec.lua`.
- Un archivo de spec nuevo se añade a la lista `SPECS` de `tests/run.lua`.
- Si `WowApi` gana una función que usa el Tracker, añádela también a `fake_game.lua`. Si el addon empieza a leer una global nueva de WoW, añádela a `tests/lib/wow.lua`.
- **[OBLIGATORIA]** No borres, saltes ni debilites un test existente para que pase. Si un test choca con lo que se pide, es un bloqueo (§0).
- La suite no tiene dependencias: no añadas busted ni otras librerías.

## 9. Definición de terminado

Antes de dar una tarea por acabada:

1. `luajit tests/run.lua` → todos los tests pasan.
2. `luacheck .` → 0 avisos. Añadir a `read_globals` de `.luacheckrc` una API de WoW que se lee está permitido. Añadir algo a `globals` (escritura) es una global nueva y necesita permiso (§2).
3. Textos nuevos en inglés y español.
4. `README.md` al día: tabla de comandos, árbol de arquitectura y comportamiento.
5. Si has añadido o quitado archivos del TOC, avisa al usuario de que tiene que **reiniciar el juego** (`/reload` no carga archivos nuevos).
6. En el resumen al usuario, di qué se ha verificado (tests, lint) y qué falta por probar dentro del juego.

## Excepciones aprobadas

Ninguna por ahora. Formato:

```
- AAAA-MM-DD — Norma §N "..." — Alcance: ... — Motivo: ... — Aprobada por el usuario.
```
