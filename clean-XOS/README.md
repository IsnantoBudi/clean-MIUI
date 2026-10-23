# Modular Transsion XOS Debloater & Memory Monitor

Automated PowerShell debloating and real-time RAM diagnostic suite designed specifically for **Infinix Hot 9 Play (`X680` series)** running **Transsion XOS** (Dolphin / Cheetah on Android 9 / 10 / 10 Go Edition).

Non-root approach based on `pm uninstall -k --user 0`, with built-in instant rollback support (`cmd package install-existing`), 3-tier modular profiles, and an interactive RAM analyzer for MediaTek Helio A22/A25.

---

## English Quick Summary

### Highlights
- **Heavy Adware & Push Notification Kill**: Completely removes Phoenix Browser (`com.transsion.phoenix`), Palm Store (`com.transsion.palmstore`), and Aha Games (`com.transsion.ahagames`), stopping intrusive notification spam and background web views.
- **Transsion Telemetry Purge**: Eliminates background sales, usage reporting, and tracking daemons.
- **BatteryLab & Security Preservation**: Strictly protects `com.transsion.batterylab` and `com.transsion.zahooc` to ensure device charging logic, battery info, and core frameworks remain intact.
- **3-Tier Architecture**:
  - **Tier 1**: Core Adware, App Stores, & Factory Bloat (19 Packages)
  - **Tier 2**: XOS Secondary Utilities (Phone Master, File Manager X, Smart Panel) (10 Packages)
  - **Tier 3**: Google Heavy Background Services (Google App, TTS, Wellbeing) (5 Packages)
- **RAM Diagnostic Tool**: Dedicated `ram_monitor.ps1` optimized for low-RAM Helio A22/A25 devices (2GB-4GB).

### Quick Start
```powershell
# 1. Enter the clean-XOS folder
cd clean-XOS

# 2. Audit current package status on your Infinix
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -CheckStatus

# 3. Debloat Tier 1 (Adware, Palm Store, Phoenix Browser)
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Tier1

# 4. Monitor memory consumption
powershell -ExecutionPolicy Bypass -File .\ram_monitor.ps1 -Snapshot
```

---

## Dokumentasi Bahasa Indonesia

### 1. Latar Belakang & Masalah Performa di Infinix XOS

Infinix Hot 9 Play ditenagai oleh prosesor kelas hemat daya **MediaTek Helio A22 (Quad-Core) / Helio A25 (Octa-Core)** dengan konfigurasi RAM **2 GB (Android Go) hingga 3 GB / 4 GB**.

Tantangan utama yang menyebabkan Infinix Hot 9 Play terasa lambat, patah-patah (*lag*), dan cepat panas adalah ekosistem aplikasi bawaan Transsion XOS yang sangat agresif:
1. **Adware Latar Belakang (Phoenix Browser & Palm Store)**: Peramban Phoenix dan Palm Store secara aktif menjalankan *background webview*, mengunduh spanduk iklan, dan membanjiri bilah notifikasi dengan berita *clickbait*. Pada prosesor Helio A22/A25, aktivitas ini menghabiskan hingga 30-40% siklus CPU.
2. **Phone Master (Booster / Cleaner Palsu)**: Sering memunculkan peringatan *"RAM Penuh, Bersihkan Sekarang!"*, padahal proses pembersihan agresifnya justru memicu aplikasi Android untuk me-*restart* berulang kali, menguras baterai dan memori.
3. **Layanan Telemetri & Iklan Game (AHA Games, Scooper)**: Layanan game instan dan pembaca berita terus mengumpulkan data penjualan dan analitik.

Tool ini menerapkan **Non-Root ADB Debloating**:
- Paket dicopot hanya pada ruang profil pengguna (`--user 0`). Berkas sistem asli di partisi ROM tetap aman.
- Setiap aplikasi dapat dikembalikan kapan saja melalui perintah `cmd package install-existing <package_id>`.

---

### 2. Katalog Lengkap 34 Paket Debloat XOS

#### Tier 1: Adware, Toko & Bloatware Pabrik (19 Paket)
*Fokus: Menghentikan sumber spam iklan, push notifikasi berita, dan telemetri.*

| Nama Komponen | Package ID | Kategori | Alasan Pencopotan |
| :--- | :--- | :--- | :--- |
| Phoenix Browser | `com.transsion.phoenix` | Adware | **Sumber utama spam notifikasi dan iklan agresif di latar belakang** |
| Palm Store | `com.transsion.palmstore` | Store | Toko aplikasi Transsion dengan pop-up promosi pembaruan konstan |
| AHA Games | `com.transsion.ahagames` | Gaming Bloat | Portal game instan sarat iklan dan unduhan otomatis |
| AHA Games SDK | `com.ahagame.sdk.bussdk` | Gaming Bloat | Komponen pendukung AHA Games |
| Boomplay Music | `com.transsion.boomplayer` | Multimedia | Pemutar musik bawaan sarat iklan streaming online |
| Scooper News | `com.transsion.news.scooper` | News Feed | Agregator berita dengan spam notifikasi clickbait |
| XShare | `com.transsion.share` | Multimedia | Aplikasi transfer file dengan iklan layar penuh |
| Infinix Club / My Infinix | `com.transsion.infoto` | Community | Aplikasi forum komunitas Infinix yang memakan RAM |
| Transsion Community | `com.transsion.community` | Community | Layanan komunitas Transsion |
| YoParty | `com.transsion.yoparty` | Multimedia | Aplikasi sinkronisasi pesta musik yang jarang dipakai |
| Magic Show | `com.transsion.magicshow` | System Bloat | Efek animasi bawaan XOS yang memberatkan GPU |
| Sales Telemetry | `com.transsion.statisticalsales` | Telemetry | Pengumpul data statistik penjualan perangkat |
| Transsion Runner | `com.transsion.trun` | Telemetry | Daemon pelacak aktivitas latar belakang |
| Data Report | `com.transsion.datareport` | Telemetry | Layanan pengiriman laporan analitik ke server Transsion |
| Transsion Account Sync | `com.transsion.tabe` | Telemetry | Layanan sinkronisasi akun Transsion/Infinix |
| Facebook Services | `com.facebook.services` | Third-Party | Layanan latar belakang sistem bawaan Facebook |
| Facebook App Installer | `com.facebook.system` | Third-Party | Penginstal otomatis bawaan Facebook |
| Facebook App Manager | `com.facebook.appmanager` | Third-Party | Manajer pembaruan latar belakang Facebook |
| Facebook Stub | `com.facebook.katana` | Third-Party | Aplikasi stub pra-instalasi Facebook |

#### Tier 2: Utilitas Bawaan XOS (10 Paket - Opsional)
*Fokus: Aplikasi pembersih dan utilitas sekunder bawaan XOS.*

| Nama Komponen | Package ID | Kategori | Alasan Pencopotan |
| :--- | :--- | :--- | :--- |
| Phone Master | `com.transsion.phonemaster` | Utilities | **Booster/Cleaner yang sering mengirim spam "RAM Penuh"** |
| XOS File Manager | `com.transsion.filemanagerx` | Utilities | Pengelola file bawaan (aman dicopot jika memakai Files by Google) |
| XOS Notebook | `com.transsion.notebook` | Utilities | Catatan bawaan XOS |
| XOS Compass | `com.transsion.compass` | Utilities | Kompas bawaan |
| Scanning Recharger | `com.transsion.scanningrecharger` | Utilities | Pemindai voucher pulsa dan QR code |
| Magic Font | `com.transsion.magicfont` | Utilities | Pengubah gaya tulisan (font) sistem |
| Mobile Cloner (LetsSwitch) | `com.transsion.letswitch` | Utilities | Alat transfer data saat pindah perangkat |
| Smart Panel | `com.transsion.smartpanel` | Utilities | Pintasan bilah melayang di samping layar |
| XOS Weather | `com.transsion.weather` | Utilities | Layanan data cuaca bawaan |
| XOS User Manual | `com.transsion.manualguide` | Utilities | Buku panduan manual elektronik perangkat |

#### Tier 3: Layanan Google Non-Esensial (5 Paket)
*Fokus: Menghemat memori RAM fisik pada varian RAM 2GB/3GB.*

| Nama Komponen | Package ID | Kategori | Alasan Pencopotan |
| :--- | :--- | :--- | :--- |
| Google App (QuickSearchBox) | `com.google.android.googlequicksearchbox` | Google Heavy | Menghemat ~70 MB RAM (pencarian, feed, dan voice assist latar) |
| Google Text-to-Speech | `com.google.android.tts` | Google Heavy | Menghemat ~40 MB RAM (mesin pembaca teks Google) |
| Digital Wellbeing | `com.google.android.apps.wellbeing` | Google Heavy | Pelacak waktu layar yang aktif menggunakan CPU/RAM |
| Android Auto | `com.google.android.projection.gearhead` | Google Heavy | Integrasi mobil (tidak terpakai untuk HP harian biasa) |
| YouTube Music Stub | `com.google.android.apps.youtube.music` | Google Heavy | Aplikasi YouTube Music pra-instalasi |

---

### 3. Komponen Terproteksi (DILARANG DICOPOT)

Skrip `clean-XOS/debloat.ps1` telah dikonfigurasi secara ketat untuk memblokir pencopotan paket-paket berikut:
1. **`com.transsion.batterylab` (Battery Lab)**:
   > **PERINGATAN KERAS**: Komponen ini mengontrol menu baterai, mode hemat daya, dan batasan pengisian daya di aplikasi Pengaturan (*Settings*). Menghapus paket ini akan merusak dashboard baterai XOS dan memicu force-close menu baterai.
2. **`com.transsion.zahooc`**: Framework keamanan internal Transsion (alarm anti-maling dan perlindungan sistem).
3. **`com.transsion.plat.appupdate` / `com.transsion.ota`**: Pengelola pembaruan sistem OTA resmi.
4. **`com.transsion.XOSLauncher`**: Launcher bawaan sengaja dipertahankan agar layar utama tetap dapat digunakan normal tanpa perlu menginstal launcher pihak ketiga terlebih dahulu.

---

### 4. Panduan Eksekusi

#### Persiapan pada HP Infinix Hot 9 Play:
1. Buka **Pengaturan** -> **Tentang Ponsel** (*My Phone*).
2. Ketuk baris **Nomor Bentukan** (*Build Number*) sebanyak 7 kali berturut-turut hingga muncul pesan *"Anda sekarang adalah seorang pengembang!"*.
3. Buka **Pengaturan** -> **Sistem** -> **Opsi Pengembang** (*Developer Options*).
4. Aktifkan **Debugging USB** (*USB Debugging*).
5. Hubungkan HP ke PC via kabel USB, lalu pada pop-up layar HP centang *"Selalu izinkan dari komputer ini"* dan pilih **OK**.

#### Menjalankan Script Debloat:
Buka PowerShell dan masuk ke folder `clean-XOS`:

```powershell
cd clean-XOS

# Mode Menu Interaktif (Direkomendasikan)
powershell -ExecutionPolicy Bypass -File .\debloat.ps1

# Eksekusi Cepat via Flag CLI:
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -CheckStatus   # Audit status seluruh paket
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Tier1         # Debloat Tier 1 (Adware & Palm Store)
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Tier2         # Debloat Tier 2 (Utilitas XOS)
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Tier3         # Debloat Tier 3 (Google Heavy)
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -All           # Debloat Semua Tier (1-3)
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Restore       # Restore semua paket sistem
```

#### Menjalankan RAM Monitor:
```powershell
# Snapshot Penggunaan RAM & Top 15 Proses Helio A22/A25
powershell -ExecutionPolicy Bypass -File .\ram_monitor.ps1 -Snapshot

# Mode Live Monitoring Real-time (Refresh setiap 3 detik)
powershell -ExecutionPolicy Bypass -File .\ram_monitor.ps1 -Watch 3
```

---

### 5. Tips Optimasi Ekstra Khusus XOS Launcher

Selain debloat via ADB, lakukan 2 langkah mudah ini langsung di layar HP Infinix untuk membuang sisa iklan bawaan:
1. **Matikan Zero Screen (Feed Berita di Layar Paling Kiri)**:
   - Cubit layar utama (*Home Screen*) atau tekan area kosong hingga muncul menu pengaturan launcher.
   - Pilih **Setelan Menu** (*Menu Settings*) -> **Setelan Gerakan** atau **Tampilan**.
   - Matikan opsi **Layar Nol** (*Zero Screen*). Halaman berita beriklan di sebelah kiri home screen akan hilang total.
2. **Matikan "Aplikasi yang Disarankan" (Promoted Apps)**:
   - Pada menu setelan launcher, cari **Aplikasi yang Disarankan** (*Suggested / Promoted Apps*).
   - Nonaktifkan (*Turn off*). Ikon game/aplikasi rekomendasi yang belum terpasang tidak akan muncul lagi di app drawer.
3. **Percepat Skala Animasi**:
   - Di **Opsi Pengembang**, ubah `Skala animasi jendela`, `Skala animasi transisi`, dan `Skala durasi animator` ke **0.5x**.
