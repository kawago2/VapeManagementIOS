# VapeCare Tracker (Native iOS App)

Aplikasi native iOS offline-first untuk melacak masa pakai komponen vape (Kapas, Koil, dan Baterai) menggunakan **SwiftUI** dan **SwiftData** (iOS 17+).

---

## 📁 Struktur Direktori Proyek

```text
.
├── project.yml                        # Konfigurasi XcodeGen (Single Source of Truth)
├── VapeCareTracker.xcodeproj          # Generated project via XcodeGen
├── README.md                          # Dokumentasi setup
└── VapeCareTracker/
    ├── App/
    │   └── VapeCareTrackerApp.swift   # Entry point & persistent container setup (Documents Directory)
    ├── Models/
    │   └── VapeModel.swift            # SwiftData @Model VapeSetup & Health Calculator logic
    ├── Services/
    │   └── NotificationManager.swift  # Local Notification handler & background reminders
    └── Views/
        ├── DashboardView.swift        # Dashboard utama & ringkasan status perangkat
        ├── ComponentCardView.swift    # Komponen Card dinamis, Progress Bar & Quick Action
        └── EditDatesView.swift        # Modal form ubah tanggal & batas maksimal hari
```

---

## 🛠️ XcodeGen Setup

Proyek ini menggunakan [XcodeGen](https://github.com/yonaskolb/XcodeGen) sehingga Anda tidak perlu commit file `.xcodeproj` ke Git repository.

### 1. Generate Project File

Jalankan perintah berikut di root folder:

```bash
xcodegen generate
```

Project `VapeCareTracker.xcodeproj` akan otomatis terbuat.

### 2. Build via Terminal (Opsional)

```bash
xcodebuild -project VapeCareTracker.xcodeproj -scheme VapeCareTracker -destination "generic/platform=iOS Simulator" clean build
```

Atau buka langsung file project di Xcode:
```bash
open VapeCareTracker.xcodeproj
```

---

## ⚙️ Detail Konfigurasi

- **Target OS**: iOS 17.0+
- **Bundle ID**: `com.local.vapecare`
- **Penyimpanan Lokal**: SwiftData dengan `.store` diarahkan eksplisit ke `Documents directory` (aman dari data wipe saat re-sign atau build ulang via Xcode).
- **Notifikasi**: `UNUserNotificationCenter` terjadwal lokal jam 09:00 pagi saat hari batas pemakaian tiba.
