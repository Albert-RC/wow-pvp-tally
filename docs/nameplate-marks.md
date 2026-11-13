# La calavera: placas de nombre y retratos

Los jugadores que ya están en tu lista (los que has matado o te han matado) llevan una calavera:

- **en su placa de nombre**, a la izquierda del nombre (`UI/NameplateMarks.lua`);
- **en el retrato de tu objetivo y de tu foco**, como alternativa por si otro addon sustituye las placas (`UI/PortraitMarks.lua`).

Este documento cuenta cómo está hecho en el addon, qué se decidió y cómo se probó. Lo que se aprendió del cliente (cómo son las placas y los retratos en Forever, cómo añadirles iconos, qué texturas existen, cómo investigar en el juego) está en [forever-client-ui.md](forever-client-ui.md).

**Estado (13-11-2026):** implementado y probado en el juego con jugadores aliados. Falta probarlo con enemigos, en combate y en un campo de batalla (ver "Pendiente").

## Cómo está hecho

| Pieza | Dónde | Qué hace |
| --- | --- | --- |
| Leer las placas | `Game/WowApi.lua` | `WowApi.NamePlateForUnit(unit)` devuelve la placa si existe y ni ella ni su `UnitFrame` están prohibidas (`pcall` + `IsForbidden`). `WowApi.VisibleNamePlateUnits()` da las que ya están en pantalla al arrancar (tras un `/reload`). `WowApi.ReadPlayer(unit)` lee a cualquier jugador, aliado o enemigo. |
| Calavera en las placas | `UI/NameplateMarks.lua` | `NameplateMarks.MarkFor(player)` (puro) decide: `nil` si no está en la lista, o `{ file = SKULL }`. `NameplateMarks.New({ playerKey, namePlateFor, lookup, isEnabled, size })`. `:Show(unit)` crea la textura una vez por placa (en una tabla propia), la ancla a la izquierda del nombre, le aplica el tamaño y la muestra u oculta. `:Remove(unit)` la oculta y `:Refresh()` repasa todas. Si se perdió un `REMOVED`, una placa reciclada pasa a la unidad nueva. |
| Calavera en el retrato | `UI/PortraitMarks.lua` | `PortraitMarks.New({ frames = { target, focus }, playerKey, lookup, isEnabled })`. Una textura propia sobre `TargetFrameContainer.Portrait`, un subnivel por encima y con una máscara redonda propia 3 px por dentro (`PortraitMarks.MASK`, `PortraitMarks.INSET`). No toca la textura de Blizzard. |
| Opciones | `Core/Settings.lua` + `UI/SettingsPanel.lua` | En `PvPTallyDB`: `nameplateMarks` (activada por defecto), `nameplateMarkSize` (`Settings.MARK_SIZES`: 22, 28 y 36; 28 por defecto) y `portraitMarks` (activada por defecto). Sección **Calavera**: casilla de las placas con su nota, desplegable de tamaño (pequeña, mediana, grande) y casilla del retrato con su nota. |
| Conexión | `Init.lua` | `StartNameplateMarks` (`NAME_PLATE_UNIT_ADDED/REMOVED`, las placas ya visibles al arrancar) y `StartPortraitMarks` (`PLAYER_TARGET_CHANGED`, `PLAYER_FOCUS_CHANGED`), en `PLAYER_LOGIN`, con los manejadores en `Util.Guard`. Las dos se refrescan con `DATA_CHANGED` (una kill nueva o un jugador borrado cambia la calavera al momento) y al cambiar la opción. |
| Prueba en el juego | `Features/TestData.lua`, `Commands.lua` | `/tally skull [Nombre Apellido]`: `TestData.KeyFromName` y `TestData.AddPlayer` meten al jugador como dato de prueba (`test = true`, una kill con `how = "test"`) sin tocar a uno que ya esté en la lista. |
| Textos | `Locales/*.lua` | `SETTINGS_SKULL_HEADER`, `SETTINGS_NAMEPLATE_MARKS(_NOTE)`, `SETTINGS_MARK_SIZE(_SMALL/_MEDIUM/_LARGE)`, `SETTINGS_PORTRAIT_MARKS(_NOTE)`, `SKULL_ADDED/EXISTS/USAGE`, `HOW_test`, en todos los idiomas. |
| Tests | `tests/spec/` | `nameplate_marks_spec`, `portrait_marks_spec`, y casos en `wowapi_spec`, `settings_spec`, `settings_panel_spec`, `commands_spec`, `test_data_spec` y `addon_spec`. El WoW simulado (`tests/lib/wow.lua`) tiene `C_NamePlate`, `env.__showNamePlate` / `__hideNamePlate`, `Frame:IsForbidden`, `TargetFrame` / `FocusFrame` con su retrato, máscaras y el desplegable (`SetupMenu`, `frame:__menu()`). |

`UI/` no puede usar el Tracker, así que las calaveras no se cuelgan de él: escuchan sus eventos por su cuenta desde `Init.lua`. No hacen falta globales nuevas ni dependencias.

## Decisiones (13-11-2026)

1. **También en campos de batalla.** Las calaveras no registran nada, así que no chocan con la norma "solo PvP de mundo" (que sigue valiendo para el Tracker): no consultan `WowApi.IsWorldPvP`. En Forever no hay arenas.
2. **A todos los jugadores de la lista**, sean ahora enemigos o no (por ejemplo, un Skyborne que ha cambiado de facción). La regla es solo que estén en la lista. Los datos de prueba cuentan igual.
3. **Un solo color.** La textura tal cual, sin `SetVertexColor`. Más adelante se podría colorear según el balance (las cuentas salen de `Store.Counts`).
4. **En la placa, a la izquierda del nombre**, con la calavera del nivel "??" (`UI-TargetingFrame-Skull`), la que BetterBlizzPlates ya pinta en sus placas. Se descartó la marca de banda (se confunde con una de verdad).
5. **Tres tamaños para la placa: 22, 28 y 36 píxeles**, elegidos en el juego. Se probaron con un comando temporal (`/tally skull size`, ya retirado); un tamaño guardado entonces pasa al más cercano de los tres.
6. **En el retrato, la calavera humana** del icono del addon (`INV_Misc_Bone_HumanSkull_01`), recortada en redondo. Para objetivo y foco.

## Cómo se probó

1. **Prueba de concepto con `/run`**, antes de escribir código: pintar y quitar una calavera en todas las placas visibles y leer sus nombres (los comandos están en [forever-client-ui.md](forever-client-ui.md#cómo-investigar-en-el-juego)).
   - 13-11-2026, con 32 jugadores aliados cerca, fuera de combate: la calavera se pinta y se quita ✅, todos los nombres legibles y ninguna placa prohibida ✅, tokens hasta `nameplate35`. Los atlas `DungeonSkull` y `Dungeon` existen ✅.
2. **El addon, con `/tally skull`** sobre un aliado en el objetivo: la calavera sale en la placa ✅ y en el retrato ✅.
3. **Lo que se corrigió al verlo en el juego:**
   - con la `PortraitMask` de Blizzard, la calavera cuadrada se salía por el aro del retrato → máscara redonda propia, 3 px por dentro;
   - el texto largo de la casilla del retrato se salía de la ventana de Opciones → etiqueta corta y nota debajo.

## Pendiente

- ⚠️ Con **enemigos en combate**: si el nombre de una placa enemiga pasa a ser secreto, la calavera no sale (sin errores). Comprobarlo con el diagnóstico de nombres de [forever-client-ui.md](forever-client-ui.md#cómo-investigar-en-el-juego).
- ⚠️ En un **campo de batalla**: el cliente puede ocultar identidades (`C_Secrets.ShouldUnitIdentityBeSecret`) o prohibir placas. Debería no pintarse nada, sin errores.
- ⚠️ Confirmar que la máscara propia del retrato ya no se sale del aro.
- Con **BetterBlizzPlates**: que la calavera no choca con sus indicadores.
