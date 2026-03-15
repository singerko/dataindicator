#!/bin/bash

# build-ios.sh
# Skript na buildovanie iOS aplikácie pomocou xcodebuild.

set -e  # Exit on any error

echo "🍎 DataIndicator iOS Build Script"
echo "================================="

# Farby pre output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Konfigurácia
PROJECT_NAME="DataIndicator"
PROJECT_PATH="ios/DataIndicator.xcodeproj"
SCHEME="DataIndicator"
BUILD_DIR="ios/build"

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

# Skontroluje požiadavky (macOS, Xcode, project súbory).
check_requirements() {
    log_info "Kontrolujem requirements..."
    
    # Kontrola macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "iOS build je možný len na macOS!"
        log_info "Pre Linux/Windows použite Docker s macOS kontainerom alebo GitHub Actions"
        exit 1
    fi
    
    # Kontrola Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode nie je nainštalovaný!"
        log_info "Nainštalujte Xcode z App Store"
        exit 1
    fi
    
    # Kontrola projekt súborov
    if [[ ! -f "$PROJECT_PATH/project.pbxproj" ]]; then
        log_error "iOS projekt nenájdený na: $PROJECT_PATH"
        exit 1
    fi
    
    log_success "Všetky requirements splnené"
}

# Zobrazí dostupné simulátory a zariadenia.
list_destinations() {
    log_info "Dostupné build destinations:"
    echo ""
    
    log_info "📱 iOS Simulátory:"
    xcrun simctl list devices iOS | grep -E "iPhone|iPad" | grep "Booted\|Shutdown" | head -5
    echo ""
    
    log_info "📱 Pripojené zariadenia:"
    xcrun xctrace list devices | grep -E "iPhone|iPad" | grep -v "Simulator" | head -3
    echo ""
}

# Vyčistí build výstupy a Xcode DerivedData.
clean_build() {
    log_info "Čistím predchádzajúce buildy..."
    
    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
        log_success "Build adresár vyčistený"
    fi
    
    # Clean Xcode derived data
    rm -rf ~/Library/Developer/Xcode/DerivedData/$PROJECT_NAME-*
    log_success "Xcode DerivedData vyčistené"
}

# Build pre iOS simulátor.
build_simulator() {
    local simulator_name="$1"
    if [[ -z "$simulator_name" ]]; then
        simulator_name="iPhone 15"
    fi
    
    log_info "Buildjem pre simulator: $simulator_name"
    
    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$simulator_name" \
        -derivedDataPath "$BUILD_DIR" \
        build 2>&1 | tee ios_build.log
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        log_success "Simulator build dokončený"
    else
        log_error "Chyba pri simulator builde!"
        exit 1
    fi
}

# Build pre fyzické zariadenie.
build_device() {
    local device_name="$1"
    
    log_info "Buildjem pre zariadenie..."
    
    # Kontrola development team
    if [[ -z "$DEVELOPMENT_TEAM" ]]; then
        log_warning "DEVELOPMENT_TEAM environment variable nie je nastavená"
        log_info "Nastavte: export DEVELOPMENT_TEAM='YOUR_TEAM_ID'"
    fi
    
    local destination="generic/platform=iOS"
    if [[ -n "$device_name" ]]; then
        destination="platform=iOS,name=$device_name"
    fi
    
    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -derivedDataPath "$BUILD_DIR" \
        -configuration Release \
        DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
        build 2>&1 | tee ios_build.log
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        log_success "Device build dokončený"
    else
        log_error "Chyba pri device builde!"
        log_warning "Skontrolujte certifikáty a provisioning profiles"
        exit 1
    fi
}

# Vytvorí archive pre distribúciu (App Store/TestFlight).
build_archive() {
    log_info "Vytváram archive pre distribution..."
    
    local archive_path="$BUILD_DIR/$PROJECT_NAME.xcarchive"
    
    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "generic/platform=iOS" \
        -archivePath "$archive_path" \
        -derivedDataPath "$BUILD_DIR" \
        -configuration Release \
        DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
        archive 2>&1 | tee ios_build.log
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        log_success "Archive vytvorený: $archive_path"
        
        # Export IPA
        create_export_plist
        export_ipa "$archive_path"
    else
        log_error "Chyba pri vytváraní archive!"
        exit 1
    fi
}

# Vytvorí export.plist pre export IPA.
create_export_plist() {
    local export_plist="$BUILD_DIR/export.plist"
    
    cat > "$export_plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>$DEVELOPMENT_TEAM</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF
    
    log_success "Export plist vytvorený"
}

# Exportuje IPA súbor.
export_ipa() {
    local archive_path="$1"
    local export_path="$BUILD_DIR/export"
    local export_plist="$BUILD_DIR/export.plist"
    
    log_info "Exportujem IPA..."
    
    xcodebuild \
        -exportArchive \
        -archivePath "$archive_path" \
        -exportPath "$export_path" \
        -exportOptionsPlist "$export_plist" 2>&1 | tee -a ios_build.log
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        log_success "IPA exportované do: $export_path"
        
        # Nájdenie IPA súboru
        local ipa_file=$(find "$export_path" -name "*.ipa" | head -1)
        if [[ -n "$ipa_file" ]]; then
            local ipa_size=$(du -h "$ipa_file" | cut -f1)
            log_success "IPA súbor: $ipa_file"
            log_success "Veľkosť IPA: $ipa_size"
        fi
    else
        log_error "Chyba pri exporte IPA!"
        exit 1
    fi
}

# Skontroluje výsledky buildu.
check_results() {
    log_info "Kontrolujem výsledky buildu..."
    
    local app_path=$(find "$BUILD_DIR" -name "$PROJECT_NAME.app" | head -1)
    
    if [[ -n "$app_path" ]]; then
        log_success "APP súbor nájdený: $app_path"
        
        # Informácie o aplikácii
        local bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app_path/Info.plist" 2>/dev/null || echo "N/A")
        local version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app_path/Info.plist" 2>/dev/null || echo "N/A")
        
        log_success "Bundle ID: $bundle_id"
        log_success "Version: $version"
    else
        log_warning "APP súbor nebol nájdený v build výstupe"
    fi
}

# Nainštaluje aplikáciu do simulátora.
install_simulator() {
    local simulator_name="$1"
    if [[ -z "$simulator_name" ]]; then
        simulator_name="iPhone 15"
    fi
    
    log_info "Inštalujem na simulator: $simulator_name"
    
    # Boot simulator ak nie je spustený
    local simulator_id=$(xcrun simctl list devices | grep "$simulator_name" | grep -E -o -i "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})")
    
    if [[ -n "$simulator_id" ]]; then
        xcrun simctl boot "$simulator_id" 2>/dev/null || true
        
        # Nájdenie APP súboru
        local app_path=$(find "$BUILD_DIR" -name "$PROJECT_NAME.app" | head -1)
        
        if [[ -n "$app_path" ]]; then
            xcrun simctl install "$simulator_id" "$app_path"
            log_success "Aplikácia nainštalovaná na simulator"
            
            # Spustenie aplikácie
            local bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app_path/Info.plist" 2>/dev/null)
            if [[ -n "$bundle_id" ]]; then
                xcrun simctl launch "$simulator_id" "$bundle_id"
                log_success "Aplikácia spustená"
            fi
        else
            log_error "APP súbor nenájdený pre inštaláciu"
        fi
    else
        log_error "Simulator '$simulator_name' nenájdený"
    fi
}

# Zobrazí nápovedu pre skript.
show_help() {
    echo "Použitie: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --simulator [NAME]    Build pre iOS Simulator (default: iPhone 15)"
    echo "  --device [NAME]       Build pre fyzické zariadenie"
    echo "  --archive             Vytvor archive pre distribution"
    echo "  --install [NAME]      Nainštaluj na simulator po builde"
    echo "  --clean               Vyčisti build súbory pred buildovaním"
    echo "  --list                Zobraz dostupné destinations"
    echo "  --help                Zobraz túto nápovedu"
    echo ""
    echo "Environment variables:"
    echo "  DEVELOPMENT_TEAM      Team ID pre device/archive build"
    echo ""
    echo "Príklady:"
    echo "  $0 --simulator                     # Build pre default simulator"
    echo "  $0 --simulator \"iPhone 14 Pro\"    # Build pre konkrétny simulator"
    echo "  $0 --device --archive              # Build a archive pre zariadenie"
    echo "  $0 --clean --simulator --install   # Clean build a inštalácia"
    echo "  $0 --list                          # Zobraz destinations"
}

# Hlavný vstup do skriptu.
main() {
    local BUILD_TYPE=""
    local TARGET_NAME=""
    local CLEAN_BUILD=false
    local INSTALL_APP=false
    
    # Parse argumenty
    while [[ $# -gt 0 ]]; do
        case $1 in
            --simulator)
                BUILD_TYPE="simulator"
                if [[ -n "$2" && "$2" != --* ]]; then
                    TARGET_NAME="$2"
                    shift
                fi
                shift
                ;;
            --device)
                BUILD_TYPE="device"
                if [[ -n "$2" && "$2" != --* ]]; then
                    TARGET_NAME="$2"
                    shift
                fi
                shift
                ;;
            --archive)
                BUILD_TYPE="archive"
                shift
                ;;
            --install)
                INSTALL_APP=true
                if [[ -n "$2" && "$2" != --* ]]; then
                    TARGET_NAME="$2"
                    shift
                fi
                shift
                ;;
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --list)
                check_requirements
                list_destinations
                exit 0
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Neznámy argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Default na simulator ak nie je špecifikované
    if [[ -z "$BUILD_TYPE" ]]; then
        BUILD_TYPE="simulator"
        log_info "Žiadny build type špecifikovaný, používam --simulator"
    fi
    
    # Začiatok buildu
    echo "🕐 Čas spustenia: $(date)"
    echo ""
    
    check_requirements
    
    if [[ "$CLEAN_BUILD" == true ]]; then
        clean_build
    fi
    
    # Vytvorenie build adresára
    mkdir -p "$BUILD_DIR"
    
    # Build podľa typu
    case $BUILD_TYPE in
        simulator)
            build_simulator "$TARGET_NAME"
            ;;
        device)
            build_device "$TARGET_NAME"
            ;;
        archive)
            build_archive
            ;;
    esac
    
    check_results
    
    # Inštalácia ak je požadovaná
    if [[ "$INSTALL_APP" == true && "$BUILD_TYPE" == "simulator" ]]; then
        install_simulator "$TARGET_NAME"
    fi
    
    echo ""
    echo "🎉 iOS build dokončený úspešne!"
    echo "🕐 Čas dokončenia: $(date)"
    
    if [[ "$BUILD_TYPE" == "archive" ]]; then
        echo ""
        log_success "Archive pripravený pre distribution"
    fi
}

# Spustenie main funkcie
main "$@"
