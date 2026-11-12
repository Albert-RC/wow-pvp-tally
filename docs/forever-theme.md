# Tema "Forever" (en pausa)

Idea: que el usuario elija en Opciones entre dos estilos para la ventana de PvP Tally.

- **Classic:** el aspecto actual.
- **Forever:** el aspecto de la ventana de Habilidades del juego.

Se hizo un primer prototipo (v1) y **se retiró del addon** para rediseñarlo con más detalle. Este documento recoge el diseño, lo que se aprendió al probarlo y cómo recuperarlo. La investigación del cliente en la que se basa está en [forever-client-ui.md](forever-client-ui.md).

## Prototipo v1

El código completo está archivado en [`archive/forever-theme-v1/`](archive/forever-theme-v1/). Es una copia de los archivos que se tocaron, tal como estaban; el juego no carga esa carpeta. Para recuperarlo, compara cada archivo con su versión actual y trae los cambios: el resto del addon ha seguido avanzando.

### Distribución elegida (opción A)
- Cada jugador es una **cabecera de categoría**: caja dorada `common-button-list-collapseExpand` con `common-button-list-plus` / `-minus` a la derecha.
- Sus enfrentamientos van debajo, como las habilidades bajo "Profesiones".
- Se descartó, por ahora, la opción B: agrupar por bando con un panel de detalle a la derecha como el de Habilidades. Si se retoma, necesita una ventana más ancha (unos 900 px).

### Piezas

| Parte | Classic | Forever (v1) |
| --- | --- | --- |
| Fondo de la lista | *Inset* gris | `UI-Character-Info-General-BG` (ocultando `Inset.Bg` e `Inset.NineSlice`) |
| Bordes de la lista | — | `UI-Character-Info-ScrollLine-Long` arriba y abajo (la de abajo girada 180°), en un frame por encima del ScrollBox |
| Cabeceras de columna | Pestañas de la lista de Quién | Títulos dorados sobre una franja `ScrollLine-Long` |
| Jugador | Fila a rayas, +/- clásico a la izquierda | Caja dorada, `+`/`−` en una columna propia a la derecha |
| Kills / Deaths | Dos columnas de números | Una columna con barra: fondo `common-stat-bar-BG`, rojo (deaths) debajo y verde (kills) encima con ancho proporcional, máscara `common-stat-bar-Mask` y texto "3 / 1". Se podía ordenar por la proporción de kills |
| Resaltado | `UI-QuestTitleHighlight` (ADD, 0,6) | `linemouseover-side` + `-middle` en tres piezas, al 20 % de opacidad |
| Enfrentamientos | Banda oscura | Sin banda |

### Arquitectura
- **`Core/Settings.lua`:**
  - opción `theme` (`"classic"` por defecto) validada;
  - `Settings.Set(saved, key, value, bus)` con validadores, que lanzaba el evento `SETTINGS_CHANGED`.
- **`UI/Themes.lua`:**
  - definición pura de cada estilo (`Themes.DEFINITIONS`);
  - `Themes.Resolve(name, atlasExists)`: si falta un atlas, esa pieza se dibuja como en Classic.
- **`UI/Columns.lua`:** un juego de columnas por estilo (`Columns.SETS`), los dos sumando `LIST_WIDTH`.
- **`UI/Rows.lua`:** cada fila tenía las piezas de los dos estilos, mostraba las del actual y ocultaba el resto.
- **`UI/Window.lua`:** `ApplyTheme()` para las cabeceras (una tanda por estilo), el fondo y los bordes; el cambio de estilo era en caliente.
- **`UI/SettingsPanel.lua`:** desplegable "Estilo" (`WowStyle1DropdownTemplate` + `SetupMenu` + `CreateRadio`).
- **Tests:** `themes_spec.lua`, más casos en `columns_spec`, `list_model_spec`, `settings_spec`, `settings_panel_spec` y `addon_spec` (sección "styles").

## Lo que se vio al probarlo en el juego

1. **Error al abrir la ventana** (`Window.lua:149: attempt to index local 'header'`). `GetWidth()` disparó `OnSizeChanged` a mitad de `ApplyTheme`, con el tema nuevo puesto y las cabeceras aún sin crear. Solo pasaba con la ventana guardada más ancha que el mínimo. Se arregló leyendo el ancho antes y bloqueando `OnSizeChanged` durante el cambio. Ver [forever-client-ui.md](forever-client-ui.md).
2. **Fila blanca al pasar el ratón:** el atlas del resaltado es blanco. Se bajó al 20 % de opacidad.
3. **Lo que sí se veía bien:** las cajas doradas, la barra verde y roja con el texto, los iconos de raza y clase.

## Pendiente para la próxima versión

- Medir en el juego, comparando con Habilidades:
  - el alto de la barra (se usaron 16 px);
  - el ancho de los extremos del resaltado (16 px);
  - el tamaño del `+`/`−` (18 px);
  - el alto real de la caja dorada y de las líneas `ScrollLine-Long`.
- Decidir si las cabeceras de columna tienen sentido en Forever: Habilidades no tiene.
- Decidir la distribución definitiva (A o B, panel de detalle sí o no).
- Revisar la opacidad del resaltado frente a la fila seleccionada de Habilidades.
- Valorar un estado de "fila seleccionada", que en Habilidades existe.
