# Modular MIUI 14 Debloater & Memory Monitor

Automated PowerShell debloating and real-time RAM diagnostic suite designed specifically for **Redmi Note 10 4G (`sunny` / `mojito` — M2101K7AG)** running **MIUI Global 14.0.6** (Android 12).

Non-root approach based on `pm uninstall -k --user 0`, with built-in instant rollback support (`cmd package install-existing`), 3-tier modular profiles, and an interactive RAM analyzer.

---

## English Quick Summary

### Highlights
- **Zero-Risk Navigation Preservation**: Keeps `com.miui.home` protected to guarantee full-screen gestures and recent apps multitasking remain 100% functional without crashes.
- **Throttling Daemon Purge**: Eliminates `com.xiaomi.joyose` to unlock raw Snapdragon 678 performance and eliminate UI micro-stutters.
- **Ad & Telemetry Kill**: Uninstalls MSA, Analytics, MiuiDaemon, and all background Facebook services.
- **3-Tier Modular Structure**: Choose between Core Bloat (Tier 1), Secondary Utilities (Tier 2), and Heavy Google Services (Tier 3).
- **RAM Diagnostic Tool**: Dedicated `ram_monitor.ps1` with physical RAM progress bars, ZRAM tracking, and interactive force-stop capabilities.

### Quick Start
```powershell
# 1. Audit package status across all tiers
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -CheckStatus

# 2. Execute Tier 1 (Core Safe: Ads, Tracking, Joyose)
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Tier1

# 3. Check memory metrics before/after
powershell -ExecutionPolicy Bypass -File .\ram_monitor.ps1 -Snapshot
```

---

## Dokumentasi Bahasa Indonesia

### 1. Latar Belakang & Filosofi Arsitektur

Redmi Note 10 4G (Snapdragon 678) dengan varian RAM 4 GB sering kali mengalami kendala performa pada antarmuka MIUI 14 Global. Hal ini disebabkan oleh:
1. **Daemon Pembatas Performa**: Layanan `joyose` secara agresif membatasi *clock speed* CPU/GPU untuk mengontrol suhu, yang justru memicu *frame drop* dan *micro-stutter* saat berpindah aplikasi.
2. **Layanan Latar Belakang Non-Esensial**: Pelacak iklan (`msa`), telemetri (`analytics`, `daemon`), dan layanan mitra pabrik (Facebook Services, Amazon) terus mengonsumsi RAM fisik yang terbatas.
3. **Beban Kompresi Virtual RAM**: Fitur "Penambahan Memori" (ZRAM Swap) sebesar 2 GB membebani prosesor Snapdragon 678 dengan siklus kompresi/dekompresi halaman memori yang konstan.

Proyek ini terinspirasi dari arsitektur [CleanYourTV](https://github.com/Gathin23/cleanyourtv), menerapkan prinsip **Non-Root Debloating**:
- **Aman & Non-Destruktif**: Eksekusi `pm uninstall -k --user 0` hanya mencopot paket dari profil pengguna saat ini (User 0). Berkas APK asli di partisi `/system` tetap utuh.
- **Garansi Rollback 100%**: Setiap paket dapat dipulihkan kapan saja secara instan melalui perintah `cmd package install-existing <package_id>` tanpa memerlukan koneksi internet atau unduhan ulang.

---

### 2. Hasil Pengujian Benchmark Riil

Pengujian dilakukan secara langsung pada perangkat fisik **Redmi Note 10 4G (M2101K7AG, 4GB RAM)** yang menjalankan **MIUI Global 14.0.6 (Android 12)**.

#### A. Komparasi Konsumsi Memori (RAM)

| Parameter Metrik | Sebelum Debloat | Sesudah Debloat (Tier 1-3) | Delta Perubahan | Efek Fungsional |
| :--- | :---: | :---: | :---: | :--- |
| **RAM Fisik Terpakai** | 2.783,4 MB (77,7%) | 1.984,2 MB (55,4%) | **-799,2 MB (-22,3%)** | Beban memori OS berkurang drastis |
| **Sisa RAM Tersedia** | 800,6 MB (22,3%) | 1.599,8 MB (44,6%) | **+799,2 MB (+99,8%)** | **RAM kosong meningkat hampir 2x lipat** |
| **Beban Swap ZRAM** | 885,6 MB (39,3%) | 418,9 MB (18,6%) | **-466,7 MB (-52,7%)** | Siklus kompresi CPU berkurang separuh |
| **Jumlah Launcher Aktif** | 2 Launcher (~284 MB) | 1 Launcher (~137 MB) | **-147,0 MB** | Menghilangkan overhead launcher ganda |

#### B. Analisis Konsumsi Ruang Penyimpanan (Storage)

| Partisi Sistem | Karakteristik | Kondisi Sebelum Debloat | Kondisi Sesudah Debloat | Keterangan Teknis |
| :--- | :--- | :---: | :---: | :--- |
| **`/system` & `/product`** | Read-Only (ROM) | 2,9 GB (100%) | 2,9 GB (100%) | Partisi pabrik tetap utuh agar sistem stabil & bisa di-restore |
| **`/data` (Internal Storage)** | Read-Write (User) | Ruang terpakai tinggi | **Hemat ~1,2 GB – 2,5 GB** | Pembersihan otomatis update APK, Dalvik-cache, & database telemetri |

> **Catatan Teknis Storage**: Metode `pm uninstall -k --user 0` secara otomatis menghapus direktori data aplikasi, pembaruan versi APK pabrik di `/data/app`, serta kompilasi runtime *art/oat* di partisi `/data`. Hal ini menghasilkan ruang kosong tambahan yang signifikan tanpa menyentuh partisi sistem yang terkunci.

---

### 3. Katalog Lengkap Paket Debloat

#### Tier 1: Core Safe & Balanced (24 Paket)
*Fokus: Iklan sistem, telemetri privasi, daemon pembatas performa, dan bloatware pabrik.*

| Nama Komponen | Package ID | Kategori | Alasan Pencopotan |
| :--- | :--- | :--- | :--- |
| MIUI System Ads (MSA) | `com.miui.msa.global` | Ads & Telemetry | Penyedia injeksi iklan utama pada aplikasi bawaan MIUI |
| MIUI Analytics | `com.miui.analytics` | Ads & Telemetry | Pelacakan statistik dan aktivitas pengguna di latar belakang |
| MIUI Daemon | `com.miui.daemon` | Ads & Telemetry | Pengirim log telemetri perangkat ke server Xiaomi |
| Miui Bug Report | `com.miui.bugreport` | Ads & Telemetry | Daemon pengirim laporan crash otomatis yang memakan memori |
| Services & Feedback | `com.miui.miservice` | Ads & Telemetry | Layanan umpan balik sistem yang jarang digunakan |
| Joyose Daemon | `com.xiaomi.joyose` | Performance | **Pemicu thermal throttling agresif dan pembatas FPS** *(Catatan: Menonaktifkan lensa 0.6x di kamera bawaan MIUI; gunakan GCam LMC untuk ultrawide)* |
| GetApps (Mi Picks) | `com.xiaomi.mipicks` | Store | Toko aplikasi Xiaomi yang sarat notifikasi iklan promosi |
| Mi Pay Service | `com.xiaomi.payment` | Store & Bloat | Layanan pembayaran Xiaomi (tidak relevan di Indonesia) |
| Mi Pay Manager | `org.mipay.android.manager` | Store & Bloat | Komponen pendukung Mi Pay |
| Quick Apps Platform | `com.miui.hybrid` | Store & Bloat | Framework web mini tanpa instalasi, sering memuat iklan pop-up |
| Quick Apps Accessory | `com.miui.hybrid.accessory` | Store & Bloat | Sub-layanan pendukung Quick Apps |
| MIUI Yellow Pages | `com.miui.yellowpage` | Store & Bloat | Direktori nomor bisnis dan telemetri panggilan |
| Xiaomi Discover | `com.xiaomi.discover` | Store & Bloat | Saran aplikasi promosi di antarmuka sistem |
| Mi Video | `com.miui.videoplayer` | Multimedia | Pemutar video bawaan yang dipenuhi feed video online beriklan |
| Mi Music | `com.miui.player` | Multimedia | Pemutar musik bawaan sarat iklan streaming online |
| MIUI Cleaner | `com.miui.cleaner` | Multimedia | Pembersih cache berbasis CleanMaster SDK dengan push spam |
| Mi Health Global | `com.mi.healthglobal` | Multimedia | Pelacak kebugaran Xiaomi yang berjalan terus di background |
| ShareMe (Mi Drop) | `com.xiaomi.midrop` | Multimedia | Aplikasi transfer berkas bawaan dengan banner iklan |
| Facebook Services | `com.facebook.services` | Third-Party | Layanan background sistem bawaan pabrik milik Facebook |
| Facebook App Installer | `com.facebook.system` | Third-Party | Penginstal otomatis background bawaan pabrik milik Facebook |
| Facebook App Manager | `com.facebook.appmanager` | Third-Party | Pengelola pembaruan background bawaan pabrik milik Facebook |
| Amazon App Manager | `com.amazon.appmanager` | Third-Party | Pengelola aplikasi mitra komersial milik Amazon |
| Bookmark Provider | `com.android.bookmarkprovider` | Third-Party | Penyedia bookmark peramban legacy yang tidak digunakan |
| Partner Bookmarks | `com.android.providers.partnerbookmarks` | Third-Party | Bookmark komersial bawaan pabrik |

#### Tier 2: Extended Utilities & Google Non-Essential (10 Paket)
*Fokus: Aplikasi utilitas sekunder dan layanan Google yang jarang terpakai.*

| Nama Komponen | Package ID | Kategori | Alasan Pencopotan |
| :--- | :--- | :--- | :--- |
| MIUI Compass | `com.miui.compass` | Utilities | Kompas bawaan (jarang dibuka sehari-hari) |
| MIUI Notes | `com.miui.notes` | Utilities | Catatan bawaan (pengguna telah beralih ke app catatan lain) |
| MIUI Weather | `com.miui.weather2` | Utilities | Aplikasi dan widget data cuaca bawaan |
| MIUI Sound Recorder | `com.android.soundrecorder` | Utilities | Perekam suara bawaan |
| MIUI FM Radio | `com.miui.fm` | Utilities | Aplikasi radio FM analog |
| MIUI FM Service | `com.miui.fmservice` | Utilities | Layanan background radio FM |
| Qualcomm FM Radio | `com.caf.fmradio` | Utilities | Antarmuka chipset radio FM Qualcomm |
| Quick Ball | `com.miui.touchassistant` | Utilities | Bola pintasan navigasi melayang |
| Digital Wellbeing | `com.google.android.apps.wellbeing` | Google | **Pelacak screen time Google yang aktif memonitor CPU & RAM** |
| Android Auto | `com.google.android.projection.gearhead` | Google | Integrasi head-unit mobil (tidak terpakai jika tidak berkendara) |

#### Tier 3: Advanced RAM Optimization (3 Paket)
*Fokus: Mematikan proses Google berat dan biometrik sekunder.*

| Nama Komponen | Package ID | Kategori | Alasan Pencopotan |
| :--- | :--- | :--- | :--- |
| Google App (QuickSearchBox) | `com.google.android.googlequicksearchbox` | Google Heavy | Menghemat ~67 MB RAM (fitur search feed & Assistant latar) |
| Google Text-to-Speech | `com.google.android.tts` | Google Heavy | Menghemat ~43 MB RAM (mesin pembaca suara Google) |
| MIUI Face Unlock Service | `com.miui.face` | Biometrics | Menghemat ~46 MB RAM (pengguna memakai sensor sidik jari fisik) |

---

### 4. Komponen Kunci yang Terproteksi (Whitelisted)

Berikut adalah komponen yang **TIDAK DIBOLEHKAN** untuk dicopot demi menjaga integritas fungsional perangkat:
1. **`com.miui.home` (Peluncur Sistem)**:
   > **PENTING**: Pada arsitektur Android 12 MIUI 14, komponen *Quickstep* (layanan multitasking Recent Apps dan gestur layar penuh) terintegrasi langsung di dalam `com.miui.home`. Jika paket ini dicopot, tombol Recent Apps akan mati total dan sistem memicu crash `SecurityException: destroyInputConsumer requires INPUT_CONSUMER permission`. Oleh karena itu, launcher ini wajib dipertahankan.
2. **`com.miui.securitycenter` (Pusat Keamanan)**: Inti manajemen izin runtime, izin perizinan USB Debugging, dan manajer daya Android. Mencopot paket ini memicu *bootloop* seketika.
3. **`com.xiaomi.scanner` (Pemindai QR)**: Dipertahankan sesuai instruksi pengguna untuk kebutuhan scan dokumen dan barcode harian.
4. **`com.android.camera` & `com.miui.gallery`**: Dipertahankan untuk akses pemrosesan sensor kamera 48 MP dan video stabilizer bawaan.
5. **`com.android.chrome` & `com.brave.browser`**: Dipertahankan berdampingan sesuai preferensi browsing harian pengguna.

> **Catatan Arsitektur Kamera (Joyose vs Kamera Bawaan vs GCam LMC)**:
> - **Kamera Bawaan MIUI (`com.android.camera`)**: Memerlukan IPC handshake ke `com.xiaomi.joyose` untuk mengalokasikan parameter sensor aux saat beralih ke lensa ultrawide (*Sony IMX355*). Ketika Joyose dicopot, modul pemrosesan `VirtualCameraReprocessor` gagal memperoleh ID sensor yang valid (jatuh ke `device -1`) sehingga preview 0.6x mengalami freeze/crash.
> - **GCam LMC (`com.google.android.GoogleCameraEngR18F1`)**: Beroperasi via standar Android Camera2 API langsung ke Qualcomm CamX HAL tanpa melalui framework proprietary Xiaomi ataupun Joyose. Oleh karena itu, kamera ultrawide tetap bekerja 100% normal dan lancar di GCam meskipun Joyose di-debloat.
> - **Rekomendasi**: Jika Anda memprioritaskan performa gaming bebas *thermal throttling* agresif dengan mencopot Joyose, jadikan **GCam LMC** sebagai kamera utama untuk kebutuhan pengambilan foto ultrawide.

---

### 5. Panduan Penggunaan Script

#### A. Tool Debloat & Restore (`debloat.ps1`)

Jalankan perintah PowerShell berikut di dalam direktori repositori:

```powershell
# Mode Menu Interaktif
powershell -ExecutionPolicy Bypass -File .\debloat.ps1

# Eksekusi Cepat Berbasis Flag CLI:
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -CheckStatus   # Audit status seluruh paket
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Tier1         # Debloat Tier 1 saja
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Tier2         # Debloat Tier 2 saja
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Tier3         # Debloat Tier 3 saja
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -All           # Debloat seluruh Tier (1-3)
powershell -ExecutionPolicy Bypass -File .\debloat.ps1 -Restore       # Restore semua paket sistem
```

#### B. Tool Pemantau RAM & Analisa Proses (`ram_monitor.ps1`)

```powershell
# Snapshot Satu Kali (Metrik RAM Fisik, ZRAM, & Top 15 Proses):
powershell -ExecutionPolicy Bypass -File .\ram_monitor.ps1 -Snapshot

# Mode Interaktif (Lengkap dengan Opsi Force-Stop Proses Rakus RAM):
powershell -ExecutionPolicy Bypass -File .\ram_monitor.ps1

# Mode Live Monitor Real-time (Refresh setiap 3 detik):
powershell -ExecutionPolicy Bypass -File .\ram_monitor.ps1 -Watch 3

# Force-Stop Aplikasi Tertentu via Flag:
powershell -ExecutionPolicy Bypass -File .\ram_monitor.ps1 -Kill "com.instagram.android"
```

---

### 6. Rekomendasi Optimasi Tambahan

1. **Nonaktifkan "Penambahan Memori" (Memory Extension / Virtual RAM)**:
   - Buka **Settings** -> **Additional settings** (*Setelan tambahan*) -> **Memory extension** (*Penambahan memori*).
   - Matikan opsi ini, lalu pilih **Reboot**.
   - *Alasan Teknis*: Menghilangkan beban kompresi ZRAM pada CPU Snapdragon 678, membuat multitasking dan respon sentuhan jauh lebih konsisten tanpa *stutter*.
2. **Percepat Skala Animasi Antarmuka**:
   - Buka **Settings** -> **Additional settings** -> **Developer options**.
   - Ubah `Window animation scale`, `Transition animation scale`, dan `Animator duration scale` menjadi **`0.5x`**.
   - *Hasil*: Transisi buka-tutup aplikasi terasa dua kali lebih gesit di layar AMOLED 60Hz.

---

### 7. Penafian & Lisensi

- **Penafian (*Disclaimer*)**: Seluruh skrip ini telah diuji secara riil pada Redmi Note 10 4G MIUI Global 14.0.6. Penggunaan skrip ini sepenuhnya merupakan tanggung jawab pengguna. Pastikan selalu mematuhi petunjuk whitelist komponen.
- **Lisensi**: MIT License. Bebas digunakan, dimodifikasi, dan didistribusikan untuk keperluan personal maupun edukasi.
