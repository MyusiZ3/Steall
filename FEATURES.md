# 📋 Daftar Fitur Steall Hub (`Steal a Pet and Ride It`)

Dokumentasi lengkap mengenai fitur-fitur yang sudah diimplementasikan, dibersihkan dari telemetri, dan dioptimasi khusus untuk **Delta Executor** (Mobile & PC).

---

## 🚀 Ringkasan Fitur yang Sudah Aktif

### 1. 🥷 Auto Steal & Cage Management
* **Auto Steal Cage (Natural Walk):** Otomatis mendeteksi kandang (*cage*) terdekat yang ada di map, berjalan kaki ke lokasinya (`Humanoid:MoveTo`), mengeksekusi `ProximityPrompt`, lalu berjalan kembali membawa kandang ke plot milik Anda (tanpa teleportasi).
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

