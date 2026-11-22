# Custom Skirmish Trails

Ez a bővítmény lehetővé teszi egyéni csetepaté-hadjáratok készítését `.csv` fájlokban.

## Lehetőségek
A bővítmény ZIP-fájlja tartalmaz egy `template.csv` fájlt, amely bemutatja, mi minden módosítható.

Az első hadjárat letölthető [innen](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-First-Edition-Trail.csv), a Warchest [innen](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Warchest-Trail.csv), az Extreme hadjárat pedig [innen](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Extreme-Trail.csv).

Egy egyszerű online szerkesztő itt található: https://edit-csv.net/

Az oszlopok listája:
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
- text_dexcription_line_01 - 08: Használj `""` idézőjeleket a csetepaté-küldetés indítómenüjében megjelenő szöveghez
- trade_: Használd pl. a `trade_spear` formát (egyes számban!) az adott áru kereskedelmének be- vagy kikapcsolásához

## Hadjárat-beállítások, küldetésfájlok és nyelvek

Minden hadjárathoz tartozhat a felületen megadott hadjárat beállításfájl, amely tartalmazza a címét, összefoglalóját, kezdő évét, képeit, küldetéspozícióit, MI-neveit, küldetésadatait és nyelvi fájljait. A küldetések külön-külön egy-egy JSON-fájlban is tárolhatók, és minden nyelv egy kis JSON-fájlban, amely csak a saját szövegeit tartalmazza. Opcionális CSV-oszlopokkal küldetésenkénti játékosnevek és az emberi játékos lordja adható meg. A formátumok leírása a [docs/trail-files.md](https://github.com/gynt/ucp-extension-custom-skirmish-trails/blob/main/docs/trail-files.md) fájlban található.

## Támogatás
Minden támogatást szívesen fogadunk!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Ha PayPalt használsz:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
