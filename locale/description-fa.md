# Custom Skirmish Trails

**1.4.1**

این افزونه امکان ساخت مسیرهای سفارشی نبرد آزاد (Skirmish Trails) را که در فایل‌های `.csv` تعریف شده‌اند فراهم می‌کند.

## امکانات
فایل ZIP این افزونه شامل یک فایل `template.csv` است که همهٔ موارد قابل ویرایش را توضیح می‌دهد.

همچنین می‌توانید مسیر اول را از [اینجا](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-First-Edition-Trail.csv)، مسیر Warchest را از [اینجا](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Warchest-Trail.csv) و مسیر Extreme را از [اینجا](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Extreme-Trail.csv) دریافت کنید.

یک ویرایشگر آنلاین ساده در این نشانی در دسترس است: https://edit-csv.net/

فهرست ستون‌ها:
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
- text_dexcription_line_01 - 08: برای نوشتن متنی که در منوی شروع مأموریت نبرد آزاد نمایش داده می‌شود از `""` استفاده کنید
- trade_: برای روشن یا خاموش کردن دادوستد هر کالا، به‌صورت مفرد از الگویی مانند `trade_spear` استفاده کنید

## تازه‌های نسخهٔ ۱.۴ (از Monsterfish)

### نام بازیکنان و لرد بازیکن انسانی
ستون‌های اختیاری CSV که بهتر است در انتها قرار گیرند:
- `player1_name` تا `player8_name`: نام هر بازیکن در این مأموریت، در صفحهٔ توضیحات و درون بازی. خالی بودن آن نام معمول بازیکن یا هوش مصنوعی را حفظ می‌کند.
- `player1_lord`: مقدار `Arab` یا `Europ` به بازیکن انسانی در این مأموریت لرد عرب یا اروپایی و نیروهای آغازین همان لرد را می‌دهد. خالی گذاشتن آن انتخاب خود بازیکن را حفظ می‌کند.
- `player1_skip_start_units`: مقدار `1` باعث می‌شود بازیکن انسانی در این مأموریت هیچ نیروی آغازینی نداشته باشد (لرد همچنان ظاهر می‌شود). خالی یا `0` آن‌ها را حفظ می‌کند.

### فایل تنظیمات مسیر
هر مسیر می‌تواند یک فایل تنظیمات (یک فایل `.json` که در رابط کاربری تنظیم می‌شود) با همهٔ مشخصات مسیر داشته باشد. `resources/trail-settings.schema.json` ساختار آن را شرح می‌دهد و فایل‌های `resources/trails/template-*-settings.json` مقادیر خود بازی را در بر دارند. همهٔ فیلدها اختیاری‌اند:
- `trail_type`: یکی از `First`، `Warchest` یا `Extreme`.
- `trail_missions`: داده‌های مأموریت‌های مسیر، ادامه را ببینید.
- `trail_text_files`: فایل‌های زبان مسیر، ادامه را ببینید.
- `trail_title` و `trail_summary`: متن‌های زیر دکمهٔ مسیر در منوی نبرد آزاد. خلاصه‌ای عریض‌تر از ۵۴۰ پیکسل به خط دوم می‌شکند و هر دو متن ۱۰ پیکسل بالاتر قرار می‌گیرند.
- `starting_year`: سال شروع مأموریت اول.
- `trail_visuals`: `trail_button_idle` و `trail_button_highlighted` (تصاویر دکمهٔ مسیر در منوی نبرد آزاد، مانند `.png`) و `trail_background` (پس‌زمینهٔ صفحهٔ مسیر: فایل `.tgx` یا `.png`/`.jpg`/`.bmp` که بازی یک بار به `.tgx` تبدیل و در `ucp/.cache` ذخیره می‌کند؛ از اندازهٔ فایل خود بازی استفاده کنید).
- `trail_mission_positions`: فهرستی از نقاط `{ "x": .., "y": .. }` روی صفحهٔ مسیر ۸۰۰ × ۶۰۰، یکی برای هر مأموریت. تعداد آن‌ها شمار مأموریت‌های مسیر را تعیین می‌کند (حداکثر ۵۰ برای مسیر اول و ۳۰ برای Warchest و Extreme).
- `ai_character_mapping`: نام‌های دلخواه شما برای کلیدهای هوش مصنوعی (`"SK_RICHARD": "Robert"`). فایل‌های مأموریت از آن‌ها استفاده می‌کنند و فایل CSV نیز می‌تواند در `player1` تا `player8` از آن‌ها بهره ببرد.

مسیرهای نسبی در این فایل نسبت به پوشهٔ خود فایل سنجیده می‌شوند.

### داده‌های مأموریت: فایل CSV و فایل‌های مأموریت
`"trail_missions": { "base_name": "missions/my_trail", "data_mode": "csv" }` هم فایل CSV (`missions/my_trail.csv`) و هم پوشهٔ فایل‌های مأموریت (`missions/my_trail/my_trail_mission_01.json` و…) را مشخص می‌کند. هر فایل مأموریت (قالب ۱، `resources/mission.schema.json`) همان داده‌های یک سطر CSV را به‌شکل خوانا و آسان برای ویرایش نگه می‌دارد:
- `mission_name` و `text_description` (فهرست ۸ خط) در بالا؛
- `advantage` (`human_large`، `human_small`، `neutral`، `ai_small`، `ai_large`؛ معادل `fairness` 1–5 در CSV) و `start_mode` (`normal`، `crusader`، `deathmatch`؛ معادل `start_levels` 1–3). عددها نیز پذیرفته می‌شوند؛
- `players`: یک مدخل برای هر بازیکن که تعدادشان شمار بازیکنان مأموریت را تعیین می‌کند. `players[0]` بازیکن انسانی است و می‌تواند `lord` و `skip_start_units` داشته باشد، نه `ai`. بقیه همیشه `ai` دارند و هرگز `lord` ندارند. همه در صورت نیاز `name`، `start_position`، `team`، `aiv_type` و `gold` دارند؛
- `producible`، `recruitable`، `resources` و `tradeable`: ستون‌های پیشوندی CSV به‌صورت شیء؛
- `extra`: هر مقدار CSV که در بخش‌های بالا جا نمی‌گیرد تا هیچ داده‌ای از دست نرود.

`data_mode` مشخص می‌کند کدام منبع مرجع است و در هر بار اجرای بازی اعمال می‌شود:
- `csv`: بازی فایل CSV را می‌خواند و فایل‌های مأموریت را از روی آن می‌نویسد.
- `json_folder`: بازی فایل CSV را از فایل‌های مأموریت می‌سازد و سپس آن را بارگذاری می‌کند.
- `automatic`: برای هر مأموریت، هرکدام دیرتر ویرایش شده باشد برنده است؛ فایل‌های مأموریت تازه‌تر وارد CSV می‌شوند و سطرهای CSV تازه‌تر وارد فایل‌های مأموریت.

پیش از تغییر فایل‌ها، فایل CSV قبلی با نام `<csv>.bak` و فایل‌های مأموریت قبلی در `<پوشه>/.bak` ذخیره می‌شوند (هرکدام یک نسخهٔ پیشین). اگر از آخرین اجرا هیچ فایلی تغییر نکرده باشد، هیچ خواندن یا نوشتنی انجام نمی‌شود. بدون فایل تنظیمات مسیر، همان فایل CSV تنظیم‌شده در رابط کاربری به‌کار می‌رود.

### فایل‌های زبان
داده‌های مأموریت یک مجموعه متن (زبان پیش‌فرض) نگه می‌دارند. هر زبان دیگر یک فایل JSON کوچک فقط شامل متن‌های خودش است: `"trail_text_files": "texts/"` به پوشه‌ای شامل `english.json`، `german.json` و غیره اشاره می‌کند (یا شیئی از نگاشت زبان به فایل). نمونهٔ فایل زبان:

```json
{
  "trail_title": "Der Kreuzzug",
  "trail_summary": "...",
  "missions": {
    "1": { "mission_name": "Die Küste", "text_description_line_01": "...", "player2_name": "..." }
  }
}
```

مأموریت‌ها با شمارهٔ خود پیدا می‌شوند. متنی که در فایل زبان نباشد از داده‌های مأموریت نمایش داده می‌شود و حالت سخت‌گیرانه آن‌ها را فهرست می‌کند. با `trail_missions` فایل `texts/_template.json` با همهٔ متن‌های مأموریت به‌عنوان نقطهٔ شروع برای مترجمان ساخته می‌شود.

### مسیر فایل‌ها
پنل «مسیر فایل‌ها» برای هر مسیر فایل‌های تنظیم‌شده را فهرست و پاک می‌کند (بازنشانی خود رابط کاربری تنها بلافاصله پس از انتخاب یک مسیر کار می‌کند).

### حالت سخت‌گیرانه
سایر: هر خطا در فایل‌های CSV، مأموریت، زبان و تنظیمات مسیر، هر تنظیمی که به مقدار خود بازی برگردد و هر متنی که در فایل زبان وجود نداشته باشد را ثبت می‌کند. بدون آن، برای هر فایل دارای مشکل تنها یک هشدار نمایش داده می‌شود.

### خروجی و ورودی داده‌های CSV
پنل «داده‌های CSV» هر مسیر در رابط کاربری دارای دکمه‌های Export و Import برای تبدیل دستی است (`trail_missions` این کار را در هر شروع به‌صورت خودکار انجام می‌دهد). Export هر سطر CSV را در یک فایل مأموریت می‌نویسد و Import فایل‌های مأموریت را دوباره در فایل CSV گرد می‌آورد. از آنجا که رابط کاربری خود نمی‌تواند فایل بنویسد، دکمه درخواست را ثبت می‌کند و بازی در اجرای بعدی آن را انجام می‌دهد؛ سپس پنل نتیجه را نمایش می‌دهد.

## حمایت
هرگونه حمایت مایهٔ دلگرمی است!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

اگر پی‌پال دارید:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
