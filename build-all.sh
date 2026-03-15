#!/bin/bash

# build-all.sh
# Univerzálny build skript pre Android aj iOS.

set -e  # Exit on any error

echo "🚀 DataIndicator Universal Build Script"
echo "======================================="

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

# Zistí operačný systém.
detect_platform() {
    case "$OSTYPE" in
        linux*)   
            PLATFORM="linux"
            log_info "Detekovaná platforma: Linux"
            ;;
        darwin*)  
            PLATFORM="macos"
            log_info "Detekovaná platforma: macOS"
            ;;
        msys*|cygwin*|mingw*)    
            PLATFORM="windows"
            log_info "Detekovaná platforma: Windows"
            ;;
        *)        
            PLATFORM="unknown"
            log_warning "Neznáma platforma: $OSTYPE"
            ;;
    esac
}

# Skontroluje, či existujú build skripty.
check_build_scripts() {
    log_info "Kontrolujem build skripty..."
    
    if [[ ! -f "build-android.sh" ]]; then
        log_error "build-android.sh nenájdený!"
        exit 1
    fi
    
    if [[ ! -f "build-ios.sh" ]]; then
        log_error "build-ios.sh nenájdený!"
        exit 1
    fi
    
    # Make executable
    chmod +x build-android.sh
    chmod +x build-ios.sh
    
    log_success "Build skripty pripravené"
}

# Spustí Android build.
build_android() {
    local android_args="$1"
    
    echo ""
    echo "🤖 ================="
    echo "🤖 ANDROID BUILD"
    echo "🤖 ================="
    echo ""
    
    log_info "Spúšťam Android build..."
    
    if ./build-android.sh $android_args; then
        log_success "Android build dokončený úspešne"
        return 0
    else
        log_error "Android build zlyhal!"
        return 1
    fi
}

# Spustí iOS build (len na macOS).
build_ios() {
    local ios_args="$1"
    
    echo ""
    echo "🍎 ================="
    echo "🍎 iOS BUILD"
    echo "🍎 ================="
    echo ""
    
    if [[ "$PLATFORM" != "macos" ]]; then
        log_warning "iOS build je možný len na macOS"
        log_info "Preskakujem iOS build na $PLATFORM"
        return 0
    fi
    
    log_info "Spúšťam iOS build..."
    
    if ./build-ios.sh $ios_args; then
        log_success "iOS build dokončený úspešne"
        return 0
    else
        log_error "iOS build zlyhal!"
        return 1
    fi
}

# Vypíše zhrnutie výsledkov buildov.
show_summary() {
    local android_success="$1"
    local ios_success="$2"
    
    echo ""
    echo "📊 ================="
    echo "📊 BUILD SUMMARY"
    echo "📊 ================="
    echo ""
    
    # Android summary
    if [[ "$android_success" == "true" ]]; then
        if [[ -f "app/build/outputs/apk/release/app-release-unsigned.apk" ]]; then
            local apk_size=$(du -h "app/build/outputs/apk/release/app-release-unsigned.apk" | cut -f1)
            log_success "Android APK: app/build/outputs/apk/release/app-release-unsigned.apk ($apk_size)"
        else
            log_success "Android build dokončený"
        fi
    else
        log_error "Android build zlyhal"
    fi
    
    # iOS summary
    if [[ "$PLATFORM" == "macos" ]]; then
        if [[ "$ios_success" == "true" ]]; then
            if [[ -d "ios/build" ]]; then
                log_success "iOS build dokončený: ios/build/"
                
                # Hľadanie IPA súboru
                local ipa_file=$(find ios/build -name "*.ipa" 2>/dev/null | head -1)
                if [[ -n "$ipa_file" ]]; then
                    local ipa_size=$(du -h "$ipa_file" | cut -f1)
                    log_success "iOS IPA: $ipa_file ($ipa_size)"
                fi
            else
                log_success "iOS build dokončený"
            fi
        else
            log_error "iOS build zlyhal"
        fi
    else
        log_info "iOS build preskočený (nie macOS)"
    fi
    
    echo ""
    
    # Celkové zhrnutie
    local total_success=0
    local total_builds=1  # Android je vždy
    
    if [[ "$android_success" == "true" ]]; then
        ((total_success++))
    fi
    
    if [[ "$PLATFORM" == "macos" ]]; then
        ((total_builds++))
        if [[ "$ios_success" == "true" ]]; then
            ((total_success++))
        fi
    fi
    
    if [[ $total_success -eq $total_builds ]]; then
        log_success "Všetky buildy dokončené úspešne! ($total_success/$total_builds)"
    else
        log_warning "Niektoré buildy zlyhali ($total_success/$total_builds)"
    fi
}

# Vyčistí dočasné súbory.
cleanup() {
    log_info "Vykonávam cleanup..."
    
    # Cleanup Android temporary súbory
    if [[ -d "build/tmp" ]]; then
        rm -rf build/tmp/
    fi

    if [[ -d "app/build/tmp" ]]; then
        rm -rf app/build/tmp/
    fi
    
    # Cleanup iOS temporary súbory
    if [[ -d "ios/build/tmp" ]]; then
        rm -rf ios/build/tmp/
    fi
    
    log_success "Cleanup dokončený"
}

# Zobrazí nápovedu pre skript.
show_help() {
    echo "Použitie: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --android-only        Build len Android"
    echo "  --ios-only            Build len iOS (len macOS)"
    echo "  --clean               Clean build pre oba projekty"
    echo "  --sign                Podpísať Android APK"
    echo "  --archive             Vytvoriť iOS archive"
    echo "  --simulator [NAME]    iOS simulator build"
    echo "  --device              iOS device build"
    echo "  --install             Nainštalovať iOS na simulator"
    echo "  --help                Zobraziť túto nápovedu"
    echo ""
    echo "Príklady:"
    echo "  $0                    # Build Android + iOS (ak macOS)"
    echo "  $0 --clean --sign    # Clean build s podpisovaním Android"
    echo "  $0 --ios-only --simulator \"iPhone 15\""
    echo "  $0 --android-only --clean"
    echo ""
    echo "Podporované platformy:"
    echo "  Linux/Windows: Android only"
    echo "  macOS: Android + iOS"
}

# Hlavný vstup do skriptu.
main() {
    local BUILD_ANDROID=true
    local BUILD_IOS=true
    local ANDROID_ARGS=""
    local IOS_ARGS=""
    
    # Parse argumenty
    while [[ $# -gt 0 ]]; do
        case $1 in
            --android-only)
                BUILD_IOS=false
                shift
                ;;
            --ios-only)
                BUILD_ANDROID=false
                shift
                ;;
            --clean)
                ANDROID_ARGS="$ANDROID_ARGS --clean"
                IOS_ARGS="$IOS_ARGS --clean"
                shift
                ;;
            --sign)
                ANDROID_ARGS="$ANDROID_ARGS --sign"
                shift
                ;;
            --archive)
                IOS_ARGS="$IOS_ARGS --archive"
                shift
                ;;
            --simulator)
                IOS_ARGS="$IOS_ARGS --simulator"
                if [[ -n "$2" && "$2" != --* ]]; then
                    IOS_ARGS="$IOS_ARGS $2"
                    shift
                fi
                shift
                ;;
            --device)
                IOS_ARGS="$IOS_ARGS --device"
                shift
                ;;
            --install)
                IOS_ARGS="$IOS_ARGS --install"
                shift
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
    
    # Začiatok
    echo "🕐 Čas spustenia: $(date)"
    echo ""
    
    detect_platform
    check_build_scripts
    
    # Results tracking
    local android_success="false"
    local ios_success="false"
    
    # Build Android
    if [[ "$BUILD_ANDROID" == true ]]; then
        if build_android "$ANDROID_ARGS"; then
            android_success="true"
        fi
    else
        android_success="skipped"
    fi
    
    # Build iOS
    if [[ "$BUILD_IOS" == true ]]; then
        if build_ios "$IOS_ARGS"; then
            ios_success="true"
        fi
    else
        ios_success="skipped"
    fi
    
    # Cleanup
    cleanup
    
    # Summary
    show_summary "$android_success" "$ios_success"
    
    echo ""
    echo "🎉 Universal build dokončený!"
    echo "🕐 Čas dokončenia: $(date)"
    
    # Exit code
    if [[ "$android_success" == "true" || "$android_success" == "skipped" ]] && \
       [[ "$ios_success" == "true" || "$ios_success" == "skipped" ]]; then
        exit 0
    else
        exit 1
    fi
}

# Trap pre cleanup pri prerušení
trap cleanup EXIT

# Spustenie main funkcie
main "$@"
