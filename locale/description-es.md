# Custom Skirmish Trails

**1.4.1**

Esta extensión permite crear sendas de escaramuza personalizadas, definidas en archivos `.csv`.

## Posibilidades
El archivo ZIP de esta extensión contiene un archivo `template.csv` que describe todo lo que se puede modificar.

También puedes descargar la primera senda [aquí](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-First-Edition-Trail.csv), la senda Warchest [aquí](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Warchest-Trail.csv) y la senda Extreme [aquí](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Extreme-Trail.csv).

Puedes encontrar un editor en línea sencillo aquí: https://edit-csv.net/

Aquí tienes la lista de columnas:
- map_name
- fairness
- start_levels
- num_players
- player1
- player2
- player3
- player4
- player5
- player6
- player7
- player8
- start_position1
- start_position2
- start_position3
- start_position4
- start_position5
- start_position6
- start_position7
- start_position8
- team1
- team2
- team3
- team4
- team5
- team6
- team7
- team8
- aiv_type1
- aiv_type2
- aiv_type3
- aiv_type4
- aiv_type5
- aiv_type6
- aiv_type7
- aiv_type8
- mission_name
- gold
- producible_bows
- producible_crossbows
- producible_maces
- producible_pikes
- producible_spears
- producible_swords
- recruitable_archers
- recruitable_spearmen
- recruitable_macemen
- recruitable_crossbowmen
- recruitable_pikemen
- recruitable_swordsmen
- recruitable_knights
- recruitable_arabian_bows
- recruitable_slaves
- recruitable_slingers
- recruitable_assassins
- recruitable_horse_archers
- recruitable_arabian_swordsmen
- recruitable_fire_throwers
- resource_wood
- resource_hops
- resource_stone
- resource_iron
- resource_pitch
- resource_wheat
- resource_bread
- resource_cheese
- resource_meat
- resource_apple
- resource_ale
- resource_gold
- resource_flour
- resource_bow
- resource_crossbow
- resource_spear
- resource_pike
- resource_mace
- resource_sword
- resource_leatherarmor
- resource_ironarmor
- text_dexcription_line_01 - 08: Usa `""` para escribir el texto que se muestra en el menú inicial de la misión de escaramuza
- trade_: Usa por ejemplo `trade_spear` (¡en singular!) para activar o desactivar el comercio de ese bien

## Novedades en 1.4 (de Monsterfish)

### Nombres de jugadores y Señor del jugador humano
Columnas CSV opcionales, mejor situadas al final:
- `player1_name` a `player8_name`: el nombre que tiene un jugador en esta misión, tanto en el informe previo como en la partida. Si se deja vacío, se conserva el nombre habitual del jugador o de la IA.
- `player1_lord`: `Arab` o `Europ` otorga al jugador humano el Señor árabe o europeo en esta misión, junto con sus tropas iniciales. Vacío mantiene la elección del jugador.
- `player1_skip_start_units`: `1` hace que el jugador humano no reciba tropas iniciales en esta misión (el Señor sigue apareciendo). Vacío o `0` las conserva.

### Archivo de ajustes de la senda
Cada senda puede tener un archivo de ajustes (un archivo `.json`, configurado en la interfaz) con todo lo relativo a la senda. `resources/trail-settings.schema.json` lo describe y `resources/trails/template-*-settings.json` guardan los valores originales del juego. Cada entrada es opcional:
- `trail_type`: `First`, `Warchest` o `Extreme`.
- `trail_missions`: los datos de misiones de la senda, véase abajo.
- `trail_text_files`: los archivos de idioma de la senda, véase abajo.
- `trail_title`, `trail_summary`: los textos debajo del botón de la senda en el menú de escaramuza. Un resumen de más de 540 píxeles pasa a una segunda línea; ambos textos suben entonces 10 píxeles.
- `starting_year`: el año en que comienza la primera misión.
- `trail_visuals`: `trail_button_idle` y `trail_button_highlighted` (imágenes, por ejemplo `.png`, para el botón de la senda en el menú de escaramuza), y `trail_background` (el fondo de la pantalla de la senda: un archivo `.tgx`, o un `.png`/`.jpg`/`.bmp` que el juego convierte una vez a `.tgx` y guarda en `ucp/.cache`; usa las dimensiones del archivo del juego).
- `trail_mission_positions`: una lista de puntos `{ "x": .., "y": .. }` en la pantalla de senda de 800 × 600, uno por misión. Su cantidad define el número de misiones de la senda (como máximo 50 para la primera senda y 30 para Warchest y Extreme).
- `ai_character_mapping`: tus propios nombres para las claves de la IA (`"SK_RICHARD": "Robert"`). Los archivos de misión los usan, y el archivo CSV puede usarlos en `player1` a `player8`.

Las rutas relativas del archivo se resuelven desde la carpeta del propio archivo.

### Datos de misiones: archivo CSV y archivos de misión
`"trail_missions": { "base_name": "missions/my_trail", "data_mode": "csv" }` nombra tanto el archivo CSV (`missions/my_trail.csv`) como una carpeta de archivos de misión (`missions/my_trail/my_trail_mission_01.json`, …). Un archivo de misión (formato 1, `resources/mission.schema.json`) contiene los mismos datos que una línea del CSV, organizados para leerse y editarse con facilidad:
- `mission_name` y `text_description` (una lista de las 8 líneas) al principio;
- `advantage` (`human_large`, `human_small`, `neutral`, `ai_small`, `ai_large`; equivalente a `fairness` 1–5 del CSV) y `start_mode` (`normal`, `crusader`, `deathmatch`; equivalente a `start_levels` 1–3). Los números también sirven;
- `players`: una entrada por jugador, de modo que su cantidad es el número de jugadores de la misión. `players[0]` es el jugador humano: puede tener `lord` y `skip_start_units`, nunca `ai`. Los demás siempre tienen `ai`, nunca `lord`. Todos pueden llevar `name`, `start_position`, `team`, `aiv_type` y `gold` según haga falta;
- `producible`, `recruitable`, `resources`, `tradeable`: las columnas con prefijo del CSV agrupadas en objetos;
- `extra`: cualquier valor del CSV sin hueco arriba, para que no se pierda nada.

`data_mode` decide cuál es la fuente principal y se aplica en cada inicio del juego:
- `csv`: el juego carga el archivo CSV y genera los archivos de misión a partir de él.
- `json_folder`: el juego genera el archivo CSV a partir de los archivos de misión y luego lo carga.
- `automatic`: en cada misión gana lo editado más recientemente: los archivos de misión más nuevos se vuelcan al CSV y las líneas CSV más nuevas a los archivos de misión.

Antes de modificar archivos, el CSV anterior se guarda como `<csv>.bak` y los archivos de misión anteriores en `<carpeta>/.bak` (una versión previa de cada uno). Si ningún archivo ha cambiado desde el último inicio, no se lee ni se escribe nada. Sin archivo de ajustes de la senda se usa el archivo CSV configurado en la interfaz, como antes.

### Archivos de idioma
Los datos de misión guardan un conjunto de textos, el idioma predeterminado. Cada idioma adicional es un pequeño archivo JSON solo con sus textos: `"trail_text_files": "texts/"` apunta a una carpeta con `english.json`, `german.json`, etc. (o bien un objeto que asocie idiomas a archivos). Ejemplo de archivo de idioma:

```json
{
  "trail_title": "Der Kreuzzug",
  "trail_summary": "...",
  "missions": {
    "1": { "mission_name": "Die Küste", "text_description_line_01": "...", "player2_name": "..." }
  }
}
```

Las misiones se identifican por su número. Si falta un texto en un archivo de idioma, se muestra el texto de los datos de misión; el modo estricto enumera esas ausencias. Con `trail_missions` se genera `texts/_template.json` con todos los textos de las misiones como punto de partida para traductores.

### Rutas de archivos
El panel «Rutas de archivos» de cada senda muestra los archivos configurados para ella y permite borrarlos (el restablecimiento propio de la interfaz solo funciona justo después de fijar una ruta).

### Modo estricto
Varios: registra cada problema en los archivos CSV, de misión, de idioma y de ajustes de la senda, cada ajuste que vuelve al valor propio del juego y cada texto que falta en un archivo de idioma. Sin él, se muestra una única advertencia por archivo con problemas.

### Exportar e importar datos CSV
El panel «Datos CSV» de cada senda en la interfaz incluye botones de Exportar e Importar para convertir manualmente (`trail_missions` lo hace solo en cada inicio). Exportar escribe cada línea CSV en un archivo de misión; Importar vuelve a unir los archivos de misión en el archivo CSV. Como la interfaz no puede escribir archivos directamente, pulsar un botón guarda la solicitud y el juego la ejecuta en el siguiente inicio; el panel muestra después lo que se hizo.

## Apoyo
¡Cualquier apoyo es bienvenido!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Si tienes PayPal:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
