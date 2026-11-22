# Custom Skirmish Trails

Diese Erweiterung ermöglicht eigene Kreuzzugsmärsche, die in `.csv`-Dateien definiert werden.

## Möglichkeiten
Die ZIP-Datei dieser Erweiterung enthält eine `template.csv`-Datei, die beschreibt, was angepasst werden kann.

Du kannst auch den ersten Marsch [hier](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-First-Edition-Trail.csv), den Warchest-Marsch [hier](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Warchest-Trail.csv) und den Extreme-Marsch [hier](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Extreme-Trail.csv) herunterladen.

Ein einfacher Online-Editor findet sich hier: https://edit-csv.net/

Hier die Liste der Spalten:
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
- text_dexcription_line_01 - 08: Verwende `""`, um Text für das Startmenü der Gefechtsmission einzutragen
- trade_: Verwende z. B. `trade_spear` (Einzahl!), um den Handel mit dieser Ware ein- oder auszuschalten

## Marsch-Einstellungsdatei, Missionsdateien und Sprachen

Jeder Marsch kann eine in der GUI eingestellte Marsch-Einstellungsdatei haben – mit Titel, Kurzbeschreibung, Startjahr, Bildern, Missionspositionen, KI-Namen, Missionsdaten und Sprachdateien. Missionen lassen sich auch als je eine JSON-Datei speichern, und jede Sprache als kleine JSON-Datei mit nur ihren Texten. Optionale CSV-Spalten legen missionsspezifische Spielernamen und den Lord des menschlichen Spielers fest. Die Formate sind in [docs/trail-files.md](https://github.com/gynt/ucp-extension-custom-skirmish-trails/blob/main/docs/trail-files.md) beschrieben.

## Unterstützung
Jede Unterstützung ist willkommen!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Falls du PayPal nutzt:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
