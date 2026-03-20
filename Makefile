# Makefile
# Zjednodušené príkazy pre build, podpis a inštaláciu APK.

# Premenné
DOCKER_IMAGE = android-gradle-builder
DOCKER_FILE = gradle.Dockerfile
APK_PATH = app/build/outputs/apk/release/app-release-unsigned.apk
AAB_PATH = app/build/outputs/bundle/release/app-release.aab
BUILD_DIR = app/build

# Farby pre výstup
GREEN = \033[0;32m
BLUE = \033[0;34m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Hlavný cieľ - build APK
.PHONY: apk
apk: clean build-docker build-apk
	@echo -e "$(GREEN)✅ APK úspešne zbuildované a zarovnané!$(NC)"
	@echo -e "$(BLUE)📁 Súbor: $(APK_PATH)$(NC)"
	@echo -e "$(BLUE)📏 Veľkosť: $$(du -h $(APK_PATH) | cut -f1)$(NC)"
	@echo -e "$(YELLOW)🔐 Na podpísanie použite: ./sign.sh$(NC)"

# Vyčistenie build adresára
.PHONY: clean
clean:
	@echo -e "$(BLUE)🧹 Čistenie build adresára...$(NC)"
	@rm -rf $(BUILD_DIR) build
	@echo -e "$(GREEN)✅ Build adresár vyčistený$(NC)"

# Build Docker kontajnera
.PHONY: build-docker
build-docker:
	@echo -e "$(BLUE)🐳 Buildovanie Docker kontajnera...$(NC)"
	@if ! podman images | grep -q $(DOCKER_IMAGE); then \
		echo -e "$(YELLOW)📦 Kontajner neexistuje, buildovanie...$(NC)"; \
		podman build -f $(DOCKER_FILE) -t $(DOCKER_IMAGE) .; \
	else \
		echo -e "$(GREEN)✅ Docker kontajner už existuje$(NC)"; \
	fi

# Obnova Docker kontajnera (force rebuild)
.PHONY: rebuild-docker
rebuild-docker:
	@echo -e "$(BLUE)🔄 Obnova Docker kontajnera...$(NC)"
	@podman rmi -f $(DOCKER_IMAGE) 2>/dev/null || true
	@podman build -f $(DOCKER_FILE) -t $(DOCKER_IMAGE) .
	@echo -e "$(GREEN)✅ Docker kontajner obnovený$(NC)"

# Build APK v kontajneri
.PHONY: build-apk
build-apk: version
	@echo -e "$(BLUE)🔨 Buildovanie APK v kontajneri...$(NC)"
	@echo -e "$(YELLOW)⚠️  APK bude automaticky zipalign zarovnané$(NC)"
	@podman run --rm -v $$(pwd):/app -w /app $(DOCKER_IMAGE)
	@if [ -f "$(APK_PATH)" ]; then \
		echo -e "$(GREEN)✅ APK úspešne vytvorené$(NC)"; \
	else \
		echo -e "$(RED)❌ Chyba: APK súbor nenájdený$(NC)"; \
		exit 1; \
	fi

# Rýchly build (bez čistenia)
.PHONY: quick
quick: build-apk
	@echo -e "$(GREEN)⚡ Rýchly build dokončený$(NC)"
	@echo -e "$(BLUE)📁 APK: $(APK_PATH)$(NC)"

# Bump Android version (patch)
.PHONY: version
version:
	@python3 -c "import re,sys; from pathlib import Path; path=Path('app/build.gradle'); text=path.read_text(); vc=re.search(r'versionCode\\s+(\\d+)', text); vn=re.search(r'versionName\\s+\\\"([0-9]+)\\.([0-9]+)\\\"', text); (vc and vn) or sys.exit('versionCode/versionName nenájdené v app/build.gradle'); version_code=int(vc.group(1))+1; major=int(vn.group(1)); minor=int(vn.group(2))+1; text=re.sub(r'versionCode\\s+\\d+', f'versionCode {version_code}', text); text=re.sub(r'versionName\\s+\\\"[0-9]+\\.[0-9]+\\\"', f'versionName \\\"{major}.{minor}\\\"', text); path.write_text(text); print(f'Bumped versionCode -> {version_code}, versionName -> {major}.{minor}')"

# Full rebuild: Build v kontajneri -> Assemble Debug -> Copy APK
.PHONY: rebuild-apk
rebuild-apk: version build-docker
	@podman run --rm -v "$$(pwd):/app" -w "/app" $(DOCKER_IMAGE) ./gradlew :app:assembleDebug
	@cp app/build/outputs/apk/debug/app-debug.apk ./DataIndicator.apk
	@echo -e "$(GREEN)Build complete! APK is at ./DataIndicator.apk$(NC)"

# Build AAB (Android App Bundle) pre Google Play
.PHONY: build-aab
build-aab: version build-docker
	@echo -e "$(BLUE)📦 Buildovanie AAB v kontajneri...$(NC)"
	@podman run --rm -v "$$(pwd):/app" -w "/app" $(DOCKER_IMAGE) ./gradlew :app:bundleRelease
	@if [ -f "$(AAB_PATH)" ]; then \
		cp $(AAB_PATH) ./DataIndicator.aab; \
		echo -e "$(GREEN)✅ AAB úspešne vytvorené$(NC)"; \
		echo -e "$(BLUE)📁 Súbor: ./DataIndicator.aab$(NC)"; \
		echo -e "$(BLUE)📏 Veľkosť: $$(du -h ./DataIndicator.aab | cut -f1)$(NC)"; \
	else \
		echo -e "$(RED)❌ Chyba: AAB súbor nenájdený$(NC)"; \
		exit 1; \
	fi

# Podpísanie AAB pre Google Play
.PHONY: sign-aab
sign-aab:
	@../android.sign.aab.sh DataIndicator.aab DataIndicator.sign.aab

# Deploy AAB: build + sign
.PHONY: deploy-aab
deploy-aab: build-aab sign-aab
	@echo -e "$(GREEN)🎉 AAB pripravené pre Google Play: ./DataIndicator.sign.aab$(NC)"

# Podpísanie APK pre deploy flow
.PHONY: sign-apk
sign-apk:
	@../android.sign.sh DataIndicator.apk DataIndicator.sign.apk

# Inštalácia podpísaného APK
.PHONY: install-apk
install-apk:
	@adb install -r DataIndicator.sign.apk

# Deploy: rebuild + sign + install
.PHONY: deploy
deploy: rebuild-apk sign-apk install-apk

# Podpísanie APK
.PHONY: sign
sign:
	@echo -e "$(BLUE)🔐 Podpisovanie APK...$(NC)"
	@if [ ! -f "$(APK_PATH)" ]; then \
		echo -e "$(RED)❌ APK súbor nenájdený. Spustite najprv: make apk$(NC)"; \
		exit 1; \
	fi
	@./sign.sh
	@echo -e "$(GREEN)✅ APK podpísané$(NC)"

# Kompletný workflow - build + sign
.PHONY: release
release: apk sign
	@echo -e "$(GREEN)🎉 Release APK pripravené!$(NC)"
	@echo -e "$(BLUE)📦 Podpísané APK: app/build/outputs/apk/release/app-release-unsigned-signed.apk$(NC)"

# Inštalácia na zariadenie cez ADB
.PHONY: install
install:
	@SIGNED_APK="app/build/outputs/apk/release/app-release-unsigned-signed.apk"; \
	if [ -f "$$SIGNED_APK" ]; then \
		echo -e "$(BLUE)📱 Inštalácia podpísaného APK...$(NC)"; \
		adb install "$$SIGNED_APK"; \
	elif [ -f "$(APK_PATH)" ]; then \
		echo -e "$(YELLOW)⚠️  Inštalácia nepodpísaného APK...$(NC)"; \
		adb install "$(APK_PATH)"; \
	else \
		echo -e "$(RED)❌ Žiadne APK na inštaláciu. Spustite: make apk$(NC)"; \
		exit 1; \
	fi

# Inštalácia s prepisovaním existujúcej aplikácie
.PHONY: install-force
install-force:
	@SIGNED_APK="app/build/outputs/apk/release/app-release-unsigned-signed.apk"; \
	if [ -f "$$SIGNED_APK" ]; then \
		echo -e "$(BLUE)📱 Prepisovanie aplikácie podpísaným APK...$(NC)"; \
		adb install -r "$$SIGNED_APK"; \
	elif [ -f "$(APK_PATH)" ]; then \
		echo -e "$(YELLOW)⚠️  Prepisovanie aplikácie nepodpísaným APK...$(NC)"; \
		adb install -r "$(APK_PATH)"; \
	else \
		echo -e "$(RED)❌ Žiadne APK na inštaláciu. Spustite: make apk$(NC)"; \
		exit 1; \
	fi

# Zobrazenie informácií o APK
.PHONY: info
info:
	@echo -e "$(BLUE)📋 Informácie o projekte:$(NC)"
	@echo -e "$(BLUE)├─ Docker Image: $(DOCKER_IMAGE)$(NC)"
	@echo -e "$(BLUE)├─ Docker File: $(DOCKER_FILE)$(NC)"
	@echo -e "$(BLUE)└─ APK Path: $(APK_PATH)$(NC)"
	@echo
	@if [ -f "$(APK_PATH)" ]; then \
		echo -e "$(GREEN)📦 APK existuje:$(NC)"; \
		echo -e "$(BLUE)├─ Veľkosť: $$(du -h $(APK_PATH) | cut -f1)$(NC)"; \
		echo -e "$(BLUE)├─ Dátum: $$(stat -c %y $(APK_PATH) | cut -d' ' -f1-2)$(NC)"; \
		echo -e "$(BLUE)└─ Cesta: $(APK_PATH)$(NC)"; \
	else \
		echo -e "$(YELLOW)⚠️  APK neexistuje$(NC)"; \
	fi
	@echo
	@SIGNED_APK="app/build/outputs/apk/release/app-release-unsigned-signed.apk"; \
	if [ -f "$$SIGNED_APK" ]; then \
		echo -e "$(GREEN)🔐 Podpísané APK existuje:$(NC)"; \
		echo -e "$(BLUE)├─ Veľkosť: $$(du -h $$SIGNED_APK | cut -f1)$(NC)"; \
		echo -e "$(BLUE)├─ Dátum: $$(stat -c %y $$SIGNED_APK | cut -d' ' -f1-2)$(NC)"; \
		echo -e "$(BLUE)└─ Cesta: $$SIGNED_APK$(NC)"; \
	else \
		echo -e "$(YELLOW)🔐 Podpísané APK neexistuje$(NC)"; \
	fi

# Spustenie aplikácie na zariadení
.PHONY: run
run:
	@echo -e "$(BLUE)🚀 Spúšťanie aplikácie...$(NC)"
	@adb shell am start -n sk.dataindicator/.MainActivity

# Zobrazenie logov aplikácie
.PHONY: logs
logs:
	@echo -e "$(BLUE)📋 Zobrazovanie logov aplikácie...$(NC)"
	@adb logcat -s "DataIndicator"

# Vyčistenie všetkého (build + docker)
.PHONY: clean-all
clean-all: clean
	@echo -e "$(BLUE)🧹 Odstránenie Docker kontajnera...$(NC)"
	@podman rmi -f $(DOCKER_IMAGE) 2>/dev/null || true
	@echo -e "$(GREEN)✅ Všetko vyčistené$(NC)"

# Nápoveda
.PHONY: help
help:
	@echo -e "$(BLUE)📖 Android APK Build Makefile$(NC)"
	@echo -e "$(BLUE)═══════════════════════════════$(NC)"
	@echo
	@echo -e "$(GREEN)Hlavné príkazy:$(NC)"
	@echo -e "$(YELLOW)  make apk$(NC)           - Zbuilduje APK (clean + docker + build)"
	@echo -e "$(YELLOW)  make quick$(NC)         - Rýchly build (bez clean)"
	@echo -e "$(YELLOW)  make sign$(NC)          - Podpíše existujúce APK"
	@echo -e "$(YELLOW)  make release$(NC)       - Kompletný workflow (build + sign)"
	@echo
	@echo -e "$(GREEN)Docker operácie:$(NC)"
	@echo -e "$(YELLOW)  make build-docker$(NC)  - Zbuilduje Docker kontajner"
	@echo -e "$(YELLOW)  make rebuild-docker$(NC) - Obnová Docker kontajnera"
	@echo
	@echo -e "$(GREEN)AAB pre Google Play:$(NC)"
	@echo -e "$(YELLOW)  make build-aab$(NC)     - Zbuilduje AAB pre Google Play"
	@echo -e "$(YELLOW)  make sign-aab$(NC)      - Podpíše existujúce AAB"
	@echo -e "$(YELLOW)  make deploy-aab$(NC)    - Build + sign AAB"
	@echo
	@echo -e "$(GREEN)Zariadenie a testovanie:$(NC)"
	@echo -e "$(YELLOW)  make install$(NC)       - Inštaluje APK na zariadenie"
	@echo -e "$(YELLOW)  make install-force$(NC) - Inštaluje s prepisovaním"
	@echo -e "$(YELLOW)  make run$(NC)           - Spustí aplikáciu"
	@echo -e "$(YELLOW)  make logs$(NC)          - Zobrazí logy aplikácie"
	@echo
	@echo -e "$(GREEN)Údržba:$(NC)"
	@echo -e "$(YELLOW)  make clean$(NC)         - Vyčistí build adresár" 
	@echo -e "$(YELLOW)  make clean-all$(NC)     - Vyčistí všetko (build + docker)"
	@echo -e "$(YELLOW)  make info$(NC)          - Zobrazí informácie o projekte"
	@echo -e "$(YELLOW)  make help$(NC)          - Zobrazí túto nápovedu"
	@echo
	@echo -e "$(BLUE)💡 Tip: APK je automaticky zipalign zarovnané!$(NC)"

# Predvolený cieľ
.DEFAULT_GOAL := help
