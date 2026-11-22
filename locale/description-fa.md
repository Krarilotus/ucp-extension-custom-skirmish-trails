# Custom Skirmish Trails

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

## تنظیمات مسیر، فایل‌های مأموریت و زبان‌ها

هر مسیر می‌تواند یک فایل تنظیمات مسیر داشته باشد که در رابط کاربری تنظیم می‌شود و شامل عنوان، خلاصه، سال شروع، تصاویر، موقعیت مأموریت‌ها، نام‌های هوش مصنوعی، داده‌های مأموریت و فایل‌های زبان است. مأموریت‌ها را می‌توان به‌صورت یک فایل JSON برای هر مأموریت، و هر زبان را به‌صورت یک فایل JSON کوچک تنها شامل متن‌های خودش نگهداری کرد. ستون‌های اختیاری CSV نام بازیکنان هر مأموریت و لرد بازیکن انسانی را تعیین می‌کنند. قالب فایل‌ها در [docs/trail-files.md](https://github.com/gynt/ucp-extension-custom-skirmish-trails/blob/main/docs/trail-files.md) توضیح داده شده است.

## حمایت
هرگونه حمایت مایهٔ دلگرمی است!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

اگر پی‌پال دارید:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
