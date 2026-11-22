# Custom Skirmish Trails

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

## 征程设置、任务文件与语言

每个征程都可以配置一个在界面中指定的征程设置文件，包含其标题、简介、起始年份、图片、任务坐标、AI 名称、任务数据和语言文件。任务也可以按每关一个 JSON 文件保存，每种语言则保存为仅含自身文本的小型 JSON 文件。可选的 CSV 列可设置单个任务的玩家名称和人类玩家的领主。具体格式详见 [docs/trail-files.md](https://github.com/gynt/ucp-extension-custom-skirmish-trails/blob/main/docs/trail-files.md)。

## 支持作者
欢迎任何形式的支持！

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

如果您使用 PayPal：
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
