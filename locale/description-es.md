# Custom Skirmish Trails

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

## Ajustes de la senda, archivos de misión e idiomas

Cada senda puede tener un archivo de ajustes de la senda, configurado en la interfaz, con su título, resumen, año de inicio, imágenes, posiciones de misiones, nombres de la IA, datos de misiones y archivos de idioma. Las misiones también pueden guardarse como un archivo JSON por misión, y cada idioma como un pequeño archivo JSON solo con sus textos. Las columnas CSV opcionales definen nombres de jugadores específicos por misión y el Señor del jugador humano. Los formatos se describen en [docs/trail-files.md](https://github.com/gynt/ucp-extension-custom-skirmish-trails/blob/main/docs/trail-files.md).

## Apoyo
¡Cualquier apoyo es bienvenido!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Si tienes PayPal:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
