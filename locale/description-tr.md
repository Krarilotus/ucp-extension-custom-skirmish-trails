# Custom Skirmish Trails

Bu eklenti, `.csv` dosyalarında tanımlanan özel çarpışma seferlerini (skirmish trails) etkinleştirir.

## Olanaklar
Bu eklentinin ZIP dosyası, nelerin düzenlenebileceğini açıklayan bir `template.csv` dosyası içerir.

Ayrıca ilk seferi [buradan](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-First-Edition-Trail.csv), Warchest seferini [buradan](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Warchest-Trail.csv) ve Extreme seferini [buradan](https://raw.githubusercontent.com/gynt/ucp-extension-custom-skirmish-trails/refs/heads/main/template-Extreme-Trail.csv) indirebilirsiniz.

Kolay bir çevrimiçi düzenleyiciye buradan ulaşabilirsiniz: https://edit-csv.net/

Sütunların listesi:
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
- text_dexcription_line_01 - 08: Çarpışma görevi başlangıç menüsünde gösterilen metni yazmak için `""` kullanın
- trade_: O malın ticaretini açmak veya kapatmak için örn. `trade_spear` (tekil!) kullanın

## Sefer ayarları, görev dosyaları ve diller

Her seferin GUI'den seçilen bir sefer ayar dosyası olabilir; bu dosya başlık, özet, başlangıç yılı, görseller, görev konumları, yapay zekâ adları, görev verileri ve dil dosyalarını içerir. Görevler her biri ayrı bir JSON dosyası olarak, her dil de yalnızca kendi metinlerini içeren küçük bir JSON dosyası olarak saklanabilir. İsteğe bağlı CSV sütunları göreve özel oyuncu adlarını ve insan oyuncunun lordunu belirler. Biçimler [docs/trail-files.md](https://github.com/gynt/ucp-extension-custom-skirmish-trails/blob/main/docs/trail-files.md) dosyasında açıklanmıştır.

## Destek
Her türlü destek memnuniyetle karşılanır!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

PayPal kullanıyorsanız:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
