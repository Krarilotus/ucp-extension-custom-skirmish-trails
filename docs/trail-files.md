# Trail files

Trail settings files, mission files and language files were added in 1.4 by Monsterfish. The
JSON schemas are in `resources/`; the design note is `data-structure-and-localization.md`.

## Player names and the human player's lord
Optional csv columns, best placed at the end:
- `player1_name` to `player8_name`: the name a player has in this mission, in the briefing and in the game. Empty keeps the usual human or AI name.
- `player1_lord`: `Arab` or `Europ` gives the human player the Arabian or the European lord for this mission, and the starting troops of that lord. Empty keeps the player's own choice.
- `player1_skip_start_units`: `1` gives the human player no starting troops in this mission (the lord still comes). Empty or `0` keeps them.

## Scenario missions
The optional csv column `mission_kind` (`"mission_kind"` in a mission file) says how a mission starts:
- `skirmish` (or empty): as before, the trail sets up a skirmish on the map with the mission's players, teams, gold and goods.
- `scenario`: the mission's map is a custom scenario, for example an Invasion map made in the map editor or a saved game turned into a map. It starts the way Custom Scenarios → Play a Map starts it, so its events, goals, invasions, placed units and AI lords run as the map has them. For an Invasion map the game then shows its own briefing, as it does for Play a Map. Such a mission only needs `map_name`, `mission_name` and the 8 description lines of the trail's briefing; the other columns are not used. Other values of `mission_kind` are reported in the log, and such a mission doesn't start.
  - **The map** is looked up like any other map: in the game's `maps` folder, the Documents `Maps` folder, or an extra map folder a plugin registered with the files module. `map_name` is a file name without folders, with or without `.map`, of at most 200 bytes. Letters such as `ü` are fine (they are written in their Latin-1 form, as the files module reads them); letters outside Latin-1 are not. The map must exist and be a scenario map; the module doesn't check that.
  - **Difficulty and troops:** the engine difficulty stays Normal, as for Play a Map, and so does what Play a Map does at Normal: on a map without invasion events it removes part of the player's starting army (every 4th military unit, until about a quarter of their value is gone). `keep_start_army` `1` keeps the whole army for this mission (and its Restart); empty or `0` keeps the game's behaviour.
  - **Winning** counts for the trail as winning a skirmish mission does: the trail moves on and the trail map opens. A win counts when the map is the one of the trail's selected mission, also when the game was saved and loaded later, or started from Play a Map. Winning a map that is a mission of two trails counts for the trail that was open last. Only maps that end on the mission finished screen can be won this way (Invasion and siege maps); economic and build-only maps end with the game's quit dialog instead. The game also records the trail's months and its Skirmish Masters entry as for a skirmish mission; set the trail's `starting_year` no later than the scenarios' own years.
  - Restart and Quit in the game work as for a map started from Play a Map; Quit leads to Custom Scenarios.
  - **Dates:** a map with a date in an `availability.json` of the files module (files 1.5.0) can be started only from its date on. Until then the briefing shows the trail settings file's `trail_locked_text` (a language file can give its own), in which `{date}` becomes the date. Without that text the mission's own description is shown, and Start does nothing. With an older files module no map has a date.

A plugin can give a mission of a trail's mission data (csv or mission files) another map, for example the map in the language a player chose, from its `init.lua`: `modules["custom-skirmish-trails"]:setMissionMap("Warchest", 5, "Türchen05")` (trail `First`, `Warchest` or `Extreme`, the mission number, the map name). Call it while extensions are enabled; it applies when the trail's missions are loaded, and a mission the data doesn't have is reported in the log.

## Troop limits (`unit_limit`)
The game limits each player's troops: in Crusader to 2400 / living lords - 40, in Extreme to 9900 / living lords - 40, and not at all in custom scenarios. The optional column `unit_limit` (`"unit_limit"` in a mission file) sets the limit for this mission:
- `native`: the game's own limit (also when the column is empty);
- `formula BASE OFFSET`: BASE / living lords - OFFSET. `formula 2400 40` gives Crusader's limits in Extreme; in a scenario mission it gives a limit where the game has none.
- `by_alive LORDS=LIMIT ...`: a limit per number of living lords, for example `by_alive 8=250 4=500 2=1000 1=2000`; counts between two listed ones are interpolated (6 living lords: 375), counts outside them take the nearest listed limit.
- per difficulty: `story: native; normal: by_alive 8=400 4=800 1=3000; hard: formula 2400 40`, with `story`, `normal`, `hard`, `very_hard` and `default` (for every difficulty not named).

The limit is never higher than the game's own formula, so the unit pool can't fill up. It applies while the mission is played and follows the game state, so a saved and loaded game and a replay get the same limit; outside trail missions the game's own limit is used. The difficulty is the module setting `custom-skirmish-trails.difficulty` (`story`, `normal` (the default), `hard`, `very_hard`), which has no launcher control: a plugin, for example a difficulty preset, suggests it. The AI's troops are not limited by it.

## Trail settings file
Each trail can have a trail settings file (a .json file, set in the GUI) with everything about the trail. `resources/trail-settings.schema.json` describes it, and `resources/trails/template-*-settings.json` hold the game's own values. Every entry is optional:
- `trail_type`: `First`, `Warchest` or `Extreme`.
- `trail_missions`: the trail's mission data, see below.
- `trail_text_files`: the trail's language files, see below.
- `trail_title`, `trail_summary`: the texts under the trail's button in the skirmish menu. A summary wider than 540 pixels wraps into a second line; both texts then sit 10 pixels higher.
- `trail_locked_text`: the briefing of a scenario mission whose map isn't open yet (see Scenario missions); `{date}` becomes the date.
- `starting_year`: the year the first mission starts in.
- `trail_visuals`: `trail_button_idle` and `trail_button_highlighted` (pictures, for example .png, for the trail's button in the skirmish menu), and `trail_background` (the trail screen's background: a .tgx file, or a .png/.jpg/.bmp that the game turns into a .tgx once and keeps in `ucp/.cache`; use the size of the game's own file).
- `trail_mission_positions`: a list of `{ "x": .., "y": .. }` points on the 800 x 600 trail screen, one per mission. Their number is the trail's number of missions (at most 50 for the first trail, 30 for the Warchest and the Extreme trail).
- `ai_character_mapping`: your own names for the AI keys (`"SK_RICHARD": "Robert"`). Mission files use them, and the csv file may use them in player1 to player8.

Relative paths in the file are taken from the file's own folder.

## Mission data: csv file and mission files
`"trail_missions": { "base_name": "missions/my_trail", "data_mode": "csv" }` names both the csv file (`missions/my_trail.csv`) and a folder of mission files (`missions/my_trail/my_trail_mission_01.json`, ...). A mission file (format 1, `resources/mission.schema.json`) holds the same data as one csv line, laid out for reading and editing:
- `mission_name` and `text_description` (a list of the 8 lines) at the top;
- `advantage` (`human_large`, `human_small`, `neutral`, `ai_small`, `ai_large`; the csv's fairness 1-5) and `start_mode` (`normal`, `crusader`, `deathmatch`; the csv's start_levels 1-3). Numbers work too;
- `players`: one entry per player, so their number is the mission's number of players. `players[0]` is the human player: it may have `lord` and `skip_start_units`, never `ai`. The others always have `ai`, never `lord`. All have `name`, `start_position`, `team`, `aiv_type` and `gold` as needed;
- `producible`, `recruitable`, `resources`, `tradeable`: the csv's prefixed columns as objects;
- `extra`: any csv value that has no place above, so that nothing gets lost.

`data_mode` says which one is the ground truth. It is applied at every game start:
- `csv`: the game loads the csv file and writes the mission files from it.
- `json_folder`: the game writes the csv file from the mission files, then loads it.
- `automatic`: per mission, whichever was edited last wins: newer mission files go into the csv, newer csv lines into the mission files.

Before files are changed, the previous csv is kept as `<csv>.bak` and the previous mission files in `<folder>/.bak` (one previous version each). When no file changed since the last start, nothing is read or written. Without a trail settings file, the csv file set in the GUI is used as before.

## Language files
The mission data holds one set of texts, the default language. Each further language is one small JSON file with only its texts: `"trail_text_files": "texts/"` points to a folder with `english.json`, `german.json` and so on (or give an object of languages to files). A language file:

```json
{
  "trail_title": "Der Kreuzzug",
  "trail_summary": "...",
  "trail_locked_text": "...",
  "missions": {
    "1": { "mission_name": "Die Küste", "text_description_line_01": "...", "player2_name": "..." }
  }
}
```

Missions are found by their number. A text a language file does not have shows the mission data's text; strict mode lists those. With `trail_missions`, `texts/_template.json` is written with all texts of the mission data, as a starting point for translators.

## File paths
Each trail's "File paths" panel lists the files set for it and clears them (the GUI's own reset only works right after a path was set).

## Strict mode
Miscellaneous: logs every problem in the csv, mission, language and trail settings files, every trail setting that falls back to the game's own value, and every text a language file lacks. Without it, one warning per file with problems.

## Export and Import CSV Data
Each trail's "CSV data" panel in the GUI has an Export and an Import button, for converting by hand (`trail_missions` does it at every start on its own). Export writes every csv line into a mission file, Import puts the mission files back together into the csv file. The GUI cannot write files itself, so a button records the request and the game carries it out at its next start; the panel then shows what was done.
