#!/bin/bash

# sign.sh
# Skript na podpisovanie už zarovnaných Android APK súborov cez apksigner.
# APK je už zipalign zarovnané z Gradle buildu (zipAlignEnabled = true)
# Použitie: ./sign.sh [cesta-k-apk] [keystore] [alias]

set -e

# Cesty k nástrojom
export JAVA_HOME="/usr/lib/jvm/java-17-zulu-openjdk-jdk"
APKSIGNER="/home/singer-nike/android-sdk/build-tools/34.0.0/apksigner"

# Farby pre výstup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funkcie
# Vypíše informačnú správu.
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Vypíše úspešnú správu.
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Vypíše varovanie.
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vypíše chybovú správu.
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Predvolené hodnoty
DEFAULT_APK="app/build/outputs/apk/release/app-release-unsigned.apk"
DEFAULT_KEYSTORE="my-release-key.keystore"
DEFAULT_ALIAS="mykey"

# Argumenty
APK_PATH=${1:-$DEFAULT_APK}
KEYSTORE_PATH=${2:-$DEFAULT_KEYSTORE}
KEY_ALIAS=${3:-$DEFAULT_ALIAS}

print_info "=== Android APK Signing Script (apksigner) ==="
print_info "APK súbor: $APK_PATH"
print_info "Keystore: $KEYSTORE_PATH"
print_info "Alias: $KEY_ALIAS"
print_info "Java Home: $JAVA_HOME"
print_info "APKSigner: $APKSIGNER"
print_warning "POZNÁMKA: APK je už zipalign zarovnané z Gradle buildu"
echo

# Kontrola existencie APK súboru
if [[ ! -f "$APK_PATH" ]]; then
    print_error "APK súbor nenájdený: $APK_PATH"
    print_info "Najprv spustite: ./gradlew :app:assembleRelease"
    exit 1
fi

# Kontrola existencie keystore
if [[ ! -f "$KEYSTORE_PATH" ]]; then
    print_error "Keystore súbor nenájdený: $KEYSTORE_PATH"
    print_info "Vytvorte keystore pomocou:"
    print_info "keytool -genkey -v -keystore $KEYSTORE_PATH -alias $KEY_ALIAS -keyalg RSA -keysize 2048 -validity 10000"
    exit 1
fi

# Kontrola Java Home
if [[ ! -d "$JAVA_HOME" ]]; then
    print_error "JAVA_HOME adresár nenájdený: $JAVA_HOME"
    exit 1
fi

# Kontrola apksigner
if [[ ! -f "$APKSIGNER" ]]; then
    print_error "apksigner nenájdený: $APKSIGNER"
    print_info "Skontrolujte cestu k Android SDK build-tools"
    exit 1
fi

# Generovanie názvu výstupného súboru
APK_DIR=$(dirname "$APK_PATH")
APK_NAME=$(basename "$APK_PATH" .apk)
SIGNED_APK="$APK_DIR/${APK_NAME}-signed.apk"

print_info "Výstupný súbor: $SIGNED_APK"
echo

# Podpisovanie APK pomocou apksigner
print_info "Podpisovanie APK súboru pomocou apksigner..."
echo -n "Zadajte heslo pre keystore: "
read -s KEYSTORE_PASSWORD
echo
echo -n "Zadajte heslo pre kľúč ($KEY_ALIAS): "
read -s KEY_PASSWORD
echo
echo

if "$APKSIGNER" sign \
    --ks "$KEYSTORE_PATH" \
    --ks-key-alias "$KEY_ALIAS" \
    --ks-pass pass:"$KEYSTORE_PASSWORD" \
    --key-pass pass:"$KEY_PASSWORD" \
    --out "$SIGNED_APK" \
    "$APK_PATH"; then
    print_success "APK úspešne podpísané pomocou apksigner"
else
    print_error "Chyba pri podpisovaní APK pomocou apksigner"
    exit 1
fi

# Verifikácia podpisu pomocou apksigner
print_info "Verifikácia podpisu pomocou apksigner..."
if "$APKSIGNER" verify --verbose "$SIGNED_APK"; then
    print_success "Podpis je platný"
else
    print_error "Podpis nie je platný"
    exit 1
fi

# Finálne informácie
echo
print_success "=== HOTOVO ==="
print_success "Podpísané APK: $SIGNED_APK"

# Zobrazenie informácií о APK
APK_SIZE=$(du -h "$SIGNED_APK" | cut -f1)
print_info "Veľkosť APK: $APK_SIZE"

print_info "Na inštaláciu použite:"
print_info "  adb install \"$SIGNED_APK\""
echo

print_warning "DÔLEŽITÉ: APK je už zipalign zarovnané z Gradle buildu (zipAlignEnabled=true)"

# Vyčistenie hesiel z pamäte
unset KEYSTORE_PASSWORD
unset KEY_PASSWORD
