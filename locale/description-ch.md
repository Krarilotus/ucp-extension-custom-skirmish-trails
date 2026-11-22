# Custom Skirmish Trails

**1.4.1**

本扩展允许通过 `.csv` 文件定义自定义的遭遇战征程（Skirmish Trails）。

## 可定制内容
本扩展的 ZIP 压缩包中包含 `template.csv` 文件，列出了所有可修改的项目。

你也可以直接下载官方模板：[初版征程](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-First-Edition-Trail.csv)、[Warchest 征程](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Warchest-Trail.csv) 以及 [Extreme 征程](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Extreme-Trail.csv)。

推荐使用此便捷的在线 CSV 编辑器：https://edit-csv.net/

支持的参数列如下：
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
- text_dexcription_line_01 - 08：使用 `""` 填写遭遇战任务开始菜单中显示的说明文字
- trade_：例如使用 `trade_spear`（注意单数形式！）来开启或关闭对应物资的交易

## 1.4 新增功能（Monsterfish 分支）

### 玩家名称与人类玩家领主
可选的 CSV 列，建议放在表格末尾：
- `player1_name` 至 `player8_name`：玩家在本关任务中（简报界面和游戏内）显示的名称。留空则保持常规玩家或 AI 名称。
- `player1_lord`：填入 `Arab` 或 `Europ` 可为人类玩家在本关指定阿拉伯或欧洲领主，并获得该领主的初始部队。留空则保留玩家自行选择。
- `player1_skip_start_units`：填入 `1` 会使人类玩家在本关没有初始部队（领主仍会出现）。留空或填 `0` 则保留初始部队。

### 征程设置文件
每个征程都可以配置一个征程设置文件（在启动器界面中指定的 `.json` 文件），统一定义征程的所有内容。格式详见 `resources/trail-settings.schema.json`，`resources/trails/template-*-settings.json` 中保存了游戏原生默认值。每个字段均为可选：
- `trail_type`：`First`、`Warchest` 或 `Extreme`。
- `trail_missions`：征程的任务数据，见下文。
- `trail_text_files`：征程的语言文件，见下文。
- `trail_title`、`trail_summary`：遭遇战菜单中征程按钮下方的标题与简介。宽度超过 540 像素的简介会自动换到第二行，同时两段文字整体上移 10 像素。
- `starting_year`：第一关的起始年份。
- `trail_visuals`：`trail_button_idle` 与 `trail_button_highlighted`（遭遇战菜单中征程按钮的图片，如 `.png`），以及 `trail_background`（征程界面的背景图：`.tgx` 文件，或 `.png`/`.jpg`/`.bmp`，游戏会将其一次性转换为 `.tgx` 并缓存在 `ucp/.cache` 中；请保持与原版文件相同尺寸）。
- `trail_mission_positions`：800 × 600 征程界面上的 `{ "x": .., "y": .. }` 坐标列表，每个任务一个点。列表长度决定征程的任务总数（初版征程最多 50 关，Warchest 和 Extreme 征程最多 30 关）。
- `ai_character_mapping`：为 AI 键值定义自定义名称（例如 `"SK_RICHARD": "Alfonso"`）。任务文件会使用这些名称，CSV 文件也可在 `player1` 至 `player8` 列中使用它们。

文件中的相对路径均以该文件所在文件夹为基准。

### 任务数据：CSV 文件与任务文件
`"trail_missions": { "base_name": "missions/reconquista", "data_mode": "csv" }` 同时指定了 CSV 文件（`missions/reconquista.csv`）和任务文件夹（`missions/reconquista/reconquista_mission_01.json` 等）。每个任务文件（格式 1，`resources/mission.schema.json`）保存与一行 CSV 相同的数据，但结构更便于阅读和编辑：
- 顶部为 `mission_name` 和 `text_description`（包含 8 行文本的列表）；
- `advantage`（`human_large`、`human_small`、`neutral`、`ai_small`、`ai_large`，对应 CSV 的 `fairness` 1–5）和 `start_mode`（`normal`、`crusader`、`deathmatch`，对应 CSV 的 `start_levels` 1–3），也可直接写数字；
- `players`：每位玩家一项，条目数即任务玩家数。`players[0]` 为人类玩家，可包含 `lord` 和 `skip_start_units`，不可含 `ai`；其余玩家必须含 `ai`，不可含 `lord`。所有玩家均按需包含 `name`、`start_position`、`team`、`aiv_type` 和 `gold`；
- `producible`、`recruitable`、`resources`、`tradeable`：CSV 中带前缀的各列整理为对象；
- `extra`：未归入上述字段的任何 CSV 数值，确保不会丢失数据。

`data_mode` 决定以哪一方为准，并在每次启动游戏时生效：
- `csv`：游戏读取 CSV 文件，并据此生成任务文件。
- `json_folder`：游戏根据任务文件生成 CSV 文件，然后再读取。
- `automatic`：逐关比较最后修改时间，较新者胜出——较新的任务文件同步进 CSV，较新的 CSV 行同步进任务文件。

在修改文件前，旧的 CSV 会备份为 `<csv>.bak`，旧的任务文件会备份在 `<文件夹>/.bak`（各保留一份上一版本）。若自上次启动以来未改动任何文件，则不进行读写。若未配置征程设置文件，则照常使用界面中设置的 CSV 文件。

### 语言文件
任务数据中保存一套默认语言文本。其他语言各自使用一个仅含文本的小型 JSON 文件：`"trail_text_files": "texts/"` 指向包含 `english.json`、`german.json` 等文件的文件夹（或提供语言到文件的映射对象）。示例：

```json
{
  "trail_title": "Die Reconquista",
  "trail_summary": "...",
  "missions": {
    "1": { "mission_name": "Die Küste", "text_description_line_01": "...", "player2_name": "..." }
  }
}
```

任务按编号匹配。语言文件中缺失的文本会回退显示任务数据中的文本；严格模式会列出这些缺漏。使用 `trail_missions` 时会自动生成包含任务数据全部文本的 `texts/_template.json`，方便翻译人员起步。

### 文件路径
每个征程的“文件路径”面板会列出已设置的文件并允许清除（启动器自带的重置功能仅在刚设置完路径时有效）。

### 严格模式
开发者选项：记录 CSV、任务、语言和征程设置文件中的每一处问题、每一项回退到游戏默认值的设置，以及语言文件中缺失的每一段文本。关闭此项时，每个有问题的文件仅显示一条警告。

### 导出和导入 CSV 数据
启动器界面中每个征程的“CSV 数据”面板都提供了“导出”和“导入”按钮，用于手动转换（配置 `trail_missions` 后每次启动会自动处理）。导出会将每行 CSV 写入对应的任务文件，导入则将任务文件重新合并回 CSV 文件。由于启动器界面本身无法直接写文件，点击按钮后会记录请求，待下次启动游戏时执行，随后面板会显示处理结果。

## 支持作者
欢迎任何形式的支持！

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

如果您使用 PayPal：
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
