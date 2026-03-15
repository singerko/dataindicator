# DataIndicator iOS

iOS verzia aplikácie pre monitorovanie typu internetového pripojenia s vizuálnym indikátorom.

## ✨ Funkcie

- 🟢 **WiFi pripojenie** - zelený indikátor
- 🔴 **Mobilné dáta** - červený indikátor  
- ⚫ **Bez internetu** - sivý indikátor
- ⚙️ **Konfigurovateľné nastavenia** - farby, veľkosť, pozícia
- 🔄 **Auto-štart** (iOS obmedzenia)

## 📱 Požiadavky

- iOS 15.0+
- Xcode 15.0+
- Swift 5.0+

## 🏗️ Inštalácia a build

### Xcode
1. Otvorte `DataIndicator.xcodeproj` v Xcode
2. Vyberte target device/simulator
3. Stlačte Cmd+R pre spustenie

### Command Line
```bash
# Build pre simulator
xcodebuild -project DataIndicator.xcodeproj -scheme DataIndicator -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build pre device (vyžaduje Developer Account)
xcodebuild -project DataIndicator.xcodeproj -scheme DataIndicator -destination 'platform=iOS,name=YOUR_DEVICE' build
```

## 🔧 Architektúra

| Súbor | Účel |
|-------|------|
| `DataIndicatorApp.swift` | Hlavná aplikácia, vstupný bod |
| `ContentView.swift` | Hlavné UI s ovládaním |
| `NetworkMonitor.swift` | Monitorovanie siete a overlay management |
| `OverlayView.swift` | Vizuálny indikátor overlay |
| `SettingsView.swift` | Konfigurácia nastavení |

## ⚠️ iOS Obmedzenia

Na rozdiel od Androidu, iOS má prísnejšie obmedzenia:

1. **Overlay nad inými aplikáciami** - iOS neumožňuje overlay nad systémovými aplikáciami
2. **Background execution** - iOS pozastavuje aplikácie v pozadí
3. **Auto-štart** - iOS neumožňuje automatické spustenie po reštarte

## 🎨 Nastavenia

- **Farby indikátora** - RGB hex kódy
- **Rozmery** - výška (1-20px), šírka (10-100%)
- **Pozícia** - vľavo, stred, vpravo
- **Auto-štart** - obmedzený iOS pravidlami

## 🚀 Deployment

### TestFlight (Beta)
1. Archive v Xcode (Product → Archive)
2. Upload do App Store Connect
3. Distribute cez TestFlight

### App Store
1. Získajte Apple Developer Account
2. Vytvorte App ID v Developer Portal
3. Configure Provisioning Profiles
4. Archive a upload cez Xcode

## 📦 Výstup

Výsledok: **DataIndicator.app**  
Veľkosť: ~5-10MB  
Podpora: iOS 15.0 - 18.x+  