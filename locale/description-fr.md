# Custom Skirmish Trails

Cette extension permet de créer des pistes d'escarmouche personnalisées, définies dans des fichiers `.csv`.

## Possibilités
L'archive ZIP de cette extension contient un fichier `template.csv` qui décrit tout ce qu'il est possible de modifier.

Vous pouvez également télécharger la première piste [ici](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-First-Edition-Trail.csv), la piste Warchest [ici](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Warchest-Trail.csv) et la piste Extreme [ici](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Extreme-Trail.csv).

Un éditeur en ligne pratique est disponible ici : https://edit-csv.net/

Voici la liste des colonnes :
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
- text_dexcription_line_01 - 08 : Utilisez `""` pour écrire le texte affiché dans le menu de lancement de la mission d'escarmouche
- trade_ : Utilisez par ex. `trade_spear` (au singulier !) pour activer ou désactiver le commerce de cette marchandise

## Paramètres de piste, fichiers de mission et langues

Chaque piste peut disposer d'un fichier de paramètres de piste, défini dans l'interface, avec son titre, son résumé, son année de départ, ses images, ses positions de missions, ses noms d'IA, ses données de missions et ses fichiers de langue. Les missions peuvent aussi être conservées dans un fichier JSON chacune, et chaque langue dans un petit fichier JSON contenant uniquement ses textes. Des colonnes CSV optionnelles définissent des noms de joueurs propres à chaque mission et le seigneur du joueur humain. Les formats sont décrits dans [docs/trail-files.md](https://github.com/gynt/ucp-extension-custom-skirmish-trails/blob/main/docs/trail-files.md).

## Soutien
Tout soutien est le bienvenu !

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Si vous utilisez PayPal :
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
