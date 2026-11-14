# La interfaz del cliente de WoW Forever

Lo que sabemos del cliente de Forever para hacer interfaces con su aspecto y para tocar las placas de nombre y los retratos. Está comprobado en el juego (noviembre de 2026) o leído en los addons de Forever instalados. Si algo cambia con un parche, actualiza este documento.

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
| Caja de texto de varias líneas: `InsetFrameTemplate` > `ScrollFrameTemplate` > `EditBox` con `SetMultiLine(true)` como hijo del scroll (`SetScrollChild`) | ✅ (así la hace ForeverCore en `UI/Report.lua`; ForeverMail y ForeverDungeonJournal también usan `SetMultiLine`). La caja de `StaticPopupDialogs` (`hasEditBox`) es de una sola línea |

Otras texturas clásicas que siguen existiendo y otros addons de Forever usan: `Interface\DialogFrame\UI-DialogBox-Border` / `-Background` / `-Header`, `Interface\Tooltips\UI-Tooltip-Border`, `Interface\FrameGeneral\UI-Background-Rock`, `Interface\PaperDollInfoFrame\UI-Character-Skills-Bar` / `-BarBorder`.

## Placas de nombre (nameplates)

Comprobado en el juego en noviembre de 2026 y leído en BetterBlizzPlates (rama `forever/`) y en el port de Spy (`Spy/Forever.lua`). Uso en PvP Tally: [nameplate-marks.md](nameplate-marks.md).

### Cómo son

- **Son las del cliente moderno, no las de Classic.** BetterBlizzPlates trata Forever como "mainline" (`BBP.isMainline = BBP.isMidnight or BBP.isForever`).
- **Estructura:**
  - `nameplate`: el frame base, de `C_NamePlate.GetNamePlateForUnit(unit)` o de `C_NamePlate.GetNamePlates()`.
  - `nameplate.UnitFrame`: el frame de Blizzard con el contenido:
    - `.unit`: el token (`"nameplate3"`);
    - `.name`: el FontString del nombre;
    - `.HealthBarsContainer.healthBar`: la barra de vida;
    - `.CastBarsContainer.castBar`, `.RaidTargetFrame`…
- **Eventos:** `NAME_PLATE_UNIT_ADDED` y `NAME_PLATE_UNIT_REMOVED`, con el token como argumento.
- **Tras un `/reload`** las placas que ya estaban en pantalla no vuelven a lanzar `ADDED`: hay que recorrer `C_NamePlate.GetNamePlates()` al arrancar.
- **Se reciclan:** la misma placa pasa de una unidad a otra. Lo que se le añada hay que mostrarlo u ocultarlo de nuevo en **cada** `ADDED`; si no, se queda en la unidad siguiente.
- **Hay muchas:** con mucha gente cerca se vieron tokens hasta `nameplate35`. No supongas un máximo pequeño.
- **Placas prohibidas:** en instancias el cliente puede prohibir tocar algunas placas (cualquier llamada da error). Comprueba `IsForbidden()` en la placa y en su `UnitFrame` antes de usarlas, y llama a `C_NamePlate` con `pcall`.
- **Los nombres se leen:** en el mundo, fuera de combate, `UnitName("nameplateN")` dio el nombre legible en 32 placas de 32 (ninguno secreto). `C_Secrets.ShouldUnitIdentityBeSecret(unit)` dice si el cliente va a ocultar una identidad. ⚠️ Sin comprobar: enemigos en combate y campos de batalla.

### Añadirles un icono

- **Una textura propia por placa, creada una sola vez:** `nameplate:CreateTexture(nil, "OVERLAY")`, guardada en una tabla propia indexada por la placa (`textures[nameplate]`). No escribas campos en los frames de Blizzard: otros addons también los usan.
- **Ánclala a `UnitFrame.name`** (por ejemplo `SetPoint("RIGHT", name, "LEFT", -2, 0)`): sigue al nombre aunque Blizzard o BetterBlizzPlates lo muevan. Si no hay `name`, encima de `UnitFrame`.
- **Vuelve a aplicar lo que pueda cambiar** (icono, tamaño) cada vez que se muestra, no solo al crearla.
- BetterBlizzPlates hace lo mismo con un frame propio sobre la barra de vida (`CreateFrame("Frame", nil, healthBar)`, estrato `DIALOG`), y con él muestra todos sus indicadores.
- **Combate:** crear, mover y mostrar texturas propias no es una acción protegida, así que funciona en combate. No toques el tamaño, la posición ni la visibilidad de la placa de Blizzard.

### Limitaciones

- **Solo existen las placas que muestra el cliente.** Sin "Mostrar siempre las placas de nombre" (CVar `nameplateShowAll`) solo salen en combate; sin `nameplateShowEnemies` o `nameplateShowFriends` no salen las enemigas o las aliadas. También dependen de la distancia (`nameplateMaxDistance`).
- **Los addons que sustituyen las placas** (Plater, Kui…) ocultan el `UnitFrame` de Blizzard, y con él lo que se le haya añadido. BetterBlizzPlates modifica las de Blizzard, así que con él sí se ve.

### Texturas de calavera que existen

| Textura | Comentario |
| --- | --- |
| `Interface\TargetingFrame\UI-TargetingFrame-Skull` | La del nivel "??". BetterBlizzPlates la pinta en sus placas. Pequeña y legible. |
| `Interface\TargetingFrame\UI-RaidTargetingIcon_8` | La marca de banda: se confunde con una marca de verdad. |
| `Interface\Icons\INV_Misc_Bone_HumanSkull_01`, `INV_Misc_Bone_Skull_02` | Iconos de objeto, cuadrados. Se ven bien recortados en redondo. |
| atlas `DungeonSkull`, `Dungeon` | ✅ Existen (comprobado en el juego). Son los iconos de mazmorra del mapa. |

## Retratos del objetivo y del foco

Leído en BetterBlizzFrames (`forever/modules/bigDebuffs.lua`, `camelotFrames.lua`) y comprobado en el juego en noviembre de 2026. Uso en PvP Tally: `UI/PortraitMarks.lua`.

- **Estructura:** `TargetFrame.TargetFrameContainer.Portrait` (la textura del retrato) y `.PortraitMask` (su máscara redonda). Lo mismo en `FocusFrame`. También existen `.FrameTexture` (el marco) y `.BossPortraitFrameTexture`.
- **No cambies la textura de Blizzard.** Blizzard la redibuja cuando quiere (`UnitFramePortrait_Update`, al cambiar de objetivo o de retrato), y otros addons la enganchan (BetterBlizzFrames pone iconos de especialización con `hooksecurefunc("UnitFramePortrait_Update", …)`). Lo que pongas con `SetTexture` se pisa.
- **Pon una textura propia encima:**
  - `TargetFrameContainer:CreateTexture(nil, capa, nil, subnivel + 1)`, con la capa y el subnivel de `Portrait:GetDrawLayer()` (el subnivel como mucho vale 7). Así queda encima del retrato y debajo del marco;
  - `SetAllPoints(Portrait)`.
- **Recórtala con una máscara propia, no con `PortraitMask`.** Con la de Blizzard, un icono cuadrado se salía por el aro del marco (visto en el juego). Funciona una máscara propia:
  ```lua
  local mask = container:CreateMaskTexture()
  mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  mask:SetPoint("TOPLEFT", portrait, "TOPLEFT", 3, -3)
  mask:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMRIGHT", -3, 3)
  texture:AddMaskTexture(mask)
  ```
  `TempPortraitAlphaMask` es la máscara redonda que usa BetterBlizzFrames en Forever. Los 3 px por dentro hacen que el aro tape el borde. ⚠️ Pendiente de confirmar en el juego que con este margen ya no se sale.
- **Cuándo actualizar:** `PLAYER_TARGET_CHANGED` y `PLAYER_FOCUS_CHANGED`.
- **Los addons que sustituyen los marcos de unidad** (ElvUI, Shadowed Unit Frames…) ocultan `TargetFrame`. Comprueba que existen `TargetFrameContainer` y `Portrait` antes de usarlos.

## Panel de Opciones

- **Las etiquetas de las casillas no saltan de línea.** Con `UICheckButtonTemplate`, un texto largo se sale de la ventana. Usa una etiqueta corta y pon la explicación en un FontString debajo, con `SetWidth` (unos 560 px) y `SetJustifyH("LEFT")`, que sí salta de línea.
- **Desplegable:** `CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")` y `dropdown:SetupMenu(function(_, root) root:CreateRadio(texto, estaElegido, elegir) end)`. Lo usan Syndicator, Baganator, Leatrix_Plus y Auctionator en Forever. Para que muestre un valor cambiado desde fuera, llama a `dropdown:GenerateMenu()`.

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
- **`/chatlog` no sirve para pasar resultados.** `Logs\WoWChatLog.txt` solo guarda los mensajes de chat de verdad, no lo que escribe `print`. Para que Claude lea algo, guárdalo en `PvPTallyDB.dump` y haz `/reload`, como arriba.
- **Las capturas** (tecla Impr Pant) se guardan en `_forever_\Screenshots`, y Claude puede abrirlas. Son la forma más rápida de enseñar un problema visual.
- **Un `/run` no llega a lo que crea el addon.** Sus frames y texturas cuelgan del espacio de nombres `ns`, no de globales. Buscarlos recorriendo las regiones de un frame no funcionó con las placas de nombre. Para ajustar algo del addon en directo hace falta un comando del addon (como el temporal `/tally skull size` con el que se eligieron los tamaños de la calavera).
- **Probar sin pelear:** `/tally skull Nombre Apellido` (o `/tally skull` con un jugador en el objetivo) mete a ese jugador en la lista como dato de prueba. Se borra con `/tally test clear`.
- **¿Se leen los nombres de las placas?** Guarda una línea por placa (token, nombre o `<secret>`, y si está prohibida) en `PvPTallyDB.dump`; luego `/reload`:
  ```
  /run local d={}PvPTallyDB.dump=d for _,p in ipairs(C_NamePlate.GetNamePlates())do local u=p.UnitFrame.unit local n=UnitName(u)d[#d+1]=u.." "..(issecretvalue(n)and"<secret>"or tostring(n)).." forbidden="..tostring(p.UnitFrame:IsForbidden())end print(#d)
  ```
- **Prueba de concepto con `/run`:** a lo que no es del addon sí se llega. Por ejemplo, esto pinta una calavera junto al nombre en todas las placas visibles (se guarda en `p.PTS` solo para la prueba):
  ```
  /run for _,p in ipairs(C_NamePlate.GetNamePlates())do local t=p.PTS or p:CreateTexture(nil,"OVERLAY")p.PTS=t t:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")t:SetSize(16,16)t:SetPoint("RIGHT",p.UnitFrame.name,"LEFT",-2,0)t:Show()end
  ```
