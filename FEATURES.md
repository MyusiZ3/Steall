# 📋 Daftar Fitur Steall Hub (`Steal a Pet and Ride It`)

Dokumentasi lengkap mengenai fitur-fitur yang sudah diimplementasikan, dibersihkan dari telemetri, dan dioptimasi khusus untuk **Delta Executor** (Mobile & PC).

---

## 🚀 Ringkasan Fitur yang Sudah Aktif

### 1. 🥷 Auto Steal, Cage Management & Smart Slow Mode (Anti-Sliding)
* **Smart Auto Slow Mode Near Egg (Target Egg Only + Steal Zone Auto-Off):** 
  * **Target Egg Only:** Hanya mengaktifkan Slow Mode ke telur yang *sedang dituju* oleh pergerakan karakter (bukan ke semua telur di map), sehingga karakter tidak melambat saat sekadar berlari melewati telur lain.
  * **Pengereman Halus (Deceleration):** Menyalakan tombol Slow Mode saat jarak karakter berada di antara zona ambil (`~12 studs`) dan jarak target (`SlowModeEggDist`, default `28 studs`).
  * **Auto-Off di Zona Ambil Telor:** Begitu karakter melangkah memasuki zona interaksi telur (`<= 12 studs` / prompt range), Slow Mode **otomatis langsung mati (OFF)** agar karakter siap mengambil telur dan kabur dengan kecepatan penuh tanpa tertangkap monster.
  * **Fail-safe Hold E & Carrying:** Begitu mulai menekan Hold E atau membawa telur, Slow Mode langsung dipastikan mati (OFF).
* **Auto Slow Mode In Base:** Otomatis menyalakan **Slow Mode** setelah karakter terdeteksi berada di dalam Safe Zone / Base selama **2 detik** berturut-turut, dan otomatis mematikannya kembali saat karakter hendak keluar mencuri egg.
* **Auto Steal Cage (Natural Walk):** Otomatis mendeteksi kandang (*cage*) terdekat di `workspace.Paths`, berjalan kaki ke lokasinya (`Humanoid:MoveTo`), mengeksekusi `StealPrompt`, lalu berjalan kembali membawa kandang ke plot milik Anda (tanpa teleportasi).
* **Auto Place Cage:** Otomatis menaruh kandang yang sedang dibawa ke slot kandang (*stall*) kosong di plot Anda menggunakan remote `PlaceCage`.
* **Auto Open Cage:** Memindai seluruh kandang yang ada di plot dan otomatis membukanya (`OpenCage`) begitu *timer cooldown* selesai.

---

### 2. 🏃‍♂️ Training & Speed Progression
* **Auto Train (Treadmill):** Otomatis berpindah dan berdiri di treadmill plot pribadi untuk melatih kecepatan (*speed*) saat tidak ada tugas mencuri kandang.
* **Auto Upgrade Treadmill:** Otomatis membeli level treadmill berikutnya (`UpgradeTreadmill`) begitu saldo koin/uang mencukupi.
* **Auto Tap Boost:** Otomatis mendeteksi dan mengklik gelembung/balon speed boost yang muncul di layar saat sedang latihan di treadmill.

---

### 3. 💰 Upgrades, Economy & Claims
* **Auto Buy Plot Stalls:** Otomatis melakukan *upgrade* kapasitas kandang plot setiap 10 detik (`UpgradePlot`) agar bisa menampung lebih banyak pet.
* **Auto Buy & Equip Best Trail:** Membeli jejak (*trail*) terbaik yang mampu dibeli menggunakan koin (`BuyTrail`) dan langsung memakainya (`EquipTrail`).
* **Auto Claim Rewards:**
  * Klaim hadiah harian (`ClaimDaily`).
  * Klaim hadiah index / koleksi pet (`ClaimAllIndexRewards`).
  * Klaim hadiah tantangan champion (`ChampionClaim`).
* **Auto Equip Best Pets:** Otomatis melengkapi dan menggunakan pet terbaik berdasarkan *income* tertinggi (`EquipBest`).
* **Auto Rebirth:** Melakukan rebirth secara otomatis (`Rebirth`) ketika syarat uang dan kecepatan terpenuhi (default: *Off*).

---

### 4. ⚡ Player Mods & Quality of Life (QoL)
* **Noclip:** Mematikan tabrakan (*CanCollide*) pada karakter sehingga bisa menembus dinding dan rintangan tanpa terhalang. *(Modifikasi WalkSpeed dan Teleport telah dihapus untuk mencegah deteksi moderasi).*

---

### 5. 🛡️ Pembersihan & Optimasi Keamanan (Clean Script)
* **100% Bebas Obfuscator / VM:** Tidak ada kode terenkripsi atau karakter acak, script murni open-source dan mudah diedit.
* **Bebas Tracker Telemetri:** Menghapus script pelacak bawaan:
  * Pelacak ScriptBlox (`https://scriptblox.com/ingest/clientv2.lua`) ❌
  * Pelacak RScripts (`https://rscripts.net/api/telemetry/v2/client.lua`) ❌
* **Bebas Webhook Pihak Ketiga:** Tidak ada pengiriman data atau statistik akun ke webhook Discord milik pengembang lama.
* **GUI Ringan:** Menggunakan antarmuka gelap responsif yang mendukung kontrol layar sentuh di HP (Delta Mobile) dan keyboard di PC.

---

## ⚙️ Tabel Konfigurasi (`getgenv().SAP_Settings`)

Pengaturan ini dapat diubah langsung melalui kode atau melalui menu GUI di dalam game:

| Variabel | Tipe | Default | Deskripsi |
| :--- | :---: | :---: | :--- |
| `SlowModeNearEgg` | `boolean` | `true` | Otomatis aktifkan Slow Mode dekat egg & matikan saat Hold E |
| `SlowModeEggDist` | `number` | `0` | Jarak (studs) ke egg (`0` = Default `28 studs`, `> 0` = Custom studs) |
| `SlowModeInBase` | `boolean` | `true` | Otomatis aktifkan Slow Mode setelah 2 detik di Base / Safe Zone |
| `AutoSteal` | `boolean` | `false` | Menyalakan/mematikan siklus pencurian kandang (berjalan kaki) |
| `AutoPlaceCage` | `boolean` | `true` | Otomatis menaruh kandang di slot kosong |
| `AutoOpenCage` | `boolean` | `true` | Otomatis membuka kandang saat timer selesai |
| `AutoTrain` | `boolean` | `false` | Berdiri otomatis di treadmill saat idle |
| `AutoUpgradeTreadmill` | `boolean` | `true` | Membeli level treadmill saat uang cukup |
| `AutoTapBoost` | `boolean` | `true` | Mengklik balon boost saat treadmill |
| `AutoBuyStalls` | `boolean` | `true` | Membeli slot kandang baru setiap 10 detik |
| `AutoTrail` | `boolean` | `true` | Membeli & memakai trail terbaik |
| `AutoEquipBest` | `boolean` | `true` | Memakai pet dengan pendapatan terbaik |
| `AutoClaimRewards` | `boolean` | `true` | Klaim daily, index, dan champion rewards |
| `AutoRebirth` | `boolean` | `false` | Melakukan rebirth otomatis |
| `Noclip` | `boolean` | `false` | Menembus dinding & rintangan |

---

## 📁 Struktur File di Repositori

```text
Steall/
├── FEATURES.md                       # Daftar fitur lengkap (file ini)
├── README.md                         # Petunjuk instalasi & eksekusi
├── Steal-A-Pet-And-Ride-It_clean.lua # Core logic (tanpa UI, ultra-ringan)
├── Steal-A-Pet-And-Ride-It_with_ui.lua # Script lengkap dengan menu GUI
├── Steal-A-Pet-And-Ride-It_raw.lua   # Script mentah asli (sebelum didekripsi)
└── extracted_strings.txt             # 1.408 data konstanta & nama remote asli
```

