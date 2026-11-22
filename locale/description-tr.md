# Custom Skirmish Trails

**1.4.1**

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

## 1.4 sürümündeki yenilikler (Monsterfish)

### Oyuncu adları ve insan oyuncunun lordu
İsteğe bağlı CSV sütunları, tercihen en sona eklenir:
- `player1_name` – `player8_name`: bir oyuncunun bu görevde, brifingde ve oyun içinde sahip olacağı ad. Boş bırakılırsa olağan insan veya yapay zekâ adı korunur.
- `player1_lord`: `Arab` veya `Europ`, insan oyuncuya bu görev için Arap veya Avrupalı lordu ve o lordun başlangıç birliklerini verir. Boş bırakılırsa oyuncunun kendi seçimi korunur.
- `player1_skip_start_units`: `1` değeri bu görevde insan oyuncuya başlangıç birliği vermez (lord yine gelir). Boş veya `0` değerinde birlikler korunur.

### Sefer ayar dosyası
Her seferin, seferle ilgili her şeyi içeren bir ayar dosyası (GUI'den seçilen bir `.json` dosyası) olabilir. Biçimi `resources/trail-settings.schema.json` dosyasında açıklanmıştır ve `resources/trails/template-*-settings.json` dosyaları oyunun kendi değerlerini içerir. Her alan isteğe bağlıdır:
- `trail_type`: `First`, `Warchest` veya `Extreme`.
- `trail_missions`: seferin görev verileri, aşağıya bakın.
- `trail_text_files`: seferin dil dosyaları, aşağıya bakın.
- `trail_title`, `trail_summary`: çarpışma menüsünde sefer düğmesinin altındaki metinler. 540 pikselden geniş bir özet ikinci satıra sarılır; her iki metin de bu durumda 10 piksel yukarı kayar.
- `starting_year`: ilk görevin başladığı yıl.
- `trail_visuals`: `trail_button_idle` ve `trail_button_highlighted` (çarpışma menüsündeki sefer düğmesi için örn. `.png` görselleri) ve `trail_background` (sefer ekranının arka planı: bir `.tgx` dosyası ya da oyunun tek seferde `.tgx` biçimine dönüştürüp `ucp/.cache` içinde sakladığı `.png`/`.jpg`/`.bmp` dosyası; oyunun kendi dosyasının boyutunu kullanın).
- `trail_mission_positions`: 800 × 600 sefer ekranında görev başına bir adet `{ "x": .., "y": .. }` nokta listesi. Sayıları seferin görev sayısını belirler (ilk sefer için en fazla 50, Warchest ve Extreme için 30).
- `ai_character_mapping`: yapay zekâ anahtarları için kendi adlarınız (`"SK_RICHARD": "Robert"`). Görev dosyaları bunları kullanır ve CSV dosyası da `player1`–`player8` sütunlarında kullanabilir.

Dosyadaki göreceli yollar dosyanın kendi klasörüne göre yorumlanır.

### Görev verileri: CSV dosyası ve görev dosyaları
`"trail_missions": { "base_name": "missions/my_trail", "data_mode": "csv" }` hem CSV dosyasını (`missions/my_trail.csv`) hem de görev dosyaları klasörünü (`missions/my_trail/my_trail_mission_01.json`, …) tanımlar. Bir görev dosyası (biçim 1, `resources/mission.schema.json`), bir CSV satırıyla aynı verileri okuması ve düzenlemesi kolay bir yapıda tutar:
- Üstte `mission_name` ve `text_description` (8 satırlık liste);
- `advantage` (`human_large`, `human_small`, `neutral`, `ai_small`, `ai_large`; CSV'deki 1–5 arası `fairness` değerleri) ve `start_mode` (`normal`, `crusader`, `deathmatch`; CSV'deki 1–3 arası `start_levels` değerleri). Sayılar da çalışır;
- `players`: oyuncu başına bir girdi, yani sayıları görevin oyuncu sayısını belirler. `players[0]` insan oyuncudur: `lord` ve `skip_start_units` içerebilir, asla `ai` içermez. Diğerlerinde her zaman `ai` bulunur, asla `lord` bulunmaz. Hepsinde gerektiğinde `name`, `start_position`, `team`, `aiv_type` ve `gold` yer alabilir;
- `producible`, `recruitable`, `resources`, `tradeable`: CSV'deki ön ekli sütunlar nesne olarak;
- `extra`: yukarıda yeri olmayan herhangi bir CSV değeri, böylece hiçbir veri kaybolmaz.

`data_mode` hangi kaynağın esas alınacağını belirler ve her oyun başlangıcında uygulanır:
- `csv`: oyun CSV dosyasını yükler ve ondan görev dosyalarını yazar.
- `json_folder`: oyun görev dosyalarından CSV dosyasını oluşturur, ardından yükler.
- `automatic`: her görev için en son hangisi düzenlendiyse o geçerli olur — daha yeni görev dosyaları CSV'ye, daha yeni CSV satırları görev dosyalarına aktarılır.

Dosyalar değiştirilmeden önce önceki CSV `<csv>.bak` olarak, önceki görev dosyaları ise `<klasör>/.bak` içinde yedeklenir (her biri için bir önceki sürüm). Son başlangıçtan beri hiçbir dosya değişmediyse okuma veya yazma yapılmaz. Sefer ayar dosyası yoksa eskisi gibi GUI'de seçilen CSV dosyası kullanılır.

### Dil dosyaları
Görev verileri tek bir metin kümesi (varsayılan dil) içerir. Eklenen her dil, yalnızca kendi metinlerini barındıran küçük bir JSON dosyasıdır: `"trail_text_files": "texts/"`, içinde `english.json`, `german.json` vb. bulunan bir klasöre işaret eder (veya dilleri dosyalara eşleyen bir nesne verin). Örnek bir dil dosyası:

```json
{
  "trail_title": "Der Kreuzzug",
  "trail_summary": "...",
  "missions": {
    "1": { "mission_name": "Die Küste", "text_description_line_01": "...", "player2_name": "..." }
  }
}
```

Görevler numaralarıyla eşleştirilir. Bir dil dosyasında bulunmayan metin için görev verilerindeki metin gösterilir; katı mod bunları listeler. `trail_missions` kullanıldığında, çevirmenlere başlangıç noktası olması için görev verilerindeki tüm metinleri içeren `texts/_template.json` oluşturulur.

### Dosya yolları
Her seferin «Dosya yolları» paneli o sefer için tanımlı dosyaları listeler ve temizler (GUI'nin kendi sıfırlaması yalnızca bir yol yeni seçildikten hemen sonra çalışır).

### Katı mod
Diğer: CSV, görev, dil ve sefer ayar dosyalarındaki her sorunu, oyunun kendi değerine geri dönen her ayarı ve bir dil dosyasında eksik olan her metni günlüğe yazar. Kapalıyken sorunlu dosya başına bir uyarı gösterilir.

### CSV verilerini dışa ve içe aktarma
GUI'de her seferin «CSV verileri» panelinde elle dönüştürme için bir Dışa Aktar ve bir İçe Aktar düğmesi bulunur (`trail_missions` bunu her başlangıçta kendiliğinden yapar). Dışa Aktar her CSV satırını bir görev dosyasına yazar; İçe Aktar görev dosyalarını yeniden CSV dosyasında birleştirir. GUI kendisi dosya yazamadığından düğmeye basmak isteği kaydeder ve oyun bir sonraki başlangıçta bunu uygular; panel daha sonra yapılan işlemi gösterir.

## Destek
Her türlü destek memnuniyetle karşılanır!

[!["Buy Me A Coffee"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/orange_img.webp)](https://www.buymeacoffee.com/gynt)

PayPal kullanıyorsanız:
[!["Support me on Ko-Fi"](https://raw.githubusercontent.com/gynt/ucp-extension-running-units/main/locale/kofi_button_red.png)](https://ko-fi.com/kofigynt)
