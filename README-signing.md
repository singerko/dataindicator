# 🔐 APK Podpisovanie (apksigner)

## ⚠️ DÔLEŽITÉ: Zipalign je už zahrnuté v build proces

APK súbory generované cez `./gradlew :app:assembleRelease` sú už automaticky zipalign zarovnané vďaka `zipAlignEnabled = true` v `app/build.gradle`. Skript `sign.sh` **iba podpisuje** už zarovnané APK pomocou `apksigner`.

## Požiadavky

- **Java:** `/usr/lib/jvm/java-17-zulu-openjdk-jdk`
- **APKSigner:** `/home/singer-nike/android-sdk/build-tools/34.0.0/apksigner`

## Vytvorenie keystore súboru

```bash
keytool -genkey -v -keystore my-release-key.keystore -alias mykey -keyalg RSA -keysize 2048 -validity 10000
```

## Použitie sign.sh skriptu

### Základné použitie:
```bash
./sign.sh
```

### S vlastnými parametrami:
```bash
./sign.sh [cesta-k-apk] [keystore] [alias]
```

### Príklady:
```bash
# Predvolené hodnoty
./sign.sh

# Vlastné APK
./sign.sh app/build/outputs/apk/release/app-release-unsigned.apk

# Vlastný keystore a alias
./sign.sh app/build/outputs/apk/release/app-release-unsigned.apk my-key.keystore myalias
```

## Workflow

1. **Build APK (už zipalign zarovnané):**
   ```bash
   podman run --rm -v $(pwd):/app -w /app android-gradle-builder
   ```

2. **Podpíš APK (na tvojom počítači):**
   ```bash
   ./sign.sh
   ```

3. **Inštaluj APK:**
   ```bash
   adb install app/build/outputs/apk/release/app-release-unsigned-signed.apk
   ```

## Výstupné súbory

- **Input:** `app-release-unsigned.apk` (z Gradle buildu, už zipalign zarovnané)
- **Output:** `app-release-unsigned-signed.apk` (podpísané pomocou apksigner)

## Výhody apksigner vs jarsigner

- ✅ **Moderný** - Google odporúča apksigner pre Android
- ✅ **V4 signing scheme** - podpora najnovších Android verzií
- ✅ **Lepšia verifikácia** - komplexnejšie kontroly
- ✅ **Play Store ready** - optimalizované pre Google Play

## Bezpečnosť

- Heslá sa zadávajú interaktívne (nie sú uložené v súboroch)
- Heslá sa vyčistia z pamäte po použití
- Používa oficálny Android apksigner nástroj

## Čo skript nerobí

- ❌ **Zipalign** - už je v Gradle buildu
- ❌ **Optimalizácia** - už je v Gradle buildu  
- ✅ **Iba podpisovanie** - pomocou apksigner
