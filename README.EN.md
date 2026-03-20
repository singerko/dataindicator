# DataIndicator

While travelling, I needed a way to tell whether I was on WiFi or using mobile data — because it happened to me more than once that while roaming I assumed I was on WiFi, but it dropped and my phone silently switched to data. The color indicator doesn't interfere with normal phone usage or even full screen video watching. If the WiFi connection drops while watching a video, the user is instantly notified.

Android app that permanently displays a thin colored network indicator bar above all other apps.

## 🚀 Key Features

* **Always-on overlay:** The indicator is visible even above other apps.
* **Real-time connection status:** Wi‑Fi / mobile data / no internet.
* **Appearance customization:** Colors, height, width and alignment of the bar.
* **Auto-start on boot:** The app can resume monitoring after a device restart.
* **Easy deployment:** Build, sign and install via `Makefile`.

## 📱 Screenshots

| Main Screen | Configuration | Launcher |
| :---: | :---: | :---: |
| ![Main Screen](docs/screenshots/main-screen.png) | ![App Config](docs/screenshots/app-config.png) | ![Launcher](docs/screenshots/launcher-home.png) |

| VLC Fullscreen 1 | VLC Fullscreen 2 | Vertical Video |
| :---: | :---: | :---: |
| ![VLC Overlay 1](docs/screenshots/vlc-overlay-1.png) | ![VLC Overlay 2](docs/screenshots/vlc-overlay-2.png) | ![VLC Overlay Vertical](docs/screenshots/vlc-overlay-vertical.png) |

## 🛠️ Technologies

* **Android Native:** Kotlin, Android SDK
* **Build System:** Gradle + Makefile
* **Containerized build:** Podman
* **Deploy:** ADB

## 📦 Installation and Setup

### Prerequisites
* Linux (tested)
* Podman
* Make
* Android SDK + ADB
* Android device with USB debugging enabled (for deploy)

### Commands

1. **Build APK**
```bash
make rebuild-apk
```

2. **Sign APK**
```bash
make sign-apk
```

3. **Install to device**
```bash
make install-apk
```

4. **Full deploy (build + sign + install)**
```bash
make deploy
```

## 🔐 Permissions

The app uses:
* `SYSTEM_ALERT_WINDOW` — draw overlay above other apps
* `FOREGROUND_SERVICE` — run as a foreground service
* `FOREGROUND_SERVICE_SPECIAL_USE` — special-use foreground service category
* `ACCESS_NETWORK_STATE` — detect current network connection type
* `INTERNET` — verify actual internet connectivity
* `POST_NOTIFICATIONS` — show foreground service notification
* `RECEIVE_BOOT_COMPLETED` — auto-start after device reboot

## 🤖 AI Note

This project was generated and iteratively updated with the help of AI.

## 📝 License

The project is freely usable.

Anyone may use, modify and redistribute the code without restrictions.
