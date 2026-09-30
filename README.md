# VapeCare (iOS Native)

A personal vape device management and maintenance app built natively for iOS using **SwiftUI** and **SwiftData** (iOS 17+). Supports persistent offline storage on-device and cloud database synchronization via **Turso (libSQL)**.

---

## Features

- **Battery Management**: Track charging cycles, purchase history, and battery health degradation indicators.
- **E-Liquid Management**: Monitor remaining bottle volume, nicotine strength, and flavor history.
- **Tank & Coil Management**: Real-time coil and cotton lifespan tracking with component replacement logs.
- **Turso Database Synchronization**: Two-way data synchronization (push and pull) via the Turso REST API, configurable via runtime config or the in-app settings UI.
- **Local Notifications**: Automated scheduled reminders via `UNUserNotificationCenter` when component lifespan thresholds are reached.

---

## Technical Specifications

- **Platform & Target OS**: iOS 17.0+
- **Language & Framework**: Swift, SwiftUI
- **Local Storage**: SwiftData with persistent store explicitly directed to the `Documents Directory` (preserves data across Xcode rebuilds and re-signing).
- **Cloud Database**: Turso / libSQL HTTP API
- **Notifications**: UserNotifications Framework (`UNUserNotificationCenter`)
- **Project Generator**: [XcodeGen](https://github.com/yonaskolb/XcodeGen)

---

## Installation & Setup

### 1. Generate Project via XcodeGen
Ensure `xcodegen` is installed on your Mac (`brew install xcodegen`). Run the following command in the root folder:

```bash
xcodegen generate
```

The `VapeCare.xcodeproj` project file will be generated automatically.

### 2. Environment Configuration (Turso Credentials)
Create a `Config.xcconfig` file or configure credentials directly in the app settings:

```text
TURSO_DATABASE_URL = https://<your-database-name>.turso.io
TURSO_AUTH_TOKEN = <your-turso-auth-token>
```

### 3. Build & Run the App

Open in Xcode:
```bash
open VapeCare.xcodeproj
```

Build via Terminal (iOS Simulator):
```bash
xcodebuild -project VapeCare.xcodeproj -scheme VapeCare -destination "generic/platform=iOS Simulator" clean build
```

---

## Directory Structure

```text
.
├── project.yml                   # XcodeGen configuration (Single Source of Truth)
├── VapeCare.xcodeproj            # Generated project via XcodeGen
└── VapeCare/
    ├── App/                      # App entry point & container setup
    ├── Models/                   # SwiftData entities & health calculation logic
    ├── Repositories/             # Data abstraction for local & cloud sync
    ├── Services/                 # Turso API client & Local Notification Manager
    ├── Views/                    # Main views & dashboard layouts
    └── Widgets/                  # Reusable UI cards, dialogs, and progress bars
```

---

## Git Commit Message Convention

Format used for commit messages:

```text
[TYPE] (SCOPE) Description of changes
```

Examples:
- `[FEAT] (TURSO) Add libSQL HTTP sync integration`
- `[FIX] (SWIFTDATA) Fix persistent store migration issue`
- `[CHORE] (DOCS) Update README file`