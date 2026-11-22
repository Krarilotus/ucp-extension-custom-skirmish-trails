# Custom Skirmish Trails

**1.4.1**

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

## Újdonságok az 1.4-ben (Monsterfish munkája)

### Játékosnevek és az emberi játékos lordja
Opcionális CSV-oszlopok, célszerűen a végére helyezve:
- `player1_name` – `player8_name`: az adott játékos neve ebben a küldetésben, az eligazításon és a játékban. Üresen hagyva marad a szokásos emberi vagy MI-név.
- `player1_lord`: az `Arab` vagy `Europ` érték az arab vagy az európai lordot adja az emberi játékosnak ebben a küldetésben, a hozzá tartozó kezdőcsapatokkal együtt. Üresen marad a játékos saját választása.
- `player1_skip_start_units`: az `1` érték elveszi az emberi játékos kezdőcsapatait ebben a küldetésben (a lord továbbra is megjelenik). Üresen vagy `0` esetén megmaradnak.

### Hadjárat beállításfájl
Minden hadjárathoz tartozhat egy beállításfájl (egy `.json` fájl, a felületen megadva), amely a hadjárat minden adatát tartalmazza. A `resources/trail-settings.schema.json` írja le a formátumát, a `resources/trails/template-*-settings.json` fájlok pedig a játék saját értékeit tartalmazzák. Minden bejegyzés opcionális:
- `trail_type`: `First`, `Warchest` vagy `Extreme`.
- `trail_missions`: a hadjárat küldetésadatai, lásd alább.
- `trail_text_files`: a hadjárat nyelvi fájljai, lásd alább.
- `trail_title`, `trail_summary`: a hadjárat gombja alatt megjelenő szövegek a csetepaté menüben. Az 540 pixelnél szélesebb összefoglaló második sorba törik; ilyenkor mindkét szöveg 10 pixellel feljebb kerül.
- `starting_year`: az évszám, amelyben az első küldetés kezdődik.
- `trail_visuals`: `trail_button_idle` és `trail_button_highlighted` (képek, például `.png`, a hadjárat gombjához a csetepaté menüben), valamint `trail_background` (a hadjárat-képernyő háttere: `.tgx` fájl, vagy `.png`/`.jpg`/`.bmp`, amelyet a játék egyszer átalakít `.tgx` formátumra és a `ucp/.cache` mappában tárol; használd a játék saját fájljának méretét).
- `trail_mission_positions`: `{ "x": .., "y": .. }` pontok listája a 800 × 600-as hadjárat-képernyőn, küldetésenként egy. A számuk határozza meg a hadjárat küldetéseinek számát (legfeljebb 50 az első hadjáratnál, 30 a Warchest és Extreme hadjáratnál).
- `ai_character_mapping`: saját nevek az MI-kulcsokhoz (`"SK_RICHARD": "Robert"`). A küldetésfájlok ezeket használják, és a CSV-fájlban is használhatók a `player1`–`player8` oszlopokban.

A fájlban szereplő relatív útvonalak a fájl saját mappájához viszonyítva értendők.

### Küldetésadatok: CSV-fájl és küldetésfájlok
A `"trail_missions": { "base_name": "missions/my_trail", "data_mode": "csv" }` egyszerre nevezi meg a CSV-fájlt (`missions/my_trail.csv`) és a küldetésfájlok mappáját (`missions/my_trail/my_trail_mission_01.json`, …). Egy küldetésfájl (1-es formátum, `resources/mission.schema.json`) ugyanazokat az adatokat tárolja, mint egy CSV-sor, olvasásra és szerkesztésre áttekinthetően elrendezve:
- `mission_name` és `text_description` (a 8 sor listája) legfelül;
- `advantage` (`human_large`, `human_small`, `neutral`, `ai_small`, `ai_large`; a CSV `fairness` 1–5 értéke) és `start_mode` (`normal`, `crusader`, `deathmatch`; a CSV `start_levels` 1–3 értéke). Számok is működnek;
- `players`: játékosonként egy bejegyzés, így a számuk adja meg a küldetés játékosszámát. A `players[0]` az emberi játékos: lehet benne `lord` és `skip_start_units`, de sosem `ai`. A többiben mindig van `ai`, és sosem `lord`. Mindegyik tartalmazhat `name`, `start_position`, `team`, `aiv_type` és `gold` mezőt igény szerint;
- `producible`, `recruitable`, `resources`, `tradeable`: a CSV előtagos oszlopai objektumokként;
- `extra`: minden olyan CSV-érték, amelynek nincs külön helye fent, hogy semmi ne vesszen el.

A `data_mode` mondja meg, melyik a mérvadó forrás, és minden játékinduláskor lefut:
- `csv`: a játék betölti a CSV-fájlt, és abból írja ki a küldetésfájlokat.
- `json_folder`: a játék a küldetésfájlokból írja meg a CSV-fájlt, majd betölti azt.
- `automatic`: küldetésenként a legutóbb szerkesztett változat nyer – az újabb küldetésfájlok bekerülnek a CSV-be, az újabb CSV-sorok pedig a küldetésfájlokba.

A fájlok módosítása előtt az előző CSV `<csv>.bak`, az előző küldetésfájlok pedig `<mappa>/.bak` alatt megőrzésre kerülnek (egy-egy korábbi verzió). Ha az utolsó indítás óta nem változott fájl, nem történik olvasás vagy írás. Beállításfájl nélkül a felületen megadott CSV-fájl használatos, mint korábban.

### Nyelvi fájlok
A küldetésadatok egy szövegkészletet tartalmaznak, az alapértelmezett nyelvet. Minden további nyelv egy kis JSON-fájl, amely csak a saját szövegeit tárolja: a `"trail_text_files": "texts/"` egy `english.json`, `german.json` stb. fájlokat tartalmazó mappára mutat (vagy megadható egy nyelveket fájlokhoz rendelő objektum is). Egy nyelvi fájl felépítése:

```json
{
  "trail_title": "Der Kreuzzug",
  "trail_summary": "...",
  "missions": {
    "1": { "mission_name": "Die Küste", "text_description_line_01": "...", "player2_name": "..." }
  }
}
```

A küldetéseket a sorszámuk alapján azonosítja. A nyelvi fájlból hiányzó szövegek helyén a küldetésadatok szövege jelenik meg; a szigorú mód ezeket felsorolja. A `trail_missions` használatakor létrejön a `texts/_template.json` fájl a küldetésadatok összes szövegével, kiindulási alapként fordítók számára.

### Fájlútvonalak
Minden hadjárat „Fájlútvonalak” panelje felsorolja a hozzá beállított fájlokat és törli azokat (a felület saját visszaállítása csak közvetlenül egy útvonal beállítása után működik).

### Szigorú mód
Egyéb: naplóz minden hibát a CSV-, küldetés-, nyelvi és beállításfájlokban, minden alapértelmezésre visszaeső beállítást, valamint minden nyelvi fájlból hiányzó szöveget. Enélkül fájlonként egy figyelmeztetés jelenik meg.

### CSV-adatok exportálása és importálása
Minden hadjárat „CSV-adatok” paneljén a felületen található egy Export és egy Import gomb kézi átalakításhoz (a `trail_missions` ezt minden induláskor magától elvégzi). Az Export minden CSV-sort egy küldetésfájlba ír, az Import pedig visszaállítja a küldetésfájlokból a CSV-fájlt. Mivel a felület önmagában nem tud fájlokat írni, a gomb rögzíti a kérést, a játék pedig a következő indításkor végrehajtja; a panel ezután megmutatja az eredményt.

## Támogatás
Minden támogatást szívesen fogadunk!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Ha PayPalt használsz:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
