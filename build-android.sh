#!/bin/bash

# build-android.sh
# Skript na buildovanie Android APK (lokálne alebo v kontajneri).

set -e  # Exit on any error

echo "🤖 DataIndicator Android Build Script"
echo "======================================"

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

# Kontrola requirements (Docker/Podman, gradle súbory)
check_requirements() {
    log_info "Kontrolujem requirements..."
    
    # Kontrola Docker/Podman
    if command -v podman &> /dev/null; then
        CONTAINER_CMD="podman"
        log_success "Podman nájdený"
    elif command -v docker &> /dev/null; then
        CONTAINER_CMD="docker"
        log_success "Docker nájdený"
    else
        log_error "Ani Docker ani Podman nie sú nainštalované!"
        exit 1
    fi
    
    # Kontrola súborov
    if [[ ! -f "build.gradle" ]]; then
        log_error "build.gradle nenájdený! Spustite skript z root adresára projektu."
        exit 1
    fi
    
    if [[ ! -f "gradle.Dockerfile" ]]; then
        log_error "gradle.Dockerfile nenájdený!"
        exit 1
    fi
}

# Vyčistí build adresáre.
clean_build() {
    log_info "Čistím predchádzajúce buildy..."
    
    if [[ -d "build" ]]; then
        rm -rf build/
        log_success "Root build adresár vyčistený"
    fi

    if [[ -d "app/build" ]]; then
        rm -rf app/build/
        log_success "App build adresár vyčistený"
    fi
    
    if [[ -d ".gradle" ]]; then
        rm -rf .gradle/
        log_success "Gradle cache vyčistený"
    fi
}

# Zbuildí kontajner s Android SDK a Gradle.
build_container() {
    log_info "Buildjem Android build container..."
    
    $CONTAINER_CMD build -f gradle.Dockerfile -t android-gradle-builder . 2>&1 | tee build.log
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        log_success "Container úspešne zbuildený"
    else
        log_error "Chyba pri buildovaní containera!"
        exit 1
    fi
}

# Zbuildí APK cez Gradle.
build_apk() {
    log_info "Buildjem Android APK..."
    
    # Spustenie Gradle buildu v containeri
    $CONTAINER_CMD run --rm \
        -v "$(pwd)":/app \
        -w /app \
        android-gradle-builder \
        ./gradlew :app:assembleRelease 2>&1 | tee -a build.log
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        log_success "APK úspešne zbuildený"
    else
        log_error "Chyba pri buildovaní APK!"
        exit 1
    fi
}

# Skontroluje výstupný APK a vypíše informácie.
check_results() {
    log_info "Kontrolujem výsledky buildu..."
    
    APK_PATH="app/build/outputs/apk/release/app-release-unsigned.apk"
    
    if [[ -f "$APK_PATH" ]]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        log_success "APK súbor nájdený: $APK_PATH"
        log_success "Veľkosť APK: $APK_SIZE"
        
        # Overenie zipalign
        if command -v aapt &> /dev/null; then
            log_info "Overujem zipalign..."
            if aapt dump badging "$APK_PATH" &> /dev/null; then
                log_success "APK je validný a zipalign správny"
            else
                log_warning "APK možno nie je správne zipalign-ovaný"
            fi
        fi
    else
        log_error "APK súbor nebol nájdený!"
        exit 1
    fi
}

# Voliteľné podpísanie APK po builde.
sign_apk() {
    if [[ "$1" == "--sign" ]]; then
        log_info "Podpisujem APK..."
        
        if [[ -f "sign.sh" ]]; then
            chmod +x sign.sh
            ./sign.sh
            log_success "APK podpísaný"
        else
            log_warning "sign.sh skript nenájdený, preskakujem podpisovanie"
        fi
    fi
}

# Vyčistí dočasné súbory.
cleanup() {
    log_info "Čistím temporary súbory..."
    
    # Nemazať build adresár, len temporary súbory
    if [[ -d "build/tmp" ]]; then
        rm -rf build/tmp/
    fi

    if [[ -d "app/build/tmp" ]]; then
        rm -rf app/build/tmp/
    fi
    
    log_success "Cleanup dokončený"
}

# Zobrazí nápovedu pre skript.
show_help() {
    echo "Použitie: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --clean       Vyčistiť všetky build súbory pred buildovaním"
    echo "  --sign        Podpísať APK po buildovaní (vyžaduje sign.sh)"
    echo "  --no-container Použiť lokálny Gradle namiesto containera"
    echo "  --help        Zobraziť túto nápovedu"
    echo ""
    echo "Príklady:"
    echo "  $0                    # Základný build"
    echo "  $0 --clean --sign    # Clean build s podpisovaním"
    echo "  $0 --no-container    # Lokálny build bez containera"
}

# Hlavný vstup do skriptu.
main() {
    local CLEAN_BUILD=false
    local SIGN_APK=false
    local USE_CONTAINER=true
    
    # Parse argumenty
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                CLEAN_BUILD=true
                shift
                ;;
            --sign)
                SIGN_APK=true
                shift
                ;;
            --no-container)
                USE_CONTAINER=false
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
    
    # Začiatok buildu
    echo "🕐 Čas spustenia: $(date)"
    echo ""
    
    # Clean ak je požadovaný
    if [[ "$CLEAN_BUILD" == true ]]; then
        clean_build
    fi
    
    if [[ "$USE_CONTAINER" == true ]]; then
        check_requirements
        build_container
        build_apk
    else
        log_info "Buildjem lokálne pomocou Gradle..."
        if [[ ! -f "gradlew" ]]; then
            log_error "gradlew nenájdený!"
            exit 1
        fi
        
        chmod +x gradlew
        ./gradlew :app:assembleRelease 2>&1 | tee build.log
        
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            log_success "Lokálny build dokončený"
        else
            log_error "Chyba pri lokálnom builde!"
            exit 1
        fi
    fi
    
    check_results
    
    if [[ "$SIGN_APK" == true ]]; then
        sign_apk --sign
    fi
    
    cleanup
    
    echo ""
    echo "🎉 Build dokončený úspešne!"
    echo "🕐 Čas dokončenia: $(date)"
    echo ""
    log_success "APK pripravený na inštaláciu: app/build/outputs/apk/release/app-release-unsigned.apk"
}

# Spustenie main funkcie
main "$@"
