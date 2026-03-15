# Dockerfile
# Multi-stage build pre Maven variantu (export APK ako artefakt).
FROM openjdk:17-jdk-slim AS builder

# Nastavenie prostredia
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

# Inštalácia závislostí
RUN apt-get update && apt-get install -y \
    unzip \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Stiahnutie Android SDK
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm cmdline-tools.zip

# Inštalácia Android SDK komponentov
RUN yes | sdkmanager --licenses > /dev/null 2>&1 && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null 2>&1

# Kopírovanie projektu
WORKDIR /app
COPY . .

# Build aplikácie
RUN chmod +x ./mvnw && \
    ./mvnw clean package -q

# Produkčný stage
FROM scratch AS output
COPY --from=builder /app/target/connection-indicator.apk /connection-indicator.apk
