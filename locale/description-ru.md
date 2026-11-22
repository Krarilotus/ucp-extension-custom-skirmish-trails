# Custom Skirmish Trails

Это расширение позволяет создавать пользовательские пути схваток, заданные в файлах `.csv`.

## Возможности
В ZIP-архиве этого расширения есть файл `template.csv`, описывающий все параметры для модификации.

Вы также можете скачать первый путь [здесь](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-First-Edition-Trail.csv), путь Warchest [здесь](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Warchest-Trail.csv) и путь Extreme [здесь](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Extreme-Trail.csv).

Удобный онлайн-редактор доступен здесь: https://edit-csv.net/

Список столбцов:
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
- text_dexcription_line_01 - 08: Используйте `""` для записи текста, отображаемого в стартовом меню миссии схватки
- trade_: Используйте, например, `trade_spear` (в единственном числе!), чтобы включить или отключить торговлю этим товаром

## Настройки пути, файлы миссий и языки

У каждого пути может быть файл настроек пути, указываемый в интерфейсе, с его названием, описанием, годом начала, изображениями, координатами миссий, именами ИИ, данными миссий и языковыми файлами. Миссии также можно хранить в отдельных JSON-файлах по одному на миссию, а каждый язык — в небольшом JSON-файле только со своими текстами. Необязательные столбцы CSV задают имена игроков для конкретной миссии и лорда игрока-человека. Форматы описаны в [docs/trail-files.md](https://github.com/gynt/ucp-extension-custom-skirmish-trails/blob/main/docs/trail-files.md).

## Поддержка
Любая поддержка приветствуется!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Если у вас есть PayPal:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
