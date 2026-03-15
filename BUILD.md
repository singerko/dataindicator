# 🔨 Build Guide - DataIndicator

Kompletný návod na buildovanie Android a iOS verzií aplikácie DataIndicator.

## 📋 Obsah

- [Android Build](#android-build)
- [iOS Build](#ios-build)
- [Universal Build](#universal-build)
- [Inštalácia](#inštalácia)
- [Troubleshooting](#troubleshooting)

## 🤖 Android Build

### Requirements
- **Linux/macOS/Windows** - podporované všetky platformy
- **Docker/Podman** - pre kontajnerový build
- **Gradle** - pre lokálny build (voliteľné)

### Quick Start
```bash
# Základný build
./build-android.sh

# Clean build s podpisovaním
./build-android.sh --clean --sign

# Lokálny build bez containera
./build-android.sh --no-container
```

### Parametry
| Parameter | Popis |
|-----------|-------|
| `--clean` | Vyčistiť build súbory pred buildovaním |
| `--sign` | Podpísať APK po buildovaní |
| `--no-container` | Použiť lokálny Gradle namiesto Docker/Podman |
| `--help` | Zobraziť nápovedu |

### Výstup
- **APK súbor:** `app/build/outputs/apk/release/app-release-unsigned.apk`
- **Veľkosť:** ~2-4MB
- **Log súbor:** `build.log`

## 🍎 iOS Build

### Requirements
- **macOS** - povinné pre iOS build
- **Xcode 15.0+** - s iOS SDK
- **iOS 15.0+** - target verzia

### Quick Start
```bash
# Build pre simulator
./build-ios.sh --simulator

# Build pre zariadenie
./build-ios.sh --device

# Archive pre distribution
./build-ios.sh --archive
```

### Parametry
| Parameter | Popis |
|-----------|-------|
| `--simulator [NAME]` | Build pre iOS Simulator |
| `--device [NAME]` | Build pre fyzické zariadenie |
| `--archive` | Vytvor archive pre App Store |
| `--install [NAME]` | Nainštaluj na simulator po builde |
| `--clean` | Vyčisti build súbory |
| `--list` | Zobraz dostupné destinations |
| `--help` | Zobraz nápovedu |

### Environment Variables
```bash
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"  # Pre device/archive build
```

### Výstup
- **APP súbor:** `ios/build/Build/Products/Release-iphoneos/DataIndicator.app`
- **IPA súbor:** `ios/build/export/DataIndicator.ipa` (pri archive)
- **Log súbor:** `ios_build.log`

## 🚀 Universal Build

Builduje Android + iOS naraz (ak je macOS).

### Quick Start
```bash
# Build oboch platforiem
./build-all.sh

# Clean build s pokročilými options
./build-all.sh --clean --sign --archive

# Len Android
./build-all.sh --android-only --clean

# Len iOS
./build-all.sh --ios-only --simulator "iPhone 15"
```

### Parametry
| Parameter | Popis |
|-----------|-------|
| `--android-only` | Build len Android |
| `--ios-only` | Build len iOS |
| `--clean` | Clean build pre oba projekty |
| `--sign` | Podpísať Android APK |
| `--archive` | Vytvoriť iOS archive |
| `--simulator [NAME]` | iOS simulator build |
| `--device` | iOS device build |
| `--install` | Nainštalovať iOS na simulator |

## 📱 Inštalácia Android

### Requirements
- **ADB** - Android Debug Bridge
- **USB zariadenie** alebo **Android emulátor**

### Quick Start
```bash
# Automatická inštalácia
./install-android.sh

# Force inštalácia a spustenie
./install-android.sh --force --launch

# Špecifické zariadenie
./install-android.sh --device emulator-5554

# Zobrazenie logov
./install-android.sh --logs
```

### Parametry
| Parameter | Popis |
|-----------|-------|
| `--device ID` | Špecifikovať zariadenie |
| `--force` | Prepisovať bez pýtania |
| `--launch` | Spustiť po inštalácii |
| `--logs` | Zobraziť logy |
| `--list` | Zobraziť pripojené zariadenia |
| `--uninstall` | Odinštalovať aplikáciu |

## 🔧 Detailné Build Konfigurácie

### Android Gradle Build
```bash
# Rôzne build typy
./gradlew :app:assembleDebug          # Debug APK
./gradlew :app:assembleRelease        # Release APK
./gradlew :app:bundleRelease          # Android App Bundle

# Čistenie
./gradlew clean

# Testovanie
./gradlew :app:test
./gradlew :app:connectedAndroidTest
```

### iOS Xcode Build
```bash
# Rôzne configurations
xcodebuild -configuration Debug
xcodebuild -configuration Release

# Rôzne destinations
xcodebuild -destination 'platform=iOS Simulator,name=iPhone 15'
xcodebuild -destination 'platform=iOS,name=My iPhone'
xcodebuild -destination 'generic/platform=iOS'

# Archive
xcodebuild archive -archivePath DataIndicator.xcarchive
```

## 📦 Build Artefakty

### Android
```
app/build/
├── outputs/
│   ├── apk/
│   │   ├── debug/
│   │   │   └── app-debug.apk
│   │   └── release/
│   │       └── app-release-unsigned.apk
│   └── bundle/
│       └── release/
│           └── app-release.aab
└── build.log
```

### iOS
```
ios/build/
├── Build/
│   └── Products/
│       ├── Debug-iphonesimulator/
│       │   └── DataIndicator.app
│       └── Release-iphoneos/
│           └── DataIndicator.app
├── export/
│   └── DataIndicator.ipa
└── DataIndicator.xcarchive
```

## 🐛 Troubleshooting

### Android Issues

#### Container Build Fails
```bash
# Skúsiť Podman namiesto Docker
podman --version

# Skúsiť lokálny build
./build-android.sh --no-container
```

#### Gradle Issues
```bash
# Aktualizovať Gradle Wrapper
./gradlew wrapper --gradle-version 8.5

# Vyčistiť cache
rm -rf ~/.gradle/caches/
```

#### Permission Denied
```bash
chmod +x gradlew
chmod +x build-android.sh
```

### iOS Issues

#### No Developer Account
```bash
# Nastaviť development team
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"

# Alebo build len pre simulator
./build-ios.sh --simulator
```

#### Xcode Command Line Tools
```bash
xcode-select --install
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

#### Simulator Not Found
```bash
# Zobraziť dostupné simulátory
./build-ios.sh --list

# Alebo príkaz xcrun
xcrun simctl list devices iOS
```

### Universal Build Issues

#### Platform Detection
```bash
# Skontrolovať platform
echo $OSTYPE

# Manuálne špecifikovať
./build-all.sh --android-only  # Pre non-macOS
```

### ADB Issues

#### Device Not Found
```bash
# Povoliť USB debugging
adb devices

# Reštartovať ADB server
adb kill-server
adb start-server
```

#### Permission Denied
```bash
# Pridať udev rules (Linux)
sudo usermod -a -G plugdev $USER

# Alebo použiť sudo
sudo adb install app.apk
```

## 🎯 Best Practices

### Development Workflow
1. **Clean build** pri významných zmenách
2. **Test na simulátore/emulátore** pred device buildovaniem
3. **Podpisovať APK** pre production build
4. **Archive iOS** pre App Store submission

### CI/CD Integration
```yaml
# GitHub Actions example
- name: Build Android
  run: ./build-android.sh --clean

- name: Build iOS
  run: ./build-ios.sh --simulator
  if: runner.os == 'macOS'

- name: Upload artifacts
  uses: actions/upload-artifact@v3
  with:
    name: app-builds
    path: |
      app/build/outputs/apk/release/*.apk
      ios/build/export/*.ipa
```

### Performance Tips
- Používať **Gradle Build Cache**
- Používať **parallel builds**: `./gradlew --parallel`
- Prekompilovať **dependencies** len pri potrebe
- Používať **incremental builds**

## 📞 Support

Pri problémoch s buildovaním:
1. Skontrolujte **build logy** (`build.log`, `ios_build.log`)
2. Overte **requirements** pre vašu platformu
3. Použite `--help` parameter pre detailné informácie
4. Skúste **clean build** s `--clean` parametrom
