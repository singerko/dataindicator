#!/bin/bash

# install-android.sh
# Skript na inštaláciu APK na Android zariadenie alebo emulátor.

set -e  # Exit on any error

echo "📱 DataIndicator Android Installation Script"
echo "============================================"

# Farby pre output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funkcie
# Vypíše informačnú správu.
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Vypíše úspešnú správu.
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Vypíše varovanie.
log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Vypíše chybovú správu.
log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Skontroluje, či je ADB dostupné.
check_adb() {
    log_info "Kontrolujem ADB..."
    
    if ! command -v adb &> /dev/null; then
        log_error "ADB nie je nainštalované!"
        log_info "Nainštalujte Android SDK Platform Tools"
        log_info "Ubuntu/Debian: sudo apt install adb"
        log_info "macOS: brew install android-platform-tools"
        log_info "Windows: Stiahnite z developer.android.com"
        exit 1
    fi
    
    log_success "ADB nájdené"
}

# Vypíše pripojené zariadenia.
list_devices() {
    log_info "Pripojené zariadenia:"
    
    local devices=$(adb devices | grep -v "List of devices" | grep -v "^$" | wc -l)
    
    if [[ $devices -eq 0 ]]; then
        log_warning "Žiadne zariadenia pripojené"
        log_info "Pripojte Android zariadenie cez USB alebo spustite emulátor"
        return 1
    fi
    
    echo ""
    adb devices -l
    echo ""
    
    return 0
}

# Nájde vhodný APK súbor v build výstupoch.
find_apk() {
    local apk_path=""
    
    # Hľadanie v build adresári
    if [[ -f "app/build/outputs/apk/release/app-release-unsigned.apk" ]]; then
        apk_path="app/build/outputs/apk/release/app-release-unsigned.apk"
    elif [[ -f "app/build/outputs/apk/release/app-release.apk" ]]; then
        apk_path="app/build/outputs/apk/release/app-release.apk"
    elif [[ -f "app/build/outputs/apk/debug/app-debug.apk" ]]; then
        apk_path="app/build/outputs/apk/debug/app-debug.apk"
    else
        # Hľadanie akéhokoľvek APK
        apk_path=$(find . -name "*.apk" -type f | head -1)
    fi
    
    echo "$apk_path"
}

# Vypíše základné informácie o APK.
get_apk_info() {
    local apk_path="$1"
    
    if command -v aapt &> /dev/null; then
        log_info "Informácie o APK:"
        
        local package_name=$(aapt dump badging "$apk_path" | grep "package:" | sed "s/.*name='\\([^']*\\)'.*/\\1/")
        local version_name=$(aapt dump badging "$apk_path" | grep "versionName" | sed "s/.*versionName='\\([^']*\\)'.*/\\1/")
        local version_code=$(aapt dump badging "$apk_path" | grep "versionCode" | sed "s/.*versionCode='\\([^']*\\)'.*/\\1/")
        
        echo "  Package: $package_name"
        echo "  Version: $version_name ($version_code)"
        echo "  Súbor: $apk_path"
        echo "  Veľkosť: $(du -h "$apk_path" | cut -f1)"
        echo ""
    fi
}

# Skontroluje, či je aplikácia už nainštalovaná.
check_existing_app() {
    local package_name="$1"
    local device="$2"
    
    local device_arg=""
    if [[ -n "$device" ]]; then
        device_arg="-s $device"
    fi
    
    if adb $device_arg shell pm list packages | grep -q "$package_name"; then
        log_warning "Aplikácia $package_name je už nainštalovaná"
        return 0
    else
        log_info "Aplikácia $package_name nie je nainštalovaná"
        return 1
    fi
}

# Odinštaluje existujúcu aplikáciu.
uninstall_app() {
    local package_name="$1"
    local device="$2"
    
    local device_arg=""
    if [[ -n "$device" ]]; then
        device_arg="-s $device"
    fi
    
    log_info "Odinštalovávam existujúcu aplikáciu..."
    
    if adb $device_arg uninstall "$package_name" &>/dev/null; then
        log_success "Aplikácia odinštalovaná"
    else
        log_warning "Nepodarilo sa odinštalovať aplikáciu"
    fi
}

# Nainštaluje APK na zariadenie.
install_apk() {
    local apk_path="$1"
    local device="$2"
    local force_install="$3"
    
    local device_arg=""
    if [[ -n "$device" ]]; then
        device_arg="-s $device"
    fi
    
    # Získanie package name
    local package_name=""
    if command -v aapt &> /dev/null; then
        package_name=$(aapt dump badging "$apk_path" | grep "package:" | sed "s/.*name='\\([^']*\\)'.*/\\1/")
    fi
    
    # Kontrola existujúcej aplikácie
    if [[ -n "$package_name" && "$force_install" != "true" ]]; then
        if check_existing_app "$package_name" "$device"; then
            read -p "Chcete prepísať existujúcu aplikáciu? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                uninstall_app "$package_name" "$device"
            else
                log_info "Inštalácia zrušená"
                return 1
            fi
        fi
    elif [[ -n "$package_name" && "$force_install" == "true" ]]; then
        if check_existing_app "$package_name" "$device"; then
            uninstall_app "$package_name" "$device"
        fi
    fi
    
    log_info "Inštalujem APK..."
    
    if adb $device_arg install "$apk_path"; then
        log_success "APK úspešne nainštalované!"
        
        # Zobrazenie inštalačných informácií
        if [[ -n "$package_name" ]]; then
            log_success "Package: $package_name"
            
            # Pokus o spustenie aplikácie
            log_info "Spúšťam aplikáciu..."
            adb $device_arg shell monkey -p "$package_name" -c android.intent.category.LAUNCHER 1 &>/dev/null || true
        fi
        
        return 0
    else
        log_error "Chyba pri inštalácii APK!"
        return 1
    fi
}

# Spustenie aplikácie
launch_app() {
    local package_name="$1"
    local device="$2"
    
    if [[ -z "$package_name" ]]; then
        package_name="sk.dataindicator"
    fi
    
    local device_arg=""
    if [[ -n "$device" ]]; then
        device_arg="-s $device"
    fi
    
    log_info "Spúšťam aplikáciu $package_name..."
    
    # Pokus o spustenie hlavnej aktivity
    adb $device_arg shell am start -n "$package_name/.MainActivity" &>/dev/null || \
    adb $device_arg shell monkey -p "$package_name" -c android.intent.category.LAUNCHER 1 &>/dev/null || \
    log_warning "Nepodarilo sa automaticky spustiť aplikáciu"
}

# Zobrazenie logov
show_logs() {
    local package_name="$1"
    local device="$2"
    
    if [[ -z "$package_name" ]]; then
        package_name="sk.dataindicator"
    fi
    
    local device_arg=""
    if [[ -n "$device" ]]; then
        device_arg="-s $device"
    fi
    
    log_info "Zobrazujem logy aplikácie (Ctrl+C pre ukončenie)..."
    echo ""
    
    adb $device_arg logcat | grep "$package_name"
}

# Help
show_help() {
    echo "Použitie: $0 [OPTIONS] [APK_PATH]"
    echo ""
    echo "OPTIONS:"
    echo "  --device ID           Špecifikovať konkrétne zariadenie"
    echo "  --force              Prepisovať bez pýtania"
    echo "  --launch             Spustiť aplikáciu po inštalácii"
    echo "  --logs               Zobraziť logy po inštalácii"
    echo "  --list               Zobraziť len pripojené zariadenia"
    echo "  --uninstall          Odinštalovať aplikáciu"
    echo "  --help               Zobraziť túto nápovedu"
    echo ""
    echo "Príklady:"
    echo "  $0                                    # Nájsť a nainštalovať APK"
    echo "  $0 --force --launch                  # Prepisovať a spustiť"
    echo "  $0 --device emulator-5554             # Konkrétne zariadenie"
    echo "  $0 my-app.apk --launch               # Špecifický APK súbor"
    echo "  $0 --uninstall                       # Odinštalovať aplikáciu"
}

# Main execution
main() {
    local APK_PATH=""
    local DEVICE=""
    local FORCE_INSTALL=false
    local LAUNCH_APP=false
    local SHOW_LOGS=false
    local UNINSTALL_APP=false
    
    # Parse argumenty
    while [[ $# -gt 0 ]]; do
        case $1 in
            --device)
                DEVICE="$2"
                shift 2
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --launch)
                LAUNCH_APP=true
                shift
                ;;
            --logs)
                SHOW_LOGS=true
                shift
                ;;
            --list)
                check_adb
                list_devices
                exit 0
                ;;
            --uninstall)
                UNINSTALL_APP=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *.apk)
                APK_PATH="$1"
                shift
                ;;
            *)
                log_error "Neznámy argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    check_adb
    
    # Zobrazenie zariadení
    if ! list_devices; then
        exit 1
    fi
    
    # Odinštalovanie
    if [[ "$UNINSTALL_APP" == true ]]; then
        uninstall_app "sk.dataindicator" "$DEVICE"
        exit 0
    fi
    
    # Hľadanie APK ak nie je špecifikované
    if [[ -z "$APK_PATH" ]]; then
        APK_PATH=$(find_apk)
        if [[ -z "$APK_PATH" ]]; then
            log_error "APK súbor nenájdený!"
            log_info "Spustite najprv build: ./build-android.sh"
            exit 1
        fi
        log_info "Nájdený APK: $APK_PATH"
    elif [[ ! -f "$APK_PATH" ]]; then
        log_error "APK súbor neexistuje: $APK_PATH"
        exit 1
    fi
    
    # Informácie o APK
    get_apk_info "$APK_PATH"
    
    # Inštalácia
    if install_apk "$APK_PATH" "$DEVICE" "$FORCE_INSTALL"; then
        
        # Spustenie aplikácie
        if [[ "$LAUNCH_APP" == true ]]; then
            sleep 2
            launch_app "sk.dataindicator" "$DEVICE"
        fi
        
        # Zobrazenie logov
        if [[ "$SHOW_LOGS" == true ]]; then
            sleep 2
            show_logs "sk.dataindicator" "$DEVICE"
        fi
        
        log_success "Inštalácia dokončená!"
    else
        exit 1
    fi
}

# Spustenie main funkcie
main "$@"
