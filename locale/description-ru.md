# Custom Skirmish Trails

**1.4.1**

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

## Новое в 1.4 (форк от Monsterfish)

### Имена игроков и лорд игрока-человека
Необязательные столбцы CSV, которые лучше размещать в конце:
- `player1_name` — `player8_name`: имя игрока в этой миссии (в брифинге и в самой игре). Пустое значение сохраняет обычное имя игрока или ИИ.
- `player1_lord`: `Arab` или `Europ` задаёт игроку-человеку арабского или европейского лорда в этой миссии вместе со стартовыми войсками этого лорда. Пустое значение оставляет выбор игрока.
- `player1_skip_start_units`: `1` убирает стартовые войска игрока-человека в этой миссии (лорд всё равно появляется). Пустое значение или `0` сохраняет их.

### Файл настроек пути
У каждого пути может быть файл настроек (`.json`, указываемый в лаунчере) со всеми параметрами пути. Его формат описан в `resources/trail-settings.schema.json`, а `resources/trails/template-*-settings.json` содержат стандартные значения игры. Каждый параметр необязателен:
- `trail_type`: `First`, `Warchest` или `Extreme`.
- `trail_missions`: данные миссий пути, см. ниже.
- `trail_text_files`: языковые файлы пути, см. ниже.
- `trail_title`, `trail_summary`: тексты под кнопкой пути в меню схватки. Описание шире 540 пикселей переносится на вторую строку, а оба текста при этом сдвигаются на 10 пикселей вверх.
- `starting_year`: год начала первой миссии.
- `trail_visuals`: `trail_button_idle` и `trail_button_highlighted` (изображения, например `.png`, для кнопки пути в меню схватки), а также `trail_background` (фон экрана пути: файл `.tgx` или `.png`/`.jpg`/`.bmp`, который игра один раз преобразует в `.tgx` и сохранит в `ucp/.cache`; используйте размер исходного файла игры).
- `trail_mission_positions`: список точек `{ "x": .., "y": .. }` на экране пути 800 × 600, по одной на миссию. Их количество задаёт число миссий в пути (не более 50 для первого пути и 30 для Warchest и Extreme).
- `ai_character_mapping`: ваши собственные имена для ключей ИИ (`"SK_RICHARD": "Alfonso"`). Они используются в файлах миссий, и их можно писать в CSV в столбцах `player1`–`player8`.

Относительные пути в файле отсчитываются от папки, в которой лежит сам файл.

### Данные миссий: CSV-файл и файлы миссий
`"trail_missions": { "base_name": "missions/reconquista", "data_mode": "csv" }` задаёт одновременно CSV-файл (`missions/reconquista.csv`) и папку с файлами миссий (`missions/reconquista/reconquista_mission_01.json`, …). Файл миссии (формат 1, `resources/mission.schema.json`) хранит те же данные, что и одна строка CSV, но в удобном для чтения и правки виде:
- `mission_name` и `text_description` (список из 8 строк) в начале;
- `advantage` (`human_large`, `human_small`, `neutral`, `ai_small`, `ai_large` — соответствует `fairness` 1–5 в CSV) и `start_mode` (`normal`, `crusader`, `deathmatch` — соответствует `start_levels` 1–3). Числа также поддерживаются;
- `players`: по одной записи на игрока, так что их число равно количеству игроков в миссии. `players[0]` — игрок-человек: может иметь `lord` и `skip_start_units`, но никогда `ai`. У остальных всегда есть `ai` и никогда нет `lord`. Все могут содержать `name`, `start_position`, `team`, `aiv_type` и `gold` по необходимости;
- `producible`, `recruitable`, `resources`, `tradeable`: столбцы CSV с префиксами в виде объектов;
- `extra`: любые значения CSV, для которых нет поля выше, чтобы ничего не пропало.

Параметр `data_mode` определяет главный источник данных и применяется при каждом запуске игры:
- `csv`: игра загружает CSV-файл и записывает из него файлы миссий.
- `json_folder`: игра собирает CSV-файл из файлов миссий, затем загружает его.
- `automatic`: для каждой миссии побеждает последний изменённый файл — более новые файлы миссий обновляют CSV, а более новые строки CSV обновляют файлы миссий.

Перед изменением файлов предыдущий CSV сохраняется как `<csv>.bak`, а предыдущие файлы миссий — в `<папка>/.bak` (по одной предыдущей версии). Если с последнего запуска ничего не менялось, чтение и запись не выполняются. Без файла настроек пути используется CSV-файл из интерфейса, как раньше.

### Языковые файлы
В данных миссий хранится один набор текстов — язык по умолчанию. Каждый дополнительный язык — это небольшой JSON-файл только со своими текстами: `"trail_text_files": "texts/"` указывает на папку с файлами `english.json`, `german.json` и т. д. (или задайте объект соответствия языков и файлов). Пример языкового файла:

```json
{
  "trail_title": "Die Reconquista",
  "trail_summary": "...",
  "missions": {
    "1": { "mission_name": "Die Küste", "text_description_line_01": "...", "player2_name": "..." }
  }
}
```

Миссии сопоставляются по номеру. Если текста нет в языковом файле, показывается текст из данных миссий; строгий режим перечисляет такие пропуски. При использовании `trail_missions` создаётся `texts/_template.json` со всеми текстами миссий как заготовка для переводчиков.

### Пути к файлам
Панель «Пути к файлам» каждого пути показывает заданные для него файлы и позволяет их очистить (собственный сброс интерфейса работает только сразу после выбора пути).

### Строгий режим
Настройки для разработчиков: записывает в журнал каждую проблему в CSV, файлах миссий, языковых файлах и файле настроек пути, каждый параметр, откатившийся к значению игры по умолчанию, и каждый отсутствующий в языковом файле текст. Без него выводится по одному предупреждению на проблемный файл.

### Экспорт и импорт данных CSV
На панели «Данные CSV» каждого пути в интерфейсе есть кнопки экспорта и импорта для ручного преобразования (`trail_missions` выполняет это автоматически при каждом запуске). Экспорт записывает каждую строку CSV в отдельный файл миссии, а импорт собирает файлы миссий обратно в CSV. Поскольку интерфейс не может сам записывать файлы, нажатие кнопки сохраняет запрос, и игра выполняет его при следующем запуске, после чего панель показывает результат.

## Поддержка
Любая поддержка приветствуется!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

Если у вас есть PayPal:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
