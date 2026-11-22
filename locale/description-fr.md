# Custom Skirmish Trails

**1.4.1**

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

## Nouveautés de la 1.4 (par Monsterfish)

### Noms des joueurs et seigneur du joueur humain
Colonnes CSV optionnelles, de préférence placées à la fin :
- `player1_name` à `player8_name` : le nom qu'un joueur porte dans cette mission, dans le briefing et en jeu. Vide conserve le nom habituel du joueur ou de l'IA.
- `player1_lord` : `Arab` ou `Europ` donne au joueur humain le seigneur arabe ou européen pour cette mission, avec les troupes de départ correspondantes. Vide conserve le choix du joueur.
- `player1_skip_start_units` : `1` ne donne aucune troupe de départ au joueur humain dans cette mission (le seigneur apparaît toujours). Vide ou `0` les conserve.

### Fichier de paramètres de piste
Chaque piste peut disposer d'un fichier de paramètres de piste (un fichier `.json` défini dans l'interface) regroupant toutes ses données. `resources/trail-settings.schema.json` le décrit et `resources/trails/template-*-settings.json` contiennent les valeurs d'origine du jeu. Chaque entrée est facultative :
- `trail_type` : `First`, `Warchest` ou `Extreme`.
- `trail_missions` : les données de missions de la piste, voir ci-dessous.
- `trail_text_files` : les fichiers de langue de la piste, voir ci-dessous.
- `trail_title`, `trail_summary` : les textes affichés sous le bouton de la piste dans le menu d'escarmouche. Un résumé de plus de 540 pixels passe sur une deuxième ligne ; les deux textes remontent alors de 10 pixels.
- `starting_year` : l'année de départ de la première mission.
- `trail_visuals` : `trail_button_idle` et `trail_button_highlighted` (images, par exemple `.png`, pour le bouton de la piste dans le menu d'escarmouche), ainsi que `trail_background` (l'arrière-plan de l'écran de piste : un fichier `.tgx`, ou un `.png`/`.jpg`/`.bmp` que le jeu convertit une fois en `.tgx` et conserve dans `ucp/.cache` ; utilisez les dimensions du fichier du jeu).
- `trail_mission_positions` : une liste de points `{ "x": .., "y": .. }` sur l'écran de piste 800 × 600, un par mission. Leur nombre définit le nombre de missions de la piste (au maximum 50 pour la première piste, 30 pour Warchest et Extreme).
- `ai_character_mapping` : vos propres noms pour les clés d'IA (`"SK_RICHARD": "Robert"`). Les fichiers de mission les utilisent, et le fichier CSV peut les employer dans `player1` à `player8`.

Les chemins relatifs dans le fichier sont résolus à partir du dossier de ce fichier.

### Données de missions : fichier CSV et fichiers de mission
`"trail_missions": { "base_name": "missions/my_trail", "data_mode": "csv" }` désigne à la fois le fichier CSV (`missions/my_trail.csv`) et un dossier de fichiers de mission (`missions/my_trail/my_trail_mission_01.json`, …). Un fichier de mission (format 1, `resources/mission.schema.json`) contient les mêmes données qu'une ligne CSV, structurées pour être lues et modifiées facilement :
- `mission_name` et `text_description` (une liste des 8 lignes) en haut ;
- `advantage` (`human_large`, `human_small`, `neutral`, `ai_small`, `ai_large` ; équivalent de `fairness` 1–5 dans le CSV) et `start_mode` (`normal`, `crusader`, `deathmatch` ; équivalent de `start_levels` 1–3). Les nombres fonctionnent aussi ;
- `players` : une entrée par joueur, leur nombre déterminant le nombre de joueurs de la mission. `players[0]` est le joueur humain : il peut avoir `lord` et `skip_start_units`, jamais `ai`. Les autres ont toujours `ai`, jamais `lord`. Tous peuvent inclure `name`, `start_position`, `team`, `aiv_type` et `gold` selon les besoins ;
- `producible`, `recruitable`, `resources`, `tradeable` : les colonnes préfixées du CSV sous forme d'objets ;
- `extra` : toute valeur CSV sans emplacement ci-dessus, afin que rien ne soit perdu.

`data_mode` indique quelle source fait foi et s'applique à chaque lancement du jeu :
- `csv` : le jeu charge le fichier CSV et génère les fichiers de mission à partir de celui-ci.
- `json_folder` : le jeu génère le fichier CSV à partir des fichiers de mission, puis le charge.
- `automatic` : pour chaque mission, le fichier modifié le plus récemment l'emporte : les fichiers de mission plus récents mettent à jour le CSV, les lignes CSV plus récentes mettent à jour les fichiers de mission.

Avant toute modification, le CSV précédent est sauvegardé en `<csv>.bak` et les fichiers de mission précédents dans `<dossier>/.bak` (une version précédente chacun). Si aucun fichier n'a changé depuis le dernier lancement, rien n'est lu ni écrit. Sans fichier de paramètres de piste, le fichier CSV défini dans l'interface est utilisé comme auparavant.

### Fichiers de langue
Les données de missions contiennent un jeu de textes, la langue par défaut. Chaque langue supplémentaire est un petit fichier JSON ne contenant que ses textes : `"trail_text_files": "texts/"` pointe vers un dossier contenant `english.json`, `german.json`, etc. (ou un objet associant des langues à des fichiers). Exemple :

```json
{
  "trail_title": "Der Kreuzzug",
  "trail_summary": "...",
  "missions": {
    "1": { "mission_name": "Die Küste", "text_description_line_01": "...", "player2_name": "..." }
  }
}
```

Les missions sont repérées par leur numéro. Un texte absent d'un fichier de langue affiche le texte des données de missions ; le mode strict dresse la liste de ces manques. Avec `trail_missions`, `texts/_template.json` est généré avec tous les textes des données de missions comme base pour les traducteurs.

### Chemins de fichiers
Le panneau « Chemins de fichiers » de chaque piste liste les fichiers définis pour celle-ci et permet de les effacer (la réinitialisation native de l'interface ne fonctionne que juste après avoir défini un chemin).

### Mode strict
Divers : consigne chaque problème dans les fichiers CSV, de mission, de langue et de paramètres de piste, chaque paramètre qui revient à la valeur par défaut du jeu, et chaque texte absent d'un fichier de langue. Sans cette option, un seul avertissement est affiché par fichier défectueux.

### Exporter et importer des données CSV
Le panneau « Données CSV » de chaque piste dans l'interface propose un bouton Exporter et un bouton Importer pour convertir manuellement (`trail_missions` le fait automatiquement à chaque lancement). Exporter écrit chaque ligne CSV dans un fichier de mission ; Importer rassemble les fichiers de mission dans le fichier CSV. Comme l'interface ne peut pas écrire de fichiers elle-même, un clic enregistre la demande et le jeu l'exécute au prochain démarrage ; le panneau indique ensuite ce qui a été effectué.

## Soutien
Tout soutien est le bienvenu !

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Si vous utilisez PayPal :
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
