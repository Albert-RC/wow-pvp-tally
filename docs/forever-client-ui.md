# La interfaz del cliente de WoW Forever

Lo que sabemos del cliente de Forever para hacer interfaces con su aspecto. Está comprobado en el juego (noviembre de 2026) o leído en los addons de Forever instalados. Si algo cambia con un parche, actualiza este documento.

## "Camelot" es el cliente, no un tema

- **Camelot es el nombre interno del proyecto Forever:**
  - `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT` (vale 18; Prat y AtlasLoot lo comparan);
  - TOCs con sufijo `_Camelot` (`BetterBlizzFrames_Camelot.toc`);
  - archivos que solo carga este cliente con `[AllowLoadGameType camelot]`;
  - pantallas de carga `Camelot160\...\loadscreen_camelot_*`.
- **La "skin Camelot" es el dibujo que el cliente pone a los atlas de siempre.** El marco de las ventanas usa los nombres estándar (`UI-Frame-Metal-*`, `UI-Frame-PortraitMetal-CornerTopLeft`, `RedButton-Exit`…), pero con el arte de Forever. Por eso **cualquier ventana con `ButtonFrameTemplate` o `PortraitFrameTemplate` ya tiene el aspecto de Forever** sin hacer nada.
  - Baganator, en Forever, solo corrige el `ButtonFrameTemplate` en 2 px arriba y 5 px abajo.
- **No hay una opción del cliente para elegir estilo:** ningún CVar de estilo de UI. El aspecto "clásico" en Forever lo dan addons de terceros (ClassicUI Forever).
- **Iconos de clase:** cada clase se dibuja con su arma característica (bastón para sacerdote, arco para cazador, espada para guerrero, garra para druida…). Salen igual con los atlas `classicon-<clase>` que con la hoja clásica `Interface\WorldStateFrame\Icons-Classes` + `CLASS_ICON_TCOORDS`. Es el estilo del cliente, no un error.

## La ventana de Habilidades (Personaje > Habilidades)

Es la referencia del "aspecto Forever" para listas. Estructura según `/fstack` y un volcado de sus texturas:

- `CharacterFrame`: el marco. `TitleContainer` y `NineSlice` vienen de `Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml`, igual que en `ButtonFrameTemplate`.
  - `CharacterFrameLeftPaneHost`: el panel de la lista.
  - `CharacterFrameRightPaneHost`: el panel de detalle.
  - `CharacterFrameRightPaneToggleButton`: el botón que pliega el panel derecho (texturas 130757, 130868, 130869).
  - `CharacterFrameModeTab1..6`: las pestañas laterales.
- `SkillsFrame` (con s; no es el `SkillFrame` de Classic): el contenido, construido con código propio.
  - `ScrollBox` + `ScrollBar` (`MinimalScrollBar`).
  - Filas `ScrollTarget.<id>`: cabeceras de categoría, y filas de habilidad con `Content.BackgroundHighlight` y `Content.SkillsBar`.
  - `SkillDetailFrame`: el panel de detalle, con `RankBar` y `DescriptionScrollBar`.

### Atlas y texturas

| Pieza | Atlas o textura |
| --- | --- |
| Marco | `UI-Frame-Metal-*`, `UI-Frame-PortraitMetal-CornerTopLeft` |
| Cerrar | `RedButton-Exit`, `-Disabled`, `-Highlight`, `-exit-pressed` |
| Fondo del panel izquierdo | `UI-Character-Info-General-BG` |
| Fondo del panel derecho | `UI-Character-Info-Stat-BG` + `UI-Character-Info-Stat-StoneBG3` |
| Separador entre paneles | `common-framedivider` |
| Bordes superior e inferior de la lista | `UI-Character-Info-ScrollLine-Long` |
| Título del panel de detalle | `UI-Character-Info-ScrollLine` |
| Cabecera de categoría (caja dorada) | `common-button-list-collapseExpand` |
| Botón de categoría | `common-button-list-minus` / `common-button-list-plus` |
| Barra "150 / 150" | `common-stat-bar-BG` + `common-stat-bar-Mask` + relleno `common-stat-bar-blue` |
| Otros rellenos de barra | `common-stat-bar-green` ✅, `common-stat-bar-red` ✅, `common-stat-bar-yellow` ❌ (no existe) |
| Resaltado de fila | `charactercreate-customize-dropdown-linemouseover-side` (extremos) + `-middle` (centro). **El atlas es blanco**: a opacidad completa tapa la fila; en Habilidades se ve como un gris suave (con un 20 % se parece) |
| Pestañas laterales | `common-sidetab`, `-hover`, `-selected`, `-mask` |
| Scroll | `minimal-scrollbar-*` |

Todos son atlas públicos: un addon puede usarlos con `texture:SetAtlas(nombre)`.

### Plantillas

| Plantilla | ¿Disponible para addons? |
| --- | --- |
| `SkillLabelTemplate`, `SkillStatusBarTemplate`, `SkillRankFrameTemplate` | ❌ (las cabeceras y barras de Habilidades no son plantillas públicas) |
| `MinimalScrollBar`, `SquareIconButtonTemplate` | ✅ |
| `ButtonFrameTemplate`, `PortraitFrameTemplate`, `UIPanelButtonTemplate`, `SearchBoxTemplate`, `WowScrollBoxList`, `TabButtonTemplate` | ✅ (los usan muchos addons de Forever) |
| `WowStyle1DropdownTemplate` + `dropdown:SetupMenu(fn)` con `rootDescription:CreateRadio(...)` | ✅ (74 usos en addons de Forever) |
| `CreateMaskTexture` / `AddMaskTexture` | ✅ (más de 200 usos) |
| API `Settings` (`RegisterCanvasLayoutCategory`, `RegisterAddOnCategory`, `OpenToCategory(category:GetID())`) | ✅ (Syndicator y Leatrix_Plus la usan) |

Otras texturas clásicas que siguen existiendo y otros addons de Forever usan: `Interface\DialogFrame\UI-DialogBox-Border` / `-Background` / `-Header`, `Interface\Tooltips\UI-Tooltip-Border`, `Interface\FrameGeneral\UI-Background-Rock`, `Interface\PaperDollInfoFrame\UI-Character-Skills-Bar` / `-BarBorder`.

## Comportamientos del cliente que hay que tener en cuenta

- **El tamaño de un frame se notifica más tarde.** Leer `GetWidth()` o `GetHeight()` puede disparar `OnSizeChanged` en ese mismo momento. Si el código está a medio cambiar el estado de la ventana, ese `OnSizeChanged` lo ve a medias (error real: `Window.lua:149` en el prototipo del tema Forever). Lee el tamaño antes de empezar y no actúes en `OnSizeChanged` a medio cambio. El WoW simulado de los tests reproduce este comportamiento.
- **El panel de Opciones no se abre en combate.** Comprueba `InCombatLockdown()` (`WowApi.InCombat()`) y avisa.
- **BugSack captura los errores de `/run`** sin mostrarlos en el chat: si un comando "no hace nada", mira BugSack.
- **Archivos nuevos en el TOC:** no se cargan con `/reload`; hay que reiniciar el juego.

## Cómo investigar en el juego

- **`/fstack`** y pasar el ratón por un elemento: muestra su nombre, su jerarquía y, en `SOURCE`, el archivo XML y la línea de donde sale.
- **¿Existe una plantilla?**
  ```
  /run for _,t in ipairs({"SkillLabelTemplate","MinimalScrollBar"}) do print(t, C_XMLUtil.GetTemplateInfo(t) and "sí" or "no") end
  ```
- **¿Existe un atlas?**
  ```
  /run for _,a in ipairs({"classicon-rogue","common-stat-bar-green"}) do print(a, C_Texture.GetAtlasInfo(a) and "sí" or "no") end
  ```
- **Volcar las texturas de una ventana.** La línea del chat admite como mucho **255 caracteres**, así que va en dos pasos. El resultado se guarda en los ajustes de PvP Tally; tras `/reload` aparece en `WTF/Account/<cuenta>/SavedVariables/PvPTally.lua`.
  ```
  /run function PTD(f,t) for _,r in ipairs({f:GetRegions()}) do local a=r.GetAtlas and(r:GetAtlas()or r:GetTexture()) if a then t[#t+1]=f:GetDebugName()..(f:IsVisible()and" "or" [h] ")..a end end for _,c in ipairs({f:GetChildren()}) do PTD(c,t) end end
  ```
  ```
  /run PvPTallyDB.dump={} PTD(CharacterFrame,PvPTallyDB.dump) print(#PvPTallyDB.dump)
  ```
  Al terminar, bórralo: `/run PvPTallyDB.dump=nil PTD=nil` y `/reload`.
