# Trail files

Trail settings files, mission files and language files were added in 1.4 by Monsterfish. The
JSON schemas are in `resources/`; the design note is `data-structure-and-localization.md`.

## Player names and the human player's lord
Optional csv columns, best placed at the end:
- `player1_name` to `player8_name`: the name a player has in this mission, in the briefing and in the game. Empty keeps the usual human or AI name.
- `player1_lord`: `Arab` or `Europ` gives the human player the Arabian or the European lord for this mission, and the starting troops of that lord. Empty keeps the player's own choice.
- `player1_skip_start_units`: `1` gives the human player no starting troops in this mission (the lord still comes). Empty or `0` keeps them.

## Start gold
`gold_player_1` (the human player) to `gold_player_8` (`gold` of a player in a mission file) set a player's start gold in this mission; `0` is no gold. Empty keeps the game's start gold for the mission's advantage and start mode. The briefing shows the human player's gold and, when an AI player has its own gold, one value per AI player in player order, for example `4000 / 3000 / 4000`. As in every game, each player's keep pays the start gold out bit by bit at the start; the gold still to come shows as `Starting goods`.
Below the gold, the briefing shows the skirmish menu's button picture of the mission's start mode (normal, crusader or deathmatch).

## Player colours
A player's skirmish colour is its player slot: red (the human player's), orange, yellow, blue, black, purple, lightblue and green. The optional columns `player2_color` to `player8_color` (`color` of an AI player in a mission file) put that AI player into the slot of a colour name or slot number (2-8). The other AI players keep their slot, or take the first free one when it is taken. Empty keeps the player's own slot. A colour that is red, unknown or already given to another player is reported in the log and not used.

## Scenario missions
Trail missions with a custom map name can only start when the game can open that map. The optional csv column `mission_kind` (`"mission_kind"` in a mission file) says how a mission starts:
- `skirmish` (or empty): as before, the trail sets up a skirmish on the map with the mission's players, teams, gold and goods.
- `scenario`: the mission's map is a custom scenario, for example an Invasion map made in the map editor or a saved game turned into a map. It starts the way Custom Scenarios → Play a Map starts it, so its events, goals, invasions, placed units and AI lords run as the map has them. For an Invasion map the game then shows its own briefing, as it does for Play a Map. Such a mission only needs `map_name`, `mission_name` and the 8 description lines of the trail's briefing; the other columns are not used. Other values of `mission_kind` are reported in the log, and such a mission doesn't start.
  - **The map** is looked up like any other map: in the game's `maps` folder, the Documents `Maps` folder, or an extra map folder a plugin registered with the files module. `map_name` is a file name without folders, with or without `.map`, of at most 200 bytes. Letters such as `ü` are fine (they are written in their Latin-1 form, as the files module reads them); letters outside Latin-1 are not. Choose a map that Play a Map can start.
  - **The briefing's lords:** the trail's briefing shows the AI lords and teams the map sets, as the skirmish briefing does. They fill `player2` .. `player8` and `team1` .. `team8` where the mission leaves them empty (the mission's own values win), and `num_players` grows to the map's last AI lord. The map is read when the trail's missions are loaded, only once its date has come, and only when the map stores its lords uncompressed. These columns don't change the scenario itself.
  - **Briefing text:** the optional column `scenario_briefing` (`"scenario_briefing"` in a mission file) is the game's briefing text for this mission, shown instead of the map's own description in the game's briefing. A language file can give it in each game language, so one map serves every language. It is written in the game's text encoding and cut to 999 bytes. The objectives come from the map as before and follow the game language. Empty keeps the map's text.
  - **Difficulty and troops:** the engine difficulty stays Normal, as for Play a Map, and so does what Play a Map does at Normal: on a map without invasion events it removes part of the player's starting army (every 4th military unit, until about a quarter of their value is gone). `keep_start_army` `1` keeps the whole army when the trail starts this mission and on its Restart; empty or `0` keeps the game's behaviour.
  - **Winning** counts for the trail as winning a skirmish mission does: the trail moves on and the trail map opens. A win counts for the scenario the trail started, while the trail remembers it (see below). Winning a map that is a mission of two trails counts for the trail that was open last. Only maps that end on the mission finished screen can be won this way (Invasion and siege maps); economic and build-only maps end with the game's quit dialog instead. The game also records the trail's months and its Skirmish Masters entry as for a skirmish mission; set the trail's `starting_year` no later than the scenarios' own years. For a map saved from a skirmish game the recorded months can be wrong: the game counts them from the start month stored in the map.
  - Restart and Quit in the game work as for a map started from Play a Map; Quit leads to Custom Scenarios. A map saved from a skirmish game keeps the skirmish rules (for example, it is won when every enemy lord is dead) and plays as a skirmish mission of the trail: Restart starts it again from the trail, Quit leads to the trail map, and its saves keep the mission, its `unit_limit` and its win, as a skirmish mission's saves do.
  - For other maps, the trail remembers the scenario it started until the next trail Start, until the Play a Map list is opened, until a save of another map is loaded or until the game is closed. While it does, Restart and loaded saves of that map count as this mission (also a save of another game on that map); a save that names no map ends it. A save loaded after the game was started again plays without the mission's `keep_start_army` on Restart and without its `unit_limit`, and winning it doesn't count for the trail.
  - **Dates:** a map with a date in an `availability.json` of the files module (files 1.5.0) can be started only from its date on. Until then the briefing shows the trail settings file's `trail_locked_text` (a language file can give its own), in which `{date}` becomes the date. Without that text the mission's own description is shown, and Start does nothing. With an older files module no map has a date.

A plugin can give a mission of a trail's mission data (csv or mission files) another map, for example the map in the language a player chose, from its `init.lua`: `modules["custom-skirmish-trails"]:setMissionMap("Warchest", 5, "Türchen05")` (trail `First`, `Warchest` or `Extreme`, the mission number, the map name). Call it while extensions are enabled; it applies when the trail's missions are loaded, and a mission the data doesn't have is reported in the log.

## Troop limits (`unit_limit`)
The game limits each player's troops: in Crusader to 2400 / living lords - 40, in Extreme to 9900 / living lords - 40, and not at all in custom scenarios. The optional column `unit_limit` (`"unit_limit"` in a mission file) sets the limit for this mission:
- `native`: the game's own limit (also when the column is empty);
- `formula BASE OFFSET`: BASE / living lords - OFFSET. `formula 2400 40` gives Crusader's limits in Extreme; in a scenario mission it gives a limit where the game has none.
- `by_alive LORDS=LIMIT ...`: a limit per number of living lords, for example `by_alive 8=250 4=500 2=1000 1=2000`; counts between two listed ones are interpolated and rounded down (6 living lords: 375), counts outside them take the nearest listed limit. Each count 1–8 at most once, each limit at most 100000.
- per difficulty: `story: native; normal: by_alive 8=400 4=800 1=3000; hard: formula 2400 40`, with `story`, `normal`, `hard`, `very_hard` and `default` (for every difficulty not named).

The limit is never higher than the game's skirmish formula for the living lords (also in scenario missions, where the game has none), for example at most 2360 with one living lord in Crusader. In a scenario mission the living lords are the lords of the map's players that are still alive. Placed and AI units share the game's unit pool, so a limit doesn't guarantee room for the player's troops. The limit is worked out each tick from the mission being played (a skirmish mission: the game's trail state; a scenario mission: the scenario the trail started, see above) and the difficulty set now; outside trail missions the game's own limit is used. A mission with a limit doesn't start when the game code for it is not found. The difficulty is the module setting `custom-skirmish-trails.difficulty` (`story`, `normal` (the default), `hard`, `very_hard`), which has no launcher control: a plugin, for example a difficulty preset, suggests it. The AI's troops are not limited by it.

## Trail settings file
Each trail can have a trail settings file (a .json file, set in the GUI) with everything about the trail. `resources/trail-settings.schema.json` describes it, and `resources/trails/template-*-settings.json` hold the game's own values. Every entry is optional:
- `trail_type`: `First`, `Warchest` or `Extreme`.
- `trail_missions`: the trail's mission data, see below.
- `trail_text_files`: the trail's language files, see below.
- `trail_title`, `trail_summary`: the texts under the trail's button in the skirmish menu. A summary wider than 540 pixels wraps into a second line; both texts then sit 10 pixels higher.
- `trail_locked_text`: the briefing of a scenario mission whose map isn't open yet (see Scenario missions); `{date}` becomes the date.
- `starting_year`: the year the first mission starts in.
- `trail_visuals`: `trail_button_idle` and `trail_button_highlighted` (pictures, for example .png, for the trail's button in the skirmish menu), and `trail_background` (the trail screen's background: a .tgx file, or a .png/.jpg/.bmp that the game turns into a .tgx once and keeps in `ucp/.cache`; use the size of the game's own file), and `trail_marker_sheet` (door pictures, see below).
- `trail_mission_positions`: a list of `{ "x": .., "y": .. }` points on the 800 x 600 trail screen, one per mission. Their number is the trail's number of missions (at most 50 for the first trail, 30 for the Warchest and the Extreme trail).
- `ai_character_mapping`: your own names for the AI keys (`"SK_RICHARD": "Robert"`). Mission files use them, and the csv file may use them in player1 to player8.

Relative paths in the file are taken from the file's own folder.

## Mission data: csv file and mission files
`"trail_missions": { "base_name": "missions/my_trail", "data_mode": "csv" }` names both the csv file (`missions/my_trail.csv`) and a folder of mission files (`missions/my_trail/my_trail_mission_01.json`, ...). A mission file (format 1, `resources/mission.schema.json`) holds the same data as one csv line, laid out for reading and editing:
- `mission_name` and `text_description` (a list of the 8 lines) at the top;
- `advantage` (`human_large`, `human_small`, `neutral`, `ai_small`, `ai_large`; the csv's fairness 1-5) and `start_mode` (`normal`, `crusader`, `deathmatch`; the csv's start_levels 1-3). Numbers work too;
- `players`: one entry per player, so their number is the mission's number of players. `players[0]` is the human player: it may have `lord` and `skip_start_units`, never `ai`. The others always have `ai`, never `lord`. All have `name`, `start_position`, `team`, `aiv_type` and `gold` as needed, and AI players `color`;
- `producible`, `recruitable`, `resources`, `tradeable`: the csv's prefixed columns as objects;
- `marker`: `locked`, `available` and `won`, the csv's `marker_locked`, `marker_available` and `marker_won` (door pictures, see below);
- `extra`: any csv value that has no place above, so that nothing gets lost. A conflicting value in `extra` takes precedence and logs a warning before it can be written to CSV.

`data_mode` says which one is the ground truth. It is applied at every game start:
- `csv`: the game loads the csv file and writes the mission files from it.
- `json_folder`: the game writes the csv file from the mission files, then loads it.
- `automatic`: each mission JSON file is compared against the modification time of the entire CSV. The newer file wins, with ties going to the CSV. A malformed mission JSON file stops sync, including in CSV mode.

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

Validate language files with [the language-file schema](../resources/trail-language.schema.json). Missions are found by their number. A text a language file does not have shows the mission data's text; strict mode lists those. With `trail_missions`, `texts/_template.json` is written with all texts of the mission data, as a starting point for translators.

## File paths
Each trail's "File paths" panel lists the files set for it and clears them (the GUI's own reset only works right after a path was set).

## Strict mode
Miscellaneous: logs every problem in the csv, mission, language and trail settings files, every trail setting that falls back to the game's own value, and every text a language file lacks. Without it, one warning per file with problems.

## Export and Import CSV Data
Each trail's "CSV data" panel in the GUI has an Export and an Import button, for converting by hand (`trail_missions` does it at every start on its own). Export writes every csv line into a mission file, Import puts the mission files back together into the csv file. The GUI cannot write files itself, so a button records the request and the game carries it out at its next start; the panel then shows what was done.

### Skip tokens by difficulty

Set `chickens` in the trail settings JSON to change its total skip budget. The
game subtracts spent tokens when it opens the trail screen. An omitted
difficulty uses the game�s default. `"unlimited"` supplies enough tokens to
skip every mission on that trail.

```json
"chickens": { "story": "unlimited", "normal": 6, "hard": 3, "very_hard": 0 }
```

### Door pictures

`trail_visuals.trail_marker_sheet` names a .gm1 file laid out like the game's
`skirmish_trail_icons.gm1`: 130 pictures of 100 x 100, the same GM1 type. A mission
with a `marker` shows its pictures (numbered from 0) in place of the game's flag,
drawn where the game draws its flag:

- `locked`: the mission can't be clicked yet. It is open once the trail has reached
  it, its date has come (see Scenario missions) and its map is installed.
- `available`: an open mission; it can be clicked.
- `won`: drawn over the closed picture once the mission is won (not when a chicken
  skipped it).

The game's chicken stays on the selected mission. Missions without a `marker` and
trails without a sheet keep the game's markers.

```json
"trail_visuals": { "trail_marker_sheet": "doors.gm1" }
"marker": { "locked": 0, "available": 1, "won": 2 }
```
